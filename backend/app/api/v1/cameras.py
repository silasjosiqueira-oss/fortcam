from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.camera import Camera
import secrets, os

router = APIRouter(prefix="/cameras", tags=["Cameras"])

API_URL = os.getenv("API_URL", "https://fortcam.com.br")
MQTT_BROKER = os.getenv("MQTT_BROKER", "fortcam.com.br")

class CameraCreate(BaseModel):
    name: str
    serial: str
    model: Optional[str] = None
    ip: Optional[str] = None
    port_service: Optional[int] = 37777
    port_web: Optional[int] = 80
    port_rtsp: Optional[int] = 554
    cam_user: Optional[str] = "admin"
    cam_password: Optional[str] = None
    location: Optional[str] = None
    direction: Optional[str] = "both"
    access_type: Optional[str] = "stop_go"
    stream_url: Optional[str] = None
    stream_type: Optional[str] = "rtsp"   # rtsp | hls | mjpeg | snapshot | webrtc
    snapshot_url: Optional[str] = None

class CameraUpdate(CameraCreate):
    pass

def cam_to_dict(cam: Camera) -> dict:
    return {
        "id": cam.id,
        "name": cam.name,
        "serial": cam.serial,
        "model": getattr(cam, "model", None),
        "ip": cam.ip,
        "port_service": getattr(cam, "port_service", 37777),
        "port_web": getattr(cam, "port_web", 80),
        "port_rtsp": getattr(cam, "port_rtsp", 554),
        "cam_user": getattr(cam, "cam_user", "admin"),
        "location": getattr(cam, "location", None),
        "direction": getattr(cam, "direction", "both"),
        "access_type": getattr(cam, "access_type", "stop_go"),
        "is_online": cam.is_online,
        "last_seen": cam.last_seen.isoformat() if cam.last_seen else None,
        "webhook_token": cam.webhook_token,
        "stream_url": getattr(cam, "stream_url", None),
        "stream_type": getattr(cam, "stream_type", "rtsp"),
        "snapshot_url": getattr(cam, "snapshot_url", None),
        "tenant_id": cam.tenant_id,
    }

@router.get("/")
def list_cameras(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    cams = db.query(Camera).filter(Camera.tenant_id == current_user.tenant_id).all()
    return [cam_to_dict(c) for c in cams]

@router.post("/")
def create_camera(data: CameraCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    existing = db.query(Camera).filter(
        Camera.serial == data.serial,
        Camera.tenant_id == current_user.tenant_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Camera com este serial já existe")

    # Gerar stream_url automaticamente se tiver IP e não tiver URL manual
    stream_url = data.stream_url
    stream_type = data.stream_type or "rtsp"
    if not stream_url and data.ip:
        user = data.cam_user or "admin"
        pwd = data.cam_password or ""
        port = data.port_rtsp or 554
        if pwd:
            stream_url = f"rtsp://{user}:{pwd}@{data.ip}:{port}/cam/realmonitor?channel=1&subtype=0"
        else:
            stream_url = f"rtsp://{user}@{data.ip}:{port}/cam/realmonitor?channel=1&subtype=0"
        stream_type = "rtsp"

    cam = Camera(
        tenant_id=current_user.tenant_id,
        name=data.name,
        serial=data.serial.upper(),
        ip=data.ip,
        location=data.location,
        webhook_token=secrets.token_urlsafe(32),
        is_online=False,
    )
    # Campos opcionais via setattr para compatibilidade
    for field in ["model", "port_service", "port_web", "port_rtsp", "cam_user", "cam_password", "direction", "access_type"]:
        try: setattr(cam, field, getattr(data, field))
        except: pass
    try:
        cam.stream_url = stream_url
        cam.stream_type = stream_type
        cam.snapshot_url = data.snapshot_url
    except: pass

    db.add(cam)
    db.commit()
    db.refresh(cam)
    return cam_to_dict(cam)

@router.put("/{camera_id}")
def update_camera(camera_id: int, data: CameraUpdate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    cam = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == current_user.tenant_id).first()
    if not cam:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    for field in ["name", "serial", "model", "ip", "port_service", "port_web", "port_rtsp",
                  "cam_user", "cam_password", "location", "direction", "access_type",
                  "stream_url", "stream_type", "snapshot_url"]:
        try:
            val = getattr(data, field, None)
            if val is not None:
                setattr(cam, field, val)
        except: pass
    db.commit()
    db.refresh(cam)
    return cam_to_dict(cam)

@router.delete("/{camera_id}")
def delete_camera(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    cam = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == current_user.tenant_id).first()
    if not cam:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    db.delete(cam)
    db.commit()
    return {"message": "Camera removida"}

@router.get("/{camera_id}/webhook-info")
def webhook_info(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    cam = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == current_user.tenant_id).first()
    if not cam:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    ip = cam.ip or "IP_DA_CAMERA"
    port_web = getattr(cam, "port_web", 80) or 80
    port_rtsp = getattr(cam, "port_rtsp", 554) or 554
    user = getattr(cam, "cam_user", "admin") or "admin"
    serial_lower = cam.serial.lower()
    return {
        "camera": cam.name,
        "webhook_url": f"/api/v1/webhook/intelbras/{cam.webhook_token}",
        "mqtt_topic": f"fortcam/plates/{serial_lower}",
        "web_url": f"http://{ip}:{port_web}",
        "rtsp_url": f"rtsp://{user}@{ip}:{port_rtsp}/cam/realmonitor?channel=1&subtype=0",
        "stream_url": getattr(cam, "stream_url", None),
        "stream_type": getattr(cam, "stream_type", "rtsp"),
    }

@router.get("/{camera_id}/snapshot")
def get_snapshot(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """Retorna URL de snapshot da câmera para exibição no monitoramento"""
    cam = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == current_user.tenant_id).first()
    if not cam:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    
    snapshot_url = getattr(cam, "snapshot_url", None)
    stream_url = getattr(cam, "stream_url", None)
    
    # Se tiver snapshot_url configurada manualmente
    if snapshot_url:
        return {"type": "url", "url": snapshot_url}
    
    # Se for MJPEG, usa direto
    stream_type = getattr(cam, "stream_type", "rtsp")
    if stream_type == "mjpeg" and stream_url:
        return {"type": "mjpeg", "url": stream_url}
    
    # Se for HLS, usa direto
    if stream_type == "hls" and stream_url:
        return {"type": "hls", "url": stream_url}
    
    # Última foto capturada pelo webhook
    from app.models.event import Event
    last = db.query(Event).filter(
        Event.camera_id == camera_id,
        Event.image_b64 != None
    ).order_by(Event.detected_at.desc()).first()
    
    if last and last.image_b64:
        b64 = last.image_b64
        if not b64.startswith("data:"):
            b64 = f"data:image/jpeg;base64,{b64}"
        return {"type": "base64", "data": b64, "plate": last.plate, "detected_at": last.detected_at.isoformat()}
    
    return {"type": "none"}
