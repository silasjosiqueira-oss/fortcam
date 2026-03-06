# Cameras funcionais com webhook token
$backend = "C:\Users\Camera 3\fortcam-cloud\backend"
$frontend = "C:\Users\Camera 3\fortcam-cloud\frontend"

Write-Host "Atualizando cameras com webhook token..." -ForegroundColor Cyan

# ============================================================
# API CAMERAS - com webhook token gerado automaticamente
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
    ip: str = ""
    location: str = ""

class CameraResponse(BaseModel):
    id: int
    name: str
    serial: str
    ip: Optional[str]
    location: Optional[str]
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

    # Gerar token unico para webhook
    webhook_token = secrets.token_urlsafe(32)
    mqtt_topic = f"fortcam/plates/{data.serial.lower()}"

    camera = Camera(
        tenant_id=tid,
        name=data.name,
        serial=data.serial,
        ip=data.ip,
        location=data.location,
        webhook_token=webhook_token,
        mqtt_topic=mqtt_topic,
        is_online=False,
        is_active=True
    )
    db.add(camera)
    db.commit()
    db.refresh(camera)
    return camera

@router.get("/{camera_id}/webhook-info")
def webhook_info(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """Retorna a URL do webhook para configurar na camera"""
    from app.core.config import settings
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    return {
        "camera": camera.name,
        "webhook_url": f"/api/v1/webhook/intelbras/{camera.webhook_token}",
        "mqtt_topic": camera.mqtt_topic,
        "token": camera.webhook_token,
        "instructions": "Configure esta URL no campo HTTP Push da camera"
    }

@router.post("/{camera_id}/ping")
def ping_camera(camera_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    """Marca camera como online manualmente"""
    tid = current_user.tenant_id
    camera = db.query(Camera).filter(Camera.id == camera_id, Camera.tenant_id == tid).first()
    if not camera:
        raise HTTPException(status_code=404, detail="Camera nao encontrada")
    camera.is_online = True
    camera.last_seen = datetime.now()
    db.commit()
    return {"message": "Camera marcada como online"}

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
# FRONTEND - CAMERAS PAGE com webhook info
# ============================================================
[System.IO.File]::WriteAllText("$frontend\app\(dashboard)\cameras\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import { camerasAPI } from "@/lib/api";
import api from "@/lib/api";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

export default function CamerasPage() {
  const [cameras, setCameras] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [webhookModal, setWebhookModal] = useState<any>(null);
  const [nova, setNova] = useState({ name:"", serial:"", ip:"", location:"" });
  const [msg, setMsg] = useState("");

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const r = await camerasAPI.list();
      setCameras(r.data);
    } finally { setLoading(false); }
  }

  function mostrarMsg(texto: string) {
    setMsg(texto);
    setTimeout(() => setMsg(""), 3000);
  }

  async function adicionar() {
    if (!nova.name || !nova.serial) return;
    try {
      await api.post("/api/v1/cameras/", nova);
      setNova({ name:"", serial:"", ip:"", location:"" });
      setModal(false);
      carregar();
      mostrarMsg("Camera adicionada com sucesso!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao adicionar");
    }
  }

  async function verWebhook(camera: any) {
    try {
      const r = await api.get(`/api/v1/cameras/${camera.id}/webhook-info`);
      setWebhookModal({ ...r.data, camera_id: camera.id });
    } catch { mostrarMsg("Erro ao buscar info do webhook"); }
  }

  async function remover(id: number) {
    if (!confirm("Remover esta camera?")) return;
    await api.delete(`/api/v1/cameras/${id}`);
    carregar();
  }

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>CAMERAS / MONITORAMENTO</div>
        <button onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:11, fontWeight:700 }}>+ NOVA CAMERA</button>
      </div>

      {msg && <div style={{ background:"rgba(0,230,118,0.1)", border:"1px solid rgba(0,230,118,0.3)", borderRadius:8, padding:"10px 14px", color:"#00e676", fontSize:12 }}>{msg}</div>}

      {loading && <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando...</div>}

      {!loading && cameras.length === 0 && (
        <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:32, textAlign:"center", color:"#4a6a8a" }}>
          Nenhuma camera cadastrada. Clique em + NOVA CAMERA para adicionar.
        </div>
      )}

      <div style={{ display:"grid", gridTemplateColumns:"repeat(2,1fr)", gap:12 }}>
        {cameras.map(cam => (
          <div key={cam.id} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ height:120, background:cam.is_online?"linear-gradient(135deg,#0a1a2a,#0d2035)":"linear-gradient(135deg,#111,#0a0a0a)", display:"flex", alignItems:"center", justifyContent:"center", position:"relative", fontSize:13, color:cam.is_online?"rgba(0,180,255,0.4)":"rgba(255,255,255,0.1)", fontFamily:"'Orbitron',monospace", letterSpacing:2 }}>
              {cam.is_online ? "[CAMERA LIVE]" : "[OFFLINE]"}
              {cam.is_online && (
                <div style={{ position:"absolute", top:10, right:10, display:"flex", alignItems:"center", gap:4, background:"rgba(0,0,0,0.6)", padding:"3px 8px", borderRadius:4, border:"1px solid rgba(255,50,50,0.4)" }}>
                  <div style={{ width:6, height:6, borderRadius:"50%", background:"#ff3333", boxShadow:"0 0 6px #ff3333" }} />
                  <span style={{ fontSize:9, color:"#ff7777", fontWeight:700, letterSpacing:1, fontFamily:"'Orbitron',monospace" }}>AO VIVO</span>
                </div>
              )}
            </div>
            <div style={{ padding:"10px 14px" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:6 }}>
                <span style={{ fontSize:14, fontWeight:600, color:"#c8e0f0" }}>{cam.name}</span>
                <span style={{ fontSize:10, padding:"2px 8px", borderRadius:4, background:cam.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:cam.is_online?"#00e676":"#ff4444", border:`1px solid ${cam.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace" }}>{cam.is_online?"ONLINE":"OFFLINE"}</span>
              </div>
              <div style={{ fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace", marginBottom:8 }}>
                SN: {cam.serial} {cam.ip ? `| IP: ${cam.ip}` : ""}<br/>
                {cam.location ? `Local: ${cam.location}` : ""}
                {cam.last_seen ? `\nUltimo sinal: ${new Date(cam.last_seen).toLocaleString("pt-BR")}` : ""}
              </div>
              <div style={{ display:"flex", gap:6 }}>
                <button onClick={()=>verWebhook(cam)} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(0,160,255,0.3)", borderRadius:4, background:"rgba(0,100,200,0.1)", color:"#7ec8ff", fontSize:11, cursor:"pointer", fontWeight:600 }}>Ver Webhook</button>
                <button onClick={()=>remover(cam.id)} style={{ padding:"6px 12px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>Remover</button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Modal nova camera */}
      {modal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.7)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:420 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>NOVA CAMERA</div>
            {[{l:"Nome *",k:"name",p:"Entrada 01"},{l:"Serial *",k:"serial",p:"JHRM30000754S"},{l:"IP",k:"ip",p:"192.168.1.160"},{l:"Localizacao",k:"location",p:"Portao principal"}].map(c=>(
              <div key={c.k} style={{ marginBottom:12 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>{c.l}</label>
                <input value={(nova as any)[c.k]} onChange={e=>setNova(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ background:"rgba(0,100,200,0.08)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:6, padding:"10px 12px", marginBottom:16, fontSize:11, color:"#5a8aaa" }}>
              Apos cadastrar, clique em "Ver Webhook" para obter a URL de integracao com a camera.
            </div>
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>setModal(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={adicionar} style={{ flex:1, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal webhook info */}
      {webhookModal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:520 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>INTEGRACAO - {webhookModal.camera}</div>

            <div style={{ marginBottom:16 }}>
              <div style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", marginBottom:6 }}>URL do Webhook (configure na camera)</div>
              <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, padding:"10px 12px", fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#00bfff", wordBreak:"break-all" }}>
                {API_URL}{webhookModal.webhook_url}
              </div>
            </div>

            <div style={{ marginBottom:16 }}>
              <div style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", marginBottom:6 }}>Topico MQTT</div>
              <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, padding:"10px 12px", fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#00e676" }}>
                {webhookModal.mqtt_topic}
              </div>
            </div>

            <div style={{ background:"rgba(0,100,50,0.08)", border:"1px solid rgba(0,160,100,0.2)", borderRadius:6, padding:"10px 12px", marginBottom:16, fontSize:11, color:"#5a9a7a" }}>
              <strong style={{ color:"#00e676" }}>Como configurar na Intelbras VIP 5460:</strong><br/>
              1. Acesse a interface web da camera<br/>
              2. Va em Configuracoes → Eventos → HTTP Push<br/>
              3. Cole a URL do webhook acima<br/>
              4. Metodo: POST | Formato: JSON<br/>
              5. Salve e teste enviando uma placa
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
Write-Host "Cameras atualizadas!" -ForegroundColor Green
Write-Host ""
Write-Host "Agora envie o cameras.py para a VPS:" -ForegroundColor Yellow
Write-Host "  scp app\api\v1\cameras.py root@187.77.231.19:/opt/fortcam/app/api/v1/" -ForegroundColor White
Write-Host ""
Write-Host "E reinicie o backend na VPS:" -ForegroundColor Yellow
Write-Host "  systemctl restart fortcam" -ForegroundColor White
