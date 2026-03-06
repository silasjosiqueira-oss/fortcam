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
            <input type="password" value={password} onChange={e=>setPassword(e.target.value)} placeholder="â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢" required
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