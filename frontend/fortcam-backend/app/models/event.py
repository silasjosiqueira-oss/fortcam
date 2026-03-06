from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from app.core.database import Base

class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    plate = Column(String(20), index=True, nullable=False)
    camera_id = Column(Integer, ForeignKey("cameras.id"), nullable=True)
    camera_name = Column(String(100), nullable=True)
    status = Column(String(20), nullable=False)  # granted, denied
    reason = Column(String(100), nullable=True)  # not_in_whitelist, out_of_hours, etc
    image_b64 = Column(Text, nullable=True)
    detected_at = Column(DateTime(timezone=True), server_default=func.now())
