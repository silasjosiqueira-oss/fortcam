# Criar sistema completo de portoes/barreiras
$backend = "C:\Users\Camera 3\fortcam-cloud\backend"
$frontend = "C:\Users\Camera 3\fortcam-cloud\frontend"

Write-Host "Criando sistema de portoes..." -ForegroundColor Cyan

# ============================================================
# MODEL - GATE
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\models\gate.py", @'
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.core.database import Base

class Gate(Base):
    __tablename__ = "gates"

    id = Column(Integer, primary_key=True, index=True)
    tenant_id = Column(Integer, ForeignKey("tenants.id"), nullable=False)
    camera_id = Column(Integer, ForeignKey("cameras.id"), nullable=True)

    name = Column(String(100), nullable=False)
    location = Column(String(200), nullable=True)
    gate_type = Column(String(50), default="cancela")   # cancela, portao, porta
    mode = Column(String(20), default="auto")           # auto, manual
    open_time = Column(Integer, default=5)              # segundos aberto
    mqtt_topic = Column(String(200), nullable=True)     # topico para receber comandos
    
    is_online = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    last_trigger = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# API - GATE completa
# ============================================================
[System.IO.File]::WriteAllText("$backend\app\api\v1\gate.py", @'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime
import paho.mqtt.publish as publish
from app.core.database import get_db
from app.core.security import get_current_user
from app.core.config import settings
from app.models.gate import Gate

router = APIRouter(prefix="/gate", tags=["Portao"])

class GateCreate(BaseModel):
    name: str
    location: Optional[str] = ""
    gate_type: Optional[str] = "cancela"
    mode: Optional[str] = "auto"
    open_time: Optional[int] = 5
    camera_id: Optional[int] = None

class GateResponse(BaseModel):
    id: int
    name: str
    location: Optional[str]
    gate_type: str
    mode: str
    open_time: int
    camera_id: Optional[int]
    mqtt_topic: Optional[str]
    is_online: bool
    is_active: bool
    last_trigger: Optional[datetime]

    class Config:
        from_attributes = True

def mqtt_publish(topic: str, payload: str):
    try:
        publish.single(
            topic=topic,
            payload=payload,
            hostname=settings.MQTT_BROKER,
            port=settings.MQTT_PORT,
            auth={"username": settings.MQTT_USER, "password": settings.MQTT_PASSWORD} if settings.MQTT_USER else None
        )
        return True
    except Exception as e:
        print(f"[MQTT][ERRO] {e}")
        return False

@router.get("/", response_model=List[GateResponse])
def list_gates(db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    return db.query(Gate).filter(Gate.tenant_id == current_user.tenant_id, Gate.is_active == True).all()

@router.post("/", response_model=GateResponse)
def create_gate(data: GateCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    tid = current_user.tenant_id
    gate = Gate(
        tenant_id=tid,
        mqtt_topic=f"fortcam/barrier/{tid}/gate_{data.name.lower().replace(' ','_')}/open",
        **data.model_dump()
    )
    db.add(gate)
    db.commit()
    db.refresh(gate)
    return gate

@router.put("/{gate_id}", response_model=GateResponse)
def update_gate(gate_id: int, data: GateCreate, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    for k, v in data.model_dump(exclude_unset=True).items():
        setattr(gate, k, v)
    db.commit()
    db.refresh(gate)
    return gate

@router.post("/{gate_id}/open")
def open_gate(gate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    import json
    payload = json.dumps({
        "action": "open",
        "open_time": gate.open_time,
        "triggered_by": current_user.email,
        "ts": datetime.now().isoformat()
    })
    success = mqtt_publish(gate.mqtt_topic, payload)
    if success:
        gate.last_trigger = datetime.now()
        db.commit()
        return {"success": True, "message": f"Comando ABRIR enviado para {gate.name}"}
    raise HTTPException(status_code=500, detail="Erro ao enviar comando MQTT")

@router.post("/{gate_id}/close")
def close_gate(gate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    import json
    payload = json.dumps({"action": "close", "ts": datetime.now().isoformat()})
    success = mqtt_publish(gate.mqtt_topic, payload)
    return {"success": success, "message": "Comando FECHAR enviado"}

@router.delete("/{gate_id}")
def delete_gate(gate_id: int, db: Session = Depends(get_db), current_user=Depends(get_current_user)):
    if current_user.role not in ["admin", "superadmin"]:
        raise HTTPException(status_code=403, detail="Sem permissao")
    gate = db.query(Gate).filter(Gate.id == gate_id, Gate.tenant_id == current_user.tenant_id).first()
    if not gate:
        raise HTTPException(status_code=404, detail="Portao nao encontrado")
    gate.is_active = False
    db.commit()
    return {"message": "Portao removido"}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# FRONTEND - PORTOES PAGE
# ============================================================
New-Item -ItemType Directory -Force -Path "$frontend\app\(dashboard)\portoes" | Out-Null
[System.IO.File]::WriteAllText("$frontend\app\(dashboard)\portoes\page.tsx", @'
"use client";
import { useState, useEffect, useCallback } from "react";
import api from "@/lib/api";

const VAZIO = { name:"", location:"", gate_type:"cancela", mode:"auto", open_time:5, camera_id:null as any };

const inputStyle: React.CSSProperties = { width:"100%", padding:"8px 10px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:12, outline:"none", boxSizing:"border-box" };
const labelStyle: React.CSSProperties = { fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:3 };

function GateForm({ data, cameras, onChange, onSave, onCancel, title }: any) {
  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100, padding:20 }}>
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:24, width:480 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16, paddingBottom:12, borderBottom:"1px solid rgba(0,160,255,0.1)" }}>{title}</div>

        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:14 }}>
          <div><label style={labelStyle}>Nome *</label><input value={data.name} onChange={e=>onChange("name",e.target.value)} placeholder="Portao Principal" style={inputStyle} /></div>
          <div><label style={labelStyle}>Localizacao</label><input value={data.location} onChange={e=>onChange("location",e.target.value)} placeholder="Entrada" style={inputStyle} /></div>
          <div>
            <label style={labelStyle}>Tipo</label>
            <select value={data.gate_type} onChange={e=>onChange("gate_type",e.target.value)} style={inputStyle}>
              <option value="cancela">Cancela</option>
              <option value="portao">Portao Deslizante</option>
              <option value="porta">Porta</option>
            </select>
          </div>
          <div>
            <label style={labelStyle}>Modo</label>
            <select value={data.mode} onChange={e=>onChange("mode",e.target.value)} style={inputStyle}>
              <option value="auto">Automatico (por placa)</option>
              <option value="manual">Manual</option>
            </select>
          </div>
          <div>
            <label style={labelStyle}>Tempo Aberto (seg)</label>
            <input type="number" value={data.open_time} onChange={e=>onChange("open_time",+e.target.value)} style={inputStyle} min={1} max={60} />
          </div>
          <div>
            <label style={labelStyle}>Camera Vinculada</label>
            <select value={data.camera_id || ""} onChange={e=>onChange("camera_id", e.target.value ? +e.target.value : null)} style={inputStyle}>
              <option value="">Nenhuma</option>
              {cameras.map((c:any) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
        </div>

        <div style={{ background:"rgba(0,100,200,0.08)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:6, padding:"10px 12px", marginBottom:14, fontSize:11, color:"#5a8aaa" }}>
          O topico MQTT sera gerado automaticamente. O controlador fisico deve se inscrever neste topico para receber os comandos de abertura.
        </div>

        <div style={{ display:"flex", gap:8 }}>
          <button onClick={onCancel} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
          <button onClick={onSave} style={{ flex:2, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR PORTAO</button>
        </div>
      </div>
    </div>
  );
}

export default function PortoesPage() {
  const [gates, setGates] = useState<any[]>([]);
  const [cameras, setCameras] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editModal, setEditModal] = useState(false);
  const [mqttModal, setMqttModal] = useState<any>(null);
  const [nova, setNova] = useState({...VAZIO});
  const [editData, setEditData] = useState<any>(null);
  const [msg, setMsg] = useState({ texto:"", cor:"#00e676" });
  const [abrindo, setAbrindo] = useState<number|null>(null);

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const [g, c] = await Promise.all([
        api.get("/api/v1/gate/"),
        api.get("/api/v1/cameras/")
      ]);
      setGates(g.data);
      setCameras(c.data);
    } finally { setLoading(false); }
  }

  function mostrarMsg(texto: string, cor = "#00e676") {
    setMsg({ texto, cor });
    setTimeout(() => setMsg({ texto:"", cor:"#00e676" }), 4000);
  }

  const handleNovaChange = useCallback((f: string, v: any) => setNova(p=>({...p,[f]:v})), []);
  const handleEditChange = useCallback((f: string, v: any) => setEditData((p:any)=>({...p,[f]:v})), []);

  async function salvar() {
    if (!nova.name) { mostrarMsg("Nome obrigatorio", "#ff4444"); return; }
    try {
      await api.post("/api/v1/gate/", nova);
      setNova({...VAZIO});
      setModal(false);
      carregar();
      mostrarMsg("Portao cadastrado!");
    } catch (err: any) { mostrarMsg(err.response?.data?.detail || "Erro", "#ff4444"); }
  }

  async function atualizar() {
    try {
      await api.put(`/api/v1/gate/${editData.id}`, editData);
      setEditModal(false);
      carregar();
      mostrarMsg("Portao atualizado!");
    } catch (err: any) { mostrarMsg(err.response?.data?.detail || "Erro", "#ff4444"); }
  }

  async function abrir(gate: any) {
    setAbrindo(gate.id);
    try {
      await api.post(`/api/v1/gate/${gate.id}/open`);
      mostrarMsg(`Comando ABRIR enviado para ${gate.name}!`);
      carregar();
    } catch { mostrarMsg("Erro ao enviar comando", "#ff4444"); }
    finally { setAbrindo(null); }
  }

  async function fechar(gate: any) {
    try {
      await api.post(`/api/v1/gate/${gate.id}/close`);
      mostrarMsg(`Comando FECHAR enviado para ${gate.name}`);
    } catch { mostrarMsg("Erro ao enviar comando", "#ff4444"); }
  }

  async function remover(id: number) {
    if (!confirm("Remover este portao?")) return;
    await api.delete(`/api/v1/gate/${id}`);
    carregar();
  }

  const TIPO_ICON: any = { cancela:"⚡", portao:"🚗", porta:"🚪" };
  const camNome = (id: number) => cameras.find(c=>c.id===id)?.name || "Nenhuma";

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>PORTOES / BARREIRAS</div>
        <button onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:11, fontWeight:700 }}>+ NOVO PORTAO</button>
      </div>

      {msg.texto && <div style={{ background:`${msg.cor}15`, border:`1px solid ${msg.cor}44`, borderRadius:8, padding:"10px 14px", color:msg.cor, fontSize:12 }}>{msg.texto}</div>}

      {loading && <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando...</div>}
      {!loading && gates.length === 0 && (
        <div style={{ background:"rgba(0,0,0,0.2)", border:"1px solid rgba(0,160,255,0.1)", borderRadius:10, padding:32, textAlign:"center", color:"#4a6a8a" }}>
          Nenhum portao cadastrado. Clique em + NOVO PORTAO.
        </div>
      )}

      <div style={{ display:"grid", gridTemplateColumns:"repeat(2,1fr)", gap:12 }}>
        {gates.map(gate => (
          <div key={gate.id} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ padding:"14px 16px", borderBottom:"1px solid rgba(0,160,255,0.08)" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:6 }}>
                <div style={{ display:"flex", alignItems:"center", gap:8 }}>
                  <span style={{ fontSize:20 }}>{TIPO_ICON[gate.gate_type]}</span>
                  <span style={{ fontSize:14, fontWeight:600, color:"#c8e0f0" }}>{gate.name}</span>
                </div>
                <span style={{ fontSize:9, padding:"2px 8px", borderRadius:4, background:gate.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:gate.is_online?"#00e676":"#ff4444", border:`1px solid ${gate.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace" }}>{gate.is_online?"ONLINE":"OFFLINE"}</span>
              </div>
              <div style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace", lineHeight:1.7 }}>
                {gate.location && `Local: ${gate.location} | `}Tipo: {gate.gate_type} | Modo: {gate.mode}<br/>
                Camera: {camNome(gate.camera_id)} | Tempo aberto: {gate.open_time}s<br/>
                {gate.last_trigger && `Ultimo acionamento: ${new Date(gate.last_trigger).toLocaleString("pt-BR")}`}
              </div>
            </div>

            {/* Botoes de controle */}
            <div style={{ padding:"10px 14px", background:"rgba(0,0,0,0.2)", display:"flex", gap:6, marginBottom:8 }}>
              <button onClick={()=>abrir(gate)} disabled={abrindo===gate.id} style={{ flex:1, padding:"10px 0", border:"none", borderRadius:6, background:abrindo===gate.id?"rgba(0,200,80,0.2)":"linear-gradient(135deg,#00aa44,#007733)", color:"#fff", fontSize:12, cursor:"pointer", fontWeight:700, fontFamily:"'Orbitron',monospace" }}>
                {abrindo===gate.id?"ABRINDO...":"▲ ABRIR"}
              </button>
              <button onClick={()=>fechar(gate)} style={{ flex:1, padding:"10px 0", border:"1px solid rgba(255,120,0,0.4)", borderRadius:6, background:"rgba(255,120,0,0.1)", color:"#ff9944", fontSize:12, cursor:"pointer", fontWeight:700, fontFamily:"'Orbitron',monospace" }}>▼ FECHAR</button>
            </div>

            <div style={{ padding:"0 14px 10px", display:"flex", gap:6 }}>
              <button onClick={()=>setMqttModal(gate)} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(0,160,255,0.3)", borderRadius:4, background:"rgba(0,100,200,0.1)", color:"#7ec8ff", fontSize:11, cursor:"pointer" }}>Config MQTT</button>
              <button onClick={()=>{ setEditData({...gate}); setEditModal(true); }} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(255,165,0,0.3)", borderRadius:4, background:"rgba(255,165,0,0.1)", color:"#ffaa44", fontSize:11, cursor:"pointer" }}>Editar</button>
              <button onClick={()=>remover(gate.id)} style={{ padding:"6px 12px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>X</button>
            </div>
          </div>
        ))}
      </div>

      {modal && <GateForm data={nova} cameras={cameras} onChange={handleNovaChange} onSave={salvar} onCancel={()=>setModal(false)} title="NOVO PORTAO" />}
      {editModal && editData && <GateForm data={editData} cameras={cameras} onChange={handleEditChange} onSave={atualizar} onCancel={()=>{ setEditModal(false); setEditData(null); }} title={`EDITAR - ${editData.name}`} />}

      {mqttModal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:24, width:500 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16 }}>CONFIG MQTT - {mqttModal.name}</div>

            <div style={{ marginBottom:12 }}>
              <div style={{ fontSize:10, color:"#5a7a9a", textTransform:"uppercase", letterSpacing:1, marginBottom:4 }}>Topico MQTT (controlador assina este topico)</div>
              <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(0,230,118,0.2)", borderRadius:6, padding:"10px 12px", fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#00e676", wordBreak:"break-all" }}>{mqttModal.mqtt_topic}</div>
            </div>

            <div style={{ marginBottom:12 }}>
              <div style={{ fontSize:10, color:"#5a7a9a", textTransform:"uppercase", letterSpacing:1, marginBottom:4 }}>Broker MQTT</div>
              <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, padding:"10px 12px", fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#00bfff" }}>fortcam.com.br:1883</div>
            </div>

            <div style={{ background:"rgba(0,80,40,0.1)", border:"1px solid rgba(0,160,100,0.2)", borderRadius:6, padding:"12px", marginBottom:14, fontSize:11, color:"#5a9a7a", lineHeight:1.7 }}>
              <strong style={{ color:"#00e676" }}>Como configurar o controlador (ESP32/Arduino):</strong><br/>
              1. Conectar no broker: <strong>fortcam.com.br:1883</strong><br/>
              2. Assinar o topico acima<br/>
              3. Quando receber <strong>"action": "open"</strong> → acionar rele por <strong>{mqttModal.open_time}s</strong><br/>
              4. Publicar confirmacao em: <strong>{mqttModal.mqtt_topic}/status</strong>
            </div>

            <div style={{ background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.1)", borderRadius:6, padding:"10px 12px", marginBottom:14, fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>
              Payload recebido:<br/>
              {"{"}"action": "open", "open_time": {mqttModal.open_time}, "ts": "..."{"}"}
            </div>

            <button onClick={()=>setMqttModal(null)} style={{ width:"100%", padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Fechar</button>
          </div>
        </div>
      )}
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Sistema de portoes criado!" -ForegroundColor Green
Write-Host ""
Write-Host "Execute:" -ForegroundColor Yellow
Write-Host "  scp app\models\gate.py root@187.77.231.19:/opt/fortcam/app/models/" -ForegroundColor White
Write-Host "  scp app\api\v1\gate.py root@187.77.231.19:/opt/fortcam/app/api/v1/" -ForegroundColor White
Write-Host "  npm run build" -ForegroundColor White
Write-Host "  scp -r out\* root@187.77.231.19:/var/www/fortcam/" -ForegroundColor White
