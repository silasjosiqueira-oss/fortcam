from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import ssl
import paho.mqtt.publish as publish
from app.core.database import get_db
from app.core.security import get_current_user
from app.core.config import settings
from app.models.gate import Gate

router = APIRouter(prefix="/gate", tags=["Portao"])

class GateCreate(BaseModel):
    name: str
    location: Optional[str] = ""
    gate_type: Optional[str] = "cancela"
    mode: Optional[str] = "auto"
    open_time: Optional[int] = 5
    camera_id: Optional[int] = None

class GateResponse(BaseModel):
    id: int
    name: str
    location: Optional[str]
    gate_type: str
    mode: str
    open_time: int
    camera_id: Optional[int]
    mqtt_topic: Optional[str]
    is_online: bool
    is_active: bool
    last_trigger: Optional[datetime]

    class Config:
        from_attributes = True

def mqtt_publish(topic: str, payload: str):
    """
    Publica mensagem no broker MQTT.
    - Porta 1883 (localhost): sem TLS, conexão interna
    - Porta 8883 (externo):   TLS obrigatório com certificado Let's Encrypt
    """
    try:
        port = int(getattr(settings, "MQTT_PORT", 1883))
        host = getattr(settings, "MQTT_BROKER", "127.0.0.1")
        user = getattr(settings, "MQTT_USER", None)
        password = getattr(settings, "MQTT_PASSWORD", None)

        auth = {"username": user, "password": password} if user else None

        # TLS automático para porta 8883
        tls = None
        if port == 8883:
            tls = {
                "ca_certs": None,           # usa CAs do sistema (Let's Encrypt reconhecido)
                "tls_version": ssl.PROTOCOL_TLS_CLIENT,
                "cert_reqs": ssl.CERT_REQUIRED,
            }

        publish.single(
            topic=topic,
            payload=payload,
            hostname=host,
            port=port,
            auth=auth,
            tls=tls,
        )
        return True
    except Exception as e:
        print(f"[MQTT][ERRO] {e}")
        return False

@router.get("/", response_model=List[GateResponse])
def list_gates(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return db.query(Gate).filter(Gate.tenant_id == current_user.tenant_id, Gate.is_active == True).all()

@router.post("/", response_model=GateResponse)
def create_gate(data: GateCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    gate = Gate(
        tenant_id=tid,
        mqtt_topic=f"fortcam/barrier/{tid}/gate_{data.name.lower().replace(' ','_')}/open",
        **data.model_dump()
    )
    db.add(gate)
    db.commit()
    db.refresh(gate)
    return gate

@router.put("/{gate_id}", response_model=GateResponse)
def update_gate(gate_id: int, data: GateCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(gate, k, v)
    db.commit()
    db.refresh(gate)
    return gate

@router.post("/{gate_id}/open")
def open_gate(gate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    import json
    payload = json.dumps({
        "action": "open",
        "open_time": gate.open_time,
        "triggered_by": current_user.email,
        "ts": datetime.now().isoformat()
    })
    success = mqtt_publish(gate.mqtt_topic, payload)
    if success:
        gate.last_trigger = datetime.now()
        db.commit()
        return {"success": True, "message": f"Comando ABRIR enviado para {gate.name}"}
    raise HTTPException(status_code=500, detail="Erro ao enviar comando MQTT")

@router.post("/{gate_id}/close")
def close_gate(gate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    import json
    payload = json.dumps({"action": "close", "ts": datetime.now().isoformat()})
    success = mqtt_publish(gate.mqtt_topic, payload)
    return {"success": success, "message": "Comando FECHAR enviado"}

@router.delete("/{gate_id}")
def delete_gate(gate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    gate.is_active = False
    db.commit()
    return {"message": "Portao removido"}