# Script para criar todos os arquivos do Fortcam Cloud em Portugues
# Execute como: .\instalar.ps1

$base = "C:\Users\Camera 3\fortcam-cloud\frontend"

Write-Host "Criando arquivos do Fortcam Cloud..." -ForegroundColor Cyan

# ============================================================
# LOGIN PAGE
# ============================================================
$loginContent = @'
"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleLogin(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    setTimeout(() => {
      if (email && password) {
        router.push("/dashboard");
      } else {
        setError("Preencha o e-mail e a senha.");
        setLoading(false);
      }
    }, 1000);
  }

  return (
    <div style={{
      minHeight: "100vh",
      background: "linear-gradient(135deg, #080d14 0%, #0a1525 50%, #080d14 100%)",
      display: "flex", alignItems: "center", justifyContent: "center",
      fontFamily: "'Rajdhani', sans-serif", position: "relative", overflow: "hidden",
    }}>
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&family=Rajdhani:wght@400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet" />
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: "linear-gradient(rgba(0,160,255,0.03) 1px, transparent 1px), linear-gradient(90deg, rgba(0,160,255,0.03) 1px, transparent 1px)",
        backgroundSize: "40px 40px",
      }} />
      <div style={{
        width: 420, background: "linear-gradient(135deg, #0d1520, #0a1018)",
        border: "1px solid rgba(0,160,255,0.2)", borderRadius: 16, padding: "40px 36px",
        position: "relative", boxShadow: "0 0 60px rgba(0,100,200,0.15)",
      }}>
        <div style={{ position: "absolute", top: 0, left: "20%", right: "20%", height: 2, background: "linear-gradient(90deg, transparent, #00bfff, transparent)", borderRadius: 2 }} />
        <div style={{ textAlign: "center", marginBottom: 32 }}>
          <div style={{
            width: 64, height: 64, background: "linear-gradient(135deg, #0066cc, #003d7a)",
            borderRadius: 16, display: "flex", alignItems: "center", justifyContent: "center",
            fontSize: 32, margin: "0 auto 16px", boxShadow: "0 0 24px rgba(0,100,200,0.4)",
          }}>🛡</div>
          <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 22, fontWeight: 900, color: "#7ec8ff", letterSpacing: 3 }}>FORTCAM</div>
          <div style={{ fontFamily: "'Share Tech Mono', monospace", fontSize: 10, color: "#4a7aaa", letterSpacing: 6, marginTop: 2 }}>PLATAFORMA CLOUD</div>
        </div>
        <form onSubmit={handleLogin}>
          <div style={{ marginBottom: 16 }}>
            <label style={{ fontSize: 11, color: "#5a7a9a", letterSpacing: 1, textTransform: "uppercase", display: "block", marginBottom: 6 }}>E-mail</label>
            <input type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="seu@email.com"
              style={{ width: "100%", padding: "10px 14px", background: "rgba(0,0,0,0.3)", border: "1px solid rgba(0,160,255,0.2)", borderRadius: 8, color: "#e0e8f0", fontSize: 14, fontFamily: "'Rajdhani', sans-serif", outline: "none" }}
              onFocus={e => e.target.style.borderColor = "rgba(0,160,255,0.6)"}
              onBlur={e => e.target.style.borderColor = "rgba(0,160,255,0.2)"} />
          </div>
          <div style={{ marginBottom: 24 }}>
            <label style={{ fontSize: 11, color: "#5a7a9a", letterSpacing: 1, textTransform: "uppercase", display: "block", marginBottom: 6 }}>Senha</label>
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••"
              style={{ width: "100%", padding: "10px 14px", background: "rgba(0,0,0,0.3)", border: "1px solid rgba(0,160,255,0.2)", borderRadius: 8, color: "#e0e8f0", fontSize: 14, fontFamily: "'Rajdhani', sans-serif", outline: "none" }}
              onFocus={e => e.target.style.borderColor = "rgba(0,160,255,0.6)"}
              onBlur={e => e.target.style.borderColor = "rgba(0,160,255,0.2)"} />
          </div>
          {error && <div style={{ background: "rgba(255,68,68,0.1)", border: "1px solid rgba(255,68,68,0.3)", borderRadius: 6, padding: "8px 12px", marginBottom: 16, color: "#ff7777", fontSize: 12 }}>{error}</div>}
          <button type="submit" disabled={loading} style={{
            width: "100%", padding: "12px", background: loading ? "rgba(0,100,200,0.3)" : "linear-gradient(135deg, #0066cc, #004499)",
            border: "1px solid rgba(0,160,255,0.3)", borderRadius: 8, color: "#fff",
            fontFamily: "'Orbitron', monospace", fontWeight: 700, fontSize: 13, letterSpacing: 2,
            cursor: loading ? "not-allowed" : "pointer", boxShadow: loading ? "none" : "0 0 20px rgba(0,100,200,0.3)",
          }}>{loading ? "AUTENTICANDO..." : "ENTRAR NO SISTEMA"}</button>
        </form>
        <div style={{ textAlign: "center", marginTop: 20, fontSize: 11, color: "#3a5a7a" }}>
          Esqueceu a senha? <span style={{ color: "#00bfff", cursor: "pointer" }}>Recuperar acesso</span>
        </div>
      </div>
    </div>
  );
}
'@

# ============================================================
# DASHBOARD LAYOUT
# ============================================================
$layoutContent = @'
"use client";
import { useRouter, usePathname } from "next/navigation";

const navItems = [
  { icon: "⊞", label: "Painel", path: "/dashboard" },
  { icon: "🚗", label: "Placas", path: "/plates" },
  { icon: "✓", label: "Whitelist", path: "/whitelist" },
  { icon: "📷", label: "Cameras", path: "/cameras" },
  { icon: "📊", label: "Relatorios", path: "/reports" },
  { icon: "⚙", label: "Configuracoes", path: "/settings" },
];

const rotulos: Record<string, string> = {
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

  return (
    <div style={{ display: "flex", height: "100vh", width: "100vw", fontFamily: "'Rajdhani', sans-serif", background: "#080d14", color: "#e0e8f0", overflow: "hidden" }}>
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&family=Rajdhani:wght@400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet" />
      <style>{`@keyframes blink { 0%,100%{opacity:1} 50%{opacity:0.3} }`}</style>
      <div style={{ width: 190, flexShrink: 0, background: "linear-gradient(180deg, #0a0f1a 0%, #080d14 100%)", borderRight: "1px solid rgba(0,160,255,0.15)", display: "flex", flexDirection: "column" }}>
        <div style={{ padding: "20px 16px 16px", borderBottom: "1px solid rgba(0,160,255,0.1)", display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{ width: 36, height: 36, background: "linear-gradient(135deg, #0066cc, #003d7a)", borderRadius: 8, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 18, boxShadow: "0 0 12px rgba(0,100,200,0.5)" }}>🛡</div>
          <div>
            <div style={{ fontSize: 13, fontWeight: 700, fontFamily: "'Orbitron', monospace", color: "#7ec8ff", letterSpacing: 1 }}>FORTCAM</div>
            <div style={{ fontSize: 8, color: "#4a7aaa", letterSpacing: 3, fontFamily: "'Share Tech Mono', monospace" }}>CLOUD</div>
          </div>
        </div>
        <nav style={{ flex: 1, padding: "12px 0" }}>
          {navItems.map(item => {
            const active = pathname === item.path;
            return (
              <div key={item.path} onClick={() => router.push(item.path)} style={{ display: "flex", alignItems: "center", gap: 10, padding: "10px 16px", margin: "2px 8px", borderRadius: 6, background: active ? "rgba(0,120,255,0.15)" : "transparent", borderLeft: active ? "2px solid #0099ff" : "2px solid transparent", color: active ? "#7ec8ff" : "#5a7a9a", fontSize: 13, fontWeight: active ? 600 : 400, cursor: "pointer", transition: "all 0.2s" }}>
                <span style={{ fontSize: 14 }}>{item.icon}</span>{item.label}
              </div>
            );
          })}
        </nav>
        <div style={{ padding: "12px 16px", borderTop: "1px solid rgba(0,160,255,0.1)", fontSize: 11, color: "#3a5a7a", display: "flex", alignItems: "center", gap: 8 }}>
          <span style={{ width: 6, height: 6, borderRadius: "50%", background: "#00e676", boxShadow: "0 0 6px #00e676", display: "inline-block" }} />Administrador
        </div>
      </div>
      <div style={{ flex: 1, display: "flex", flexDirection: "column", overflow: "hidden" }}>
        <div style={{ height: 52, background: "rgba(8,13,20,0.95)", borderBottom: "1px solid rgba(0,160,255,0.1)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 20px" }}>
          <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 11, color: "#4a7aaa", letterSpacing: 2 }}>{rotulos[pathname] || "PAINEL"}</div>
          <div style={{ width: 32, height: 32, borderRadius: "50%", background: "linear-gradient(135deg, #0066cc, #003d7a)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 14 }}>👤</div>
        </div>
        <div style={{ flex: 1, overflowY: "auto" }}>{children}</div>
      </div>
    </div>
  );
}
'@

# ============================================================
# DASHBOARD PAGE
# ============================================================
$dashboardContent = @'
"use client";
import { useState, useEffect } from "react";

const eventos = [
  { id: 1, placa: "BRA7A23", estado: "SP", status: "Acesso Liberado", hora: "14:32", horario: "13:00 - 22:23" },
  { id: 2, placa: "QWE456", estado: "RJ", status: "Negado", hora: "14:28", horario: "13:00 - 22:23" },
  { id: 3, placa: "JLK890", estado: "MG", status: "Acesso Liberado", hora: "14:15", horario: "13:00 - 22:23" },
  { id: 4, placa: "ABC1D23", estado: "SP", status: "Acesso Liberado", hora: "13:58", horario: "08:00 - 18:00" },
  { id: 5, placa: "XYZ9F87", estado: "PR", status: "Negado", hora: "13:45", horario: "09:00 - 17:00" },
];

const cameras = [
  { id: 1, nome: "Entrada 01", status: "online" },
  { id: 2, nome: "Portao 02", status: "online" },
  { id: 3, nome: "Estacionamento 03", status: "online" },
  { id: 4, nome: "Area Rural 04", status: "offline" },
];

function Ponto({ cor }: { cor: string }) {
  return <span style={{ display: "inline-block", width: 8, height: 8, borderRadius: "50%", background: cor, boxShadow: `0 0 6px ${cor}`, marginRight: 4 }} />;
}

function Card({ label, valor, icone, cor, sub }: { label: string; valor: string; icone: string; cor: string; sub?: string }) {
  return (
    <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, padding: "14px 16px", position: "relative", overflow: "hidden" }}>
      <div style={{ position: "absolute", top: 0, left: 0, right: 0, height: 2, background: `linear-gradient(90deg, transparent, ${cor}, transparent)` }} />
      <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 6 }}>
        <span style={{ fontSize: 11, color: "#5a7a9a" }}>{label}</span>
        <span style={{ fontSize: 16 }}>{icone}</span>
      </div>
      <div style={{ display: "flex", alignItems: "baseline", gap: 6 }}>
        <span style={{ fontSize: 32, fontWeight: 700, fontFamily: "'Orbitron', monospace", color: cor, textShadow: `0 0 20px ${cor}60` }}>{valor}</span>
        {sub && <span style={{ fontSize: 11, color: cor, opacity: 0.7 }}>{sub}</span>}
      </div>
    </div>
  );
}

export default function PainelPage() {
  const [portao, setPortao] = useState<"aberto" | "fechado">("fechado");
  const [relogio, setRelogio] = useState(new Date());
  useEffect(() => { const t = setInterval(() => setRelogio(new Date()), 1000); return () => clearInterval(t); }, []);
  const ultimo = eventos[0];

  return (
    <div style={{ padding: 16, display: "flex", flexDirection: "column", gap: 12 }}>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 12 }}>
        <Card label="Acessos Hoje" valor="128" icone="✦" cor="#00bfff" />
        <Card label="Cameras Ativas" valor="12" icone="📷" cor="#00e676" sub="Online" />
        <Card label="Whitelist Hoje" valor="87" icone="✉" cor="#00bfff" />
        <Card label="Alertas" valor="3" icone="⚠" cor="#ff6b35" sub="Avisos" />
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "1fr 280px", gap: 12 }}>
        <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, overflow: "hidden" }}>
          <div style={{ padding: "10px 14px", borderBottom: "1px solid rgba(0,160,255,0.1)", fontSize: 12, fontWeight: 600, color: "#8ab0cc" }}>Ultima Placa Detectada</div>
          <div style={{ position: "relative", height: 160, background: "linear-gradient(135deg, #0a1a2a, #0d2035)" }}>
            {[{top:10,left:10},{top:10,right:10},{bottom:10,left:10},{bottom:10,right:10}].map((pos, i) => (
              <div key={i} style={{ position: "absolute", ...pos, width: 20, height: 20, borderTop: i < 2 ? "2px solid rgba(0,180,255,0.6)" : "none", borderBottom: i >= 2 ? "2px solid rgba(0,180,255,0.6)" : "none", borderLeft: i % 2 === 0 ? "2px solid rgba(0,180,255,0.6)" : "none", borderRight: i % 2 === 1 ? "2px solid rgba(0,180,255,0.6)" : "none" }} />
            ))}
            <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 60, opacity: 0.15 }}>🚗</div>
            <div style={{ position: "absolute", top: 10, right: 10, display: "flex", alignItems: "center", gap: 4, background: "rgba(0,0,0,0.6)", padding: "3px 8px", borderRadius: 4, border: "1px solid rgba(255,50,50,0.4)" }}>
              <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#ff3333", boxShadow: "0 0 6px #ff3333", animation: "blink 1.5s ease infinite" }} />
              <span style={{ fontSize: 9, color: "#ff7777", fontWeight: 700, letterSpacing: 1, fontFamily: "'Orbitron', monospace" }}>AO VIVO</span>
            </div>
            <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, background: "linear-gradient(transparent, rgba(0,0,0,0.9))", padding: "20px 16px 12px" }}>
              <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 26, fontWeight: 900, color: "#fff", letterSpacing: 4 }}>{ultimo.placa}</div>
              <div style={{ fontSize: 11, color: "#7a9ab8", fontFamily: "'Share Tech Mono', monospace" }}>{ultimo.hora} • {relogio.toLocaleDateString("pt-BR")}</div>
            </div>
          </div>
        </div>
        <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
          <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, padding: "10px 14px" }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: "#8ab0cc", marginBottom: 10 }}>Controle do Portao</div>
            <div style={{ display: "flex", gap: 8 }}>
              <button onClick={() => setPortao("aberto")} style={{ flex: 1, padding: "10px 0", border: "none", borderRadius: 6, background: portao === "aberto" ? "linear-gradient(135deg, #00aa44, #007733)" : "linear-gradient(135deg, #008833, #005522)", color: "#fff", fontFamily: "'Orbitron', monospace", fontWeight: 700, fontSize: 13, cursor: "pointer", boxShadow: portao === "aberto" ? "0 0 16px rgba(0,200,80,0.5)" : "none" }}>ABRIR</button>
              <button onClick={() => setPortao("fechado")} style={{ flex: 1, padding: "10px 0", border: "none", borderRadius: 6, background: portao === "fechado" ? "linear-gradient(135deg, #cc2200, #991100)" : "linear-gradient(135deg, #aa1a00, #881200)", color: "#fff", fontFamily: "'Orbitron', monospace", fontWeight: 700, fontSize: 13, cursor: "pointer", boxShadow: portao === "fechado" ? "0 0 16px rgba(220,50,20,0.5)" : "none" }}>FECHAR</button>
            </div>
            <div style={{ textAlign: "center", marginTop: 8, fontSize: 10, fontFamily: "'Share Tech Mono', monospace", letterSpacing: 2, color: portao === "aberto" ? "#00e676" : "#ff6644" }}>STATUS: {portao === "aberto" ? "ABERTO" : "FECHADO"}</div>
          </div>
          <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, padding: "10px 14px", flex: 1 }}>
            <div style={{ fontSize: 12, fontWeight: 600, color: "#8ab0cc", marginBottom: 10 }}>Status do Sistema</div>
            {[{label:"Servidor Online",ok:true},{label:"MQTT Conectado",ok:true},{label:"Banco de Dados",ok:true},{label:"TLS/SSL",ok:true}].map((item, i, arr) => (
              <div key={i} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "5px 0", borderBottom: i < arr.length - 1 ? "1px solid rgba(255,255,255,0.04)" : "none" }}>
                <div style={{ display: "flex", alignItems: "center" }}><Ponto cor={item.ok ? "#00e676" : "#ff4444"} /><span style={{ fontSize: 12, color: "#8ab0cc" }}>{item.label}</span></div>
                <div style={{ display: "flex", gap: 3 }}><Ponto cor="#00e676" /><Ponto cor="#00e676" /></div>
              </div>
            ))}
          </div>
        </div>
      </div>
      <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, overflow: "hidden" }}>
        <div style={{ padding: "10px 14px", borderBottom: "1px solid rgba(0,160,255,0.1)", display: "flex", justifyContent: "space-between" }}>
          <span style={{ fontSize: 12, fontWeight: 600, color: "#8ab0cc" }}>Eventos Recentes</span>
          <span style={{ fontSize: 10, color: "#4a6a8a", cursor: "pointer", fontFamily: "'Share Tech Mono', monospace" }}>VER TODOS →</span>
        </div>
        <div style={{ padding: "6px 14px", borderBottom: "1px solid rgba(255,255,255,0.04)", display: "grid", gridTemplateColumns: "36px 130px 60px 1fr 140px 140px", fontSize: 10, color: "#4a6a8a", textTransform: "uppercase" }}>
          <span/><span>Placa</span><span>Estado</span><span>Resultado</span><span>Horario</span><span>Status</span>
        </div>
        {eventos.map(ev => {
          const ok = ev.status === "Acesso Liberado";
          return (
            <div key={ev.id} style={{ display: "grid", gridTemplateColumns: "36px 130px 60px 1fr 140px 140px", padding: "8px 14px", borderBottom: "1px solid rgba(255,255,255,0.03)", alignItems: "center" }}>
              <div style={{ width: 24, height: 24, borderRadius: 4, background: ok ? "rgba(0,77,32,0.5)" : "rgba(77,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, color: ok ? "#00e676" : "#ff4444" }}>{ok ? "✓" : "✕"}</div>
              <span style={{ fontFamily: "'Orbitron', monospace", fontSize: 12, fontWeight: 700, color: "#c8e0f0", letterSpacing: 2 }}>{ev.placa}</span>
              <span style={{ background: "#009c3b", color: "#fff", fontSize: 9, fontWeight: 700, padding: "2px 5px", borderRadius: 3, display: "inline-block", width: "fit-content" }}>{ev.estado}</span>
              <span style={{ fontSize: 11, color: "#6a8aa8" }}>{ev.status}</span>
              <span style={{ fontFamily: "'Share Tech Mono', monospace", fontSize: 10, color: "#5a7a9a" }}>{ev.horario}</span>
              <span style={{ color: ok ? "#00e676" : "#ff4444", fontSize: 11, fontWeight: 600, background: ok ? "rgba(0,230,118,0.1)" : "rgba(255,68,68,0.1)", padding: "2px 8px", borderRadius: 4, border: `1px solid ${ok ? "rgba(0,230,118,0.3)" : "rgba(255,68,68,0.3)"}`, display: "inline-block", width: "fit-content" }}>{ev.status}</span>
            </div>
          );
        })}
      </div>
      <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, overflow: "hidden" }}>
        <div style={{ padding: "10px 14px", borderBottom: "1px solid rgba(0,160,255,0.1)", fontSize: 12, fontWeight: 600, color: "#8ab0cc" }}>Status das Cameras</div>
        <div style={{ display: "flex", gap: 12, padding: 14 }}>
          {cameras.map(cam => (
            <div key={cam.id} style={{ flex: 1, borderRadius: 8, overflow: "hidden", border: "1px solid rgba(255,255,255,0.08)", background: "#0a0f1a", position: "relative" }}>
              <div style={{ height: 90, background: cam.status === "online" ? "linear-gradient(135deg, #0d1b2a, #1a2a3a)" : "linear-gradient(135deg, #111, #1a1a1a)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, color: cam.status === "online" ? "rgba(0,180,255,0.3)" : "rgba(255,255,255,0.08)" }}>📷</div>
              <div style={{ position: "absolute", bottom: 0, left: 0, right: 0, background: "linear-gradient(transparent, rgba(0,0,0,0.85))", padding: "16px 8px 6px", fontSize: 10, color: "#ccc", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <span>{cam.nome}</span>
                <Ponto cor={cam.status === "online" ? "#00e676" : "#555"} />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
'@

# ============================================================
# PLACAS PAGE
# ============================================================
$placasContent = @'
"use client";
import { useState } from "react";

const todasPlacas = [
  { id: 1, placa: "BRA7A23", estado: "SP", status: "Acesso Liberado", camera: "Entrada 01", hora: "14:32", data: "03/04/2024" },
  { id: 2, placa: "QWE456", estado: "RJ", status: "Negado", camera: "Portao 02", hora: "14:28", data: "03/04/2024" },
  { id: 3, placa: "JLK890", estado: "MG", status: "Acesso Liberado", camera: "Entrada 01", hora: "14:15", data: "03/04/2024" },
  { id: 4, placa: "ABC1D23", estado: "SP", status: "Acesso Liberado", camera: "Estacionamento 03", hora: "13:58", data: "03/04/2024" },
  { id: 5, placa: "XYZ9F87", estado: "PR", status: "Negado", camera: "Portao 02", hora: "13:45", data: "03/04/2024" },
];

export default function PlacasPage() {
  const [busca, setBusca] = useState("");
  const [filtro, setFiltro] = useState("todos");
  const filtradas = todasPlacas.filter(p => {
    const mb = p.placa.includes(busca.toUpperCase()) || p.camera.toLowerCase().includes(busca.toLowerCase());
    const mf = filtro === "todos" || (filtro === "liberado" && p.status === "Acesso Liberado") || (filtro === "negado" && p.status === "Negado");
    return mb && mf;
  });
  return (
    <div style={{ padding: 16 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
        <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 14, color: "#7ec8ff", letterSpacing: 2 }}>PLACAS / HISTORICO</div>
        <div style={{ display: "flex", gap: 8 }}>
          <input value={busca} onChange={e => setBusca(e.target.value)} placeholder="Buscar placa ou camera..."
            style={{ padding: "8px 12px", background: "rgba(0,0,0,0.3)", border: "1px solid rgba(0,160,255,0.2)", borderRadius: 6, color: "#e0e8f0", fontSize: 13, outline: "none", width: 240 }} />
          {[{k:"todos",l:"Todos"},{k:"liberado",l:"✓ Liberados"},{k:"negado",l:"✕ Negados"}].map(f => (
            <button key={f.k} onClick={() => setFiltro(f.k)} style={{ padding: "8px 14px", borderRadius: 6, cursor: "pointer", background: filtro === f.k ? "rgba(0,120,255,0.3)" : "rgba(0,0,0,0.3)", color: filtro === f.k ? "#7ec8ff" : "#5a7a9a", border: `1px solid ${filtro === f.k ? "rgba(0,160,255,0.4)" : "rgba(255,255,255,0.08)"}`, fontSize: 12, fontWeight: 600 }}>{f.l}</button>
          ))}
        </div>
      </div>
      <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, overflow: "hidden" }}>
        <div style={{ display: "grid", gridTemplateColumns: "140px 60px 1fr 140px 80px 60px 150px", padding: "8px 14px", borderBottom: "1px solid rgba(0,160,255,0.1)", fontSize: 10, color: "#4a6a8a", textTransform: "uppercase" }}>
          <span>Placa</span><span>Estado</span><span>Camera</span><span>Data</span><span>Hora</span><span></span><span>Status</span>
        </div>
        {filtradas.map(ev => {
          const ok = ev.status === "Acesso Liberado";
          return (
            <div key={ev.id} style={{ display: "grid", gridTemplateColumns: "140px 60px 1fr 140px 80px 60px 150px", padding: "10px 14px", borderBottom: "1px solid rgba(255,255,255,0.03)", alignItems: "center" }}>
              <span style={{ fontFamily: "'Orbitron', monospace", fontSize: 13, fontWeight: 700, color: "#c8e0f0", letterSpacing: 2 }}>{ev.placa}</span>
              <span style={{ background: "#009c3b", color: "#fff", fontSize: 9, fontWeight: 700, padding: "2px 5px", borderRadius: 3, display: "inline-block", width: "fit-content" }}>{ev.estado}</span>
              <span style={{ fontSize: 12, color: "#8ab0cc" }}>{ev.camera}</span>
              <span style={{ fontFamily: "'Share Tech Mono', monospace", fontSize: 11, color: "#5a7a9a" }}>{ev.data}</span>
              <span style={{ fontFamily: "'Share Tech Mono', monospace", fontSize: 11, color: "#5a7a9a" }}>{ev.hora}</span>
              <div style={{ width: 24, height: 24, borderRadius: 4, background: ok ? "rgba(0,77,32,0.5)" : "rgba(77,0,0,0.5)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: 12, color: ok ? "#00e676" : "#ff4444" }}>{ok ? "✓" : "✕"}</div>
              <span style={{ color: ok ? "#00e676" : "#ff4444", fontSize: 11, fontWeight: 600, background: ok ? "rgba(0,230,118,0.1)" : "rgba(255,68,68,0.1)", padding: "2px 8px", borderRadius: 4, border: `1px solid ${ok ? "rgba(0,230,118,0.3)" : "rgba(255,68,68,0.3)"}`, display: "inline-block", width: "fit-content" }}>{ev.status}</span>
            </div>
          );
        })}
        {filtradas.length === 0 && <div style={{ padding: 32, textAlign: "center", color: "#4a6a8a" }}>Nenhum resultado encontrado.</div>}
      </div>
    </div>
  );
}
'@

# ============================================================
# WHITELIST PAGE
# ============================================================
$whitelistContent = @'
"use client";
import { useState } from "react";

const listaInicial = [
  { id: 1, placa: "BRA7A23", nome: "Joao Silva", horario: "08:00 - 22:00", ativo: true },
  { id: 2, placa: "ABC1D23", nome: "Maria Santos", horario: "07:00 - 18:00", ativo: true },
  { id: 3, placa: "GHI8J90", nome: "Carlos Lima", horario: "00:00 - 23:59", ativo: true },
  { id: 4, placa: "DEF5G67", nome: "Ana Costa", horario: "09:00 - 17:00", ativo: false },
];

export default function WhitelistPage() {
  const [lista, setLista] = useState(listaInicial);
  const [modal, setModal] = useState(false);
  const [nova, setNova] = useState({ placa: "", nome: "", horario: "00:00 - 23:59" });

  function alternar(id: number) { setLista(l => l.map(i => i.id === id ? { ...i, ativo: !i.ativo } : i)); }
  function remover(id: number) { setLista(l => l.filter(i => i.id !== id)); }
  function adicionar() {
    if (!nova.placa || !nova.nome) return;
    setLista(l => [...l, { id: Date.now(), ...nova, ativo: true }]);
    setNova({ placa: "", nome: "", horario: "00:00 - 23:59" });
    setModal(false);
  }

  return (
    <div style={{ padding: 16 }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 16 }}>
        <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 14, color: "#7ec8ff", letterSpacing: 2 }}>WHITELIST / PLACAS LIBERADAS</div>
        <button onClick={() => setModal(true)} style={{ padding: "8px 16px", border: "none", borderRadius: 6, cursor: "pointer", background: "linear-gradient(135deg, #0066cc, #004499)", color: "#fff", fontFamily: "'Orbitron', monospace", fontSize: 11, fontWeight: 700, letterSpacing: 1, boxShadow: "0 0 16px rgba(0,100,200,0.3)" }}>+ ADICIONAR PLACA</button>
      </div>
      <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, overflow: "hidden" }}>
        <div style={{ display: "grid", gridTemplateColumns: "150px 1fr 160px 80px 120px", padding: "8px 14px", borderBottom: "1px solid rgba(0,160,255,0.1)", fontSize: 10, color: "#4a6a8a", textTransform: "uppercase" }}>
          <span>Placa</span><span>Nome</span><span>Horario</span><span>Ativo</span><span>Acoes</span>
        </div>
        {lista.map(item => (
          <div key={item.id} style={{ display: "grid", gridTemplateColumns: "150px 1fr 160px 80px 120px", padding: "10px 14px", borderBottom: "1px solid rgba(255,255,255,0.03)", alignItems: "center" }}>
            <span style={{ fontFamily: "'Orbitron', monospace", fontSize: 13, fontWeight: 700, color: "#c8e0f0", letterSpacing: 2 }}>{item.placa}</span>
            <span style={{ fontSize: 13, color: "#8ab0cc" }}>{item.nome}</span>
            <span style={{ fontFamily: "'Share Tech Mono', monospace", fontSize: 11, color: "#5a7a9a" }}>{item.horario}</span>
            <div onClick={() => alternar(item.id)} style={{ width: 40, height: 22, borderRadius: 11, cursor: "pointer", background: item.ativo ? "#00e676" : "#333", position: "relative", transition: "background 0.2s", boxShadow: item.ativo ? "0 0 10px rgba(0,230,118,0.4)" : "none" }}>
              <div style={{ position: "absolute", top: 3, left: item.ativo ? 21 : 3, width: 16, height: 16, borderRadius: "50%", background: "#fff", transition: "left 0.2s" }} />
            </div>
            <button onClick={() => remover(item.id)} style={{ padding: "4px 12px", border: "1px solid rgba(255,68,68,0.3)", borderRadius: 4, background: "rgba(255,68,68,0.1)", color: "#ff6666", fontSize: 11, cursor: "pointer", fontWeight: 600 }}>Remover</button>
          </div>
        ))}
      </div>
      {modal && (
        <div style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.7)", display: "flex", alignItems: "center", justifyContent: "center", zIndex: 100 }}>
          <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.25)", borderRadius: 12, padding: 28, width: 400, boxShadow: "0 0 40px rgba(0,100,200,0.2)" }}>
            <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 13, color: "#7ec8ff", marginBottom: 20 }}>NOVA PLACA</div>
            {[{l:"Placa",k:"placa",p:"ABC1D23"},{l:"Nome / Responsavel",k:"nome",p:"Nome do motorista"},{l:"Horario",k:"horario",p:"00:00 - 23:59"}].map(c => (
              <div key={c.k} style={{ marginBottom: 14 }}>
                <label style={{ fontSize: 10, color: "#5a7a9a", letterSpacing: 1, textTransform: "uppercase", display: "block", marginBottom: 5 }}>{c.l}</label>
                <input value={(nova as any)[c.k]} onChange={e => setNova(p => ({ ...p, [c.k]: e.target.value }))} placeholder={c.p}
                  style={{ width: "100%", padding: "8px 12px", background: "rgba(0,0,0,0.3)", border: "1px solid rgba(0,160,255,0.2)", borderRadius: 6, color: "#e0e8f0", fontSize: 13, fontFamily: c.k === "placa" ? "'Orbitron', monospace" : "inherit", outline: "none" }} />
              </div>
            ))}
            <div style={{ display: "flex", gap: 8 }}>
              <button onClick={() => setModal(false)} style={{ flex: 1, padding: 10, border: "1px solid rgba(255,255,255,0.1)", borderRadius: 6, background: "transparent", color: "#5a7a9a", cursor: "pointer", fontWeight: 600 }}>Cancelar</button>
              <button onClick={adicionar} style={{ flex: 1, padding: 10, border: "none", borderRadius: 6, background: "linear-gradient(135deg, #0066cc, #004499)", color: "#fff", cursor: "pointer", fontFamily: "'Orbitron', monospace", fontWeight: 700, fontSize: 11, letterSpacing: 1 }}>SALVAR</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
'@

# ============================================================
# CAMERAS PAGE
# ============================================================
$camerasContent = @'
"use client";
import { useState } from "react";

const cameras = [
  { id: 1, nome: "Entrada 01", serial: "FC-2024-001", ip: "192.168.1.101", status: "online", eventos: 47 },
  { id: 2, nome: "Portao 02", serial: "FC-2024-002", ip: "192.168.1.102", status: "online", eventos: 38 },
  { id: 3, nome: "Estacionamento 03", serial: "FC-2024-003", ip: "192.168.1.103", status: "online", eventos: 22 },
  { id: 4, nome: "Area Rural 04", serial: "FC-2024-004", ip: "192.168.1.104", status: "offline", eventos: 0 },
];

export default function CamerasPage() {
  const [sel, setSel] = useState<number | null>(null);
  return (
    <div style={{ padding: 16 }}>
      <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 14, color: "#7ec8ff", letterSpacing: 2, marginBottom: 16 }}>CAMERAS / MONITORAMENTO</div>
      <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 12 }}>
        {cameras.map(cam => (
          <div key={cam.id} onClick={() => setSel(sel === cam.id ? null : cam.id)} style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: `1px solid ${sel === cam.id ? "rgba(0,160,255,0.4)" : "rgba(0,160,255,0.15)"}`, borderRadius: 10, overflow: "hidden", cursor: "pointer", boxShadow: sel === cam.id ? "0 0 20px rgba(0,100,200,0.2)" : "none", transition: "all 0.2s" }}>
            <div style={{ height: 160, background: cam.status === "online" ? "linear-gradient(135deg, #0a1a2a, #0d2035)" : "linear-gradient(135deg, #111, #0a0a0a)", display: "flex", alignItems: "center", justifyContent: "center", position: "relative", fontSize: 48, color: cam.status === "online" ? "rgba(0,180,255,0.2)" : "rgba(255,255,255,0.05)" }}>
              📷
              {cam.status === "online" && (
                <div style={{ position: "absolute", top: 10, right: 10, display: "flex", alignItems: "center", gap: 4, background: "rgba(0,0,0,0.6)", padding: "3px 8px", borderRadius: 4, border: "1px solid rgba(255,50,50,0.4)" }}>
                  <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#ff3333", boxShadow: "0 0 6px #ff3333", animation: "blink 1.5s ease infinite" }} />
                  <span style={{ fontSize: 9, color: "#ff7777", fontWeight: 700, letterSpacing: 1, fontFamily: "'Orbitron', monospace" }}>AO VIVO</span>
                </div>
              )}
              {cam.status === "offline" && (
                <div style={{ position: "absolute", inset: 0, display: "flex", alignItems: "center", justifyContent: "center", background: "rgba(0,0,0,0.5)", fontSize: 13, color: "#ff4444", fontFamily: "'Orbitron', monospace", letterSpacing: 2 }}>OFFLINE</div>
              )}
            </div>
            <div style={{ padding: "10px 14px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
                <span style={{ fontSize: 14, fontWeight: 600, color: "#c8e0f0" }}>{cam.nome}</span>
                <span style={{ fontSize: 10, padding: "2px 8px", borderRadius: 4, background: cam.status === "online" ? "rgba(0,230,118,0.1)" : "rgba(255,68,68,0.1)", color: cam.status === "online" ? "#00e676" : "#ff4444", border: `1px solid ${cam.status === "online" ? "rgba(0,230,118,0.3)" : "rgba(255,68,68,0.3)"}`, fontFamily: "'Orbitron', monospace" }}>{cam.status === "online" ? "ONLINE" : "OFFLINE"}</span>
              </div>
              <div style={{ display: "flex", gap: 16, fontSize: 11, color: "#5a7a9a", fontFamily: "'Share Tech Mono', monospace" }}>
                <span>SN: {cam.serial}</span><span>IP: {cam.ip}</span><span>Eventos: {cam.eventos}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
'@

# ============================================================
# ESCREVER ARQUIVOS
# ============================================================

# Criar diretorios
New-Item -ItemType Directory -Force -Path "$base\app\(auth)\login" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\app\(dashboard)\dashboard" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\app\(dashboard)\plates" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\app\(dashboard)\whitelist" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\app\(dashboard)\cameras" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\app\(dashboard)\reports" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\app\(dashboard)\settings" | Out-Null

# Salvar arquivos
$loginContent      | Set-Content -Path "$base\app\(auth)\login\page.tsx" -Encoding UTF8
$layoutContent     | Set-Content -Path "$base\app\(dashboard)\layout.tsx" -Encoding UTF8
$dashboardContent  | Set-Content -Path "$base\app\(dashboard)\dashboard\page.tsx" -Encoding UTF8
$placasContent     | Set-Content -Path "$base\app\(dashboard)\plates\page.tsx" -Encoding UTF8
$whitelistContent  | Set-Content -Path "$base\app\(dashboard)\whitelist\page.tsx" -Encoding UTF8
$camerasContent    | Set-Content -Path "$base\app\(dashboard)\cameras\page.tsx" -Encoding UTF8

# Reports e Settings
@'
export default function RelatoriosPage() {
  return (
    <div style={{ padding: 16 }}>
      <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 14, color: "#7ec8ff", letterSpacing: 2, marginBottom: 24 }}>RELATORIOS</div>
      <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, padding: 32, textAlign: "center", color: "#4a6a8a", fontSize: 13 }}>
        Modulo de relatorios em desenvolvimento...
      </div>
    </div>
  );
}
'@ | Set-Content -Path "$base\app\(dashboard)\reports\page.tsx" -Encoding UTF8

@'
export default function ConfiguracoesPage() {
  return (
    <div style={{ padding: 16 }}>
      <div style={{ fontFamily: "'Orbitron', monospace", fontSize: 14, color: "#7ec8ff", letterSpacing: 2, marginBottom: 24 }}>CONFIGURACOES</div>
      <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 10, padding: 32, textAlign: "center", color: "#4a6a8a", fontSize: 13 }}>
        Configuracoes em desenvolvimento...
      </div>
    </div>
  );
}
'@ | Set-Content -Path "$base\app\(dashboard)\settings\page.tsx" -Encoding UTF8

# page.tsx raiz - redireciona para login
@'
import { redirect } from "next/navigation";
export default function Home() { redirect("/login"); }
'@ | Set-Content -Path "$base\app\page.tsx" -Encoding UTF8

Write-Host ""
Write-Host "✅ Todos os arquivos criados com sucesso!" -ForegroundColor Green
Write-Host "▶  Agora rode: npm run dev" -ForegroundColor Cyan
