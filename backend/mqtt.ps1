# Instalar integracao MQTT no backend
$backend = "C:\Users\Camera 3\fortcam-cloud\backend"

Write-Host "Instalando integracao MQTT..." -ForegroundColor Cyan

# Criar pasta services
New-Item -ItemType Directory -Force -Path "$backend\app\services" | Out-Null

# Criar __init__.py
[System.IO.File]::WriteAllText("$backend\app\services\__init__.py", "", [System.Text.Encoding]::UTF8)

# MQTT SERVICE
[System.IO.File]::WriteAllText("$backend\app\services\mqtt_service.py", @'
import json
import threading
from datetime import datetime
import paho.mqtt.client as mqtt
from app.core.config import settings
from app.core.database import SessionLocal
from app.models.event import Event
from app.models.camera import Camera
from app.models.whitelist import Whitelist


def verificar_placa(db, plate: str, camera_name: str, camera_id=None):
    plate = plate.strip().upper()
    entry = db.query(Whitelist).filter(Whitelist.plate == plate, Whitelist.is_active == True).first()

    if not entry:
        status, reason = "denied", "not_in_whitelist"
    else:
        now = datetime.now().strftime("%H:%M")
        if entry.time_start <= now <= entry.time_end:
            status, reason = "granted", "whitelist"
        else:
            status, reason = "denied", "out_of_hours"

    evento = Event(plate=plate, camera_id=camera_id, camera_name=camera_name, status=status, reason=reason, detected_at=datetime.now())
    db.add(evento)
    db.commit()

    icone = "V" if status == "granted" else "X"
    print(f"[MQTT][{icone}] {plate} | {camera_name} | {status.upper()}")
    return status, reason


def on_connect(client, userdata, flags, rc, properties=None):
    if rc == 0:
        print(f"[MQTT] Conectado! Inscrito em: {settings.MQTT_TOPIC}")
        client.subscribe(settings.MQTT_TOPIC)
    else:
        print(f"[MQTT] Falha na conexao rc={rc}")


def on_message(client, userdata, msg):
    try:
        topic = msg.topic
        payload = msg.payload.decode("utf-8").strip()
        print(f"[MQTT] Topico: {topic} | Payload: {payload}")

        parts = topic.split("/")
        camera_topic = parts[-1] if len(parts) >= 3 else "desconhecida"

        db = SessionLocal()
        try:
            camera = db.query(Camera).filter(Camera.is_active == True).filter(
                Camera.mqtt_topic.contains(camera_topic)
            ).first()

            try:
                data = json.loads(payload)
                plate = data.get("plate", payload)
            except Exception:
                plate = payload

            camera_name = camera.name if camera else f"Camera {camera_topic}"
            camera_id = camera.id if camera else None

            if camera:
                camera.is_online = True
                camera.last_seen = datetime.now()
                db.commit()

            verificar_placa(db, plate, camera_name, camera_id)
        finally:
            db.close()
    except Exception as e:
        print(f"[MQTT] Erro: {e}")


def start_mqtt_service():
    client = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2)
    if settings.MQTT_USER:
        client.username_pw_set(settings.MQTT_USER, settings.MQTT_PASSWORD)
    client.on_connect = on_connect
    client.on_message = on_message
    try:
        client.connect(settings.MQTT_BROKER, settings.MQTT_PORT, keepalive=60)
        print(f"[MQTT] Conectando a {settings.MQTT_BROKER}:{settings.MQTT_PORT}...")
        client.loop_forever()
    except Exception as e:
        print(f"[MQTT] Erro ao conectar: {e}")


def start_mqtt_thread():
    thread = threading.Thread(target=start_mqtt_service, daemon=True)
    thread.start()
    print("[MQTT] Servico iniciado em background!")
    return thread
'@, [System.Text.Encoding]::UTF8)

# MAIN.PY atualizado com MQTT
[System.IO.File]::WriteAllText("$backend\app\main.py", @'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1 import auth, whitelist, events, cameras, gate

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    description="API do sistema de controle de acesso por LPR",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(whitelist.router, prefix="/api/v1")
app.include_router(events.router, prefix="/api/v1")
app.include_router(cameras.router, prefix="/api/v1")
app.include_router(gate.router, prefix="/api/v1")

@app.on_event("startup")
async def startup_event():
    try:
        from app.services.mqtt_service import start_mqtt_thread
        start_mqtt_thread()
    except Exception as e:
        print(f"[APP] MQTT nao iniciado: {e}")

@app.get("/")
def root():
    return {"message": "Fortcam Cloud API", "version": "1.0.0", "docs": "/docs"}

@app.get("/health")
def health():
    return {"status": "ok"}
'@, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "MQTT integrado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Reinicie o backend:" -ForegroundColor Yellow
Write-Host "  uvicorn app.main:app --reload --port 8000" -ForegroundColor White
Write-Host ""
Write-Host "Para testar, publique uma placa:" -ForegroundColor Yellow
Write-Host "  cd 'C:\Program Files\mosquitto'" -ForegroundColor White
Write-Host "  .\mosquitto_pub.exe -t 'fortcam/plates/cam1' -m 'BRA7A23'" -ForegroundColor White
