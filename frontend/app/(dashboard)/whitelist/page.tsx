"use client";
import { useState, useEffect } from "react";
import { whitelistAPI } from "@/lib/api";

export default function WhitelistPage() {
  const [lista, setLista] = useState<any[]>([]);
  const [modal, setModal] = useState(false);
  const [loading, setLoading] = useState(true);
  const [nova, setNova] = useState({ plate:"", owner_name:"", time_start:"00:00", time_end:"23:59" });

  useEffect(() => { carregar(); }, []);

  async function carregar() {
    try {
      const res = await whitelistAPI.list();
      setLista(res.data);
    } finally {
      setLoading(false);
    }
  }

  async function alternar(id: number, ativo: boolean) {
    await whitelistAPI.update(id, { is_active: !ativo });
    carregar();
  }

  async function remover(id: number) {
    if (!confirm("Remover esta placa?")) return;
    await whitelistAPI.remove(id);
    carregar();
  }

  async function adicionar() {
    if (!nova.plate || !nova.owner_name) return;
    try {
      await whitelistAPI.add(nova);
      setNova({ plate:"", owner_name:"", time_start:"00:00", time_end:"23:59" });
      setModal(false);
      carregar();
    } catch (err: any) {
      alert(err.response?.data?.detail || "Erro ao adicionar");
    }
  }

  return (
    <div style={{ padding:16 }}>
      <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:16 }}>
        <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>WHITELIST / PLACAS LIBERADAS</div>
        <button onClick={()=>setModal(true)} style={{ padding:"8px 16px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:11, fontWeight:700, letterSpacing:1 }}>+ ADICIONAR PLACA</button>
      </div>
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ display:"grid", gridTemplateColumns:"150px 1fr 160px 80px 120px", padding:"8px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", fontSize:10, color:"#4a6a8a", textTransform:"uppercase" }}>
          <span>Placa</span><span>Nome</span><span>Horario</span><span>Ativo</span><span>Acoes</span>
        </div>
        {loading && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loading && lista.length === 0 && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Nenhuma placa cadastrada.</div>}
        {lista.map(item => (
          <div key={item.id} style={{ display:"grid", gridTemplateColumns:"150px 1fr 160px 80px 120px", padding:"10px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
            <span style={{ fontFamily:"'Orbitron',monospace", fontSize:13, fontWeight:700, color:"#c8e0f0", letterSpacing:2 }}>{item.plate}</span>
            <span style={{ fontSize:13, color:"#8ab0cc" }}>{item.owner_name}</span>
            <span style={{ fontFamily:"'Share Tech Mono',monospace", fontSize:11, color:"#5a7a9a" }}>{item.time_start} - {item.time_end}</span>
            <div onClick={()=>alternar(item.id, item.is_active)} style={{ width:40, height:22, borderRadius:11, cursor:"pointer", background:item.is_active?"#00e676":"#333", position:"relative", transition:"background 0.2s" }}>
              <div style={{ position:"absolute", top:3, left:item.is_active?21:3, width:16, height:16, borderRadius:"50%", background:"#fff", transition:"left 0.2s" }} />
            </div>
            <button onClick={()=>remover(item.id)} style={{ padding:"4px 12px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>Remover</button>
          </div>
        ))}
      </div>
      {modal && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.7)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:400 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>NOVA PLACA</div>
            {[{l:"Placa",k:"plate",p:"ABC1D23"},{l:"Nome / Responsavel",k:"owner_name",p:"Nome do motorista"},{l:"Horario inicio",k:"time_start",p:"00:00"},{l:"Horario fim",k:"time_end",p:"23:59"}].map(c => (
              <div key={c.k} style={{ marginBottom:14 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>{c.l}</label>
                <input value={(nova as any)[c.k]} onChange={e=>setNova(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>setModal(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={adicionar} style={{ flex:1, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}