"use client";
import { useRouter, usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { useAuthStore } from "@/store/auth";
import api from "@/lib/api";

function PushButton() {
  const [status, setStatus] = useState<"idle"|"loading"|"granted"|"denied">("idle");
  useEffect(() => {
    if ("Notification" in window && Notification.permission === "granted") setStatus("granted");
  }, []);
  async function ativar() {
    setStatus("loading");
    try {
      const { data } = await api.get("/api/v1/push/vapid-key");
      const reg = await navigator.serviceWorker.ready;
      const keyBytes = Uint8Array.from(atob(data.public_key.replace(/-/g,"+").replace(/_/g,"/")), c => c.charCodeAt(0));
      const sub = await reg.pushManager.subscribe({ userVisibleOnly: true, applicationServerKey: keyBytes });
      const s = sub.toJSON();
      await api.post("/api/v1/push/subscribe", { endpoint: s.endpoint, p256dh: s.keys?.p256dh, auth: s.keys?.auth });
      setStatus("granted");
    } catch { setStatus("denied"); }
  }
  if (status === "granted") return <span style={{ fontSize:11, color:"#00e676" }}>🔔 Ativo</span>;
  return <button onClick={ativar} disabled={status==="loading"} style={{ padding:"4px 10px", border:"1px solid rgba(0,160,255,0.3)", borderRadius:6, background:"rgba(0,100,200,0.15)", color:"#7ec8ff", fontSize:11, cursor:"pointer" }}>{status==="loading"?"...":"🔔"}</button>;
}

const navItems = [
  { label: "Painel",       path: "/dashboard", icon: "📊" },
  { label: "Placas",       path: "/plates",    icon: "🚗" },
  { label: "Whitelist",    path: "/whitelist", icon: "✅" },
  { label: "Cameras",      path: "/cameras",   icon: "📷" },
  { label: "Portoes",      path: "/portoes",   icon: "🚦" },
  { label: "Relatorios",   path: "/reports",   icon: "📈" },
  { label: "Configuracoes",path: "/settings",  icon: "⚙️" },
];

const rotulos: Record<string,string> = {
  "/dashboard": "PAINEL",
  "/plates":    "PLACAS",
  "/whitelist": "WHITELIST",
  "/cameras":   "CAMERAS",
  "/portoes":   "PORTOES",
  "/reports":   "RELATORIOS",
  "/settings":  "CONFIGURACOES",
};

const globalStyle = `
  @keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}
  @keyframes slideDown{from{opacity:0;transform:translateY(-8px)}to{opacity:1;transform:translateY(0)}}

  /* Mobile nav bottom bar */
  .mobile-nav {
    display: none;
  }
  .desktop-sidebar {
    display: flex;
  }

  @media (max-width: 768px) {
    .desktop-sidebar { display: none !important; }
    .mobile-nav { display: flex !important; }
    .topbar-title { display: none !important; }
  }
`;

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const { user, token, logout, loadUser } = useAuthStore();
  const [menuOpen, setMenuOpen] = useState(false);

  useEffect(() => {
    if (!token) { router.push("/login"); return; }
    if (!user) loadUser();
  }, [token]);

  // Fecha menu ao navegar
  useEffect(() => { setMenuOpen(false); }, [pathname]);

  return (
    <div style={{ display:"flex", height:"100vh", width:"100vw", fontFamily:"'Rajdhani',sans-serif", background:"#080d14", color:"#e0e8f0", overflow:"hidden" }}>
      <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;700;900&family=Rajdhani:wght@400;500;600;700&family=Share+Tech+Mono&display=swap" rel="stylesheet" />
      <style dangerouslySetInnerHTML={{ __html: globalStyle }} />

      {/* ── Desktop Sidebar ── */}
      <div className="desktop-sidebar" style={{ width:200, flexShrink:0, background:"linear-gradient(180deg,#0a0f1a,#080d14)", borderRight:"1px solid rgba(0,160,255,0.15)", flexDirection:"column" }}>
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
                <span style={{ fontSize:14 }}>{item.icon}</span>
                {item.label}
              </div>
            );
          })}
        </nav>
        <div style={{ padding:"12px 16px", borderTop:"1px solid rgba(0,160,255,0.1)" }}>
          <div style={{ fontSize:11, color:"#5a7a9a", marginBottom:6 }}>{user?.name || "..."}</div>
          <div onClick={logout} style={{ fontSize:11, color:"#ff6644", cursor:"pointer", fontWeight:600 }}>Sair do sistema</div>
        </div>
      </div>

      {/* ── Main content ── */}
      <div style={{ flex:1, display:"flex", flexDirection:"column", overflow:"hidden", minWidth:0 }}>

        {/* Topbar */}
        <div style={{ height:52, flexShrink:0, background:"rgba(8,13,20,0.95)", borderBottom:"1px solid rgba(0,160,255,0.1)", display:"flex", alignItems:"center", justifyContent:"space-between", padding:"0 16px" }}>
          {/* Hamburger (mobile) */}
          <button onClick={()=>setMenuOpen(o=>!o)} style={{ display:"none", background:"none", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, padding:"6px 10px", color:"#7ec8ff", cursor:"pointer", fontSize:16 }}
            className="hamburger-btn">☰</button>

          <div className="topbar-title" style={{ fontFamily:"'Orbitron',monospace", fontSize:11, color:"#4a7aaa", letterSpacing:2 }}>{rotulos[pathname]||"PAINEL"}</div>

          <div style={{ display:"flex", alignItems:"center", gap:12 }}>
            <PushButton />
            <div style={{ fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace" }}>{user?.role?.toUpperCase()}</div>
          </div>
        </div>

        {/* Mobile dropdown menu */}
        {menuOpen && (
          <div style={{ position:"fixed", top:52, left:0, right:0, background:"#0a0f1a", borderBottom:"1px solid rgba(0,160,255,0.2)", zIndex:200, padding:"8px 0", animation:"slideDown 0.2s ease" }}>
            {navItems.map(item => {
              const active = pathname === item.path;
              return (
                <div key={item.path} onClick={()=>router.push(item.path)} style={{ display:"flex", alignItems:"center", gap:12, padding:"12px 20px", background:active?"rgba(0,120,255,0.15)":"transparent", color:active?"#7ec8ff":"#8ab0cc", fontSize:14, cursor:"pointer", borderLeft:active?"3px solid #0099ff":"3px solid transparent" }}>
                  <span>{item.icon}</span>{item.label}
                </div>
              );
            })}
            <div style={{ padding:"12px 20px", borderTop:"1px solid rgba(0,160,255,0.1)", marginTop:4 }}>
              <div style={{ fontSize:12, color:"#5a7a9a", marginBottom:4 }}>{user?.name}</div>
              <div onClick={logout} style={{ fontSize:12, color:"#ff6644", cursor:"pointer", fontWeight:600 }}>Sair do sistema</div>
            </div>
          </div>
        )}

        {/* Page content */}
        <div style={{ flex:1, overflowY:"auto", paddingBottom:70 }}>{children}</div>
      </div>

      {/* ── Mobile Bottom Nav ── */}
      <div className="mobile-nav" style={{ position:"fixed", bottom:0, left:0, right:0, height:60, background:"#0a0f1a", borderTop:"1px solid rgba(0,160,255,0.15)", zIndex:100, alignItems:"center", justifyContent:"space-around", padding:"0 4px" }}>
        {navItems.slice(0,5).map(item => {
          const active = pathname === item.path;
          return (
            <div key={item.path} onClick={()=>router.push(item.path)} style={{ display:"flex", flexDirection:"column", alignItems:"center", gap:2, padding:"6px 8px", flex:1, cursor:"pointer", color:active?"#7ec8ff":"#4a6a8a" }}>
              <span style={{ fontSize:18 }}>{item.icon}</span>
              <span style={{ fontSize:8, fontFamily:"'Share Tech Mono',monospace", letterSpacing:0.5 }}>{item.label.toUpperCase()}</span>
              {active && <div style={{ width:20, height:2, background:"#0099ff", borderRadius:1 }} />}
            </div>
          );
        })}
        <div onClick={()=>setMenuOpen(o=>!o)} style={{ display:"flex", flexDirection:"column", alignItems:"center", gap:2, padding:"6px 8px", flex:1, cursor:"pointer", color:menuOpen?"#7ec8ff":"#4a6a8a" }}>
          <span style={{ fontSize:18 }}>⋯</span>
          <span style={{ fontSize:8, fontFamily:"'Share Tech Mono',monospace" }}>MAIS</span>
        </div>
      </div>

      {/* hamburger visible on mobile via inline style override */}
      <style>{`
        @media (max-width: 768px) {
          .hamburger-btn { display: block !important; }
          .topbar-title { display: none !important; }
        }
      `}</style>
    </div>
  );
}
