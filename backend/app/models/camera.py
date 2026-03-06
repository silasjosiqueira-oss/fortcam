from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class Camera(Base):
    __tablename__ = "cameras"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    
    # Identificacao
    name = Column(String(100), nullable=False)
    serial = Column(String(100), unique=True, nullable=False)
    model = Column(String(100), nullable=True)           # VIP-5460-LPR-IA
    
    # Rede
    ip = Column(String(50), nullable=True)
    port_service = Column(Integer, default=37777)        # Porta de servico (SDK)
    port_web = Column(Integer, default=80)               # Porta web (HTTP)
    port_rtsp = Column(Integer, default=554)             # Porta RTSP (video)
    
    # Autenticacao
    cam_user = Column(String(100), default="admin")     # Usuario da camera
    cam_password = Column(String(100), nullable=True)   # Senha da camera
    
    # Configuracao
    location = Column(String(200), nullable=True)
    direction = Column(String(20), default="both")      # entry, exit, both
    access_type = Column(String(20), default="stop_go") # stop_go, free_flow
    
    # Integracao
    mqtt_topic = Column(String(200), nullable=True)
    webhook_token = Column(String(100), nullable=True)
    
    # Status
    is_online = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    last_seen = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())