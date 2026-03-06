from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class EventResponse(BaseModel):
    id: int
    plate: str
    camera_name: Optional[str]
    status: str
    reason: Optional[str]
    detected_at: datetime

    class Config:
        from_attributes = True

class DashboardStats(BaseModel):
    total_today: int
    granted_today: int
    denied_today: int
    cameras_online: int
    whitelist_matches_today: int
    alerts: int
