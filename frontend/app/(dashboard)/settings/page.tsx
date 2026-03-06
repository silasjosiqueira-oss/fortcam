"use client";
import { useState, useEffect } from "react";
import { camerasAPI } from "@/lib/api";
import api from "@/lib/api";

export default function ConfiguracoesPage() {
  const [cameras, setCameras] = useState<any[]>([]);
  const [modalCam, setModalCam] = useState(false);
  const [modalUser, setModalUser] = useState(false);
  const [loadingCam, setLoadingCam] = useState(true);
  const [novaCam, setNovaCam] = useState({ name:"", serial:"", ip:"", location:"" });
  const [novoUser, setNovoUser] = useState({ name:"", email:"", password:"", role:"operator" });
  const [msg, setMsg] = useState("");
  const [msgCor, setMsgCor] = useState("#00e676");

  useEffect(() => { carregarCameras(); }, []);

  async function carregarCameras() {
    try { const r = await camerasAPI.list(); setCameras(r.data); } finally { setLoadingCam(false); }
  }

  function mostrarMsg(texto: string, cor = "#00e676") {
    setMsg(texto); setMsgCor(cor);
    setTimeout(() => setMsg(""), 3000);
  }

  async function adicionarCamera() {
    if (!novaCam.name || !novaCam.serial) return;
    try {
      await api.post("/api/v1/cameras/", novaCam);
      setNovaCam({ name:"", serial:"", ip:"", location:"" });
      setModalCam(false);
      carregarCameras();
      mostrarMsg("Camera adicionada com sucesso!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao adicionar camera", "#ff4444");
    }
  }

  async function removerCamera(id: number) {
    if (!confirm("Remover esta camera?")) return;
    try {
      await api.delete(`/api/v1/cameras/${id}`);
      carregarCameras();
      mostrarMsg("Camera removida!");
    } catch { mostrarMsg("Erro ao remover", "#ff4444"); }
  }

  async function criarUsuario() {
    if (!novoUser.name || !novoUser.email || !novoUser.password) return;
    try {
      await api.post("/api/v1/auth/users", novoUser);
      setNovoUser({ name:"", email:"", password:"", role:"operator" });
      setModalUser(false);
      mostrarMsg("Usuario criado com sucesso!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao criar usuario", "#ff4444");
    }
  }

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>CONFIGURACOES</div>

      {msg && <div style={{ background:msgCor==="red"?"rgba(255,68,68,0.1)":"rgba(0,230,118,0.1)", border:`1px solid ${msgCor}44`, borderRadius:8, padding:"10px 14px", color:msgCor, fontSize:12 }}>{msg}</div>}

      {/* Cameras */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ padding:"10px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
          <span style={{ fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Gerenciar Cameras</span>
          <button onClick={()=>setModalCam(true)} style={{ padding:"6px 14px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:10, fontWeight:700 }}>+ NOVA CAMERA</button>
        </div>
        {loadingCam && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loadingCam && cameras.length === 0 && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a", fontSize:12 }}>Nenhuma camera cadastrada.</div>}
        {cameras.map(cam => (
          <div key={cam.id} style={{ display:"grid", gridTemplateColumns:"1fr 1fr 120px 80px", padding:"10px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
            <span style={{ fontSize:13, color:"#c8e0f0", fontWeight:600 }}>{cam.name}</span>
            <span style={{ fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace" }}>SN: {cam.serial} | IP: {cam.ip||"---"}</span>
            <span style={{ fontSize:10, padding:"2px 8px", borderRadius:4, background:cam.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:cam.is_online?"#00e676":"#ff4444", border:`1px solid ${cam.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace", display:"inline-block" }}>{cam.is_online?"ONLINE":"OFFLINE"}</span>
            <button onClick={()=>removerCamera(cam.id)} style={{ padding:"4px 10px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>Remover</button>
          </div>
        ))}
      </div>

      {/* Usuarios */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:12 }}>
          <span style={{ fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Gerenciar Usuarios</span>
          <button onClick={()=>setModalUser(true)} style={{ padding:"6px 14px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:10, fontWeight:700 }}>+ NOVO USUARIO</button>
        </div>
        <div style={{ fontSize:11, color:"#4a6a8a" }}>Gerencie os usuarios que tem acesso ao sistema. Apenas administradores podem criar novos usuarios.</div>
      </div>

      {/* Info sistema */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
        <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:12 }}>Informacoes do Sistema</div>
        {[
          { label:"Versao da API", valor:"1.0.0" },
          { label:"Banco de dados", valor:"SQLite (desenvolvimento)" },
          { label:"MQTT Broker", valor:"localhost:1883" },
          { label:"Documentacao API", valor:"/docs (porta 8000)" },
        ].map((item,i) => (
          <div key={i} style={{ display:"flex", justifyContent:"space-between", padding:"6px 0", borderBottom:"1px solid rgba(255,255,255,0.04)" }}>
            <span style={{ fontSize:12, color:"#5a7a9a" }}>{item.label}</span>
            <span style={{ fontSize:12, color:"#7ec8ff", fontFamily:"'Share Tech Mono',monospace" }}>{item.valor}</span>
          </div>
        ))}
      </div>

      {/* Modal Camera */}
      {modalCam && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.7)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:400 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>NOVA CAMERA</div>
            {[{l:"Nome",k:"name",p:"Entrada 01"},{l:"Serial",k:"serial",p:"FC-2024-001"},{l:"IP",k:"ip",p:"192.168.1.101"},{l:"Localizacao",k:"location",p:"Portao principal"}].map(c=>(
              <div key={c.k} style={{ marginBottom:14 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>{c.l}</label>
                <input value={(novaCam as any)[c.k]} onChange={e=>setNovaCam(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>setModalCam(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={adicionarCamera} style={{ flex:1, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Usuario */}
      {modalUser && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.7)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:400 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>NOVO USUARIO</div>
            {[{l:"Nome",k:"name",p:"Nome completo"},{l:"Email",k:"email",p:"usuario@email.com"},{l:"Senha",k:"password",p:"senha123"}].map(c=>(
              <div key={c.k} style={{ marginBottom:14 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>{c.l}</label>
                <input type={c.k==="password"?"password":"text"} value={(novoUser as any)[c.k]} onChange={e=>setNovoUser(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ marginBottom:14 }}>
              <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>Perfil</label>
              <select value={novoUser.role} onChange={e=>setNovoUser(p=>({...p,role:e.target.value}))}
                style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none" }}>
                <option value="operator">Operador</option>
                <option value="admin">Administrador</option>
              </select>
            </div>
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>setModalUser(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={criarUsuario} style={{ flex:1, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>CRIAR</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}