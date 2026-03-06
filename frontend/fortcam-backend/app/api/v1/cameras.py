from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.camera import Camera
from app.models.user import User

router = APIRouter(prefix="/cameras", tags=["Cameras"])

class CameraCreate(BaseModel):
    name: str
    serial: str
    ip: str = ""
    location: str = ""
    mqtt_topic: str = ""

class CameraResponse(BaseModel):
    id: int
    name: str
    serial: str
    ip: str | None
    location: str | None
    is_online: bool
    is_active: bool

    class Config:
        from_attributes = True

@router.get("/", response_model=List[CameraResponse])
def list_cameras(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return db.query(Camera).filter(Camera.is_active == True).all()

@router.post("/", response_model=CameraResponse)
def create_camera(data: CameraCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Apenas administradores podem cadastrar cameras")
    if db.query(Camera).filter(Camera.serial == data.serial).first():
        raise HTTPException(status_code=400, detail="Serial ja cadastrado")
    camera = Camera(**data.model_dump())
    db.add(camera)
    db.commit()
    db.refresh(camera)
    return camera

@router.delete("/{camera_id}")
def delete_camera(camera_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Apenas administradores podem remover cameras")
    camera = db.query(Camera).filter(Camera.id == camera_id).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    camera.is_active = False
    db.commit()
    return {"message": "Camera removida"}
