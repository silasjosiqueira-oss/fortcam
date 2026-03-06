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
  return <button onClick={ativar} disabled={status==="loading"} style={{ padding:"4px 10px", border:"1px solid rgba(0,160,255,0.3)", borderRadius:6, background:"rgba(0,100,200,0.15)", color:"#7ec8ff", fontSize:11, cursor:"pointer" }}>{status==="loading"?"...":"🔔 Notificacoes"}</button>;
}const navItems = [
  { label: "Painel", path: "/dashboard" },
  { label: "Placas", path: "/plates" },
  { label: "Whitelist", path: "/whitelist" },
  { label: "Cameras", path: "/cameras" },
  { label: "Portoes", path: "/portoes" },
  { label: "Relatorios", path: "/reports" },
  { label: "Configuracoes", path: "/settings" },
];

const rotulos: Record<string,string> = {
  "/dashboard": "PAINEL / VISAO GERAL",
  "/plates": "PLACAS / HISTORICO",
  "/whitelist": "WHITELIST / LIBERADOS",
  "/cameras": "CAMERAS / MONITORAMENTO",
  "/portoes": "PORTOES / BARREIRAS",
  "/reports": "RELATORIOS",
  "/settings": "CONFIGURACOES",
};

const globalStyle = `@keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}`;export default function DashboardLayout({ children }: { children: React.ReactNode }) {
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
      <style dangerouslySetInnerHTML={{ __html: globalStyle }} />

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
          <div style={{ display:"flex", alignItems:"center", gap:12 }}>
            <PushButton />
            <div style={{ fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace" }}>{user?.role?.toUpperCase()}</div>
          </div>
        </div>
        <div style={{ flex:1, overflowY:"auto" }}>{children}</div>
      </div>
    </div>
  );
}