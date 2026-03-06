# Reestruturacao Multitenant do Fortcam Cloud
$backend = "C:\Users\Camera 3\fortcam-cloud\backend"

Write-Host "Reestruturando banco de dados para multitenant..." -ForegroundColor Cyan

# ============================================================
# MODEL - TENANT
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\models\tenant.py", @'
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
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# MODEL - USER (com tenant_id)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\models\user.py", @'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=True)  # NULL = superadmin
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    role = Column(String(20), default="operator")  # superadmin, admin, operator
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# MODEL - CAMERA (com tenant_id)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\models\camera.py", @'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class Camera(Base):
    __tablename__ = "cameras"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    serial = Column(String(100), unique=True, nullable=False)
    ip = Column(String(50), nullable=True)
    location = Column(String(200), nullable=True)
    mqtt_topic = Column(String(200), nullable=True)
    webhook_token = Column(String(100), nullable=True)  # token para autenticar webhook
    is_online = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    last_seen = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# MODEL - WHITELIST (com tenant_id)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\models\whitelist.py", @'
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
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# MODEL - EVENT (com tenant_id)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\models\event.py", @'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.sql import func
from app.core.database import Base

class Event(Base):
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False, index=True)
    plate = Column(String(20), index=True, nullable=False)
    camera_id = Column(Integer, ForeignKey("cameras.id"), nullable=True)
    camera_name = Column(String(100), nullable=True)
    status = Column(String(20), nullable=False)   # granted, denied
    reason = Column(String(100), nullable=True)
    image_b64 = Column(Text, nullable=True)
    detected_at = Column(DateTime(timezone=True), server_default=func.now())
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# SECURITY - JWT com tenant_id
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\core\security.py", @'
from datetime import datetime, timedelta
from typing import Optional
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")

def hash_password(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token invalido")

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    from app.models.user import User
    payload = decode_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(status_code=401, detail="Token invalido")
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Usuario nao encontrado")
    return user

def require_superadmin(current_user=Depends(get_current_user)):
    if current_user.role != "superadmin":
        raise HTTPException(status_code=403, detail="Apenas superadmin pode executar esta acao")
    return current_user
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - TENANTS (superadmin)
# ============================================================
New-Item -ItemType Directory -Force -Path "$backend\app\api\v1" | Out-Null

[System.IO.File]::WriteAllText("$backend\app\api\v1\tenants.py", @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
from app.core.database import get_db
from app.core.security import get_current_user, require_superadmin, hash_password
from app.models.tenant import Tenant
from app.models.user import User

router = APIRouter(prefix="/tenants", tags=["Tenants (Superadmin)"])

class TenantCreate(BaseModel):
    name: str
    slug: str
    plan: str = "basic"
    max_cameras: int = 5
    max_users: int = 3
    notes: Optional[str] = None
    admin_name: str
    admin_email: str
    admin_password: str

class TenantResponse(BaseModel):
    id: int
    name: str
    slug: str
    plan: str
    max_cameras: int
    max_users: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

@router.get("/", response_model=List[TenantResponse])
def list_tenants(db: Session = Depends(get_db), current_user=Depends(require_superadmin)):
    return db.query(Tenant).all()

@router.post("/", response_model=TenantResponse)
def create_tenant(data: TenantCreate, db: Session = Depends(get_db), current_user=Depends(require_superadmin)):
    if db.query(Tenant).filter(Tenant.slug == data.slug).first():
        raise HTTPException(status_code=400, detail="Slug ja em uso")

    tenant = Tenant(
        name=data.name,
        slug=data.slug,
        plan=data.plan,
        max_cameras=data.max_cameras,
        max_users=data.max_users,
        notes=data.notes
    )
    db.add(tenant)
    db.commit()
    db.refresh(tenant)

    # Criar admin do tenant
    admin = User(
        tenant_id=tenant.id,
        name=data.admin_name,
        email=data.admin_email,
        hashed_password=hash_password(data.admin_password),
        role="admin"
    )
    db.add(admin)
    db.commit()

    return tenant

@router.put("/{tenant_id}/toggle")
def toggle_tenant(tenant_id: int, db: Session = Depends(get_db), current_user=Depends(require_superadmin)):
    tenant = db.query(Tenant).filter(Tenant.id == tenant_id).first()
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant nao encontrado")
    tenant.is_active = not tenant.is_active
    db.commit()
    return {"is_active": tenant.is_active}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - AUTH (atualizado com tenant)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\auth.py", @'
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr
from typing import Optional
from app.core.database import get_db
from app.core.security import verify_password, create_access_token, hash_password, get_current_user
from app.models.user import User
from app.models.tenant import Tenant

router = APIRouter(prefix="/auth", tags=["Autenticacao"])

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    tenant_id: Optional[int]
    tenant_name: Optional[str]

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    role: str
    tenant_id: Optional[int]
    is_active: bool

    class Config:
        from_attributes = True

@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Email ou senha incorretos")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Usuario inativo")

    # Verificar se tenant esta ativo
    if user.tenant_id:
        tenant = db.query(Tenant).filter(Tenant.id == user.tenant_id).first()
        if not tenant or not tenant.is_active:
            raise HTTPException(status_code=403, detail="Conta inativa. Entre em contato com o suporte.")
        tenant_name = tenant.name
    else:
        tenant_name = "Fortcam Cloud"

    token = create_access_token({
        "sub": str(user.id),
        "email": user.email,
        "role": user.role,
        "tenant_id": user.tenant_id
    })
    return {"access_token": token, "role": user.role, "tenant_id": user.tenant_id, "tenant_name": tenant_name}

@router.get("/me", response_model=UserResponse)
def me(current_user=Depends(get_current_user)):
    return current_user

@router.post("/users", response_model=UserResponse)
def create_user(
    name: str, email: str, password: str, role: str = "operator",
    db: Session = Depends(get_db),
    current_user=Depends(get_current_user)
):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email ja cadastrado")

    user = User(
        tenant_id=current_user.tenant_id,
        name=name, email=email,
        hashed_password=hash_password(password),
        role=role
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - WHITELIST (filtrada por tenant)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\whitelist.py", @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.whitelist import Whitelist

router = APIRouter(prefix="/whitelist", tags=["Whitelist"])

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

def get_tenant_id(current_user):
    if not current_user.tenant_id:
        raise HTTPException(status_code=400, detail="Usuario sem tenant")
    return current_user.tenant_id

@router.get("/", response_model=List[WhitelistResponse])
def list_whitelist(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    return db.query(Whitelist).filter(Whitelist.tenant_id == tid).order_by(Whitelist.created_at.desc()).all()

@router.post("/", response_model=WhitelistResponse)
def add_plate(data: WhitelistCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    if db.query(Whitelist).filter(Whitelist.tenant_id == tid, Whitelist.plate == data.plate.upper()).first():
        raise HTTPException(status_code=400, detail="Placa ja cadastrada")
    entry = Whitelist(tenant_id=tid, **data.model_dump(), plate=data.plate.upper())
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry

@router.put("/{plate_id}", response_model=WhitelistResponse)
def update_plate(plate_id: int, data: WhitelistUpdate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    entry = db.query(Whitelist).filter(Whitelist.id == plate_id, Whitelist.tenant_id == tid).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Placa nao encontrada")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry

@router.delete("/{plate_id}")
def delete_plate(plate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = get_tenant_id(current_user)
    entry = db.query(Whitelist).filter(Whitelist.id == plate_id, Whitelist.tenant_id == tid).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Placa nao encontrada")
    db.delete(entry)
    db.commit()
    return {"message": "Placa removida"}

@router.get("/check/{plate}")
def check_plate(plate: str, tenant_id: int, db: Session = Depends(get_db)):
    from datetime import datetime as dt
    entry = db.query(Whitelist).filter(
        Whitelist.tenant_id == tenant_id,
        Whitelist.plate == plate.upper(),
        Whitelist.is_active == True
    ).first()
    if not entry:
        return {"allowed": False, "reason": "Placa nao encontrada"}
    now = dt.now().strftime("%H:%M")
    if not (entry.time_start <= now <= entry.time_end):
        return {"allowed": False, "reason": "Fora do horario"}
    return {"allowed": True, "owner": entry.owner_name}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - EVENTS (filtrado por tenant)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\events.py", @'
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
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - CAMERAS (filtrada por tenant)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\cameras.py", @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.camera import Camera

router = APIRouter(prefix="/cameras", tags=["Cameras"])

class CameraCreate(BaseModel):
    name: str
    serial: str
    ip: str = ""
    location: str = ""
    mqtt_topic: str = ""

class CameraResponse(BaseModel):
    id: int
    name: str
    serial: str
    ip: Optional[str]
    location: Optional[str]
    is_online: bool
    is_active: bool

    class Config:
        from_attributes = True

@router.get("/", response_model=List[CameraResponse])
def list_cameras(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = current_user.tenant_id
    return db.query(Camera).filter(Camera.tenant_id == tid, Camera.is_active == True).all()

@router.post("/", response_model=CameraResponse)
def create_camera(data: CameraCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    if db.query(Camera).filter(Camera.serial == data.serial).first():
        raise HTTPException(status_code=400, detail="Serial ja cadastrado")
    camera = Camera(tenant_id=tid, **data.model_dump())
    db.add(camera)
    db.commit()
    db.refresh(camera)
    return camera

@router.delete("/{camera_id}")
def delete_camera(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    camera.is_active = False
    db.commit()
    return {"message": "Camera removida"}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - GATE
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\gate.py", @'
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from app.core.security import get_current_user
from app.core.config import settings
import paho.mqtt.publish as publish

router = APIRouter(prefix="/gate", tags=["Portao"])

class GateCommand(BaseModel):
    camera_id: int
    action: str

@router.post("/command")
def send_gate_command(data: GateCommand, current_user=Depends(get_current_user)):
    if data.action not in ["open", "close"]:
        raise HTTPException(status_code=400, detail="Acao invalida")
    topic = f"fortcam/gate/{current_user.tenant_id}/{data.camera_id}/command"
    try:
        publish.single(
            topic=topic, payload=data.action.upper(),
            hostname=settings.MQTT_BROKER, port=settings.MQTT_PORT,
            auth={"username": settings.MQTT_USER, "password": settings.MQTT_PASSWORD} if settings.MQTT_USER else None
        )
        return {"success": True, "message": f"Comando {data.action.upper()} enviado"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - WEBHOOK (com tenant por token)
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\webhook.py", @'
from fastapi import APIRouter, Request, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
from app.core.database import get_db
from app.models.event import Event
from app.models.camera import Camera
from app.models.whitelist import Whitelist

router = APIRouter(prefix="/webhook", tags=["Webhook LPR"])

def processar_placa(db, plate: str, camera_name: str, tenant_id: int, camera_id=None):
    plate = plate.strip().upper()
    entry = db.query(Whitelist).filter(
        Whitelist.tenant_id == tenant_id,
        Whitelist.plate == plate,
        Whitelist.is_active == True
    ).first()

    if not entry:
        status, reason = "denied", "not_in_whitelist"
    else:
        now = datetime.now().strftime("%H:%M")
        status = "granted" if entry.time_start <= now <= entry.time_end else "denied"
        reason = "whitelist" if status == "granted" else "out_of_hours"

    evento = Event(
        tenant_id=tenant_id,
        plate=plate,
        camera_id=camera_id,
        camera_name=camera_name,
        status=status,
        reason=reason,
        detected_at=datetime.now()
    )
    db.add(evento)
    db.commit()
    print(f"[WEBHOOK][{'V' if status=='granted' else 'X'}] {plate} | tenant={tenant_id} | {status}")
    return status, reason

@router.post("/intelbras/{camera_token}")
async def webhook_intelbras(camera_token: str, request: Request, db: Session = Depends(get_db)):
    camera = db.query(Camera).filter(Camera.webhook_token == camera_token, Camera.is_active == True).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")

    camera.is_online = True
    camera.last_seen = datetime.now()
    db.commit()

    try:
        data = await request.json()
    except:
        form = await request.form()
        data = dict(form)

    plate = data.get("plate") or data.get("licensePlate") or data.get("Plate") or str(data)
    status, reason = processar_placa(db, str(plate), camera.name, camera.tenant_id, camera.id)
    return {"success": True, "plate": plate, "status": status}

@router.get("/test/{tenant_id}/{plate}")
async def test_webhook(tenant_id: int, plate: str, db: Session = Depends(get_db)):
    status, reason = processar_placa(db, plate, "Teste Manual", tenant_id)
    return {"plate": plate, "status": status, "reason": reason}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# MAIN.PY
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\main.py", @'
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
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# CREATE SUPERADMIN
# ============================================================
[System.IO.File]::WriteAllText("$backend\create_superadmin.py", @'
"""
Cria o superadmin e um tenant de demonstracao
Execute: python create_superadmin.py
"""
import sys
sys.path.append(".")

from app.core.database import SessionLocal, engine, Base
from app.core.security import hash_password
from app.models.user import User
from app.models.tenant import Tenant
from app.models.camera import Camera
from app.models.whitelist import Whitelist
from app.models.event import Event

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# Superadmin
if not db.query(User).filter(User.email == "super@fortcam.com").first():
    super_user = User(
        tenant_id=None,
        name="Super Admin",
        email="super@fortcam.com",
        hashed_password=hash_password("super123"),
        role="superadmin"
    )
    db.add(super_user)
    db.commit()
    print("Superadmin criado: super@fortcam.com / super123")

# Tenant demo
tenant = db.query(Tenant).filter(Tenant.slug == "demo").first()
if not tenant:
    tenant = Tenant(name="Cliente Demo", slug="demo", plan="pro", max_cameras=10, max_users=5)
    db.add(tenant)
    db.commit()
    db.refresh(tenant)
    print(f"Tenant demo criado (ID: {tenant.id})")

    # Admin do tenant
    if not db.query(User).filter(User.email == "admin@fortcam.com").first():
        admin = User(
            tenant_id=tenant.id,
            name="Administrador",
            email="admin@fortcam.com",
            hashed_password=hash_password("admin123"),
            role="admin"
        )
        db.add(admin)
        db.commit()
        print("Admin demo criado: admin@fortcam.com / admin123")

print("")
print("="*40)
print("Contas criadas:")
print("SUPERADMIN: super@fortcam.com / super123")
print("ADMIN DEMO: admin@fortcam.com / admin123")
print("="*40)

db.close()
'@, [System.Text.Encoding]::UTF8)

# Remover banco antigo para recriar
if (Test-Path "$backend\fortcam.db") {
    Remove-Item "$backend\fortcam.db" -Force
    Write-Host "Banco antigo removido!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Multitenant configurado!" -ForegroundColor Green
Write-Host ""
Write-Host "Agora execute:" -ForegroundColor Yellow
Write-Host "  python create_superadmin.py" -ForegroundColor White
Write-Host "  uvicorn app.main:app --reload --port 8000" -ForegroundColor White
