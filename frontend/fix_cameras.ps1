# Corrigir bug dos inputs na pagina de cameras
$frontend = "C:\Users\Camera 3\fortcam-cloud\frontend"

Write-Host "Corrigindo bug dos inputs..." -ForegroundColor Cyan

[System.IO.File]::WriteAllText("$frontend\app\(dashboard)\cameras\page.tsx", @'
"use client";
import { useState, useEffect, useCallback } from "react";
import api from "@/lib/api";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

const VAZIO = {
  name:"", serial:"", model:"", ip:"",
  port_service:37777, port_web:80, port_rtsp:554,
  cam_user:"admin", cam_password:"",
  location:"", direction:"both", access_type:"stop_go"
};

const inputStyle: React.CSSProperties = { width:"100%", padding:"8px 10px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:12, outline:"none", boxSizing:"border-box" };
const labelStyle: React.CSSProperties = { fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:3 };

function CameraForm({ data, onChange, onSave, onCancel, title }: {
  data: any, onChange: (field: string, value: any) => void,
  onSave: () => void, onCancel: () => void, title: string
}) {
  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100, padding:20 }}>
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:24, width:520, maxHeight:"90vh", overflowY:"auto" }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16, paddingBottom:12, borderBottom:"1px solid rgba(0,160,255,0.1)" }}>{title}</div>

        <div style={{ fontSize:11, color:"#00bfff", marginBottom:8, fontWeight:600 }}>IDENTIFICACAO</div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:14 }}>
          <div><label style={labelStyle}>Nome *</label><input value={data.name} onChange={e=>onChange("name",e.target.value)} placeholder="Entrada 01" style={inputStyle} /></div>
          <div><label style={labelStyle}>Serial *</label><input value={data.serial} onChange={e=>onChange("serial",e.target.value)} placeholder="JHRM30000754S" style={inputStyle} /></div>
          <div><label style={labelStyle}>Modelo</label><input value={data.model} onChange={e=>onChange("model",e.target.value)} placeholder="VIP-5460-LPR-IA" style={inputStyle} /></div>
          <div><label style={labelStyle}>Localizacao</label><input value={data.location} onChange={e=>onChange("location",e.target.value)} placeholder="Portao principal" style={inputStyle} /></div>
        </div>

        <div style={{ fontSize:11, color:"#00bfff", marginBottom:8, fontWeight:600 }}>REDE</div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr 1fr", gap:10, marginBottom:14 }}>
          <div style={{ gridColumn:"1/3" }}><label style={labelStyle}>Endereco IP</label><input value={data.ip} onChange={e=>onChange("ip",e.target.value)} placeholder="192.168.1.160" style={inputStyle} /></div>
          <div></div>
          <div><label style={labelStyle}>Porta Servico</label><input type="number" value={data.port_service} onChange={e=>onChange("port_service",+e.target.value)} style={inputStyle} /></div>
          <div><label style={labelStyle}>Porta Web</label><input type="number" value={data.port_web} onChange={e=>onChange("port_web",+e.target.value)} style={inputStyle} /></div>
          <div><label style={labelStyle}>Porta RTSP</label><input type="number" value={data.port_rtsp} onChange={e=>onChange("port_rtsp",+e.target.value)} style={inputStyle} /></div>
        </div>

        <div style={{ fontSize:11, color:"#00bfff", marginBottom:8, fontWeight:600 }}>AUTENTICACAO</div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:14 }}>
          <div><label style={labelStyle}>Usuario</label><input value={data.cam_user} onChange={e=>onChange("cam_user",e.target.value)} placeholder="admin" style={inputStyle} /></div>
          <div><label style={labelStyle}>Senha</label><input type="password" value={data.cam_password} onChange={e=>onChange("cam_password",e.target.value)} placeholder="••••••••" style={inputStyle} /></div>
        </div>

        <div style={{ fontSize:11, color:"#00bfff", marginBottom:8, fontWeight:600 }}>CONFIGURACAO</div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:16 }}>
          <div>
            <label style={labelStyle}>Direcao</label>
            <select value={data.direction} onChange={e=>onChange("direction",e.target.value)} style={inputStyle}>
              <option value="entry">Entrada</option>
              <option value="exit">Saida</option>
              <option value="both">Entrada e Saida</option>
            </select>
          </div>
          <div>
            <label style={labelStyle}>Tipo de Acesso</label>
            <select value={data.access_type} onChange={e=>onChange("access_type",e.target.value)} style={inputStyle}>
              <option value="stop_go">Stop and Go</option>
              <option value="free_flow">Fluxo Livre</option>
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

export default function CamerasPage() {
  const [cameras, setCameras] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editModal, setEditModal] = useState(false);
  const [webhookModal, setWebhookModal] = useState<any>(null);
  const [nova, setNova] = useState({...VAZIO});
  const [editData, setEditData] = useState<any>(null);
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

  const handleNovaChange = useCallback((field: string, value: any) => {
    setNova(p => ({ ...p, [field]: value }));
  }, []);

  const handleEditChange = useCallback((field: string, value: any) => {
    setEditData((p: any) => ({ ...p, [field]: value }));
  }, []);

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
      await api.put(`/api/v1/cameras/${editData.id}`, editData);
      setEditModal(false);
      setEditData(null);
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
          Nenhuma camera cadastrada. Clique em + NOVA CAMERA.
        </div>
      )}

      <div style={{ display:"grid", gridTemplateColumns:"repeat(2,1fr)", gap:12 }}>
        {cameras.map(cam => (
          <div key={cam.id} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ height:80, background:cam.is_online?"linear-gradient(135deg,#0a1a2a,#0d2035)":"linear-gradient(135deg,#111,#0a0a0a)", display:"flex", alignItems:"center", justifyContent:"center", position:"relative" }}>
              <span style={{ fontSize:11, color:cam.is_online?"rgba(0,180,255,0.5)":"rgba(255,255,255,0.1)", fontFamily:"'Orbitron',monospace", letterSpacing:2 }}>{cam.is_online?"[ONLINE]":"[OFFLINE]"}</span>
              <span style={{ position:"absolute", top:8, right:8, fontSize:9, padding:"2px 7px", borderRadius:4, background:cam.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:cam.is_online?"#00e676":"#ff4444", border:`1px solid ${cam.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace" }}>{cam.is_online?"ONLINE":"OFFLINE"}</span>
            </div>
            <div style={{ padding:"10px 14px" }}>
              <div style={{ fontSize:14, fontWeight:600, color:"#c8e0f0", marginBottom:4 }}>{cam.name}</div>
              <div style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace", lineHeight:1.7, marginBottom:8 }}>
                SN: {cam.serial}{cam.model ? ` | ${cam.model}` : ""}<br/>
                {cam.ip ? `IP: ${cam.ip} | Web: ${cam.port_web} | RTSP: ${cam.port_rtsp}` : "IP nao configurado"}<br/>
                {cam.location && `Local: ${cam.location}`}
              </div>
              <div style={{ display:"flex", gap:6 }}>
                <button onClick={()=>verWebhook(cam)} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(0,160,255,0.3)", borderRadius:4, background:"rgba(0,100,200,0.1)", color:"#7ec8ff", fontSize:11, cursor:"pointer", fontWeight:600 }}>Webhook</button>
                <button onClick={()=>{ setEditData({...cam}); setEditModal(true); }} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(255,165,0,0.3)", borderRadius:4, background:"rgba(255,165,0,0.1)", color:"#ffaa44", fontSize:11, cursor:"pointer", fontWeight:600 }}>Editar</button>
                <button onClick={()=>remover(cam.id)} style={{ padding:"6px 12px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>X</button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {modal && <CameraForm data={nova} onChange={handleNovaChange} onSave={salvar} onCancel={()=>setModal(false)} title="NOVA CAMERA" />}
      {editModal && editData && <CameraForm data={editData} onChange={handleEditChange} onSave={atualizar} onCancel={()=>{ setEditModal(false); setEditData(null); }} title={`EDITAR - ${editData.name}`} />}

      {webhookModal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:24, width:520 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16 }}>INTEGRACAO - {webhookModal.camera}</div>
            {[
              { label:"URL Webhook", value:`${API_URL}${webhookModal.webhook_url}`, cor:"#00bfff" },
              { label:"Topico MQTT", value:webhookModal.mqtt_topic, cor:"#00e676" },
              { label:"Interface Web da Camera", value:webhookModal.web_url, cor:"#ffaa44" },
              { label:"Stream RTSP", value:webhookModal.rtsp_url, cor:"#aa88ff" },
            ].map((item,i) => (
              <div key={i} style={{ marginBottom:10 }}>
                <div style={{ fontSize:10, color:"#5a7a9a", textTransform:"uppercase", letterSpacing:1, marginBottom:3 }}>{item.label}</div>
                <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(255,255,255,0.05)", borderRadius:6, padding:"8px 10px", fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:item.cor, wordBreak:"break-all" }}>{item.value}</div>
              </div>
            ))}
            <button onClick={()=>setWebhookModal(null)} style={{ width:"100%", marginTop:8, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Fechar</button>
          </div>
        </div>
      )}
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Bug corrigido!" -ForegroundColor Green
Write-Host ""
Write-Host "Execute:" -ForegroundColor Yellow
Write-Host "  npm run build" -ForegroundColor White
Write-Host "  scp -r out\* root@187.77.231.19:/var/www/fortcam/" -ForegroundColor White
