"use client";
import { useState, useEffect } from "react";
import { eventsAPI, dashboardAPI } from "@/lib/api";

function BarChart({ data, maxVal, cor }: { data: { label: string; value: number }[]; maxVal: number; cor: string }) {
  return (
    <div style={{ display:"flex", alignItems:"flex-end", gap:4, height:100, padding:"0 4px", overflowX:"auto" }}>
      {data.map((d, i) => (
        <div key={i} style={{ flex:1, minWidth:18, display:"flex", flexDirection:"column", alignItems:"center", gap:2 }}>
          <span style={{ fontSize:8, color:"#5a7a9a", fontFamily:"'Orbitron',monospace" }}>{d.value||""}</span>
          <div style={{ width:"100%", background:`linear-gradient(180deg,${cor},${cor}88)`, borderRadius:"3px 3px 0 0", height: maxVal > 0 ? `${(d.value/maxVal)*80}px` : "2px", minHeight:2, boxShadow:`0 0 6px ${cor}44`, transition:"height 0.5s" }} />
          <span style={{ fontSize:7, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace", textAlign:"center", whiteSpace:"nowrap" }}>{d.label}</span>
        </div>
      ))}
    </div>
  );
}

export default function RelatoriosPage() {
  const [eventos, setEventos] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([eventsAPI.list({ limit: 200 }), dashboardAPI.stats()])
      .then(([e]) => { setEventos(e.data); })
      .finally(() => setLoading(false));
  }, []);

  const porHora = Array.from({ length: 24 }, (_, h) => ({
    label: `${h}h`,
    value: eventos.filter(e => new Date(e.detected_at).getHours() === h).length,
  }));
  const maxHora = Math.max(...porHora.map(d => d.value), 1);

  const camaras: Record<string, number> = {};
  eventos.forEach(e => { const c = e.camera_name || "Sem cam"; camaras[c] = (camaras[c] || 0) + 1; });
  const porCamera = Object.entries(camaras).map(([label, value]) => ({ label: label.split(" ")[0], value }));
  const maxCamera = Math.max(...porCamera.map(d => d.value), 1);

  const liberados = eventos.filter(e => e.status === "granted").length;
  const negados = eventos.filter(e => e.status === "denied").length;
  const total = eventos.length;
  const taxaLiber = total > 0 ? Math.round((liberados / total) * 100) : 0;

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <style>{`
        @media (max-width: 600px) {
          .rel-cards { grid-template-columns: repeat(2, 1fr) !important; }
          .rel-graficos { grid-template-columns: 1fr !important; }
          .rel-hist-row { grid-template-columns: 28px 120px 1fr 100px !important; }
          .rel-hist-col-hidden { display: none !important; }
        }
      `}</style>

      <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>RELATORIOS</div>

      {loading ? <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando...</div> : (
        <>
          {/* Cards */}
          <div className="rel-cards" style={{ display:"grid", gridTemplateColumns:"repeat(4,1fr)", gap:10 }}>
            {[
              { label:"Total", valor:total, cor:"#00bfff" },
              { label:"Liberados", valor:liberados, cor:"#00e676" },
              { label:"Negados", valor:negados, cor:"#ff4444" },
              { label:"Taxa", valor:`${taxaLiber}%`, cor:"#7ec8ff" },
            ].map((c,i) => (
              <div key={i} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"12px 14px", position:"relative", overflow:"hidden" }}>
                <div style={{ position:"absolute", top:0, left:0, right:0, height:2, background:`linear-gradient(90deg,transparent,${c.cor},transparent)` }} />
                <div style={{ fontSize:10, color:"#5a7a9a", marginBottom:4 }}>{c.label}</div>
                <div style={{ fontSize:24, fontWeight:700, fontFamily:"'Orbitron',monospace", color:c.cor }}>{c.valor}</div>
              </div>
            ))}
          </div>

          {/* Graficos */}
          <div className="rel-graficos" style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:12 }}>
            <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
              <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:12 }}>Por Hora</div>
              {total === 0 ? <div style={{ textAlign:"center", color:"#4a6a8a", fontSize:12, padding:24 }}>Sem dados</div> : <BarChart data={porHora} maxVal={maxHora} cor="#00bfff" />}
            </div>
            <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
              <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:12 }}>Por Camera</div>
              {porCamera.length === 0 ? <div style={{ textAlign:"center", color:"#4a6a8a", fontSize:12, padding:24 }}>Sem dados</div> : <BarChart data={porCamera} maxVal={maxCamera} cor="#00e676" />}
            </div>
          </div>

          {/* Barra liberados/negados */}
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
            <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:10 }}>Liberados vs Negados</div>
            <div style={{ display:"flex", gap:6, alignItems:"center", height:24, borderRadius:4, overflow:"hidden" }}>
              {liberados > 0 && <div style={{ flex:liberados, background:"linear-gradient(90deg,#00aa44,#00e676)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, color:"#fff", fontWeight:700 }}>{taxaLiber}%</div>}
              {negados > 0 && <div style={{ flex:negados, background:"linear-gradient(90deg,#cc2200,#ff4444)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, color:"#fff", fontWeight:700 }}>{100-taxaLiber}%</div>}
            </div>
            <div style={{ display:"flex", gap:16, marginTop:8 }}>
              <span style={{ fontSize:11, color:"#00e676" }}>✅ {liberados}</span>
              <span style={{ fontSize:11, color:"#ff4444" }}>❌ {negados}</span>
            </div>
          </div>

          {/* Historico */}
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
            <div style={{ padding:"10px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Historico</div>
            {eventos.slice(0,20).map(ev => {
              const ok = ev.status === "granted";
              return (
                <div key={ev.id} className="rel-hist-row" style={{ display:"grid", gridTemplateColumns:"28px 130px 1fr 140px 110px", padding:"8px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
                  <div style={{ width:22, height:22, borderRadius:4, background:ok?"rgba(0,77,32,0.5)":"rgba(77,0,0,0.5)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, color:ok?"#00e676":"#ff4444", fontWeight:700 }}>{ok?"V":"X"}</div>
                  <span style={{ fontFamily:"'Orbitron',monospace", fontSize:12, fontWeight:700, color:"#c8e0f0", letterSpacing:1 }}>{ev.plate}</span>
                  <span className="rel-hist-col-hidden" style={{ fontSize:11, color:"#6a8aa8" }}>{ev.camera_name||"---"}</span>
                  <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#5a7a9a" }}>{new Date(ev.detected_at).toLocaleString("pt-BR")}</span>
                  <span className="rel-hist-col-hidden" style={{ color:ok?"#00e676":"#ff4444", fontSize:11, background:ok?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", padding:"2px 8px", borderRadius:4, border:`1px solid ${ok?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, display:"inline-block" }}>{ok?"Liberado":"Negado"}</span>
                </div>
              );
            })}
          </div>
        </>
      )}
    </div>
  );
}
