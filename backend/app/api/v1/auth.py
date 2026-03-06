from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.core.database import get_db
from app.core.security import verify_password, create_access_token, hash_password, get_current_user
from app.models.user import User
from app.models.tenant import Tenant

router = APIRouter(prefix="/auth", tags=["Autenticacao"])

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    tenant_id: Optional[int]
    tenant_name: Optional[str]

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    tenant_id: Optional[int]
    is_active: bool

    class Config:
        from_attributes = True

@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Email ou senha incorretos")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Usuario inativo")

    # Verificar se tenant esta ativo
    if user.tenant_id:
        tenant = db.query(Tenant).filter(Tenant.id == user.tenant_id).first()
        if not tenant or not tenant.is_active:
            raise HTTPException(status_code=403, detail="Conta inativa. Entre em contato com o suporte.")
        tenant_name = tenant.name
    else:
        tenant_name = "Fortcam Cloud"

    token = create_access_token({
        "sub": str(user.id),
        "email": user.email,
        "role": user.role,
        "tenant_id": user.tenant_id
    })
    return {"access_token": token, "role": user.role, "tenant_id": user.tenant_id, "tenant_name": tenant_name}

@router.get("/me", response_model=UserResponse)
def me(current_user=Depends(get_current_user)):
    return current_user

@router.post("/users", response_model=UserResponse)
def create_user(
    name: str, email: str, password: str, role: str = "operator",
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email ja cadastrado")

    user = User(
        tenant_id=current_user.tenant_id,
        name=name, email=email,
        hashed_password=hash_password(password),
        role=role
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user