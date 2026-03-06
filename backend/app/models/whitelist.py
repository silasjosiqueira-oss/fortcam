from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class Whitelist(Base):
    __tablename__ = "whitelist"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    plate = Column(String(20), index=True, nullable=False)
    owner_name = Column(String(150), nullable=False)
    time_start = Column(String(5), default="00:00")
    time_end = Column(String(5), default="23:59")
    is_active = Column(Boolean, default=True)
    notes = Column(String(300), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())