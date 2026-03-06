# Atualizar camera com todos os campos necessarios
$backend = "C:\Users\Camera 3\fortcam-cloud\backend"
$frontend = "C:\Users\Camera 3\fortcam-cloud\frontend"

Write-Host "Atualizando cameras com campos completos..." -ForegroundColor Cyan

# ============================================================
# MODEL - CAMERA completo
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\models\camera.py", @'
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
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API CAMERAS - campos completos
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\cameras.py", @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import secrets
from app.core.database import get_db
from app.core.security import get_current_user
from app.models.camera import Camera

router = APIRouter(prefix="/cameras", tags=["Cameras"])

class CameraCreate(BaseModel):
    name: str
    serial: str
    model: Optional[str] = ""
    ip: Optional[str] = ""
    port_service: Optional[int] = 37777
    port_web: Optional[int] = 80
    port_rtsp: Optional[int] = 554
    cam_user: Optional[str] = "admin"
    cam_password: Optional[str] = ""
    location: Optional[str] = ""
    direction: Optional[str] = "both"
    access_type: Optional[str] = "stop_go"

class CameraResponse(BaseModel):
    id: int
    name: str
    serial: str
    model: Optional[str]
    ip: Optional[str]
    port_service: Optional[int]
    port_web: Optional[int]
    port_rtsp: Optional[int]
    cam_user: Optional[str]
    location: Optional[str]
    direction: Optional[str]
    access_type: Optional[str]
    mqtt_topic: Optional[str]
    webhook_token: Optional[str]
    is_online: bool
    is_active: bool
    last_seen: Optional[datetime]

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

    webhook_token = secrets.token_urlsafe(32)
    mqtt_topic = f"fortcam/plates/{data.serial.lower()}"

    camera = Camera(
        tenant_id=tid,
        webhook_token=webhook_token,
        mqtt_topic=mqtt_topic,
        **data.model_dump()
    )
    db.add(camera)
    db.commit()
    db.refresh(camera)
    return camera

@router.put("/{camera_id}", response_model=CameraResponse)
def update_camera(camera_id: int, data: CameraCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(camera, field, value)
    db.commit()
    db.refresh(camera)
    return camera

@router.get("/{camera_id}/webhook-info")
def webhook_info(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    return {
        "camera": camera.name,
        "webhook_url": f"/api/v1/webhook/intelbras/{camera.webhook_token}",
        "mqtt_topic": camera.mqtt_topic,
        "token": camera.webhook_token,
        "rtsp_url": f"rtsp://{camera.cam_user}:SENHA@{camera.ip}:{camera.port_rtsp}/stream" if camera.ip else "Configure o IP primeiro",
        "web_url": f"http://{camera.ip}:{camera.port_web}" if camera.ip else "Configure o IP primeiro",
    }

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
# FRONTEND - CAMERAS PAGE completa
# ============================================================
[System.IO.File]::WriteAllText("$frontend\app\(dashboard)\cameras\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import api from "@/lib/api";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

const DIRECOES = [
  { value:"entry", label:"Entrada" },
  { value:"exit", label:"Saida" },
  { value:"both", label:"Entrada e Saida" },
];
const TIPOS = [
  { value:"stop_go", label:"Stop & Go (veiculo para)" },
  { value:"free_flow", label:"Fluxo Livre (veiculo em movimento)" },
];

const VAZIO = {
  name:"", serial:"", model:"", ip:"",
  port_service:37777, port_web:80, port_rtsp:554,
  cam_user:"admin", cam_password:"",
  location:"", direction:"both", access_type:"stop_go"
};

export default function CamerasPage() {
  const [cameras, setCameras] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editModal, setEditModal] = useState<any>(null);
  const [webhookModal, setWebhookModal] = useState<any>(null);
  const [nova, setNova] = useState({...VAZIO});
  const [msg, setMsg] = useState({ texto:"", cor:"#00e676" });

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const r = await api.get("/api/v1/cameras/");
      setCameras(r.data);
    } finally { setLoading(false); }
  }

  function mostrarMsg(texto: string, cor = "#00e676") {
    setMsg({ texto, cor });
    setTimeout(() => setMsg({ texto:"", cor:"#00e676" }), 4000);
  }

  async function salvar() {
    if (!nova.name || !nova.serial) { mostrarMsg("Nome e Serial sao obrigatorios", "#ff4444"); return; }
    try {
      await api.post("/api/v1/cameras/", nova);
      setNova({...VAZIO});
      setModal(false);
      carregar();
      mostrarMsg("Camera cadastrada com sucesso!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao cadastrar", "#ff4444");
    }
  }

  async function atualizar() {
    try {
      await api.put(`/api/v1/cameras/${editModal.id}`, editModal);
      setEditModal(null);
      carregar();
      mostrarMsg("Camera atualizada!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao atualizar", "#ff4444");
    }
  }

  async function verWebhook(cam: any) {
    try {
      const r = await api.get(`/api/v1/cameras/${cam.id}/webhook-info`);
      setWebhookModal(r.data);
    } catch { mostrarMsg("Erro ao buscar webhook", "#ff4444"); }
  }

  async function remover(id: number) {
    if (!confirm("Remover esta camera?")) return;
    await api.delete(`/api/v1/cameras/${id}`);
    carregar();
    mostrarMsg("Camera removida");
  }

  const inputStyle = { width:"100%", padding:"8px 10px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:12, outline:"none", boxSizing:"border-box" as const };
  const labelStyle = { fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase" as const, display:"block" as const, marginBottom:3 };

  function FormCamera({ data, setData, onSave, onCancel, title }: any) {
    return (
      <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100, overflowY:"auto", padding:20 }}>
        <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:24, width:520, maxHeight:"90vh", overflowY:"auto" }}>
          <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16, paddingBottom:12, borderBottom:"1px solid rgba(0,160,255,0.1)" }}>{title}</div>

          <div style={{ fontSize:11, color:"#00bfff", marginBottom:10, fontWeight:600 }}>IDENTIFICACAO</div>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:12 }}>
            <div><label style={labelStyle}>Nome *</label><input value={data.name} onChange={e=>setData((p:any)=>({...p,name:e.target.value}))} placeholder="Entrada 01" style={inputStyle} /></div>
            <div><label style={labelStyle}>Serial *</label><input value={data.serial} onChange={e=>setData((p:any)=>({...p,serial:e.target.value}))} placeholder="JHRM30000754S" style={inputStyle} /></div>
            <div><label style={labelStyle}>Modelo</label><input value={data.model} onChange={e=>setData((p:any)=>({...p,model:e.target.value}))} placeholder="VIP-5460-LPR-IA" style={inputStyle} /></div>
            <div><label style={labelStyle}>Localizacao</label><input value={data.location} onChange={e=>setData((p:any)=>({...p,location:e.target.value}))} placeholder="Portao principal" style={inputStyle} /></div>
          </div>

          <div style={{ fontSize:11, color:"#00bfff", marginBottom:10, fontWeight:600 }}>REDE</div>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr 1fr 1fr", gap:10, marginBottom:12 }}>
            <div style={{ gridColumn:"1/3" }}><label style={labelStyle}>Endereco IP</label><input value={data.ip} onChange={e=>setData((p:any)=>({...p,ip:e.target.value}))} placeholder="192.168.1.160" style={inputStyle} /></div>
            <div><label style={labelStyle}>Porta Servico</label><input type="number" value={data.port_service} onChange={e=>setData((p:any)=>({...p,port_service:+e.target.value}))} style={inputStyle} /></div>
            <div><label style={labelStyle}>Porta Web</label><input type="number" value={data.port_web} onChange={e=>setData((p:any)=>({...p,port_web:+e.target.value}))} style={inputStyle} /></div>
            <div><label style={labelStyle}>Porta RTSP</label><input type="number" value={data.port_rtsp} onChange={e=>setData((p:any)=>({...p,port_rtsp:+e.target.value}))} style={inputStyle} /></div>
          </div>

          <div style={{ fontSize:11, color:"#00bfff", marginBottom:10, fontWeight:600 }}>AUTENTICACAO</div>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:12 }}>
            <div><label style={labelStyle}>Usuario</label><input value={data.cam_user} onChange={e=>setData((p:any)=>({...p,cam_user:e.target.value}))} placeholder="admin" style={inputStyle} /></div>
            <div><label style={labelStyle}>Senha</label><input type="password" value={data.cam_password} onChange={e=>setData((p:any)=>({...p,cam_password:e.target.value}))} placeholder="••••••••" style={inputStyle} /></div>
          </div>

          <div style={{ fontSize:11, color:"#00bfff", marginBottom:10, fontWeight:600 }}>CONFIGURACAO</div>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:16 }}>
            <div>
              <label style={labelStyle}>Direcao</label>
              <select value={data.direction} onChange={e=>setData((p:any)=>({...p,direction:e.target.value}))} style={{...inputStyle}}>
                {DIRECOES.map(d=><option key={d.value} value={d.value}>{d.label}</option>)}
              </select>
            </div>
            <div>
              <label style={labelStyle}>Tipo de Acesso</label>
              <select value={data.access_type} onChange={e=>setData((p:any)=>({...p,access_type:e.target.value}))} style={{...inputStyle}}>
                {TIPOS.map(t=><option key={t.value} value={t.value}>{t.label}</option>)}
              </select>
            </div>
          </div>

          <div style={{ display:"flex", gap:8 }}>
            <button onClick={onCancel} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
            <button onClick={onSave} style={{ flex:2, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR CAMERA</button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>CAMERAS / MONITORAMENTO</div>
        <button onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:11, fontWeight:700 }}>+ NOVA CAMERA</button>
      </div>

      {msg.texto && <div style={{ background:`${msg.cor}15`, border:`1px solid ${msg.cor}44`, borderRadius:8, padding:"10px 14px", color:msg.cor, fontSize:12 }}>{msg.texto}</div>}

      {loading && <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando...</div>}
      {!loading && cameras.length === 0 && (
        <div style={{ background:"rgba(0,0,0,0.2)", border:"1px solid rgba(0,160,255,0.1)", borderRadius:10, padding:32, textAlign:"center", color:"#4a6a8a" }}>
          Nenhuma camera cadastrada.
        </div>
      )}

      <div style={{ display:"grid", gridTemplateColumns:"repeat(2,1fr)", gap:12 }}>
        {cameras.map(cam => (
          <div key={cam.id} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ height:90, background:cam.is_online?"linear-gradient(135deg,#0a1a2a,#0d2035)":"linear-gradient(135deg,#111,#0a0a0a)", display:"flex", alignItems:"center", justifyContent:"center", position:"relative" }}>
              <span style={{ fontSize:11, color:cam.is_online?"rgba(0,180,255,0.5)":"rgba(255,255,255,0.1)", fontFamily:"'Orbitron',monospace", letterSpacing:2 }}>{cam.is_online?"[ONLINE]":"[OFFLINE]"}</span>
              <span style={{ position:"absolute", top:8, right:8, fontSize:9, padding:"2px 7px", borderRadius:4, background:cam.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:cam.is_online?"#00e676":"#ff4444", border:`1px solid ${cam.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace" }}>{cam.is_online?"ONLINE":"OFFLINE"}</span>
            </div>
            <div style={{ padding:"10px 14px" }}>
              <div style={{ fontSize:14, fontWeight:600, color:"#c8e0f0", marginBottom:4 }}>{cam.name}</div>
              <div style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace", lineHeight:1.6, marginBottom:8 }}>
                SN: {cam.serial}{cam.model ? ` | ${cam.model}` : ""}<br/>
                {cam.ip ? `IP: ${cam.ip} | Web: ${cam.port_web} | RTSP: ${cam.port_rtsp}` : "IP nao configurado"}<br/>
                {cam.location ? `Local: ${cam.location}` : ""}
                {cam.last_seen ? ` | Sinal: ${new Date(cam.last_seen).toLocaleString("pt-BR")}` : ""}
              </div>
              <div style={{ display:"flex", gap:6 }}>
                <button onClick={()=>verWebhook(cam)} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(0,160,255,0.3)", borderRadius:4, background:"rgba(0,100,200,0.1)", color:"#7ec8ff", fontSize:11, cursor:"pointer", fontWeight:600 }}>Webhook</button>
                <button onClick={()=>setEditModal({...cam})} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(255,165,0,0.3)", borderRadius:4, background:"rgba(255,165,0,0.1)", color:"#ffaa44", fontSize:11, cursor:"pointer", fontWeight:600 }}>Editar</button>
                <button onClick={()=>remover(cam.id)} style={{ padding:"6px 12px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>X</button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {modal && <FormCamera data={nova} setData={setNova} onSave={salvar} onCancel={()=>setModal(false)} title="NOVA CAMERA" />}
      {editModal && <FormCamera data={editModal} setData={setEditModal} onSave={atualizar} onCancel={()=>setEditModal(null)} title={`EDITAR - ${editModal.name}`} />}

      {webhookModal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:24, width:520 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16 }}>INTEGRACAO - {webhookModal.camera}</div>

            {[
              { label:"URL Webhook (configure na camera)", value:`${API_URL}${webhookModal.webhook_url}`, cor:"#00bfff" },
              { label:"Topico MQTT", value:webhookModal.mqtt_topic, cor:"#00e676" },
              { label:"URL Interface Web da Camera", value:webhookModal.web_url, cor:"#ffaa44" },
              { label:"URL Stream RTSP", value:webhookModal.rtsp_url, cor:"#aa88ff" },
            ].map((item,i) => (
              <div key={i} style={{ marginBottom:12 }}>
                <div style={{ fontSize:10, color:"#5a7a9a", textTransform:"uppercase", letterSpacing:1, marginBottom:4 }}>{item.label}</div>
                <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(255,255,255,0.05)", borderRadius:6, padding:"8px 10px", fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:item.cor, wordBreak:"break-all" }}>{item.value}</div>
              </div>
            ))}

            <div style={{ background:"rgba(0,80,40,0.1)", border:"1px solid rgba(0,160,100,0.2)", borderRadius:6, padding:"10px 12px", marginBottom:12, fontSize:11, color:"#5a9a7a" }}>
              <strong style={{ color:"#00e676" }}>Como configurar na Intelbras VIP 5460:</strong><br/>
              1. Acesse a Interface Web da Camera<br/>
              2. Va em Configuracoes → Eventos → HTTP Push<br/>
              3. Cole a URL do Webhook acima<br/>
              4. Metodo: POST | Formato: JSON<br/>
              5. Salve e aguarde deteccao de placas
            </div>

            <button onClick={()=>setWebhookModal(null)} style={{ width:"100%", padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Fechar</button>
          </div>
        </div>
      )}
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Cameras atualizadas com campos completos!" -ForegroundColor Green
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "1. Enviar camera.py para VPS:" -ForegroundColor White
Write-Host "   scp app\models\camera.py root@187.77.231.19:/opt/fortcam/app/models/" -ForegroundColor Gray
Write-Host "   scp app\api\v1\cameras.py root@187.77.231.19:/opt/fortcam/app/api/v1/" -ForegroundColor Gray
Write-Host "2. Recriar banco na VPS (novos campos)" -ForegroundColor White
Write-Host "3. Rebuildar frontend: npm run build" -ForegroundColor White
Write-Host "4. Enviar out para VPS" -ForegroundColor White
