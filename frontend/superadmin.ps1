# Tela de Superadmin - Gerenciar clientes
$base = "C:\Users\Camera 3\fortcam-cloud\frontend"

Write-Host "Criando painel superadmin..." -ForegroundColor Cyan

# Criar pasta superadmin
New-Item -ItemType Directory -Force -Path "$base\app\(superadmin)" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\app\(superadmin)\admin" | Out-Null

# ============================================================
# LAYOUT SUPERADMIN
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(superadmin)\layout.tsx", @'
"use client";
import { useRouter, usePathname } from "next/navigation";
import { useEffect } from "react";
import { useAuthStore } from "@/store/auth";

const navItems = [
  { label: "Clientes", path: "/admin" },
  { label: "Monitoramento", path: "/admin/monitor" },
];

export default function SuperAdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { user, token, logout, loadUser } = useAuthStore();

  useEffect(() => {
    if (!token) { router.push("/login"); return; }
    if (!user) loadUser().then(u => {
      if (u?.role !== "superadmin") router.push("/dashboard");
    });
    else if (user.role !== "superadmin") router.push("/dashboard");
  }, [token, user]);

  return (
    <div style={{ display:"flex", height:"100vh", fontFamily:"'Rajdhani',sans-serif", background:"#080d14", color:"#e0e8f0" }}>
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Rajdhani:wght@400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet" />

      <div style={{ width:200, background:"linear-gradient(180deg,#0a0f1a,#080d14)", borderRight:"1px solid rgba(255,100,0,0.2)", display:"flex", flexDirection:"column" }}>
        <div style={{ padding:"20px 16px", borderBottom:"1px solid rgba(255,100,0,0.1)" }}>
          <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, fontWeight:900, color:"#ff6600", letterSpacing:2 }}>FORTCAM</div>
          <div style={{ fontSize:9, color:"#aa4400", letterSpacing:3, fontFamily:"'Share Tech Mono',monospace" }}>SUPERADMIN</div>
        </div>
        <nav style={{ flex:1, padding:"12px 0" }}>
          {navItems.map(item => {
            const active = pathname === item.path;
            return (
              <div key={item.path} onClick={()=>router.push(item.path)}
                style={{ padding:"10px 16px", margin:"2px 8px", borderRadius:6, background:active?"rgba(255,100,0,0.15)":"transparent", borderLeft:active?"2px solid #ff6600":"2px solid transparent", color:active?"#ff9944":"#5a7a9a", fontSize:13, fontWeight:active?600:400, cursor:"pointer" }}>
                {item.label}
              </div>
            );
          })}
        </nav>
        <div style={{ padding:"12px 16px", borderTop:"1px solid rgba(255,100,0,0.1)" }}>
          <div style={{ fontSize:11, color:"#5a7a9a", marginBottom:6 }}>{user?.name}</div>
          <div onClick={logout} style={{ fontSize:11, color:"#ff4444", cursor:"pointer", fontWeight:600 }}>Sair</div>
        </div>
      </div>

      <div style={{ flex:1, display:"flex", flexDirection:"column", overflow:"hidden" }}>
        <div style={{ height:52, background:"rgba(8,13,20,0.95)", borderBottom:"1px solid rgba(255,100,0,0.1)", display:"flex", alignItems:"center", padding:"0 20px", gap:12 }}>
          <div style={{ fontFamily:"'Orbitron',monospace", fontSize:11, color:"#aa4400", letterSpacing:2 }}>PAINEL SUPERADMIN</div>
          <div style={{ fontSize:10, background:"rgba(255,100,0,0.1)", border:"1px solid rgba(255,100,0,0.3)", borderRadius:4, padding:"2px 8px", color:"#ff6600", fontFamily:"'Orbitron',monospace" }}>ACESSO TOTAL</div>
        </div>
        <div style={{ flex:1, overflowY:"auto" }}>{children}</div>
      </div>
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# PAGINA CLIENTES
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(superadmin)\admin\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import api from "@/lib/api";

interface Tenant {
  id: number;
  name: string;
  slug: string;
  plan: string;
  max_cameras: number;
  max_users: number;
  is_active: boolean;
  created_at: string;
}

const PLANOS = ["basic", "pro", "enterprise"];
const COR_PLANO: Record<string,string> = { basic:"#5a7a9a", pro:"#00bfff", enterprise:"#ff6600" };

export default function AdminPage() {
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [msg, setMsg] = useState("");
  const [msgCor, setMsgCor] = useState("#00e676");
  const [novo, setNovo] = useState({
    name: "", slug: "", plan: "basic",
    max_cameras: 5, max_users: 3,
    admin_name: "", admin_email: "", admin_password: ""
  });

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const r = await api.get("/api/v1/tenants/");
      setTenants(r.data);
    } catch { mostrarMsg("Erro ao carregar clientes", "#ff4444"); }
    finally { setLoading(false); }
  }

  function mostrarMsg(texto: string, cor = "#00e676") {
    setMsg(texto); setMsgCor(cor);
    setTimeout(() => setMsg(""), 4000);
  }

  async function criarTenant() {
    if (!novo.name || !novo.slug || !novo.admin_email || !novo.admin_password) {
      mostrarMsg("Preencha todos os campos obrigatorios", "#ff4444");
      return;
    }
    try {
      await api.post("/api/v1/tenants/", novo);
      setModal(false);
      setNovo({ name:"", slug:"", plan:"basic", max_cameras:5, max_users:3, admin_name:"", admin_email:"", admin_password:"" });
      carregar();
      mostrarMsg("Cliente criado com sucesso!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao criar cliente", "#ff4444");
    }
  }

  async function toggleTenant(id: number) {
    try {
      const r = await api.put(`/api/v1/tenants/${id}/toggle`);
      carregar();
      mostrarMsg(r.data.is_active ? "Cliente ativado!" : "Cliente desativado!");
    } catch { mostrarMsg("Erro", "#ff4444"); }
  }

  const totalAtivos = tenants.filter(t => t.is_active).length;

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>

      {/* Cards resumo */}
      <div style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:12 }}>
        {[
          { label:"Total de Clientes", valor:tenants.length, cor:"#ff6600" },
          { label:"Clientes Ativos", valor:totalAtivos, cor:"#00e676" },
          { label:"Clientes Inativos", valor:tenants.length-totalAtivos, cor:"#ff4444" },
          { label:"Planos Pro/Enterprise", valor:tenants.filter(t=>t.plan!=="basic").length, cor:"#00bfff" },
        ].map((c,i) => (
          <div key={i} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(255,100,0,0.15)", borderRadius:10, padding:"14px 16px", position:"relative", overflow:"hidden" }}>
            <div style={{ position:"absolute", top:0, left:0, right:0, height:2, background:`linear-gradient(90deg,transparent,${c.cor},transparent)` }} />
            <div style={{ fontSize:11, color:"#5a7a9a", marginBottom:6 }}>{c.label}</div>
            <div style={{ fontSize:28, fontWeight:700, fontFamily:"'Orbitron',monospace", color:c.cor }}>{c.valor}</div>
          </div>
        ))}
      </div>

      {msg && (
        <div style={{ background:msgCor==="#ff4444"?"rgba(255,68,68,0.1)":"rgba(0,230,118,0.1)", border:`1px solid ${msgCor}44`, borderRadius:8, padding:"10px 14px", color:msgCor, fontSize:12 }}>{msg}</div>
      )}

      {/* Lista de clientes */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(255,100,0,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ padding:"12px 16px", borderBottom:"1px solid rgba(255,100,0,0.1)", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
          <span style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#ff9944", letterSpacing:1 }}>CLIENTES CADASTRADOS</span>
          <button onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#cc4400,#aa2200)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:11, fontWeight:700, letterSpacing:1 }}>+ NOVO CLIENTE</button>
        </div>

        <div style={{ display:"grid", gridTemplateColumns:"1fr 120px 100px 80px 80px 120px 100px", padding:"8px 16px", borderBottom:"1px solid rgba(255,255,255,0.04)", fontSize:10, color:"#4a6a8a", textTransform:"uppercase" }}>
          <span>Nome / Slug</span><span>Plano</span><span>Cameras</span><span>Users</span><span>Status</span><span>Criado em</span><span>Acoes</span>
        </div>

        {loading && <div style={{ padding:32, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loading && tenants.length === 0 && <div style={{ padding:32, textAlign:"center", color:"#4a6a8a" }}>Nenhum cliente cadastrado.</div>}

        {tenants.map(t => (
          <div key={t.id} style={{ display:"grid", gridTemplateColumns:"1fr 120px 100px 80px 80px 120px 100px", padding:"12px 16px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
            <div>
              <div style={{ fontSize:13, fontWeight:600, color:"#c8e0f0" }}>{t.name}</div>
              <div style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>{t.slug}</div>
            </div>
            <span style={{ fontSize:11, fontWeight:700, color:COR_PLANO[t.plan]||"#5a7a9a", background:`${COR_PLANO[t.plan]}15`, padding:"3px 10px", borderRadius:4, border:`1px solid ${COR_PLANO[t.plan]}33`, textTransform:"uppercase", fontFamily:"'Orbitron',monospace", fontSize:9 }}>{t.plan}</span>
            <span style={{ fontSize:12, color:"#8ab0cc" }}>max {t.max_cameras}</span>
            <span style={{ fontSize:12, color:"#8ab0cc" }}>max {t.max_users}</span>
            <span style={{ fontSize:10, padding:"3px 8px", borderRadius:4, background:t.is_active?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:t.is_active?"#00e676":"#ff4444", border:`1px solid ${t.is_active?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace", display:"inline-block" }}>{t.is_active?"ATIVO":"INATIVO"}</span>
            <span style={{ fontSize:10, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace" }}>{new Date(t.created_at).toLocaleDateString("pt-BR")}</span>
            <button onClick={()=>toggleTenant(t.id)} style={{ padding:"5px 12px", border:`1px solid ${t.is_active?"rgba(255,68,68,0.3)":"rgba(0,230,118,0.3)"}`, borderRadius:4, background:t.is_active?"rgba(255,68,68,0.1)":"rgba(0,230,118,0.1)", color:t.is_active?"#ff6666":"#00e676", fontSize:11, cursor:"pointer", fontWeight:600 }}>
              {t.is_active?"Desativar":"Ativar"}
            </button>
          </div>
        ))}
      </div>

      {/* Modal novo cliente */}
      {modal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.8)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(255,100,0,0.3)", borderRadius:12, padding:28, width:480, maxHeight:"90vh", overflowY:"auto" }}>
            <div style={{ position:"relative", marginBottom:20 }}>
              <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#ff9944", letterSpacing:1 }}>NOVO CLIENTE</div>
              <div style={{ position:"absolute", top:0, left:0, right:0, bottom:-10, borderBottom:"1px solid rgba(255,100,0,0.2)" }} />
            </div>

            <div style={{ fontSize:11, color:"#ff6600", marginBottom:16, fontWeight:600 }}>DADOS DO CLIENTE</div>
            {[
              {l:"Nome da Empresa *",k:"name",p:"Ex: Condominio Solar"},
              {l:"Slug (identificador unico) *",k:"slug",p:"Ex: cond-solar"},
            ].map(c => (
              <div key={c.k} style={{ marginBottom:12 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>{c.l}</label>
                <input value={(novo as any)[c.k]} onChange={e=>setNovo(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}

            <div style={{ marginBottom:12 }}>
              <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>Plano</label>
              <select value={novo.plan} onChange={e=>setNovo(p=>({...p,plan:e.target.value}))}
                style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none" }}>
                {PLANOS.map(pl => <option key={pl} value={pl}>{pl.toUpperCase()}</option>)}
              </select>
            </div>

            <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:12, marginBottom:16 }}>
              <div>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>Max Cameras</label>
                <input type="number" value={novo.max_cameras} onChange={e=>setNovo(p=>({...p,max_cameras:+e.target.value}))}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
              <div>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>Max Usuarios</label>
                <input type="number" value={novo.max_users} onChange={e=>setNovo(p=>({...p,max_users:+e.target.value}))}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            </div>

            <div style={{ fontSize:11, color:"#ff6600", marginBottom:12, fontWeight:600, paddingTop:8, borderTop:"1px solid rgba(255,100,0,0.1)" }}>ADMIN DO CLIENTE</div>
            {[
              {l:"Nome do Admin *",k:"admin_name",p:"Nome completo"},
              {l:"Email do Admin *",k:"admin_email",p:"admin@empresa.com"},
              {l:"Senha do Admin *",k:"admin_password",p:"Senha inicial"},
            ].map(c => (
              <div key={c.k} style={{ marginBottom:12 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 }}>{c.l}</label>
                <input type={c.k.includes("password")?"password":"text"} value={(novo as any)[c.k]} onChange={e=>setNovo(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(255,100,0,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}

            <div style={{ display:"flex", gap:8, marginTop:8 }}>
              <button onClick={()=>setModal(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={criarTenant} style={{ flex:2, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#cc4400,#aa2200)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:12, letterSpacing:1 }}>CRIAR CLIENTE</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# ATUALIZAR AUTH STORE para redirecionar superadmin
# ============================================================
[System.IO.File]::WriteAllText("$base\store\auth.ts", @'
import { create } from "zustand";
import { authAPI } from "@/lib/api";

interface User {
  id: number;
  name: string;
  email: string;
  role: string;
  tenant_id: number | null;
}

interface AuthStore {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<User>;
  logout: () => void;
  loadUser: () => Promise<User | null>;
}

export const useAuthStore = create<AuthStore>((set) => ({
  user: null,
  token: typeof window !== "undefined" ? localStorage.getItem("token") : null,
  loading: false,

  login: async (email, password) => {
    set({ loading: true });
    try {
      const res = await authAPI.login(email, password);
      const token = res.data.access_token;
      localStorage.setItem("token", token);
      const me = await authAPI.me();
      set({ token, user: me.data, loading: false });
      return me.data;
    } catch (err) {
      set({ loading: false });
      throw err;
    }
  },

  logout: () => {
    localStorage.removeItem("token");
    set({ user: null, token: null });
    window.location.href = "/login";
  },

  loadUser: async () => {
    const token = localStorage.getItem("token");
    if (!token) return null;
    try {
      const me = await authAPI.me();
      set({ user: me.data, token });
      return me.data;
    } catch {
      localStorage.removeItem("token");
      set({ user: null, token: null });
      return null;
    }
  },
}));
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# ATUALIZAR LOGIN para redirecionar superadmin
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(auth)\login\page.tsx", @'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/store/auth";

export default function LoginPage() {
  const router = useRouter();
  const { login, loading } = useAuthStore();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    try {
      const user = await login(email, password);
      if (user.role === "superadmin") {
        router.push("/admin");
      } else {
        router.push("/dashboard");
      }
    } catch (err: any) {
      setError(err.response?.data?.detail || "Email ou senha incorretos");
    }
  }

  return (
    <div style={{ minHeight:"100vh", background:"linear-gradient(135deg,#080d14 0%,#0a1525 50%,#080d14 100%)", display:"flex", alignItems:"center", justifyContent:"center", fontFamily:"'Rajdhani',sans-serif" }}>
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&family=Rajdhani:wght@400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet" />
      <div style={{ width:420, background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:16, padding:"40px 36px", boxShadow:"0 0 60px rgba(0,100,200,0.15)", position:"relative" }}>
        <div style={{ position:"absolute", top:0, left:"20%", right:"20%", height:2, background:"linear-gradient(90deg,transparent,#00bfff,transparent)" }} />
        <div style={{ textAlign:"center", marginBottom:32 }}>
          <div style={{ width:64, height:64, background:"linear-gradient(135deg,#0066cc,#003d7a)", borderRadius:16, display:"flex", alignItems:"center", justifyContent:"center", margin:"0 auto 16px", fontSize:24, color:"#7ec8ff", fontWeight:900, fontFamily:"'Orbitron',monospace" }}>FC</div>
          <div style={{ fontFamily:"'Orbitron',monospace", fontSize:22, fontWeight:900, color:"#7ec8ff", letterSpacing:3 }}>FORTCAM</div>
          <div style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#4a7aaa", letterSpacing:6, marginTop:2 }}>PLATAFORMA CLOUD</div>
        </div>
        <form onSubmit={handleLogin}>
          <div style={{ marginBottom:16 }}>
            <label style={{ fontSize:11, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:6 }}>E-mail</label>
            <input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="seu@email.com" required
              style={{ width:"100%", padding:"10px 14px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:8, color:"#e0e8f0", fontSize:14, outline:"none", boxSizing:"border-box" }} />
          </div>
          <div style={{ marginBottom:24 }}>
            <label style={{ fontSize:11, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:6 }}>Senha</label>
            <input type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••" required
              style={{ width:"100%", padding:"10px 14px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:8, color:"#e0e8f0", fontSize:14, outline:"none", boxSizing:"border-box" }} />
          </div>
          {error && <div style={{ background:"rgba(255,68,68,0.1)", border:"1px solid rgba(255,68,68,0.3)", borderRadius:6, padding:"8px 12px", marginBottom:16, color:"#ff7777", fontSize:12 }}>{error}</div>}
          <button type="submit" disabled={loading}
            style={{ width:"100%", padding:"12px", background:loading?"rgba(0,100,200,0.3)":"linear-gradient(135deg,#0066cc,#004499)", border:"1px solid rgba(0,160,255,0.3)", borderRadius:8, color:"#fff", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:13, letterSpacing:2, cursor:loading?"not-allowed":"pointer" }}>
            {loading ? "AUTENTICANDO..." : "ENTRAR NO SISTEMA"}
          </button>
        </form>
      </div>
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Painel superadmin criado!" -ForegroundColor Green
Write-Host ""
Write-Host "Reinicie o frontend: npm run dev" -ForegroundColor Yellow
Write-Host ""
Write-Host "Login superadmin:" -ForegroundColor Cyan
Write-Host "  Email: super@fortcam.com" -ForegroundColor White
Write-Host "  Senha: super123" -ForegroundColor White
Write-Host "  URL: http://localhost:3000/admin" -ForegroundColor White
