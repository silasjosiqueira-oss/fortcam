from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.core.database import get_db
from app.core.security import get_current_user, require_superadmin, hash_password
from app.models.tenant import Tenant
from app.models.user import User

router = APIRouter(prefix="/tenants", tags=["Tenants (Superadmin)"])

class TenantCreate(BaseModel):
    name: str
    slug: str
    plan: str = "basic"
    max_cameras: int = 5
    max_users: int = 3
    notes: Optional[str] = None
    admin_name: str
    admin_email: str
    admin_password: str

class TenantResponse(BaseModel):
    id: int
    name: str
    slug: str
    plan: str
    max_cameras: int
    max_users: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

@router.get("/", response_model=List[TenantResponse])
def list_tenants(db: Session = Depends(get_db), current_user=Depends(require_superadmin)):
    return db.query(Tenant).all()

@router.post("/", response_model=TenantResponse)
def create_tenant(data: TenantCreate, db: Session = Depends(get_db), current_user=Depends(require_superadmin)):
    if db.query(Tenant).filter(Tenant.slug == data.slug).first():
        raise HTTPException(status_code=400, detail="Slug ja em uso")

    tenant = Tenant(
        name=data.name,
        slug=data.slug,
        plan=data.plan,
        max_cameras=data.max_cameras,
        max_users=data.max_users,
        notes=data.notes
    )
    db.add(tenant)
    db.commit()
    db.refresh(tenant)

    # Criar admin do tenant
    admin = User(
        tenant_id=tenant.id,
        name=data.admin_name,
        email=data.admin_email,
        hashed_password=hash_password(data.admin_password),
        role="admin"
    )
    db.add(admin)
    db.commit()

    return tenant

@router.put("/{tenant_id}/toggle")
def toggle_tenant(tenant_id: int, db: Session = Depends(get_db), current_user=Depends(require_superadmin)):
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant nao encontrado")
    tenant.is_active = not tenant.is_active
    db.commit()
    return {"is_active": tenant.is_active}