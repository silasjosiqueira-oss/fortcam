from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class Gate(Base):
    __tablename__ = "gates"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False)
    camera_id = Column(Integer, ForeignKey("cameras.id"), nullable=True)

    name = Column(String(100), nullable=False)
    location = Column(String(200), nullable=True)
    gate_type = Column(String(50), default="cancela")   # cancela, portao, porta
    mode = Column(String(20), default="auto")           # auto, manual
    open_time = Column(Integer, default=5)              # segundos aberto
    mqtt_topic = Column(String(200), nullable=True)     # topico para receber comandos
    
    is_online = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    last_trigger = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())