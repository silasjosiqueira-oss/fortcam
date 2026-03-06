from pydantic import BaseModel
from typing import Optional
from datetime import datetime

class WhitelistCreate(BaseModel):
    plate: str
    owner_name: str
    time_start: str = "00:00"
    time_end: str = "23:59"
    is_active: bool = True
    notes: Optional[str] = None

class WhitelistUpdate(BaseModel):
    owner_name: Optional[str] = None
    time_start: Optional[str] = None
    time_end: Optional[str] = None
    is_active: Optional[bool] = None
    notes: Optional[str] = None

class WhitelistResponse(BaseModel):
    id: int
    plate: str
    owner_name: str
    time_start: str
    time_end: str
    is_active: bool
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True
