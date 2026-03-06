from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.database import get_db
from app.models.event import Event
from app.models.camera import Camera
from app.models.whitelist import Whitelist

router = APIRouter(prefix="/webhook", tags=["Webhook LPR"])

def publicar_abertura(camera_id: int, plate: str, tenant_id: int):
    try:
        import paho.mqtt.publish as publish
        topic = f"fortcam/barrier/{tenant_id}/{camera_id}/open"
        payload = f'{{"plate":"{plate}","action":"open","ts":"{datetime.now().isoformat()}"}}'
        publish.single(topic, payload, hostname="localhost", port=1883)
        print(f"[MQTT][BARRIER] Comando enviado: {topic}")
    except Exception as e:
        print(f"[MQTT][BARRIER][ERRO] {e}")

def processar_placa(db, plate: str, camera_name: str, tenant_id: int, camera_id=None, image_b64=None):
    plate = plate.strip().upper()

    # Evitar duplicatas - ignora mesmo evento em menos de 10 segundos
    from datetime import timedelta
    ultimo = db.query(Event).filter(
        Event.tenant_id == tenant_id,
        Event.plate == plate,
        Event.camera_id == camera_id,
        Event.detected_at >= datetime.now() - timedelta(seconds=10)
    ).first()
    if ultimo:
        print(f"[WEBHOOK][SKIP] Duplicata ignorada: {plate}")
        return ultimo.status, "duplicate"
    entry = db.query(Whitelist).filter(
        Whitelist.tenant_id == tenant_id,
        Whitelist.plate == plate,
        Whitelist.is_active == True
    ).first()
    if not entry:
        status, reason = "denied", "not_in_whitelist"
    else:
        now = datetime.now().strftime("%H:%M")
        status = "granted" if entry.time_start <= now <= entry.time_end else "denied"
        reason = "whitelist" if status == "granted" else "out_of_hours"

    evento = Event(
        tenant_id=tenant_id,
        plate=plate,
        camera_id=camera_id,
        camera_name=camera_name,
        status=status,
        reason=reason,
        image_b64=image_b64,
        detected_at=datetime.now()
    )
    db.add(evento)
    db.commit()

    if status == "granted" and camera_id:
        publicar_abertura(camera_id, plate, tenant_id)

    print(f"[WEBHOOK][{'V' if status=='granted' else 'X'}] {plate} | tenant={tenant_id} | {status}")
    return status, reason

@router.post("/intelbras/{camera_token}")
async def webhook_intelbras(camera_token: str, request: Request, db: Session = Depends(get_db)):
    camera = db.query(Camera).filter(Camera.webhook_token == camera_token, Camera.is_active == True).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    camera.is_online = True
    camera.last_seen = datetime.now()
    db.commit()
    try:
        data = await request.json()
    except:
        form = await request.form()
        data = dict(form)
    plate = data.get("plate") or data.get("licensePlate") or data.get("Plate") or str(data)
    status, reason = processar_placa(db, str(plate), camera.name, camera.tenant_id, camera.id)
    return {"success": True, "plate": plate, "status": status}

@router.get("/test/{tenant_id}/{plate}")
async def test_webhook(tenant_id: int, plate: str, db: Session = Depends(get_db)):
    status, reason = processar_placa(db, plate, "Teste Manual", tenant_id)
    return {"plate": plate, "status": status, "reason": reason}

@router.post("/NotificationInfo/KeepAlive")
@router.post("/NotificationInfo/TollgateInfo")
async def keepalive(request: Request, db: Session = Depends(get_db)):
    return {"result": "ok"}
