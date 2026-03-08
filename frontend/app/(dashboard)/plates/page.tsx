"use client";
import { useState, useEffect } from "react";
import { eventsAPI } from "@/lib/api";
import api from "@/lib/api";

export default function PlacasPage() {
  const [eventos, setEventos] = useState<any[]>([]);
  const [busca, setBusca] = useState("");
  const [filtro, setFiltro] = useState("todos");
  const [loading, setLoading] = useState(true);
  const [fotoModal, setFotoModal] = useState<any>(null);
  const [fotoLoading, setFotoLoading] = useState(false);

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const res = await eventsAPI.list({ limit: 100 });
      setEventos(res.data);
    } finally { setLoading(false); }
  }

  async function verFoto(ev: any) {
    setFotoLoading(true);
    setFotoModal({ ...ev, image_b64: null });
    try {
      const res = await api.get(`/api/v1/events/${ev.id}/photo`);
      setFotoModal({ ...ev, image_b64: res.data.image_b64 });
    } catch {
      setFotoModal({ ...ev, image_b64: null });
    } finally { setFotoLoading(false); }
  }

  const filtrados = eventos.filter(ev => {
    const mb = ev.plate.includes(busca.toUpperCase()) || (ev.camera_name||"").toLowerCase().includes(busca.toLowerCase());
    const mf = filtro === "todos" || (filtro === "liberado" && ev.status === "granted") || (filtro === "negado" && ev.status === "denied");
    return mb && mf;
  });

  return (
    <div style={{ padding:16 }}>
      <style>{`
        @media (max-width: 600px) {
          .placas-header { flex-direction: column !important; gap: 10px !important; }
          .placas-filters { flex-wrap: wrap !important; }
          .placas-busca { width: 100% !important; }
          .placas-row-desktop { display: none !important; }
          .placas-row-mobile { display: flex !important; }
          .placas-header-row { display: none !important; }
        }
        .placas-row-mobile { display: none; }
      `}</style>

      {/* Header */}
      <div className="placas-header" style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16, gap:8 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>PLACAS / HISTORICO</div>
        <div className="placas-filters" style={{ display:"flex", gap:8 }}>
          <input className="placas-busca" value={busca} onChange={e=>setBusca(e.target.value)} placeholder="Buscar placa..."
            style={{ padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", width:200 }} />
          {[{k:"todos",l:"Todos"},{k:"liberado",l:"✅"},{k:"negado",l:"❌"}].map(f=>(
            <button key={f.k} onClick={()=>setFiltro(f.k)} style={{ padding:"8px 12px", borderRadius:6, cursor:"pointer", background:filtro===f.k?"rgba(0,120,255,0.3)":"rgba(0,0,0,0.3)", color:filtro===f.k?"#7ec8ff":"#5a7a9a", border:`1px solid ${filtro===f.k?"rgba(0,160,255,0.4)":"rgba(255,255,255,0.08)"}`, fontSize:12, fontWeight:600, whiteSpace:"nowrap" }}>{f.l}</button>
          ))}
        </div>
      </div>

      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>

        {/* Desktop header row */}
        <div className="placas-header-row" style={{ display:"grid", gridTemplateColumns:"32px 80px 130px 1fr 170px 110px", padding:"8px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:10, color:"#4a6a8a", textTransform:"uppercase" }}>
          <span/><span>Foto</span><span>Placa</span><span>Camera</span><span>Data/Hora</span><span>Status</span>
        </div>

        {loading && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loading && filtrados.length === 0 && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Nenhum evento encontrado.</div>}

        {filtrados.map(ev => {
          const ok = ev.status === "granted";
          return (
            <div key={ev.id}>
              {/* Desktop row */}
              <div className="placas-row-desktop" style={{ display:"grid", gridTemplateColumns:"32px 80px 130px 1fr 170px 110px", padding:"8px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
                <div style={{ width:22, height:22, borderRadius:4, background:ok?"rgba(0,77,32,0.5)":"rgba(77,0,0,0.5)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:11, color:ok?"#00e676":"#ff4444", fontWeight:700 }}>{ok?"V":"X"}</div>
                <button onClick={()=>verFoto(ev)} style={{ width:66, height:38, borderRadius:4, background:"rgba(0,100,200,0.15)", border:"1px solid rgba(0,160,255,0.2)", cursor:"pointer", color:"#7ec8ff", fontSize:11 }}>📷 Ver</button>
                <span style={{ fontFamily:"'Orbitron',monospace", fontSize:13, fontWeight:700, color:"#c8e0f0", letterSpacing:2 }}>{ev.plate}</span>
                <span style={{ fontSize:12, color:"#8ab0cc" }}>{ev.camera_name || "---"}</span>
                <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#5a7a9a" }}>{new Date(ev.detected_at).toLocaleString("pt-BR")}</span>
                <span style={{ color:ok?"#00e676":"#ff4444", fontSize:11, fontWeight:600, background:ok?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", padding:"2px 8px", borderRadius:4, border:`1px solid ${ok?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, display:"inline-block" }}>{ok?"Liberado":"Negado"}</span>
              </div>

              {/* Mobile row - card style */}
              <div className="placas-row-mobile" style={{ flexDirection:"column", padding:"12px 14px", borderBottom:"1px solid rgba(255,255,255,0.04)", gap:8 }}>
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                  <span style={{ fontFamily:"'Orbitron',monospace", fontSize:16, fontWeight:700, color:"#c8e0f0", letterSpacing:2 }}>{ev.plate}</span>
                  <span style={{ color:ok?"#00e676":"#ff4444", fontSize:11, fontWeight:600, background:ok?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", padding:"3px 10px", borderRadius:4, border:`1px solid ${ok?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}` }}>{ok?"✅ Liberado":"❌ Negado"}</span>
                </div>
                <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between" }}>
                  <span style={{ fontSize:12, color:"#8ab0cc" }}>📷 {ev.camera_name || "---"}</span>
                  <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:10, color:"#5a7a9a" }}>{new Date(ev.detected_at).toLocaleString("pt-BR")}</span>
                </div>
                <button onClick={()=>verFoto(ev)} style={{ alignSelf:"flex-start", padding:"6px 14px", borderRadius:4, background:"rgba(0,100,200,0.15)", border:"1px solid rgba(0,160,255,0.2)", cursor:"pointer", color:"#7ec8ff", fontSize:12 }}>📷 Ver foto</button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Modal foto */}
      {fotoModal && (
        <div onClick={()=>setFotoModal(null)} style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.92)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100, cursor:"pointer", padding:16 }}>
          <div onClick={e=>e.stopPropagation()} style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:16, width:"100%", maxWidth:660 }}>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:12 }}>
              <div style={{ fontFamily:"'Orbitron',monospace", fontSize:15, color:"#7ec8ff", letterSpacing:2 }}>{fotoModal.plate}</div>
              <div style={{ fontSize:11, color:fotoModal.status==="granted"?"#00e676":"#ff4444", fontWeight:600, padding:"3px 10px", borderRadius:4, background:fotoModal.status==="granted"?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", border:`1px solid ${fotoModal.status==="granted"?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}` }}>{fotoModal.status==="granted"?"LIBERADO":"NEGADO"}</div>
            </div>
            {fotoLoading && <div style={{ height:160, display:"flex", alignItems:"center", justifyContent:"center", color:"#4a6a8a" }}>Carregando...</div>}
            {!fotoLoading && fotoModal.image_b64 && (
              <img src={fotoModal.image_b64.startsWith("data:") ? fotoModal.image_b64 : `data:image/jpeg;base64,${fotoModal.image_b64}`}
                style={{ width:"100%", borderRadius:8, border:"1px solid rgba(0,160,255,0.15)", maxHeight:400, objectFit:"contain" }} />
            )}
            {!fotoLoading && !fotoModal.image_b64 && <div style={{ height:160, display:"flex", alignItems:"center", justifyContent:"center", color:"#4a6a8a" }}>Sem foto</div>}
            <div style={{ marginTop:10, fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace", display:"flex", justifyContent:"space-between", flexWrap:"wrap", gap:4 }}>
              <span>Cam: {fotoModal.camera_name}</span>
              <span>{new Date(fotoModal.detected_at).toLocaleString("pt-BR")}</span>
            </div>
            <button onClick={()=>setFotoModal(null)} style={{ width:"100%", marginTop:12, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Fechar</button>
          </div>
        </div>
      )}
    </div>
  );
}
