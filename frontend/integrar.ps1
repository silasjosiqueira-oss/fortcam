# Script para criar integracao frontend com backend
$base = "C:\Users\Camera 3\fortcam-cloud\frontend"

Write-Host "Criando arquivos de integracao..." -ForegroundColor Cyan

# Criar pastas
New-Item -ItemType Directory -Force -Path "$base\lib" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\hooks" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\store" | Out-Null

# ============================================================
# API CLIENT
# ============================================================
[System.IO.File]::WriteAllText("$base\lib\api.ts", @'
import axios from "axios";

const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

const api = axios.create({
  baseURL: API_URL,
  headers: { "Content-Type": "application/json" },
});

// Interceptor: adiciona token em todas as requisicoes
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// Interceptor: redireciona para login se 401
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem("token");
      window.location.href = "/login";
    }
    return Promise.reject(err);
  }
);

// AUTH
export const authAPI = {
  login: (email: string, password: string) =>
    api.post("/api/v1/auth/login", { email, password }),
  me: () => api.get("/api/v1/auth/me"),
};

// DASHBOARD
export const dashboardAPI = {
  stats: () => api.get("/api/v1/events/dashboard"),
  lastEvent: () => api.get("/api/v1/events/last"),
};

// EVENTOS
export const eventsAPI = {
  list: (params?: { plate?: string; status?: string; limit?: number }) =>
    api.get("/api/v1/events/", { params }),
};

// WHITELIST
export const whitelistAPI = {
  list: () => api.get("/api/v1/whitelist/"),
  add: (data: { plate: string; owner_name: string; time_start: string; time_end: string }) =>
    api.post("/api/v1/whitelist/", data),
  update: (id: number, data: any) => api.put(`/api/v1/whitelist/${id}`, data),
  remove: (id: number) => api.delete(`/api/v1/whitelist/${id}`),
  check: (plate: string) => api.get(`/api/v1/whitelist/check/${plate}`),
};

// CAMERAS
export const camerasAPI = {
  list: () => api.get("/api/v1/cameras/"),
};

// PORTAO
export const gateAPI = {
  command: (camera_id: number, action: "open" | "close") =>
    api.post("/api/v1/gate/command", { camera_id, action }),
};

export default api;
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# AUTH STORE (Zustand)
# ============================================================
[System.IO.File]::WriteAllText("$base\store\auth.ts", @'
import { create } from "zustand";
import { authAPI } from "@/lib/api";

interface User {
  id: number;
  name: string;
  email: string;
  role: string;
}

interface AuthStore {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  loadUser: () => Promise<void>;
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
    if (!token) return;
    try {
      const me = await authAPI.me();
      set({ user: me.data, token });
    } catch {
      localStorage.removeItem("token");
      set({ user: null, token: null });
    }
  },
}));
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# LOGIN PAGE - com API real
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
      await login(email, password);
      router.push("/dashboard");
    } catch (err: any) {
      setError(err.response?.data?.detail || "Email ou senha incorretos");
    }
  }

  return (
    <div style={{ minHeight:"100vh", background:"linear-gradient(135deg,#080d14 0%,#0a1525 50%,#080d14 100%)", display:"flex", alignItems:"center", justifyContent:"center", fontFamily:"'Rajdhani',sans-serif", overflow:"hidden", position:"relative" }}>
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&family=Rajdhani:wght@400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet" />
      <div style={{ position:"absolute", inset:0, backgroundImage:"linear-gradient(rgba(0,160,255,0.03) 1px,transparent 1px),linear-gradient(90deg,rgba(0,160,255,0.03) 1px,transparent 1px)", backgroundSize:"40px 40px" }} />
      <div style={{ width:420, background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:16, padding:"40px 36px", position:"relative", boxShadow:"0 0 60px rgba(0,100,200,0.15)" }}>
        <div style={{ position:"absolute", top:0, left:"20%", right:"20%", height:2, background:"linear-gradient(90deg,transparent,#00bfff,transparent)" }} />
        <div style={{ textAlign:"center", marginBottom:32 }}>
          <div style={{ width:64, height:64, background:"linear-gradient(135deg,#0066cc,#003d7a)", borderRadius:16, display:"flex", alignItems:"center", justifyContent:"center", margin:"0 auto 16px", boxShadow:"0 0 24px rgba(0,100,200,0.4)", fontSize:24, color:"#7ec8ff", fontWeight:900, fontFamily:"'Orbitron',monospace" }}>FC</div>
          <div style={{ fontFamily:"'Orbitron',monospace", fontSize:22, fontWeight:900, color:"#7ec8ff", letterSpacing:3 }}>FORTCAM</div>
          <div style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#4a7aaa", letterSpacing:6, marginTop:2 }}>PLATAFORMA CLOUD</div>
        </div>
        <form onSubmit={handleLogin}>
          <div style={{ marginBottom:16 }}>
            <label style={{ fontSize:11, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:6 }}>E-mail</label>
            <input type="email" value={email} onChange={e=>setEmail(e.target.value)} placeholder="seu@email.com" required
              style={{ width:"100%", padding:"10px 14px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:8, color:"#e0e8f0", fontSize:14, outline:"none", fontFamily:"'Rajdhani',sans-serif", boxSizing:"border-box" }}
              onFocus={e=>e.target.style.borderColor="rgba(0,160,255,0.6)"} onBlur={e=>e.target.style.borderColor="rgba(0,160,255,0.2)"} />
          </div>
          <div style={{ marginBottom:24 }}>
            <label style={{ fontSize:11, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:6 }}>Senha</label>
            <input type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="••••••••" required
              style={{ width:"100%", padding:"10px 14px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:8, color:"#e0e8f0", fontSize:14, outline:"none", fontFamily:"'Rajdhani',sans-serif", boxSizing:"border-box" }}
              onFocus={e=>e.target.style.borderColor="rgba(0,160,255,0.6)"} onBlur={e=>e.target.style.borderColor="rgba(0,160,255,0.2)"} />
          </div>
          {error && <div style={{ background:"rgba(255,68,68,0.1)", border:"1px solid rgba(255,68,68,0.3)", borderRadius:6, padding:"8px 12px", marginBottom:16, color:"#ff7777", fontSize:12 }}>{error}</div>}
          <button type="submit" disabled={loading} style={{ width:"100%", padding:"12px", background:loading?"rgba(0,100,200,0.3)":"linear-gradient(135deg,#0066cc,#004499)", border:"1px solid rgba(0,160,255,0.3)", borderRadius:8, color:"#fff", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:13, letterSpacing:2, cursor:loading?"not-allowed":"pointer", boxShadow:loading?"none":"0 0 20px rgba(0,100,200,0.3)" }}>
            {loading ? "AUTENTICANDO..." : "ENTRAR NO SISTEMA"}
          </button>
        </form>
        <div style={{ textAlign:"center", marginTop:16, fontSize:11, color:"#3a5a7a" }}>
          admin@fortcam.com / admin123
        </div>
      </div>
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# DASHBOARD LAYOUT - com logout real
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(dashboard)\layout.tsx", @'
"use client";
import { useRouter, usePathname } from "next/navigation";
import { useEffect } from "react";
import { useAuthStore } from "@/store/auth";

const navItems = [
  { label: "Painel", path: "/dashboard" },
  { label: "Placas", path: "/plates" },
  { label: "Whitelist", path: "/whitelist" },
  { label: "Cameras", path: "/cameras" },
  { label: "Relatorios", path: "/reports" },
  { label: "Configuracoes", path: "/settings" },
];

const rotulos: Record<string,string> = {
  "/dashboard": "PAINEL / VISAO GERAL",
  "/plates": "PLACAS / HISTORICO",
  "/whitelist": "WHITELIST / LIBERADOS",
  "/cameras": "CAMERAS / MONITORAMENTO",
  "/reports": "RELATORIOS",
  "/settings": "CONFIGURACOES",
};

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { user, token, logout, loadUser } = useAuthStore();

  useEffect(() => {
    if (!token) { router.push("/login"); return; }
    if (!user) loadUser();
  }, [token]);

  return (
    <div style={{ display:"flex", height:"100vh", width:"100vw", fontFamily:"'Rajdhani',sans-serif", background:"#080d14", color:"#e0e8f0", overflow:"hidden" }}>
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&family=Rajdhani:wght@400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet" />
      <style>{`@keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}`}</style>

      <div style={{ width:200, flexShrink:0, background:"linear-gradient(180deg,#0a0f1a,#080d14)", borderRight:"1px solid rgba(0,160,255,0.15)", display:"flex", flexDirection:"column" }}>
        <div style={{ padding:"20px 16px 16px", borderBottom:"1px solid rgba(0,160,255,0.1)", display:"flex", alignItems:"center", gap:10 }}>
          <div style={{ width:36, height:36, background:"linear-gradient(135deg,#0066cc,#003d7a)", borderRadius:8, display:"flex", alignItems:"center", justifyContent:"center", fontFamily:"'Orbitron',monospace", fontWeight:900, color:"#7ec8ff", fontSize:12, boxShadow:"0 0 12px rgba(0,100,200,0.5)" }}>FC</div>
          <div>
            <div style={{ fontSize:13, fontWeight:700, fontFamily:"'Orbitron',monospace", color:"#7ec8ff", letterSpacing:1 }}>FORTCAM</div>
            <div style={{ fontSize:8, color:"#4a7aaa", letterSpacing:3, fontFamily:"'Share Tech Mono',monospace" }}>CLOUD</div>
          </div>
        </div>
        <nav style={{ flex:1, padding:"12px 0" }}>
          {navItems.map(item => {
            const active = pathname === item.path;
            return (
              <div key={item.path} onClick={()=>router.push(item.path)} style={{ display:"flex", alignItems:"center", gap:10, padding:"10px 16px", margin:"2px 8px", borderRadius:6, background:active?"rgba(0,120,255,0.15)":"transparent", borderLeft:active?"2px solid #0099ff":"2px solid transparent", color:active?"#7ec8ff":"#5a7a9a", fontSize:13, fontWeight:active?600:400, cursor:"pointer", transition:"all 0.2s" }}>
                {item.label}
              </div>
            );
          })}
        </nav>
        <div style={{ padding:"12px 16px", borderTop:"1px solid rgba(0,160,255,0.1)" }}>
          <div style={{ fontSize:11, color:"#5a7a9a", marginBottom:6 }}>{user?.name || "Carregando..."}</div>
          <div onClick={logout} style={{ fontSize:11, color:"#ff6644", cursor:"pointer", fontWeight:600 }}>Sair do sistema</div>
        </div>
      </div>

      <div style={{ flex:1, display:"flex", flexDirection:"column", overflow:"hidden" }}>
        <div style={{ height:52, background:"rgba(8,13,20,0.95)", borderBottom:"1px solid rgba(0,160,255,0.1)", display:"flex", alignItems:"center", justifyContent:"space-between", padding:"0 20px" }}>
          <div style={{ fontFamily:"'Orbitron',monospace", fontSize:11, color:"#4a7aaa", letterSpacing:2 }}>{rotulos[pathname]||"PAINEL"}</div>
          <div style={{ fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace" }}>{user?.role?.toUpperCase()}</div>
        </div>
        <div style={{ flex:1, overflowY:"auto" }}>{children}</div>
      </div>
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# DASHBOARD PAGE - com dados reais
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(dashboard)\dashboard\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import { dashboardAPI, eventsAPI, camerasAPI, gateAPI } from "@/lib/api";

function Ponto({ cor }: { cor: string }) {
  return <span style={{ display:"inline-block", width:8, height:8, borderRadius:"50%", background:cor, boxShadow:`0 0 6px ${cor}`, marginRight:4 }} />;
}

function Card({ label, valor, cor, sub }: { label:string; valor:string|number; cor:string; sub?:string }) {
  return (
    <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px", position:"relative", overflow:"hidden" }}>
      <div style={{ position:"absolute", top:0, left:0, right:0, height:2, background:`linear-gradient(90deg,transparent,${cor},transparent)` }} />
      <div style={{ fontSize:11, color:"#5a7a9a", marginBottom:6 }}>{label}</div>
      <div style={{ display:"flex", alignItems:"baseline", gap:6 }}>
        <span style={{ fontSize:32, fontWeight:700, fontFamily:"'Orbitron',monospace", color:cor, textShadow:`0 0 20px ${cor}60` }}>{valor}</span>
        {sub && <span style={{ fontSize:11, color:cor, opacity:0.7 }}>{sub}</span>}
      </div>
    </div>
  );
}

export default function PainelPage() {
  const [stats, setStats] = useState<any>(null);
  const [lastEvent, setLastEvent] = useState<any>(null);
  const [eventos, setEventos] = useState<any[]>([]);
  const [cameras, setCameras] = useState<any[]>([]);
  const [portao, setPortao] = useState<"aberto"|"fechado">("fechado");
  const [relogio, setRelogio] = useState(new Date());

  useEffect(() => {
    const t = setInterval(() => setRelogio(new Date()), 1000);
    carregarDados();
    const r = setInterval(carregarDados, 10000); // atualiza a cada 10s
    return () => { clearInterval(t); clearInterval(r); };
  }, []);

  async function carregarDados() {
    try {
      const [s, e, c] = await Promise.all([
        dashboardAPI.stats(),
        eventsAPI.list({ limit: 5 }),
        camerasAPI.list(),
      ]);
      setStats(s.data);
      setEventos(e.data);
      setCameras(c.data);
      if (e.data.length > 0) setLastEvent(e.data[0]);
    } catch (err) {
      console.error("Erro ao carregar dados:", err);
    }
  }

  async function controlarPortao(action: "open" | "close") {
    try {
      if (cameras.length > 0) {
        await gateAPI.command(cameras[0].id, action);
      }
      setPortao(action === "open" ? "aberto" : "fechado");
    } catch {
      setPortao(action === "open" ? "aberto" : "fechado");
    }
  }

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <div style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:12 }}>
        <Card label="Acessos Hoje" valor={stats?.total_today ?? "..."} cor="#00bfff" />
        <Card label="Cameras Ativas" valor={stats?.cameras_online ?? "..."} cor="#00e676" sub="Online" />
        <Card label="Whitelist Hoje" valor={stats?.whitelist_matches_today ?? "..."} cor="#00bfff" />
        <Card label="Alertas" valor={stats?.alerts ?? "..."} cor="#ff6b35" sub="Negados" />
      </div>

      <div style={{ display:"grid", gridTemplateColumns:"1fr 280px", gap:12 }}>
        <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
          <div style={{ padding:"10px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Ultima Placa Detectada</div>
          <div style={{ position:"relative", height:160, background:"linear-gradient(135deg,#0a1a2a,#0d2035)", display:"flex", alignItems:"center", justifyContent:"center" }}>
            {[{top:10,left:10},{top:10,right:10},{bottom:10,left:10},{bottom:10,right:10}].map((pos,i)=>(
              <div key={i} style={{ position:"absolute", ...pos, width:20, height:20, borderTop:i<2?"2px solid rgba(0,180,255,0.6)":"none", borderBottom:i>=2?"2px solid rgba(0,180,255,0.6)":"none", borderLeft:i%2===0?"2px solid rgba(0,180,255,0.6)":"none", borderRight:i%2===1?"2px solid rgba(0,180,255,0.6)":"none" }} />
            ))}
            <div style={{ fontSize:40, opacity:0.1, color:"#00bfff", fontFamily:"'Orbitron',monospace" }}>[CAM]</div>
            <div style={{ position:"absolute", top:10, right:10, display:"flex", alignItems:"center", gap:4, background:"rgba(0,0,0,0.6)", padding:"3px 8px", borderRadius:4, border:"1px solid rgba(255,50,50,0.4)" }}>
              <div style={{ width:6, height:6, borderRadius:"50%", background:"#ff3333", boxShadow:"0 0 6px #ff3333", animation:"blink 1.5s ease infinite" }} />
              <span style={{ fontSize:9, color:"#ff7777", fontWeight:700, letterSpacing:1, fontFamily:"'Orbitron',monospace" }}>AO VIVO</span>
            </div>
            <div style={{ position:"absolute", bottom:0, left:0, right:0, background:"linear-gradient(transparent,rgba(0,0,0,0.9))", padding:"20px 16px 12px" }}>
              <div style={{ fontFamily:"'Orbitron',monospace", fontSize:26, fontWeight:900, color:"#fff", letterSpacing:4 }}>
                {lastEvent?.plate || "---"}
              </div>
              <div style={{ fontSize:11, color:"#7a9ab8", fontFamily:"'Share Tech Mono',monospace" }}>
                {lastEvent ? new Date(lastEvent.detected_at).toLocaleString("pt-BR") : "Nenhum evento"}
              </div>
            </div>
          </div>
        </div>

        <div style={{ display:"flex", flexDirection:"column", gap:12 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"10px 14px" }}>
            <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:10 }}>Controle do Portao</div>
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>controlarPortao("open")} style={{ flex:1, padding:"10px 0", border:"none", borderRadius:6, background:portao==="aberto"?"linear-gradient(135deg,#00aa44,#007733)":"linear-gradient(135deg,#008833,#005522)", color:"#fff", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:13, cursor:"pointer", boxShadow:portao==="aberto"?"0 0 16px rgba(0,200,80,0.5)":"none" }}>ABRIR</button>
              <button onClick={()=>controlarPortao("close")} style={{ flex:1, padding:"10px 0", border:"none", borderRadius:6, background:portao==="fechado"?"linear-gradient(135deg,#cc2200,#991100)":"linear-gradient(135deg,#aa1a00,#881200)", color:"#fff", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:13, cursor:"pointer", boxShadow:portao==="fechado"?"0 0 16px rgba(220,50,20,0.5)":"none" }}>FECHAR</button>
            </div>
            <div style={{ textAlign:"center", marginTop:8, fontSize:10, fontFamily:"'Share Tech Mono',monospace", letterSpacing:2, color:portao==="aberto"?"#00e676":"#ff6644" }}>STATUS: {portao==="aberto"?"ABERTO":"FECHADO"}</div>
          </div>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"10px 14px", flex:1 }}>
            <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:10 }}>Status do Sistema</div>
            {[{label:"Servidor Online",ok:true},{label:"API Conectada",ok:!!stats},{label:"Banco de Dados",ok:true},{label:"TLS/SSL",ok:false}].map((item,i,arr)=>(
              <div key={i} style={{ display:"flex", justifyContent:"space-between", alignItems:"center", padding:"5px 0", borderBottom:i<arr.length-1?"1px solid rgba(255,255,255,0.04)":"none" }}>
                <div style={{ display:"flex", alignItems:"center" }}><Ponto cor={item.ok?"#00e676":"#ff4444"} /><span style={{ fontSize:12, color:"#8ab0cc" }}>{item.label}</span></div>
                <span style={{ fontSize:10, color:item.ok?"#00e676":"#ff4444", fontFamily:"'Share Tech Mono',monospace" }}>{item.ok?"OK":"OFF"}</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ padding:"10px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", display:"flex", justifyContent:"space-between" }}>
          <span style={{ fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Eventos Recentes</span>
          <span style={{ fontSize:10, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>ULTIMOS {eventos.length}</span>
        </div>
        {eventos.length === 0 ? (
          <div style={{ padding:24, textAlign:"center", color:"#4a6a8a", fontSize:12 }}>Nenhum evento registrado ainda.</div>
        ) : (
          <>
            <div style={{ padding:"6px 14px", borderBottom:"1px solid rgba(255,255,255,0.04)", display:"grid", gridTemplateColumns:"36px 130px 1fr 180px 140px", fontSize:10, color:"#4a6a8a", textTransform:"uppercase" }}>
              <span/><span>Placa</span><span>Camera</span><span>Data/Hora</span><span>Status</span>
            </div>
            {eventos.map(ev => {
              const ok = ev.status === "granted";
              return (
                <div key={ev.id} style={{ display:"grid", gridTemplateColumns:"36px 130px 1fr 180px 140px", padding:"8px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
                  <div style={{ width:24, height:24, borderRadius:4, background:ok?"rgba(0,77,32,0.5)":"rgba(77,0,0,0.5)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:12, color:ok?"#00e676":"#ff4444", fontWeight:700 }}>{ok?"V":"X"}</div>
                  <span style={{ fontFamily:"'Orbitron',monospace", fontSize:12, fontWeight:700, color:"#c8e0f0", letterSpacing:2 }}>{ev.plate}</span>
                  <span style={{ fontSize:11, color:"#6a8aa8" }}>{ev.camera_name || "---"}</span>
                  <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#5a7a9a" }}>{new Date(ev.detected_at).toLocaleString("pt-BR")}</span>
                  <span style={{ color:ok?"#00e676":"#ff4444", fontSize:11, fontWeight:600, background:ok?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", padding:"2px 8px", borderRadius:4, border:`1px solid ${ok?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, display:"inline-block" }}>{ok?"Liberado":"Negado"}</span>
                </div>
              );
            })}
          </>
        )}
      </div>

      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ padding:"10px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Cameras Cadastradas</div>
        {cameras.length === 0 ? (
          <div style={{ padding:24, textAlign:"center", color:"#4a6a8a", fontSize:12 }}>Nenhuma camera cadastrada ainda.</div>
        ) : (
          <div style={{ display:"flex", gap:12, padding:14 }}>
            {cameras.map(cam => (
              <div key={cam.id} style={{ flex:1, borderRadius:8, overflow:"hidden", border:"1px solid rgba(255,255,255,0.08)", background:"#0a0f1a", position:"relative" }}>
                <div style={{ height:80, background:cam.is_online?"linear-gradient(135deg,#0d1b2a,#1a2a3a)":"linear-gradient(135deg,#111,#1a1a1a)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, color:cam.is_online?"rgba(0,180,255,0.5)":"rgba(255,255,255,0.1)", fontFamily:"'Orbitron',monospace", letterSpacing:1 }}>{cam.is_online?"[LIVE]":"[OFF]"}</div>
                <div style={{ padding:"6px 8px", fontSize:10, color:"#ccc", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
                  <span>{cam.name}</span>
                  <Ponto cor={cam.is_online?"#00e676":"#555"} />
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# WHITELIST PAGE - com API real
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(dashboard)\whitelist\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import { whitelistAPI } from "@/lib/api";

export default function WhitelistPage() {
  const [lista, setLista] = useState<any[]>([]);
  const [modal, setModal] = useState(false);
  const [loading, setLoading] = useState(true);
  const [nova, setNova] = useState({ plate:"", owner_name:"", time_start:"00:00", time_end:"23:59" });

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const res = await whitelistAPI.list();
      setLista(res.data);
    } finally {
      setLoading(false);
    }
  }

  async function alternar(id: number, ativo: boolean) {
    await whitelistAPI.update(id, { is_active: !ativo });
    carregar();
  }

  async function remover(id: number) {
    if (!confirm("Remover esta placa?")) return;
    await whitelistAPI.remove(id);
    carregar();
  }

  async function adicionar() {
    if (!nova.plate || !nova.owner_name) return;
    try {
      await whitelistAPI.add(nova);
      setNova({ plate:"", owner_name:"", time_start:"00:00", time_end:"23:59" });
      setModal(false);
      carregar();
    } catch (err: any) {
      alert(err.response?.data?.detail || "Erro ao adicionar");
    }
  }

  return (
    <div style={{ padding:16 }}>
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>WHITELIST / PLACAS LIBERADAS</div>
        <button onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:11, fontWeight:700, letterSpacing:1 }}>+ ADICIONAR PLACA</button>
      </div>
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ display:"grid", gridTemplateColumns:"150px 1fr 160px 80px 120px", padding:"8px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:10, color:"#4a6a8a", textTransform:"uppercase" }}>
          <span>Placa</span><span>Nome</span><span>Horario</span><span>Ativo</span><span>Acoes</span>
        </div>
        {loading && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loading && lista.length === 0 && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Nenhuma placa cadastrada.</div>}
        {lista.map(item => (
          <div key={item.id} style={{ display:"grid", gridTemplateColumns:"150px 1fr 160px 80px 120px", padding:"10px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
            <span style={{ fontFamily:"'Orbitron',monospace", fontSize:13, fontWeight:700, color:"#c8e0f0", letterSpacing:2 }}>{item.plate}</span>
            <span style={{ fontSize:13, color:"#8ab0cc" }}>{item.owner_name}</span>
            <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#5a7a9a" }}>{item.time_start} - {item.time_end}</span>
            <div onClick={()=>alternar(item.id, item.is_active)} style={{ width:40, height:22, borderRadius:11, cursor:"pointer", background:item.is_active?"#00e676":"#333", position:"relative", transition:"background 0.2s" }}>
              <div style={{ position:"absolute", top:3, left:item.is_active?21:3, width:16, height:16, borderRadius:"50%", background:"#fff", transition:"left 0.2s" }} />
            </div>
            <button onClick={()=>remover(item.id)} style={{ padding:"4px 12px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>Remover</button>
          </div>
        ))}
      </div>
      {modal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.7)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:400 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>NOVA PLACA</div>
            {[{l:"Placa",k:"plate",p:"ABC1D23"},{l:"Nome / Responsavel",k:"owner_name",p:"Nome do motorista"},{l:"Horario inicio",k:"time_start",p:"00:00"},{l:"Horario fim",k:"time_end",p:"23:59"}].map(c => (
              <div key={c.k} style={{ marginBottom:14 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>{c.l}</label>
                <input value={(nova as any)[c.k]} onChange={e=>setNova(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>setModal(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={adicionar} style={{ flex:1, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# PLATES PAGE - com API real
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(dashboard)\plates\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import { eventsAPI } from "@/lib/api";

export default function PlacasPage() {
  const [eventos, setEventos] = useState<any[]>([]);
  const [busca, setBusca] = useState("");
  const [filtro, setFiltro] = useState("todos");
  const [loading, setLoading] = useState(true);

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const res = await eventsAPI.list({ limit: 100 });
      setEventos(res.data);
    } finally {
      setLoading(false);
    }
  }

  const filtrados = eventos.filter(ev => {
    const mb = ev.plate.includes(busca.toUpperCase()) || (ev.camera_name||"").toLowerCase().includes(busca.toLowerCase());
    const mf = filtro === "todos" || (filtro === "liberado" && ev.status === "granted") || (filtro === "negado" && ev.status === "denied");
    return mb && mf;
  });

  return (
    <div style={{ padding:16 }}>
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>PLACAS / HISTORICO</div>
        <div style={{ display:"flex", gap:8 }}>
          <input value={busca} onChange={e=>setBusca(e.target.value)} placeholder="Buscar placa ou camera..."
            style={{ padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", width:240 }} />
          {[{k:"todos",l:"Todos"},{k:"liberado",l:"Liberados"},{k:"negado",l:"Negados"}].map(f=>(
            <button key={f.k} onClick={()=>setFiltro(f.k)} style={{ padding:"8px 14px", borderRadius:6, cursor:"pointer", background:filtro===f.k?"rgba(0,120,255,0.3)":"rgba(0,0,0,0.3)", color:filtro===f.k?"#7ec8ff":"#5a7a9a", border:`1px solid ${filtro===f.k?"rgba(0,160,255,0.4)":"rgba(255,255,255,0.08)"}`, fontSize:12, fontWeight:600 }}>{f.l}</button>
          ))}
        </div>
      </div>
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ display:"grid", gridTemplateColumns:"36px 140px 1fr 200px 150px", padding:"8px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:10, color:"#4a6a8a", textTransform:"uppercase" }}>
          <span/><span>Placa</span><span>Camera</span><span>Data/Hora</span><span>Status</span>
        </div>
        {loading && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loading && filtrados.length === 0 && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Nenhum evento encontrado.</div>}
        {filtrados.map(ev => {
          const ok = ev.status === "granted";
          return (
            <div key={ev.id} style={{ display:"grid", gridTemplateColumns:"36px 140px 1fr 200px 150px", padding:"10px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
              <div style={{ width:24, height:24, borderRadius:4, background:ok?"rgba(0,77,32,0.5)":"rgba(77,0,0,0.5)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:12, color:ok?"#00e676":"#ff4444", fontWeight:700 }}>{ok?"V":"X"}</div>
              <span style={{ fontFamily:"'Orbitron',monospace", fontSize:13, fontWeight:700, color:"#c8e0f0", letterSpacing:2 }}>{ev.plate}</span>
              <span style={{ fontSize:12, color:"#8ab0cc" }}>{ev.camera_name || "---"}</span>
              <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#5a7a9a" }}>{new Date(ev.detected_at).toLocaleString("pt-BR")}</span>
              <span style={{ color:ok?"#00e676":"#ff4444", fontSize:11, fontWeight:600, background:ok?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", padding:"2px 8px", borderRadius:4, border:`1px solid ${ok?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, display:"inline-block" }}>{ok?"Liberado":"Negado"}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# CAMERAS PAGE - com API real
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(dashboard)\cameras\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import { camerasAPI } from "@/lib/api";

export default function CamerasPage() {
  const [cameras, setCameras] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    camerasAPI.list().then(r => setCameras(r.data)).finally(() => setLoading(false));
  }, []);

  return (
    <div style={{ padding:16 }}>
      <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2, marginBottom:16 }}>CAMERAS / MONITORAMENTO</div>
      {loading && <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando...</div>}
      {!loading && cameras.length === 0 && (
        <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:32, textAlign:"center", color:"#4a6a8a" }}>
          Nenhuma camera cadastrada. Adicione cameras pela API em /docs
        </div>
      )}
      <div style={{ display:"grid", gridTemplateColumns:"repeat(2,1fr)", gap:12 }}>
        {cameras.map(cam => (
          <div key={cam.id} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ height:140, background:cam.is_online?"linear-gradient(135deg,#0a1a2a,#0d2035)":"linear-gradient(135deg,#111,#0a0a0a)", display:"flex", alignItems:"center", justifyContent:"center", position:"relative", fontSize:13, color:cam.is_online?"rgba(0,180,255,0.4)":"rgba(255,255,255,0.1)", fontFamily:"'Orbitron',monospace", letterSpacing:2 }}>
              {cam.is_online ? "[CAMERA LIVE]" : "[OFFLINE]"}
              {cam.is_online && (
                <div style={{ position:"absolute", top:10, right:10, display:"flex", alignItems:"center", gap:4, background:"rgba(0,0,0,0.6)", padding:"3px 8px", borderRadius:4, border:"1px solid rgba(255,50,50,0.4)" }}>
                  <div style={{ width:6, height:6, borderRadius:"50%", background:"#ff3333", boxShadow:"0 0 6px #ff3333", animation:"blink 1.5s ease infinite" }} />
                  <span style={{ fontSize:9, color:"#ff7777", fontWeight:700, letterSpacing:1, fontFamily:"'Orbitron',monospace" }}>AO VIVO</span>
                </div>
              )}
            </div>
            <div style={{ padding:"10px 14px" }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:6 }}>
                <span style={{ fontSize:14, fontWeight:600, color:"#c8e0f0" }}>{cam.name}</span>
                <span style={{ fontSize:10, padding:"2px 8px", borderRadius:4, background:cam.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:cam.is_online?"#00e676":"#ff4444", border:`1px solid ${cam.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace" }}>{cam.is_online?"ONLINE":"OFFLINE"}</span>
              </div>
              <div style={{ fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace" }}>
                SN: {cam.serial} | IP: {cam.ip || "---"}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

# .env.local para o Next.js
[System.IO.File]::WriteAllText("$base\.env.local", @'
NEXT_PUBLIC_API_URL=http://localhost:8000
'@, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "Integracao criada com sucesso!" -ForegroundColor Green
Write-Host "Agora instale o axios: npm install axios zustand" -ForegroundColor Cyan
