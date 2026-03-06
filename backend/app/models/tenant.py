from sqlalchemy import Column, Integer, String, Boolean, DateTime, Text
from sqlalchemy.sql import func
from app.core.database import Base

class Tenant(Base):
    __tablename__ = "tenants"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(150), nullable=False)           # Nome do cliente ex: "Condominio Solar"
    slug = Column(String(50), unique=True, index=True)   # ex: "cond-solar"
    plan = Column(String(20), default="basic")           # basic, pro, enterprise
    max_cameras = Column(Integer, default=5)
    max_users = Column(Integer, default=3)
    is_active = Column(Boolean, default=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)