from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.whitelist import Whitelist
from app.models.user import User
from app.schemas.whitelist import WhitelistCreate, WhitelistUpdate, WhitelistResponse

router = APIRouter(prefix="/whitelist", tags=["Whitelist"])

@router.get("/", response_model=List[WhitelistResponse])
def list_whitelist(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Whitelist).order_by(Whitelist.created_at.desc()).all()

@router.post("/", response_model=WhitelistResponse)
def add_plate(data: WhitelistCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if db.query(Whitelist).filter(Whitelist.plate == data.plate.upper()).first():
        raise HTTPException(status_code=400, detail="Placa ja cadastrada")
    entry = Whitelist(**data.model_dump(), plate=data.plate.upper())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry

@router.put("/{plate_id}", response_model=WhitelistResponse)
def update_plate(plate_id: int, data: WhitelistUpdate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    entry = db.query(Whitelist).filter(Whitelist.id == plate_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Placa nao encontrada")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry

@router.delete("/{plate_id}")
def delete_plate(plate_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    entry = db.query(Whitelist).filter(Whitelist.id == plate_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Placa nao encontrada")
    db.delete(entry)
    db.commit()
    return {"message": "Placa removida com sucesso"}

@router.get("/check/{plate}")
def check_plate(plate: str, db: Session = Depends(get_db)):
    from datetime import datetime
    entry = db.query(Whitelist).filter(
        Whitelist.plate == plate.upper(),
        Whitelist.is_active == True
    ).first()
    if not entry:
        return {"allowed": False, "reason": "Placa nao encontrada na whitelist"}
    now = datetime.now().strftime("%H:%M")
    if not (entry.time_start <= now <= entry.time_end):
        return {"allowed": False, "reason": "Fora do horario permitido"}
    return {"allowed": True, "owner": entry.owner_name}
