from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import secrets
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.camera import Camera

router = APIRouter(prefix="/cameras", tags=["Cameras"])

class CameraCreate(BaseModel):
    name: str
    serial: str
    model: Optional[str] = ""
    ip: Optional[str] = ""
    port_service: Optional[int] = 37777
    port_web: Optional[int] = 80
    port_rtsp: Optional[int] = 554
    cam_user: Optional[str] = "admin"
    cam_password: Optional[str] = ""
    location: Optional[str] = ""
    direction: Optional[str] = "both"
    access_type: Optional[str] = "stop_go"

class CameraResponse(BaseModel):
    id: int
    name: str
    serial: str
    model: Optional[str]
    ip: Optional[str]
    port_service: Optional[int]
    port_web: Optional[int]
    port_rtsp: Optional[int]
    cam_user: Optional[str]
    location: Optional[str]
    direction: Optional[str]
    access_type: Optional[str]
    mqtt_topic: Optional[str]
    webhook_token: Optional[str]
    is_online: bool
    is_active: bool
    last_seen: Optional[datetime]

    class Config:
        from_attributes = True

@router.get("/", response_model=List[CameraResponse])
def list_cameras(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = current_user.tenant_id
    return db.query(Camera).filter(Camera.tenant_id == tid, Camera.is_active == True).all()

@router.post("/", response_model=CameraResponse)
def create_camera(data: CameraCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    if db.query(Camera).filter(Camera.serial == data.serial).first():
        raise HTTPException(status_code=400, detail="Serial ja cadastrado")

    webhook_token = secrets.token_urlsafe(32)
    mqtt_topic = f"fortcam/plates/{data.serial.lower()}"

    camera = Camera(
        tenant_id=tid,
        webhook_token=webhook_token,
        mqtt_topic=mqtt_topic,
        **data.model_dump()
    )
    db.add(camera)
    db.commit()
    db.refresh(camera)
    return camera

@router.put("/{camera_id}", response_model=CameraResponse)
def update_camera(camera_id: int, data: CameraCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(camera, field, value)
    db.commit()
    db.refresh(camera)
    return camera

@router.get("/{camera_id}/webhook-info")
def webhook_info(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    return {
        "camera": camera.name,
        "webhook_url": f"/api/v1/webhook/intelbras/{camera.webhook_token}",
        "mqtt_topic": camera.mqtt_topic,
        "token": camera.webhook_token,
        "rtsp_url": f"rtsp://{camera.cam_user}:SENHA@{camera.ip}:{camera.port_rtsp}/stream" if camera.ip else "Configure o IP primeiro",
        "web_url": f"http://{camera.ip}:{camera.port_web}" if camera.ip else "Configure o IP primeiro",
    }

@router.delete("/{camera_id}")
def delete_camera(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    camera.is_active = False
    db.commit()
    return {"message": "Camera removida"}