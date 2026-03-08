"use client";
import { useState, useEffect, useCallback } from "react";
import api from "@/lib/api";

const VAZIO = { name:"", location:"", gate_type:"cancela", mode:"auto", open_time:5, camera_id:null as any };
const inputStyle: React.CSSProperties = { width:"100%", padding:"10px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" };
const labelStyle: React.CSSProperties = { fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 };

function GateForm({ data, cameras, onChange, onSave, onCancel, title }: any) {
  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.85)", display:"flex", alignItems:"flex-start", justifyContent:"center", zIndex:100, padding:16, overflowY:"auto" }}>
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:20, width:"100%", maxWidth:460, marginTop:8 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16, paddingBottom:10, borderBottom:"1px solid rgba(0,160,255,0.1)" }}>{title}</div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10, marginBottom:12 }}>
          <div><label style={labelStyle}>Nome *</label><input value={data.name} onChange={e=>onChange("name",e.target.value)} placeholder="Portao Principal" style={inputStyle} /></div>
          <div><label style={labelStyle}>Localizacao</label><input value={data.location} onChange={e=>onChange("location",e.target.value)} placeholder="Entrada" style={inputStyle} /></div>
          <div>
            <label style={labelStyle}>Tipo</label>
            <select value={data.gate_type} onChange={e=>onChange("gate_type",e.target.value)} style={inputStyle}>
              <option value="cancela">Cancela</option><option value="portao">Portao</option><option value="porta">Porta</option>
            </select>
          </div>
          <div>
            <label style={labelStyle}>Modo</label>
            <select value={data.mode} onChange={e=>onChange("mode",e.target.value)} style={inputStyle}>
              <option value="auto">Automatico</option><option value="manual">Manual</option>
            </select>
          </div>
          <div>
            <label style={labelStyle}>Tempo (seg)</label>
            <input type="number" value={data.open_time} onChange={e=>onChange("open_time",+e.target.value)} style={inputStyle} min={1} max={60} />
          </div>
          <div>
            <label style={labelStyle}>Camera</label>
            <select value={data.camera_id || ""} onChange={e=>onChange("camera_id", e.target.value ? +e.target.value : null)} style={inputStyle}>
              <option value="">Nenhuma</option>
              {cameras.map((c:any) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </div>
        </div>
        <div style={{ background:"rgba(0,100,200,0.08)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:6, padding:"10px 12px", marginBottom:14, fontSize:11, color:"#5a8aaa" }}>
          Topico MQTT gerado automaticamente. O controlador fisico deve assinar este topico.
        </div>
        <div style={{ display:"flex", gap:8 }}>
          <button onClick={onCancel} style={{ flex:1, padding:12, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
          <button onClick={onSave} style={{ flex:2, padding:12, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR PORTAO</button>
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
      const [g, c] = await Promise.all([api.get("/api/v1/gate/"), api.get("/api/v1/cameras/")]);
      setGates(g.data); setCameras(c.data);
    } finally { setLoading(false); }
  }

  function mostrarMsg(texto: string, cor = "#00e676") { setMsg({ texto, cor }); setTimeout(() => setMsg({ texto:"", cor:"#00e676" }), 4000); }
  const handleNovaChange = useCallback((f: string, v: any) => setNova(p=>({...p,[f]:v})), []);
  const handleEditChange = useCallback((f: string, v: any) => setEditData((p:any)=>({...p,[f]:v})), []);

  async function salvar() {
    if (!nova.name) { mostrarMsg("Nome obrigatorio", "#ff4444"); return; }
    try { await api.post("/api/v1/gate/", nova); setNova({...VAZIO}); setModal(false); carregar(); mostrarMsg("Portao cadastrado!"); }
    catch (err: any) { mostrarMsg(err.response?.data?.detail || "Erro", "#ff4444"); }
  }
  async function atualizar() {
    try { await api.put(`/api/v1/gate/${editData.id}`, editData); setEditModal(false); carregar(); mostrarMsg("Portao atualizado!"); }
    catch (err: any) { mostrarMsg(err.response?.data?.detail || "Erro", "#ff4444"); }
  }
  async function abrir(gate: any) {
    setAbrindo(gate.id);
    try { await api.post(`/api/v1/gate/${gate.id}/open`); mostrarMsg(`ABRIR enviado para ${gate.name}!`); carregar(); }
    catch { mostrarMsg("Erro ao enviar comando", "#ff4444"); }
    finally { setAbrindo(null); }
  }
  async function fechar(gate: any) {
    try { await api.post(`/api/v1/gate/${gate.id}/close`); mostrarMsg(`FECHAR enviado para ${gate.name}`); }
    catch { mostrarMsg("Erro", "#ff4444"); }
  }
  async function remover(id: number) {
    if (!confirm("Remover?")) return;
    await api.delete(`/api/v1/gate/${id}`); carregar();
  }

  const camNome = (id: number) => cameras.find(c=>c.id===id)?.name || "Nenhuma";

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <style>{`
        @media (max-width: 600px) {
          .gate-header { flex-direction: column !important; gap: 10px !important; }
          .gate-btn-new { width: 100% !important; }
          .gate-grid { grid-template-columns: 1fr !important; }
        }
      `}</style>

      <div className="gate-header" style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>PORTOES / BARREIRAS</div>
        <button className="gate-btn-new" onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:11, fontWeight:700 }}>+ NOVO PORTAO</button>
      </div>

      {msg.texto && <div style={{ background:`${msg.cor}15`, border:`1px solid ${msg.cor}44`, borderRadius:8, padding:"10px 14px", color:msg.cor, fontSize:12 }}>{msg.texto}</div>}

      {loading && <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando...</div>}
      {!loading && gates.length === 0 && <div style={{ background:"rgba(0,0,0,0.2)", border:"1px solid rgba(0,160,255,0.1)", borderRadius:10, padding:32, textAlign:"center", color:"#4a6a8a" }}>Nenhum portao. Clique em + NOVO PORTAO.</div>}

      <div className="gate-grid" style={{ display:"grid", gridTemplateColumns:"repeat(2,1fr)", gap:12 }}>
        {gates.map(gate => (
          <div key={gate.id} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ padding:"12px 14px", borderBottom:"1px solid rgba(0,160,255,0.08)" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:6 }}>
                <span style={{ fontSize:14, fontWeight:600, color:"#c8e0f0" }}>{gate.name}</span>
                <span style={{ fontSize:9, padding:"2px 7px", borderRadius:4, background:gate.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:gate.is_online?"#00e676":"#ff4444", border:`1px solid ${gate.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace" }}>{gate.is_online?"ONLINE":"OFFLINE"}</span>
              </div>
              <div style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace", lineHeight:1.7 }}>
                {gate.location && `📍 ${gate.location} · `}{gate.gate_type} · {gate.open_time}s<br/>
                📷 {camNome(gate.camera_id)}<br/>
                {gate.last_trigger && `⏱ ${new Date(gate.last_trigger).toLocaleString("pt-BR")}`}
              </div>
            </div>

            {/* Botoes ABRIR / FECHAR */}
            <div style={{ padding:"10px 12px", background:"rgba(0,0,0,0.2)", display:"flex", gap:8 }}>
              <button onClick={()=>abrir(gate)} disabled={abrindo===gate.id} style={{ flex:1, padding:"12px 0", border:"none", borderRadius:6, background:abrindo===gate.id?"rgba(0,200,80,0.2)":"linear-gradient(135deg,#00aa44,#007733)", color:"#fff", fontSize:13, cursor:"pointer", fontWeight:700, fontFamily:"'Orbitron',monospace" }}>
                {abrindo===gate.id?"...":"▲ ABRIR"}
              </button>
              <button onClick={()=>fechar(gate)} style={{ flex:1, padding:"12px 0", border:"1px solid rgba(255,120,0,0.4)", borderRadius:6, background:"rgba(255,120,0,0.1)", color:"#ff9944", fontSize:13, cursor:"pointer", fontWeight:700, fontFamily:"'Orbitron',monospace" }}>▼ FECHAR</button>
            </div>

            <div style={{ padding:"8px 12px 10px", display:"flex", gap:6 }}>
              <button onClick={()=>setMqttModal(gate)} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(0,160,255,0.3)", borderRadius:4, background:"rgba(0,100,200,0.1)", color:"#7ec8ff", fontSize:11, cursor:"pointer" }}>MQTT</button>
              <button onClick={()=>{ setEditData({...gate}); setEditModal(true); }} style={{ flex:1, padding:"6px 0", border:"1px solid rgba(255,165,0,0.3)", borderRadius:4, background:"rgba(255,165,0,0.1)", color:"#ffaa44", fontSize:11, cursor:"pointer" }}>Editar</button>
              <button onClick={()=>remover(gate.id)} style={{ padding:"6px 12px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>✕</button>
            </div>
          </div>
        ))}
      </div>

      {modal && <GateForm data={nova} cameras={cameras} onChange={handleNovaChange} onSave={salvar} onCancel={()=>setModal(false)} title="NOVO PORTAO" />}
      {editModal && editData && <GateForm data={editData} cameras={cameras} onChange={handleEditChange} onSave={atualizar} onCancel={()=>{ setEditModal(false); setEditData(null); }} title={`EDITAR - ${editData.name}`} />}

      {mqttModal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.85)", display:"flex", alignItems:"flex-start", justifyContent:"center", zIndex:100, padding:16, overflowY:"auto" }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:20, width:"100%", maxWidth:460, marginTop:8 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:14 }}>CONFIG MQTT — {mqttModal.name}</div>
            <div style={{ marginBottom:10 }}>
              <div style={{ fontSize:10, color:"#5a7a9a", textTransform:"uppercase", letterSpacing:1, marginBottom:4 }}>Topico (controlador assina)</div>
              <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(0,230,118,0.2)", borderRadius:6, padding:"10px 12px", fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#00e676", wordBreak:"break-all" }}>{mqttModal.mqtt_topic}</div>
            </div>
            <div style={{ marginBottom:10 }}>
              <div style={{ fontSize:10, color:"#5a7a9a", textTransform:"uppercase", letterSpacing:1, marginBottom:4 }}>Broker</div>
              <div style={{ background:"rgba(0,0,0,0.4)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, padding:"10px 12px", fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#00bfff" }}>fortcam.com.br:8883 (TLS) / :1883 (local)</div>
            </div>
            <div style={{ background:"rgba(0,80,40,0.1)", border:"1px solid rgba(0,160,100,0.2)", borderRadius:6, padding:"10px 12px", marginBottom:14, fontSize:11, color:"#5a9a7a", lineHeight:1.7 }}>
              <strong style={{ color:"#00e676" }}>ESP32/Arduino:</strong><br/>
              1. Broker: <strong>fortcam.com.br:8883</strong><br/>
              2. Assinar topico acima<br/>
              3. Receber <strong>"action": "open"</strong> → acionar rele por <strong>{mqttModal.open_time}s</strong>
            </div>
            <div style={{ background:"rgba(0,0,0,0.3)", borderRadius:6, padding:"8px 10px", marginBottom:12, fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>
              Payload: {"{"}"action":"open","open_time":{mqttModal.open_time}{"}"}
            </div>
            <button onClick={()=>setMqttModal(null)} style={{ width:"100%", padding:12, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Fechar</button>
          </div>
        </div>
      )}
    </div>
  );
}
