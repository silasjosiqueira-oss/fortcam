from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from pydantic import BaseModel
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.core.config import settings
import paho.mqtt.publish as publish

router = APIRouter(prefix="/gate", tags=["Portao"])

class GateCommand(BaseModel):
    camera_id: int
    action: str  # "open" ou "close"

@router.post("/command")
def send_gate_command(data: GateCommand, current_user: User = Depends(get_current_user)):
    if data.action not in ["open", "close"]:
        raise HTTPException(status_code=400, detail="Acao invalida. Use 'open' ou 'close'")

    topic = f"fortcam/gate/{data.camera_id}/command"
    payload = data.action.upper()

    try:
        publish.single(
            topic=topic,
            payload=payload,
            hostname=settings.MQTT_BROKER,
            port=settings.MQTT_PORT,
            auth={"username": settings.MQTT_USER, "password": settings.MQTT_PASSWORD} if settings.MQTT_USER else None
        )
        return {"success": True, "message": f"Comando {payload} enviado para camera {data.camera_id}"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro ao enviar comando MQTT: {str(e)}")
