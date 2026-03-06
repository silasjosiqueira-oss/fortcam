from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from typing import List, Optional
from datetime import datetime, date
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.event import Event
from app.models.camera import Camera
from app.models.user import User
from app.schemas.event import EventResponse, DashboardStats

router = APIRouter(prefix="/events", tags=["Eventos"])

@router.get("/", response_model=List[EventResponse])
def list_events(
    limit: int = 50,
    offset: int = 0,
    plate: Optional[str] = None,
    status: Optional[str] = None,
    date_from: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    query = db.query(Event)
    if plate:
        query = query.filter(Event.plate.ilike(f"%{plate}%"))
    if status:
        query = query.filter(Event.status == status)
    if date_from:
        query = query.filter(Event.detected_at >= date_from)
    return query.order_by(Event.detected_at.desc()).offset(offset).limit(limit).all()

@router.get("/dashboard", response_model=DashboardStats)
def dashboard_stats(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    today = date.today()
    today_start = datetime.combine(today, datetime.min.time())

    total_today = db.query(func.count(Event.id)).filter(Event.detected_at >= today_start).scalar()
    granted_today = db.query(func.count(Event.id)).filter(Event.detected_at >= today_start, Event.status == "granted").scalar()
    denied_today = db.query(func.count(Event.id)).filter(Event.detected_at >= today_start, Event.status == "denied").scalar()
    cameras_online = db.query(func.count(Camera.id)).filter(Camera.is_online == True).scalar()
    whitelist_matches = granted_today

    return DashboardStats(
        total_today=total_today,
        granted_today=granted_today,
        denied_today=denied_today,
        cameras_online=cameras_online,
        whitelist_matches_today=whitelist_matches,
        alerts=denied_today
    )

@router.get("/last", response_model=EventResponse)
def last_event(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    event = db.query(Event).order_by(Event.detected_at.desc()).first()
    if not event:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Nenhum evento encontrado")
    return event
