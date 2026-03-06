# Adicionar webhook Intelbras no backend
$backend = "C:\Users\Camera 3\fortcam-cloud\backend"

Write-Host "Criando webhook para camera Intelbras..." -ForegroundColor Cyan

# WEBHOOK ROUTE
[System.IO.File]::WriteAllText("$backend\app\api\v1\webhook.py", @'
from fastapi import APIRouter, Request, Depends
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.database import get_db
from app.models.event import Event
from app.models.camera import Camera
from app.models.whitelist import Whitelist

router = APIRouter(prefix="/webhook", tags=["Webhook LPR"])

def processar_placa(db: Session, plate: str, camera_name: str, camera_id=None):
    plate = plate.strip().upper()
    entry = db.query(Whitelist).filter(
        Whitelist.plate == plate,
        Whitelist.is_active == True
    ).first()

    if not entry:
        status, reason = "denied", "not_in_whitelist"
    else:
        now = datetime.now().strftime("%H:%M")
        if entry.time_start <= now <= entry.time_end:
            status, reason = "granted", "whitelist"
        else:
            status, reason = "denied", "out_of_hours"

    evento = Event(
        plate=plate,
        camera_id=camera_id,
        camera_name=camera_name,
        status=status,
        reason=reason,
        detected_at=datetime.now()
    )
    db.add(evento)
    db.commit()

    print(f"[WEBHOOK] {'V' if status=='granted' else 'X'} {plate} | {camera_name} | {status.upper()}")
    return status, reason

@router.post("/intelbras")
async def webhook_intelbras(request: Request, db: Session = Depends(get_db)):
    """Recebe eventos de placa da camera Intelbras VIP 5460 LPR IA"""
    try:
        data = await request.json()
        print(f"[WEBHOOK] Dados recebidos: {data}")

        # Formato Intelbras: { "plate": "ABC1D23", "channel": 1, ... }
        plate = (
            data.get("plate") or
            data.get("licensePlate") or
            data.get("plateNumber") or
            data.get("Plate") or
            str(data)
        )

        camera_name = data.get("cameraName") or data.get("channel") or "VIP 5460 LPR"

        # Buscar camera no banco
        camera = db.query(Camera).filter(Camera.is_active == True).first()
        camera_id = camera.id if camera else None
        if camera:
            camera_name = camera.name
            camera.is_online = True
            camera.last_seen = datetime.now()
            db.commit()

        status, reason = processar_placa(db, str(plate), str(camera_name), camera_id)

        return {
            "success": True,
            "plate": plate,
            "status": status,
            "reason": reason
        }
    except Exception as e:
        print(f"[WEBHOOK] Erro: {e}")
        return {"success": False, "error": str(e)}

@router.post("/intelbras/form")
async def webhook_intelbras_form(request: Request, db: Session = Depends(get_db)):
    """Recebe eventos em formato form-data (algumas cameras Intelbras usam isso)"""
    try:
        form = await request.form()
        data = dict(form)
        print(f"[WEBHOOK FORM] Dados recebidos: {data}")

        plate = (
            data.get("plate") or
            data.get("licensePlate") or
            data.get("plateNumber") or
            data.get("Plate") or
            "DESCONHECIDA"
        )

        camera = db.query(Camera).filter(Camera.is_active == True).first()
        camera_id = camera.id if camera else None
        camera_name = camera.name if camera else "VIP 5460 LPR"

        status, reason = processar_placa(db, str(plate), camera_name, camera_id)
        return {"success": True, "plate": plate, "status": status}
    except Exception as e:
        return {"success": False, "error": str(e)}

@router.get("/test/{plate}")
async def test_webhook(plate: str, db: Session = Depends(get_db)):
    """Testar webhook manualmente pelo navegador"""
    status, reason = processar_placa(db, plate, "Teste Manual")
    return {"plate": plate, "status": status, "reason": reason}
'@, [System.Text.Encoding]::UTF8)

# Atualizar main.py para incluir webhook
[System.IO.File]::WriteAllText("$backend\app\main.py", @'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1 import auth, whitelist, events, cameras, gate, webhook

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
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(whitelist.router, prefix="/api/v1")
app.include_router(events.router, prefix="/api/v1")
app.include_router(cameras.router, prefix="/api/v1")
app.include_router(gate.router, prefix="/api/v1")
app.include_router(webhook.router, prefix="/api/v1")

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
Write-Host "Webhook criado com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Reinicie o backend e configure a camera com:" -ForegroundColor Yellow
Write-Host ""
Write-Host "URL do Webhook:" -ForegroundColor Cyan
Write-Host "  https://nonguttural-retrouss-breann.ngrok-free.dev/api/v1/webhook/intelbras" -ForegroundColor White
Write-Host ""
Write-Host "Para testar pelo navegador:" -ForegroundColor Cyan
Write-Host "  https://nonguttural-retrouss-breann.ngrok-free.dev/api/v1/webhook/test/BRA7A23" -ForegroundColor White
