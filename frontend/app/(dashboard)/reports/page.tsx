"use client";
import { useState, useEffect } from "react";
import { eventsAPI, dashboardAPI } from "@/lib/api";

function BarChart({ data, maxVal, cor }: { data: { label: string; value: number }[]; maxVal: number; cor: string }) {
  return (
    <div style={{ display:"flex", alignItems:"flex-end", gap:6, height:120, padding:"0 4px" }}>
      {data.map((d, i) => (
        <div key={i} style={{ flex:1, display:"flex", flexDirection:"column", alignItems:"center", gap:4 }}>
          <span style={{ fontSize:9, color:"#5a7a9a", fontFamily:"'Orbitron',monospace" }}>{d.value}</span>
          <div style={{ width:"100%", background:`linear-gradient(180deg,${cor},${cor}88)`, borderRadius:"3px 3px 0 0", height: maxVal > 0 ? `${(d.value/maxVal)*90}px` : "2px", minHeight:2, boxShadow:`0 0 8px ${cor}44`, transition:"height 0.5s" }} />
          <span style={{ fontSize:8, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace", textAlign:"center" }}>{d.label}</span>
        </div>
      ))}
    </div>
  );
}

export default function RelatoriosPage() {
  const [eventos, setEventos] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([eventsAPI.list({ limit: 200 }), dashboardAPI.stats()])
      .then(([e, s]) => { setEventos(e.data); setStats(s.data); })
      .finally(() => setLoading(false));
  }, []);

  // Acessos por hora
  const porHora = Array.from({ length: 24 }, (_, h) => ({
    label: `${h}h`,
    value: eventos.filter(e => new Date(e.detected_at).getHours() === h).length,
  }));
  const maxHora = Math.max(...porHora.map(d => d.value), 1);

  // Por camera
  const camaras: Record<string, number> = {};
  eventos.forEach(e => { const c = e.camera_name || "Sem camera"; camaras[c] = (camaras[c] || 0) + 1; });
  const porCamera = Object.entries(camaras).map(([label, value]) => ({ label: label.split(" ")[0], value }));
  const maxCamera = Math.max(...porCamera.map(d => d.value), 1);

  const liberados = eventos.filter(e => e.status === "granted").length;
  const negados = eventos.filter(e => e.status === "denied").length;
  const total = eventos.length;
  const taxaLiber = total > 0 ? Math.round((liberados / total) * 100) : 0;

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>RELATORIOS / ANALISE</div>

      {loading ? <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando...</div> : (
        <>
          {/* Cards resumo */}
          <div style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:12 }}>
            {[
              { label:"Total de Eventos", valor:total, cor:"#00bfff" },
              { label:"Acessos Liberados", valor:liberados, cor:"#00e676" },
              { label:"Acessos Negados", valor:negados, cor:"#ff4444" },
              { label:"Taxa de Liberacao", valor:`${taxaLiber}%`, cor:"#7ec8ff" },
            ].map((c,i) => (
              <div key={i} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px", position:"relative", overflow:"hidden" }}>
                <div style={{ position:"absolute", top:0, left:0, right:0, height:2, background:`linear-gradient(90deg,transparent,${c.cor},transparent)` }} />
                <div style={{ fontSize:11, color:"#5a7a9a", marginBottom:6 }}>{c.label}</div>
                <div style={{ fontSize:28, fontWeight:700, fontFamily:"'Orbitron',monospace", color:c.cor }}>{c.valor}</div>
              </div>
            ))}
          </div>

          {/* Graficos */}
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:12 }}>
            <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
              <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:16 }}>Acessos por Hora</div>
              {total === 0 ? <div style={{ textAlign:"center", color:"#4a6a8a", fontSize:12, padding:32 }}>Sem dados ainda</div> : <BarChart data={porHora} maxVal={maxHora} cor="#00bfff" />}
            </div>
            <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
              <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:16 }}>Acessos por Camera</div>
              {porCamera.length === 0 ? <div style={{ textAlign:"center", color:"#4a6a8a", fontSize:12, padding:32 }}>Sem dados ainda</div> : <BarChart data={porCamera} maxVal={maxCamera} cor="#00e676" />}
            </div>
          </div>

          {/* Liberados vs Negados */}
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
            <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:12 }}>Liberados vs Negados</div>
            <div style={{ display:"flex", gap:8, alignItems:"center" }}>
              <div style={{ flex: liberados || 1, height:24, background:"linear-gradient(90deg,#00aa44,#00e676)", borderRadius:"4px 0 0 4px", display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, color:"#fff", fontWeight:700, fontFamily:"'Orbitron',monospace" }}>{liberados > 0 ? `${taxaLiber}%` : ""}</div>
              <div style={{ flex: negados || 1, height:24, background:"linear-gradient(90deg,#cc2200,#ff4444)", borderRadius:"0 4px 4px 0", display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, color:"#fff", fontWeight:700, fontFamily:"'Orbitron',monospace" }}>{negados > 0 ? `${100-taxaLiber}%` : ""}</div>
            </div>
            <div style={{ display:"flex", gap:20, marginTop:8 }}>
              <span style={{ fontSize:11, color:"#00e676" }}>Liberados: {liberados}</span>
              <span style={{ fontSize:11, color:"#ff4444" }}>Negados: {negados}</span>
            </div>
          </div>

          {/* Ultimos eventos */}
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ padding:"10px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Historico Completo</div>
            {eventos.slice(0,20).map(ev => {
              const ok = ev.status === "granted";
              return (
                <div key={ev.id} style={{ display:"grid", gridTemplateColumns:"36px 140px 1fr 200px 150px", padding:"8px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
                  <div style={{ width:24, height:24, borderRadius:4, background:ok?"rgba(0,77,32,0.5)":"rgba(77,0,0,0.5)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:12, color:ok?"#00e676":"#ff4444", fontWeight:700 }}>{ok?"V":"X"}</div>
                  <span style={{ fontFamily:"'Orbitron',monospace", fontSize:12, fontWeight:700, color:"#c8e0f0", letterSpacing:2 }}>{ev.plate}</span>
                  <span style={{ fontSize:11, color:"#6a8aa8" }}>{ev.camera_name||"---"}</span>
                  <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#5a7a9a" }}>{new Date(ev.detected_at).toLocaleString("pt-BR")}</span>
                  <span style={{ color:ok?"#00e676":"#ff4444", fontSize:11, background:ok?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", padding:"2px 8px", borderRadius:4, border:`1px solid ${ok?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, display:"inline-block" }}>{ok?"Liberado":"Negado"}</span>
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}