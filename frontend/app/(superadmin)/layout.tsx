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