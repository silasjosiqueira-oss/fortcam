from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import engine, Base
from app.api.v1 import auth, whitelist, events, cameras, gate, webhook, tenants

Base.metadata.create_all(bind=engine)

app = FastAPI(
    title=settings.APP_NAME,
    description="API multitenant do sistema de controle de acesso por LPR",
    version="2.0.0",
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
app.include_router(tenants.router, prefix="/api/v1")

@app.on_event("startup")
async def startup_event():
    try:
        from app.services.mqtt_service import start_mqtt_thread
        start_mqtt_thread()
    except Exception as e:
        print(f"[APP] MQTT nao iniciado: {e}")

@app.get("/")
def root():
    return {"message": "Fortcam Cloud API v2.0 - Multitenant", "docs": "/docs"}

@app.get("/health")
def health():
    return {"status": "ok"}