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
  const [lastPhoto, setLastPhoto] = useState<string|null>(null);
  const [lastEventId, setLastEventId] = useState<number|null>(null);

  useEffect(() => {
    const t = setInterval(() => setRelogio(new Date()), 1000);
    carregarDados();
    const r = setInterval(carregarDados, 10000);
    return () => { clearInterval(t); clearInterval(r); };
  }, []);

  // Busca foto automaticamente quando chega novo evento
  useEffect(() => {
    if (lastEvent && lastEvent.id !== lastEventId) {
      setLastEventId(lastEvent.id);
      setLastPhoto(null);
      // Se já vem image_url direto no evento, usa direto
      if (lastEvent.image_url) {
        setLastPhoto(lastEvent.image_url);
        return;
      }
      // Senão busca no endpoint de foto
      import("@/lib/api").then(({ default: api }) => {
        api.get(`/api/v1/events/${lastEvent.id}/photo`)
          .then(res => {
            if (res.data.image_url) {
              setLastPhoto(res.data.image_url);
            } else if (res.data.image_b64) {
              const b64 = res.data.image_b64;
              setLastPhoto(b64.startsWith("data:") ? b64 : `data:image/jpeg;base64,${b64}`);
            }
          })
          .catch(() => setLastPhoto(null));
      });
    }
  }, [lastEvent]);

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
          <div style={{ position:"relative", height:180, background:"linear-gradient(135deg,#0a1a2a,#0d2035)", display:"flex", alignItems:"center", justifyContent:"center", overflow:"hidden" }}>

            {/* Foto real se disponível */}
            {lastPhoto ? (
              <img src={lastPhoto} alt="Ultima placa" style={{ width:"100%", height:"100%", objectFit:"cover", opacity:0.85 }} />
            ) : (
              <>
                {[{top:10,left:10},{top:10,right:10},{bottom:10,left:10},{bottom:10,right:10}].map((pos,i)=>(
                  <div key={i} style={{ position:"absolute", ...pos, width:20, height:20, borderTop:i<2?"2px solid rgba(0,180,255,0.6)":"none", borderBottom:i>=2?"2px solid rgba(0,180,255,0.6)":"none", borderLeft:i%2===0?"2px solid rgba(0,180,255,0.6)":"none", borderRight:i%2===1?"2px solid rgba(0,180,255,0.6)":"none" }} />
                ))}
                <div style={{ fontSize:40, opacity:0.1, color:"#00bfff", fontFamily:"'Orbitron',monospace" }}>[CAM]</div>
              </>
            )}

            {/* Badge AO VIVO */}
            <div style={{ position:"absolute", top:10, right:10, display:"flex", alignItems:"center", gap:4, background:"rgba(0,0,0,0.7)", padding:"3px 8px", borderRadius:4, border:"1px solid rgba(255,50,50,0.4)", backdropFilter:"blur(4px)" }}>
              <div style={{ width:6, height:6, borderRadius:"50%", background:"#ff3333", boxShadow:"0 0 6px #ff3333", animation:"blink 1.5s ease infinite" }} />
              <span style={{ fontSize:9, color:"#ff7777", fontWeight:700, letterSpacing:1, fontFamily:"'Orbitron',monospace" }}>AO VIVO</span>
            </div>

            {/* Badge status liberado/negado */}
            {lastEvent && (
              <div style={{ position:"absolute", top:10, left:10, background:lastEvent.status==="granted"?"rgba(0,180,60,0.8)":"rgba(200,0,0,0.8)", padding:"3px 8px", borderRadius:4, fontSize:9, color:"#fff", fontWeight:700, fontFamily:"'Orbitron',monospace", backdropFilter:"blur(4px)" }}>
                {lastEvent.status==="granted"?"✅ LIBERADO":"❌ NEGADO"}
              </div>
            )}

            {/* Placa + hora na base */}
            <div style={{ position:"absolute", bottom:0, left:0, right:0, background:"linear-gradient(transparent,rgba(0,0,0,0.92))", padding:"24px 16px 12px" }}>
              <div style={{ fontFamily:"'Orbitron',monospace", fontSize:26, fontWeight:900, color:"#fff", letterSpacing:4, textShadow:"0 2px 8px rgba(0,0,0,0.8)" }}>
                {lastEvent?.plate || "---"}
              </div>
              <div style={{ fontSize:11, color:"#7a9ab8", fontFamily:"'Share Tech Mono',monospace", marginTop:2 }}>
                {lastEvent ? `📷 ${lastEvent.camera_name || "---"}  ·  ${new Date(lastEvent.detected_at).toLocaleString("pt-BR")}` : "Nenhum evento"}
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