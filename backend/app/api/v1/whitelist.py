from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.whitelist import Whitelist

router = APIRouter(prefix="/whitelist", tags=["Whitelist"])

class WhitelistCreate(BaseModel):
    plate: str
    owner_name: str
    time_start: str = "00:00"
    time_end: str = "23:59"
    is_active: bool = True
    notes: Optional[str] = None

class WhitelistUpdate(BaseModel):
    owner_name: Optional[str] = None
    time_start: Optional[str] = None
    time_end: Optional[str] = None
    is_active: Optional[bool] = None
    notes: Optional[str] = None

class WhitelistResponse(BaseModel):
    id: int
    plate: str
    owner_name: str
    time_start: str
    time_end: str
    is_active: bool
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

def get_tenant_id(current_user):
    if not current_user.tenant_id:
        raise HTTPException(status_code=400, detail="Usuario sem tenant")
    return current_user.tenant_id

@router.get("/", response_model=List[WhitelistResponse])
def list_whitelist(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    return db.query(Whitelist).filter(Whitelist.tenant_id == tid).order_by(Whitelist.created_at.desc()).all()

@router.post("/", response_model=WhitelistResponse)
def add_plate(data: WhitelistCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    if db.query(Whitelist).filter(Whitelist.tenant_id == tid, Whitelist.plate == data.plate.upper()).first():
        raise HTTPException(status_code=400, detail="Placa ja cadastrada")
    entry = Whitelist(tenant_id=tid, **data.model_dump(), plate=data.plate.upper())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry

@router.put("/{plate_id}", response_model=WhitelistResponse)
def update_plate(plate_id: int, data: WhitelistUpdate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    entry = db.query(Whitelist).filter(Whitelist.id == plate_id, Whitelist.tenant_id == tid).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Placa nao encontrada")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry

@router.delete("/{plate_id}")
def delete_plate(plate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    entry = db.query(Whitelist).filter(Whitelist.id == plate_id, Whitelist.tenant_id == tid).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Placa nao encontrada")
    db.delete(entry)
    db.commit()
    return {"message": "Placa removida"}

@router.get("/check/{plate}")
def check_plate(plate: str, tenant_id: int, db: Session = Depends(get_db)):
    from datetime import datetime as dt
    entry = db.query(Whitelist).filter(
        Whitelist.tenant_id == tenant_id,
        Whitelist.plate == plate.upper(),
        Whitelist.is_active == True
    ).first()
    if not entry:
        return {"allowed": False, "reason": "Placa nao encontrada"}
    now = dt.now().strftime("%H:%M")
    if not (entry.time_start <= now <= entry.time_end):
        return {"allowed": False, "reason": "Fora do horario"}
    return {"allowed": True, "owner": entry.owner_name}