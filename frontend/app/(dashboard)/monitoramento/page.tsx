"use client";
import { useState, useEffect, useRef, useCallback } from "react";
import api from "@/lib/api";

const inputStyle: React.CSSProperties = { width:"100%", padding:"10px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" };
const labelStyle: React.CSSProperties = { fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:4 };

// ── Player de câmera individual ────────────────────────────────────────────
function CameraPlayer({ cam, fullscreen, onFullscreen }: { cam: any; fullscreen: boolean; onFullscreen: () => void }) {
  const [snapshot, setSnapshot] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [erro, setErro] = useState(false);
  const intervalRef = useRef<any>(null);

  const carregar = useCallback(async () => {
    try {
      const { data } = await api.get(`/api/v1/cameras/${cam.id}/snapshot`);
      setSnapshot(data);
      setErro(false);
    } catch {
      setErro(true);
    } finally {
      setLoading(false);
    }
  }, [cam.id]);

  useEffect(() => {
    carregar();
    // Refresh automático dependendo do tipo
    const interval = snapshot?.type === "mjpeg" ? null :
                     snapshot?.type === "hls"   ? null :
                     15000; // snapshot/base64: atualiza a cada 15s
    if (interval) {
      intervalRef.current = setInterval(carregar, interval);
    }
    return () => { if (intervalRef.current) clearInterval(intervalRef.current); };
  }, [carregar]);

  const height = fullscreen ? "calc(100vh - 120px)" : 200;

  return (
    <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:`1px solid ${cam.is_online?"rgba(0,160,255,0.2)":"rgba(255,255,255,0.05)"}`, borderRadius:10, overflow:"hidden", display:"flex", flexDirection:"column" }}>
      {/* Header */}
      <div style={{ height:40, background:cam.is_online?"linear-gradient(135deg,#0a1a2a,#0d2035)":"linear-gradient(135deg,#111,#0a0a0a)", display:"flex", alignItems:"center", justifyContent:"space-between", padding:"0 12px", flexShrink:0 }}>
        <div style={{ display:"flex", alignItems:"center", gap:8 }}>
          <div style={{ width:6, height:6, borderRadius:"50%", background:cam.is_online?"#00e676":"#555", boxShadow:cam.is_online?"0 0 6px #00e676":"none" }} />
          <span style={{ fontSize:11, color:cam.is_online?"#7ec8ff":"#4a6a8a", fontFamily:"'Orbitron',monospace", letterSpacing:1 }}>{cam.name}</span>
        </div>
        <div style={{ display:"flex", alignItems:"center", gap:6 }}>
          {snapshot?.plate && <span style={{ fontSize:9, fontFamily:"'Orbitron',monospace", color:"#ffcc44", background:"rgba(255,200,0,0.1)", padding:"2px 6px", borderRadius:3, border:"1px solid rgba(255,200,0,0.3)" }}>{snapshot.plate}</span>}
          <span style={{ fontSize:9, color:"#4a6a8a", fontFamily:"'Share Tech Mono',monospace" }}>{(snapshot?.type||"").toUpperCase()}</span>
          <button onClick={onFullscreen} style={{ background:"none", border:"1px solid rgba(0,160,255,0.2)", borderRadius:4, color:"#7ec8ff", fontSize:11, cursor:"pointer", padding:"2px 6px" }}>
            {fullscreen ? "⊠" : "⊞"}
          </button>
          <button onClick={carregar} style={{ background:"none", border:"1px solid rgba(0,160,255,0.2)", borderRadius:4, color:"#7ec8ff", fontSize:11, cursor:"pointer", padding:"2px 6px" }}>↻</button>
        </div>
      </div>

      {/* Player area */}
      <div style={{ position:"relative", height, background:"#050a0f", display:"flex", alignItems:"center", justifyContent:"center", overflow:"hidden", flexShrink:0 }}>
        {/* Cantos estilo câmera */}
        {[{top:8,left:8},{top:8,right:8},{bottom:8,left:8},{bottom:8,right:8}].map((pos,i)=>(
          <div key={i} style={{ position:"absolute", ...pos, width:14, height:14,
            borderTop:i<2?"1px solid rgba(0,180,255,0.4)":"none",
            borderBottom:i>=2?"1px solid rgba(0,180,255,0.4)":"none",
            borderLeft:i%2===0?"1px solid rgba(0,180,255,0.4)":"none",
            borderRight:i%2===1?"1px solid rgba(0,180,255,0.4)":"none",
            zIndex:2, pointerEvents:"none"
          }} />
        ))}

        {/* Badge REC */}
        {cam.is_online && (
          <div style={{ position:"absolute", top:8, right:28, display:"flex", alignItems:"center", gap:3, background:"rgba(0,0,0,0.7)", padding:"2px 6px", borderRadius:3, zIndex:2 }}>
            <div style={{ width:5, height:5, borderRadius:"50%", background:"#ff3333", animation:"blink 1.5s ease infinite" }} />
            <span style={{ fontSize:8, color:"#ff7777", fontFamily:"'Orbitron',monospace" }}>REC</span>
          </div>
        )}

        {/* Timestamp */}
        <div style={{ position:"absolute", bottom:6, left:10, fontSize:9, color:"rgba(0,180,255,0.5)", fontFamily:"'Share Tech Mono',monospace", zIndex:2 }}>
          {snapshot?.detected_at ? new Date(snapshot.detected_at).toLocaleString("pt-BR") : new Date().toLocaleString("pt-BR")}
        </div>

        {loading && (
          <div style={{ color:"#4a6a8a", fontSize:11, fontFamily:"'Share Tech Mono',monospace" }}>Carregando...</div>
        )}

        {!loading && erro && (
          <div style={{ textAlign:"center", color:"#4a6a8a" }}>
            <div style={{ fontSize:28, marginBottom:6, opacity:0.3 }}>📷</div>
            <div style={{ fontSize:10, fontFamily:"'Orbitron',monospace", letterSpacing:1 }}>SEM SINAL</div>
          </div>
        )}

        {/* MJPEG — stream direto via <img> */}
        {!loading && !erro && snapshot?.type === "mjpeg" && snapshot.url && (
          <img src={snapshot.url} style={{ width:"100%", height:"100%", objectFit:"cover" }} onError={()=>setErro(true)} />
        )}

        {/* HLS — via video tag */}
        {!loading && !erro && snapshot?.type === "hls" && snapshot.url && (
          <VideoHLS url={snapshot.url} height={height as number} />
        )}

        {/* URL de imagem / snapshot HTTP */}
        {!loading && !erro && snapshot?.type === "url" && snapshot.url && (
          <img src={snapshot.url} style={{ width:"100%", height:"100%", objectFit:"cover" }} onError={()=>setErro(true)} />
        )}

        {/* Base64 — última foto do webhook */}
        {!loading && !erro && snapshot?.type === "base64" && snapshot.data && (
          <img src={snapshot.data} style={{ width:"100%", height:"100%", objectFit:"cover" }} />
        )}

        {/* Sem stream configurado */}
        {!loading && !erro && snapshot?.type === "none" && (
          <div style={{ textAlign:"center", color:"#4a6a8a" }}>
            <div style={{ fontSize:28, marginBottom:6, opacity:0.3 }}>📷</div>
            <div style={{ fontSize:10, fontFamily:"'Orbitron',monospace", letterSpacing:1, marginBottom:4 }}>SEM STREAM</div>
            <div style={{ fontSize:9, color:"#3a5a78" }}>Configure a URL de stream</div>
          </div>
        )}
      </div>

      {/* Footer */}
      <div style={{ padding:"6px 12px", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
        <span style={{ fontSize:9, color:"#3a5a78", fontFamily:"'Share Tech Mono',monospace" }}>
          {cam.location || cam.serial}
        </span>
        <span style={{ fontSize:9, color:cam.is_online?"#00e676":"#ff4444", fontFamily:"'Orbitron',monospace" }}>
          {cam.is_online ? "ONLINE" : "OFFLINE"}
        </span>
      </div>
    </div>
  );
}

// ── Player HLS via video nativo ────────────────────────────────────────────
function VideoHLS({ url, height }: { url: string; height: number }) {
  const ref = useRef<HTMLVideoElement>(null);
  useEffect(() => {
    const v = ref.current;
    if (!v) return;
    // Tenta HLS.js se disponível
    if (typeof window !== "undefined" && (window as any).Hls?.isSupported?.()) {
      const Hls = (window as any).Hls;
      const hls = new Hls();
      hls.loadSource(url);
      hls.attachMedia(v);
      return () => hls.destroy();
    }
    // Fallback: video nativo (Safari suporta HLS nativamente)
    v.src = url;
  }, [url]);
  return <video ref={ref} autoPlay muted playsInline style={{ width:"100%", height:"100%", objectFit:"cover" }} />;
}

// ── Modal de configuração de stream ───────────────────────────────────────
function StreamModal({ cam, onClose, onSaved }: { cam: any; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({
    stream_url: cam.stream_url || "",
    stream_type: cam.stream_type || "rtsp",
    snapshot_url: cam.snapshot_url || "",
  });
  const [saving, setSaving] = useState(false);
  const [msg, setMsg] = useState("");

  async function salvar() {
    setSaving(true);
    try {
      await api.put(`/api/v1/cameras/${cam.id}`, { ...cam, ...form });
      setMsg("✅ Salvo!");
      setTimeout(() => { onSaved(); onClose(); }, 800);
    } catch {
      setMsg("❌ Erro ao salvar");
    } finally {
      setSaving(false);
    }
  }

  const tipos = [
    { value:"rtsp",     label:"RTSP (câmera IP)",        placeholder:"rtsp://admin:senha@192.168.1.100:554/stream" },
    { value:"hls",      label:"HLS / M3U8",              placeholder:"https://servidor.com/live/stream.m3u8" },
    { value:"mjpeg",    label:"MJPEG (stream HTTP)",      placeholder:"http://192.168.1.100/video.mjpeg" },
    { value:"snapshot", label:"Snapshot (foto periódica)",placeholder:"http://192.168.1.100/snapshot.jpg" },
    { value:"webrtc",   label:"WebRTC",                   placeholder:"https://servidor.com/webrtc/stream" },
  ];
  const tipoAtual = tipos.find(t => t.value === form.stream_type) || tipos[0];

  return (
    <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.85)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:200, padding:16 }}>
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:20, width:"100%", maxWidth:480 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:16, paddingBottom:10, borderBottom:"1px solid rgba(0,160,255,0.1)" }}>
          📡 STREAM — {cam.name}
        </div>

        <div style={{ marginBottom:14 }}>
          <label style={labelStyle}>Tipo de Stream</label>
          <select value={form.stream_type} onChange={e=>setForm(p=>({...p,stream_type:e.target.value}))} style={inputStyle}>
            {tipos.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
          </select>
        </div>

        <div style={{ marginBottom:14 }}>
          <label style={labelStyle}>URL do Stream</label>
          <input value={form.stream_url} onChange={e=>setForm(p=>({...p,stream_url:e.target.value}))}
            placeholder={tipoAtual.placeholder} style={inputStyle} />
          {form.stream_type === "rtsp" && (
            <div style={{ marginTop:6, padding:"8px 10px", background:"rgba(255,170,0,0.08)", border:"1px solid rgba(255,170,0,0.2)", borderRadius:6, fontSize:10, color:"#ffaa44" }}>
              ⚠️ RTSP não funciona diretamente no browser. Use HLS ou MJPEG para visualização web, ou configure um proxy de stream.
            </div>
          )}
        </div>

        <div style={{ marginBottom:14 }}>
          <label style={labelStyle}>URL de Snapshot (opcional)</label>
          <input value={form.snapshot_url} onChange={e=>setForm(p=>({...p,snapshot_url:e.target.value}))}
            placeholder="http://192.168.1.100/snapshot.jpg" style={inputStyle} />
          <div style={{ fontSize:10, color:"#4a6a8a", marginTop:4 }}>Se preenchida, exibe esta foto periodicamente no monitoramento.</div>
        </div>

        <div style={{ padding:"10px 12px", background:"rgba(0,160,255,0.05)", border:"1px solid rgba(0,160,255,0.1)", borderRadius:6, marginBottom:14 }}>
          <div style={{ fontSize:10, color:"#5a7a9a", marginBottom:6 }}>💡 Intelbras sem IP público?</div>
          <div style={{ fontSize:10, color:"#4a6a8a", lineHeight:1.6 }}>
            Use <b style={{color:"#7ec8ff"}}>Snapshot HTTP</b>: configure a câmera para enviar snapshots periódicos via FTP/HTTP para um servidor. Ou use o <b style={{color:"#7ec8ff"}}>App Intelbras iSIC</b> para gerar links HLS/MJPEG.
          </div>
        </div>

        {msg && <div style={{ marginBottom:10, fontSize:12, color:msg.includes("✅")?"#00e676":"#ff4444" }}>{msg}</div>}

        <div style={{ display:"flex", gap:8 }}>
          <button onClick={onClose} style={{ flex:1, padding:12, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
          <button onClick={salvar} disabled={saving} style={{ flex:2, padding:12, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11, opacity:saving?0.6:1 }}>
            {saving ? "SALVANDO..." : "SALVAR"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Página principal ───────────────────────────────────────────────────────
export default function MonitoramentoPage() {
  const [cameras, setCameras] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [fullscreenId, setFullscreenId] = useState<number|null>(null);
  const [streamModal, setStreamModal] = useState<any>(null);
  const [grid, setGrid] = useState<2|3|4>(2);

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try { const r = await api.get("/api/v1/cameras/"); setCameras(r.data); }
    finally { setLoading(false); }
  }

  const camFullscreen = fullscreenId ? cameras.find(c => c.id === fullscreenId) : null;

  return (
    <div style={{ padding:12, display:"flex", flexDirection:"column", gap:10 }}>
      <style>{`
        @keyframes blink{0%,100%{opacity:1}50%{opacity:0.3}}
        @media(max-width:600px){ .monitor-grid{ grid-template-columns: 1fr !important; } }
      `}</style>

      {/* Header */}
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", flexWrap:"wrap", gap:8 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>
          📹 MONITORAMENTO
        </div>
        <div style={{ display:"flex", gap:6, alignItems:"center" }}>
          <span style={{ fontSize:10, color:"#4a6a8a" }}>GRID:</span>
          {([2,3,4] as const).map(n => (
            <button key={n} onClick={()=>setGrid(n)} style={{ padding:"4px 10px", border:`1px solid ${grid===n?"rgba(0,160,255,0.5)":"rgba(0,160,255,0.15)"}`, borderRadius:4, background:grid===n?"rgba(0,100,200,0.2)":"transparent", color:grid===n?"#7ec8ff":"#4a6a8a", fontSize:11, cursor:"pointer" }}>{n}x</button>
          ))}
          <button onClick={carregar} style={{ padding:"4px 10px", border:"1px solid rgba(0,160,255,0.2)", borderRadius:4, background:"transparent", color:"#7ec8ff", fontSize:11, cursor:"pointer" }}>↻ Refresh</button>
        </div>
      </div>

      {/* Status bar */}
      <div style={{ display:"flex", gap:12, padding:"6px 12px", background:"rgba(0,0,0,0.3)", borderRadius:6, fontSize:10, fontFamily:"'Share Tech Mono',monospace" }}>
        <span style={{ color:"#4a6a8a" }}>CAMERAS: <span style={{ color:"#7ec8ff" }}>{cameras.length}</span></span>
        <span style={{ color:"#4a6a8a" }}>ONLINE: <span style={{ color:"#00e676" }}>{cameras.filter(c=>c.is_online).length}</span></span>
        <span style={{ color:"#4a6a8a" }}>OFFLINE: <span style={{ color:"#ff4444" }}>{cameras.filter(c=>!c.is_online).length}</span></span>
        <span style={{ color:"#4a6a8a", marginLeft:"auto" }}>{new Date().toLocaleString("pt-BR")}</span>
      </div>

      {loading && <div style={{ textAlign:"center", color:"#4a6a8a", padding:32 }}>Carregando câmeras...</div>}

      {!loading && cameras.length === 0 && (
        <div style={{ background:"rgba(0,0,0,0.2)", border:"1px solid rgba(0,160,255,0.1)", borderRadius:10, padding:40, textAlign:"center", color:"#4a6a8a" }}>
          <div style={{ fontSize:32, marginBottom:8, opacity:0.3 }}>📷</div>
          <div style={{ fontFamily:"'Orbitron',monospace", fontSize:12, marginBottom:6 }}>NENHUMA CÂMERA</div>
          <div style={{ fontSize:11 }}>Cadastre câmeras na página <b style={{color:"#7ec8ff"}}>Câmeras</b></div>
        </div>
      )}

      {/* Fullscreen */}
      {camFullscreen && (
        <div style={{ position:"fixed", inset:0, background:"#050a0f", zIndex:150, padding:12, display:"flex", flexDirection:"column", gap:8 }}>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center" }}>
            <span style={{ fontFamily:"'Orbitron',monospace", color:"#7ec8ff", fontSize:13 }}>{camFullscreen.name}</span>
            <div style={{ display:"flex", gap:6 }}>
              <button onClick={()=>setStreamModal(camFullscreen)} style={{ padding:"6px 12px", border:"1px solid rgba(0,160,255,0.3)", borderRadius:4, background:"rgba(0,100,200,0.1)", color:"#7ec8ff", fontSize:11, cursor:"pointer" }}>📡 Config Stream</button>
              <button onClick={()=>setFullscreenId(null)} style={{ padding:"6px 12px", border:"1px solid rgba(255,100,0,0.3)", borderRadius:4, background:"rgba(255,100,0,0.1)", color:"#ff6644", fontSize:11, cursor:"pointer" }}>✕ Fechar</button>
            </div>
          </div>
          <CameraPlayer cam={camFullscreen} fullscreen={true} onFullscreen={()=>setFullscreenId(null)} />
        </div>
      )}

      {/* Grid de câmeras */}
      <div className="monitor-grid" style={{ display:"grid", gridTemplateColumns:`repeat(${grid},1fr)`, gap:10 }}>
        {cameras.map(cam => (
          <div key={cam.id} style={{ position:"relative" }}>
            <CameraPlayer cam={cam} fullscreen={false} onFullscreen={()=>setFullscreenId(cam.id)} />
            <button onClick={()=>setStreamModal(cam)} style={{ position:"absolute", bottom:32, right:8, padding:"3px 8px", border:"1px solid rgba(0,160,255,0.2)", borderRadius:4, background:"rgba(0,0,0,0.7)", color:"#7ec8ff", fontSize:9, cursor:"pointer", fontFamily:"'Orbitron',monospace" }}>📡</button>
          </div>
        ))}
      </div>

      {streamModal && (
        <StreamModal cam={streamModal} onClose={()=>setStreamModal(null)} onSaved={carregar} />
      )}
    </div>
  );
}
