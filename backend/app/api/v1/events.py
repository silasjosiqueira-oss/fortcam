from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional
from datetime import datetime, date
from pydantic import BaseModel
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.event import Event
from app.models.camera import Camera

router = APIRouter(prefix="/events", tags=["Eventos"])

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

@router.get("/", response_model=List[EventResponse])
def list_events(
    limit: int = 50,
    offset: int = 0,
    plate: Optional[str] = None,
    status: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    tid = current_user.tenant_id
    query = db.query(Event).filter(Event.tenant_id == tid)
    if plate:
        query = query.filter(Event.plate.ilike(f"%{plate}%"))
    if status:
        query = query.filter(Event.status == status)
    return query.order_by(Event.detected_at.desc()).offset(offset).limit(limit).all()

@router.get("/dashboard", response_model=DashboardStats)
def dashboard_stats(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = current_user.tenant_id
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())

    total_today = db.query(func.count(Event.id)).filter(Event.tenant_id == tid, Event.detected_at >= today_start).scalar()
    granted_today = db.query(func.count(Event.id)).filter(Event.tenant_id == tid, Event.detected_at >= today_start, Event.status == "granted").scalar()
    denied_today = db.query(func.count(Event.id)).filter(Event.tenant_id == tid, Event.detected_at >= today_start, Event.status == "denied").scalar()
    cameras_online = db.query(func.count(Camera.id)).filter(Camera.tenant_id == tid, Camera.is_online == True).scalar()

    return DashboardStats(
        total_today=total_today,
        granted_today=granted_today,
        denied_today=denied_today,
        cameras_online=cameras_online,
        whitelist_matches_today=granted_today,
        alerts=denied_today
    )

@router.get("/last", response_model=EventResponse)
def last_event(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    from fastapi import HTTPException
    tid = current_user.tenant_id
    event = db.query(Event).filter(Event.tenant_id == tid).order_by(Event.detected_at.desc()).first()
    if not event:
        raise HTTPException(status_code=404, detail="Nenhum evento")
    return event