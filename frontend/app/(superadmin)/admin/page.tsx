"use client";
import { useState, useEffect } from "react";
import api from "@/lib/api";

interface Tenant {
  id: number; name: string; slug: string; plan: string;
  max_cameras: number; max_users: number; is_active: boolean; created_at: string;
}

const PLANOS = ["basic", "pro", "enterprise"];
const COR_PLANO: Record<string,string> = { basic:"#5a7a9a", pro:"#00bfff", enterprise:"#ff6600" };

export default function AdminPage() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [msg, setMsg] = useState(""); const [msgCor, setMsgCor] = useState("#00e676");
  const [novo, setNovo] = useState({ name:"", slug:"", plan:"basic", max_cameras:5, max_users:3, admin_name:"", admin_email:"", admin_password:"" });

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try { const r = await api.get("/api/v1/tenants/"); setTenants(r.data); }
    catch { mostrarMsg("Erro ao carregar", "#ff4444"); } finally { setLoading(false); }
  }

  function mostrarMsg(texto: string, cor = "#00e676") {
    setMsg(texto); setMsgCor(cor);
    setTimeout(() => setMsg(""), 4000);
  }

  async function criarTenant() {
    if (!novo.name || !novo.slug || !novo.admin_email || !novo.admin_password) { mostrarMsg("Preencha todos os campos", "#ff4444"); return; }
    try {
      await api.post("/api/v1/tenants/", novo);
      setModal(false);
      setNovo({ name:"", slug:"", plan:"basic", max_cameras:5, max_users:3, admin_name:"", admin_email:"", admin_password:"" });
      carregar(); mostrarMsg("Cliente criado!");
    } catch (err: any) { mostrarMsg(err.response?.data?.detail || "Erro", "#ff4444"); }
  }

  async function toggleTenant(id: number) {
    try { const r = await api.put(`/api/v1/tenants/${id}/toggle`); carregar(); mostrarMsg(r.data.is_active ? "Ativado!" : "Desativado!"); }
    catch { mostrarMsg("Erro", "#ff4444"); }
  }

  const totalAtivos = tenants.filter(t => t.is_active).length;

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <style>{`
        @media (max-width: 600px) {
          .admin-cards { grid-template-columns: repeat(2,1fr) !important; }
          .admin-table-header { display: none !important; }
          .admin-row-desktop { display: none !important; }
          .admin-row-mobile { display: flex !important; }
          .admin-modal-inner { width: calc(100vw - 32px) !important; padding: 20px !important; }
          .admin-header { flex-direction: column !important; align-items: flex-start !important; gap: 10px !important; }
          .admin-btn-new { width: 100% !important; }
        }
        .admin-row-mobile { display: none; }
      `}</style>

      {/* Cards */}
      <div className="admin-cards" style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:10 }}>
        {[
          { label:"Total", valor:tenants.length, cor:"#ff6600" },
          { label:"Ativos", valor:totalAtivos, cor:"#00e676" },
          { label:"Inativos", valor:tenants.length-totalAtivos, cor:"#ff4444" },
          { label:"Pro/Ent", valor:tenants.filter(t=>t.plan!=="basic").length, cor:"#00bfff" },
        ].map((c,i) => (
          <div key={i} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(255,100,0,0.15)", borderRadius:10, padding:"12px 14px", position:"relative", overflow:"hidden" }}>
            <div style={{ position:"absolute", top:0, left:0, right:0, height:2, background:`linear-gradient(90deg,transparent,${c.cor},transparent)` }} />
            <div style={{ fontSize:10, color:"#5a7a9a", marginBottom:4 }}>{c.label}</div>
            <div style={{ fontSize:24, fontWeight:700, fontFamily:"'Orbitron',monospace", color:c.cor }}>{c.valor}</div>
          </div>
        ))}
      </div>

      {msg && <div style={{ background:msgCor==="#ff4444"?"rgba(255,68,68,0.1)":"rgba(0,230,118,0.1)", border:`1px solid ${msgCor}44`, borderRadius:8, padding:"10px 14px", color:msgCor, fontSize:12 }}>{msg}</div>}

      {/* Tabela clientes */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(255,100,0,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div className="admin-header" style={{ padding:"12px 16px", borderBottom:"1px solid rgba(255,100,0,0.1)", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
          <span style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#ff9944", letterSpacing:1 }}>CLIENTES</span>
          <button className="admin-btn-new" onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#cc4400,#aa2200)", color:"#fff", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>+ NOVO CLIENTE</button>
        </div>

        {/* Desktop header */}
        <div className="admin-table-header" style={{ display:"grid", gridTemplateColumns:"1fr 110px 90px 70px 90px 100px", padding:"8px 16px", borderBottom:"1px solid rgba(255,255,255,0.04)", fontSize:10, color:"#4a6a8a", textTransform:"uppercase" }}>
          <span>Nome</span><span>Plano</span><span>Cameras</span><span>Users</span><span>Status</span><span>Acao</span>
        </div>

        {loading && <div style={{ padding:32, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loading && tenants.length === 0 && <div style={{ padding:32, textAlign:"center", color:"#4a6a8a" }}>Nenhum cliente.</div>}

        {tenants.map(t => (
          <div key={t.id}>
            {/* Desktop */}
            <div className="admin-row-desktop" style={{ display:"grid", gridTemplateColumns:"1fr 110px 90px 70px 90px 100px", padding:"12px 16px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
              <div>
                <div style={{ fontSize:13, fontWeight:600, color:"#c8e0f0" }}>{t.name}</div>
                <div style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>{t.slug}</div>
              </div>
              <span style={{ fontWeight:700, color:COR_PLANO[t.plan]||"#5a7a9a", background:`${COR_PLANO[t.plan]}15`, padding:"3px 8px", borderRadius:4, border:`1px solid ${COR_PLANO[t.plan]}33`, textTransform:"uppercase", fontFamily:"'Orbitron',monospace", fontSize:9 }}>{t.plan}</span>
              <span style={{ fontSize:12, color:"#8ab0cc" }}>max {t.max_cameras}</span>
              <span style={{ fontSize:12, color:"#8ab0cc" }}>max {t.max_users}</span>
              <span style={{ fontSize:10, padding:"3px 8px", borderRadius:4, background:t.is_active?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:t.is_active?"#00e676":"#ff4444", border:`1px solid ${t.is_active?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace", display:"inline-block" }}>{t.is_active?"ATIVO":"INATIVO"}</span>
              <button onClick={()=>toggleTenant(t.id)} style={{ padding:"5px 10px", border:`1px solid ${t.is_active?"rgba(255,68,68,0.3)":"rgba(0,230,118,0.3)"}`, borderRadius:4, background:t.is_active?"rgba(255,68,68,0.1)":"rgba(0,230,118,0.1)", color:t.is_active?"#ff6666":"#00e676", cursor:"pointer", fontSize:11, fontWeight:600 }}>
                {t.is_active?"Desativar":"Ativar"}
              </button>
            </div>

            {/* Mobile card */}
            <div className="admin-row-mobile" style={{ flexDirection:"column", padding:"12px 16px", borderBottom:"1px solid rgba(255,255,255,0.04)", gap:8 }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start" }}>
                <div>
                  <div style={{ fontSize:14, fontWeight:600, color:"#c8e0f0" }}>{t.name}</div>
                  <div style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>{t.slug}</div>
                </div>
                <span style={{ fontSize:10, padding:"3px 8px", borderRadius:4, background:t.is_active?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:t.is_active?"#00e676":"#ff4444", border:`1px solid ${t.is_active?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace" }}>{t.is_active?"ATIVO":"INATIVO"}</span>
              </div>
              <div style={{ display:"flex", gap:12, alignItems:"center" }}>
                <span style={{ fontWeight:700, color:COR_PLANO[t.plan]||"#5a7a9a", fontSize:11, textTransform:"uppercase", fontFamily:"'Orbitron',monospace" }}>{t.plan}</span>
                <span style={{ fontSize:11, color:"#5a7a9a" }}>📷 max {t.max_cameras}</span>
                <span style={{ fontSize:11, color:"#5a7a9a" }}>👤 max {t.max_users}</span>
              </div>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
                <span style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>{new Date(t.created_at).toLocaleDateString("pt-BR")}</span>
                <button onClick={()=>toggleTenant(t.id)} style={{ padding:"6px 14px", border:`1px solid ${t.is_active?"rgba(255,68,68,0.3)":"rgba(0,230,118,0.3)"}`, borderRadius:4, background:t.is_active?"rgba(255,68,68,0.1)":"rgba(0,230,118,0.1)", color:t.is_active?"#ff6666":"#00e676", cursor:"pointer", fontSize:12, fontWeight:600 }}>
                  {t.is_active?"Desativar":"Ativar"}
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Modal novo cliente */}
      {modal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100, padding:16, overflowY:"auto" }}>
          <div className="admin-modal-inner" style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(255,100,0,0.3)", borderRadius:12, padding:24, width:460, maxHeight:"90vh", overflowY:"auto" }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#ff9944", marginBottom:20 }}>NOVO CLIENTE</div>

            <div style={{ color:"#ff6600", marginBottom:12, fontWeight:600, fontSize:12 }}>DADOS DO CLIENTE</div>
            {[{l:"Nome da Empresa *",k:"name",p:"Ex: Condominio Solar"},{l:"Slug *",k:"slug",p:"Ex: cond-solar"}].map(c => (
              <div key={c.k} style={{ marginBottom:12 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>{c.l}</label>
                <input value={(novo as any)[c.k]} onChange={e=>setNovo(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"10px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:14, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr 1fr", gap:10, marginBottom:12 }}>
              <div>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>Plano</label>
                <select value={novo.plan} onChange={e=>setNovo(p=>({...p,plan:e.target.value}))}
                  style={{ width:"100%", padding:"10px 8px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none" }}>
                  {PLANOS.map(pl => <option key={pl} value={pl}>{pl.toUpperCase()}</option>)}
                </select>
              </div>
              <div>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>Max Cam</label>
                <input type="number" value={novo.max_cameras} onChange={e=>setNovo(p=>({...p,max_cameras:+e.target.value}))}
                  style={{ width:"100%", padding:"10px 8px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
              <div>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>Max Users</label>
                <input type="number" value={novo.max_users} onChange={e=>setNovo(p=>({...p,max_users:+e.target.value}))}
                  style={{ width:"100%", padding:"10px 8px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            </div>

            <div style={{ color:"#ff6600", marginBottom:12, fontWeight:600, fontSize:12, paddingTop:8, borderTop:"1px solid rgba(255,100,0,0.1)" }}>ADMIN DO CLIENTE</div>
            {[{l:"Nome *",k:"admin_name",p:"Nome completo"},{l:"Email *",k:"admin_email",p:"admin@empresa.com"},{l:"Senha *",k:"admin_password",p:"Senha inicial"}].map(c => (
              <div key={c.k} style={{ marginBottom:12 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>{c.l}</label>
                <input type={c.k.includes("password")?"password":"text"} value={(novo as any)[c.k]} onChange={e=>setNovo(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"10px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:14, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ display:"flex", gap:8, marginTop:8 }}>
              <button onClick={()=>setModal(false)} style={{ flex:1, padding:12, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={criarTenant} style={{ flex:2, padding:12, border:"none", borderRadius:6, background:"linear-gradient(135deg,#cc4400,#aa2200)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:12 }}>CRIAR CLIENTE</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
