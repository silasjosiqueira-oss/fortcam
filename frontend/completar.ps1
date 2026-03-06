# Script completo - Relatorios, Configuracoes, Simulador
$base = "C:\Users\Camera 3\fortcam-cloud\frontend"
$backend = "C:\Users\Camera 3\fortcam-cloud\backend"

Write-Host "Criando telas e simulador..." -ForegroundColor Cyan

# ============================================================
# RELATORIOS PAGE
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(dashboard)\reports\page.tsx", @'
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
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# SETTINGS PAGE
# ============================================================
[System.IO.File]::WriteAllText("$base\app\(dashboard)\settings\page.tsx", @'
"use client";
import { useState, useEffect } from "react";
import { camerasAPI } from "@/lib/api";
import api from "@/lib/api";

export default function ConfiguracoesPage() {
  const [cameras, setCameras] = useState<any[]>([]);
  const [modalCam, setModalCam] = useState(false);
  const [modalUser, setModalUser] = useState(false);
  const [loadingCam, setLoadingCam] = useState(true);
  const [novaCam, setNovaCam] = useState({ name:"", serial:"", ip:"", location:"" });
  const [novoUser, setNovoUser] = useState({ name:"", email:"", password:"", role:"operator" });
  const [msg, setMsg] = useState("");
  const [msgCor, setMsgCor] = useState("#00e676");

  useEffect(() => { carregarCameras(); }, []);

  async function carregarCameras() {
    try { const r = await camerasAPI.list(); setCameras(r.data); } finally { setLoadingCam(false); }
  }

  function mostrarMsg(texto: string, cor = "#00e676") {
    setMsg(texto); setMsgCor(cor);
    setTimeout(() => setMsg(""), 3000);
  }

  async function adicionarCamera() {
    if (!novaCam.name || !novaCam.serial) return;
    try {
      await api.post("/api/v1/cameras/", novaCam);
      setNovaCam({ name:"", serial:"", ip:"", location:"" });
      setModalCam(false);
      carregarCameras();
      mostrarMsg("Camera adicionada com sucesso!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao adicionar camera", "#ff4444");
    }
  }

  async function removerCamera(id: number) {
    if (!confirm("Remover esta camera?")) return;
    try {
      await api.delete(`/api/v1/cameras/${id}`);
      carregarCameras();
      mostrarMsg("Camera removida!");
    } catch { mostrarMsg("Erro ao remover", "#ff4444"); }
  }

  async function criarUsuario() {
    if (!novoUser.name || !novoUser.email || !novoUser.password) return;
    try {
      await api.post("/api/v1/auth/users", novoUser);
      setNovoUser({ name:"", email:"", password:"", role:"operator" });
      setModalUser(false);
      mostrarMsg("Usuario criado com sucesso!");
    } catch (err: any) {
      mostrarMsg(err.response?.data?.detail || "Erro ao criar usuario", "#ff4444");
    }
  }

  return (
    <div style={{ padding:16, display:"flex", flexDirection:"column", gap:12 }}>
      <div style={{ fontFamily:"'Orbitron',monospace", fontSize:14, color:"#7ec8ff", letterSpacing:2 }}>CONFIGURACOES</div>

      {msg && <div style={{ background:msgCor==="red"?"rgba(255,68,68,0.1)":"rgba(0,230,118,0.1)", border:`1px solid ${msgCor}44`, borderRadius:8, padding:"10px 14px", color:msgCor, fontSize:12 }}>{msg}</div>}

      {/* Cameras */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, overflow:"hidden" }}>
        <div style={{ padding:"10px 14px", borderBottom:"1px solid rgba(0,160,255,0.1)", display:"flex", justifyContent:"space-between", alignItems:"center" }}>
          <span style={{ fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Gerenciar Cameras</span>
          <button onClick={()=>setModalCam(true)} style={{ padding:"6px 14px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:10, fontWeight:700 }}>+ NOVA CAMERA</button>
        </div>
        {loadingCam && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a" }}>Carregando...</div>}
        {!loadingCam && cameras.length === 0 && <div style={{ padding:24, textAlign:"center", color:"#4a6a8a", fontSize:12 }}>Nenhuma camera cadastrada.</div>}
        {cameras.map(cam => (
          <div key={cam.id} style={{ display:"grid", gridTemplateColumns:"1fr 1fr 120px 80px", padding:"10px 14px", borderBottom:"1px solid rgba(255,255,255,0.03)", alignItems:"center" }}>
            <span style={{ fontSize:13, color:"#c8e0f0", fontWeight:600 }}>{cam.name}</span>
            <span style={{ fontSize:11, color:"#5a7a9a", fontFamily:"'Share Tech Mono',monospace" }}>SN: {cam.serial} | IP: {cam.ip||"---"}</span>
            <span style={{ fontSize:10, padding:"2px 8px", borderRadius:4, background:cam.is_online?"rgba(0,230,118,0.1)":"rgba(255,68,68,0.1)", color:cam.is_online?"#00e676":"#ff4444", border:`1px solid ${cam.is_online?"rgba(0,230,118,0.3)":"rgba(255,68,68,0.3)"}`, fontFamily:"'Orbitron',monospace", display:"inline-block" }}>{cam.is_online?"ONLINE":"OFFLINE"}</span>
            <button onClick={()=>removerCamera(cam.id)} style={{ padding:"4px 10px", border:"1px solid rgba(255,68,68,0.3)", borderRadius:4, background:"rgba(255,68,68,0.1)", color:"#ff6666", fontSize:11, cursor:"pointer" }}>Remover</button>
          </div>
        ))}
      </div>

      {/* Usuarios */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
        <div style={{ display:"flex", justifyContent:"space-between", alignItems:"center", marginBottom:12 }}>
          <span style={{ fontSize:12, fontWeight:600, color:"#8ab0cc" }}>Gerenciar Usuarios</span>
          <button onClick={()=>setModalUser(true)} style={{ padding:"6px 14px", border:"none", borderRadius:6, cursor:"pointer", background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", fontFamily:"'Orbitron',monospace", fontSize:10, fontWeight:700 }}>+ NOVO USUARIO</button>
        </div>
        <div style={{ fontSize:11, color:"#4a6a8a" }}>Gerencie os usuarios que tem acesso ao sistema. Apenas administradores podem criar novos usuarios.</div>
      </div>

      {/* Info sistema */}
      <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.15)", borderRadius:10, padding:"14px 16px" }}>
        <div style={{ fontSize:12, fontWeight:600, color:"#8ab0cc", marginBottom:12 }}>Informacoes do Sistema</div>
        {[
          { label:"Versao da API", valor:"1.0.0" },
          { label:"Banco de dados", valor:"SQLite (desenvolvimento)" },
          { label:"MQTT Broker", valor:"localhost:1883" },
          { label:"Documentacao API", valor:"/docs (porta 8000)" },
        ].map((item,i) => (
          <div key={i} style={{ display:"flex", justifyContent:"space-between", padding:"6px 0", borderBottom:"1px solid rgba(255,255,255,0.04)" }}>
            <span style={{ fontSize:12, color:"#5a7a9a" }}>{item.label}</span>
            <span style={{ fontSize:12, color:"#7ec8ff", fontFamily:"'Share Tech Mono',monospace" }}>{item.valor}</span>
          </div>
        ))}
      </div>

      {/* Modal Camera */}
      {modalCam && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.7)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:400 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>NOVA CAMERA</div>
            {[{l:"Nome",k:"name",p:"Entrada 01"},{l:"Serial",k:"serial",p:"FC-2024-001"},{l:"IP",k:"ip",p:"192.168.1.101"},{l:"Localizacao",k:"location",p:"Portao principal"}].map(c=>(
              <div key={c.k} style={{ marginBottom:14 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>{c.l}</label>
                <input value={(novaCam as any)[c.k]} onChange={e=>setNovaCam(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>setModalCam(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={adicionarCamera} style={{ flex:1, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>SALVAR</button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Usuario */}
      {modalUser && (
        <div style={{ position:"fixed", inset:0, background:"rgba(0,0,0,0.7)", display:"flex", alignItems:"center", justifyContent:"center", zIndex:100 }}>
          <div style={{ background:"linear-gradient(135deg,#0d1520,#0a1018)", border:"1px solid rgba(0,160,255,0.25)", borderRadius:12, padding:28, width:400 }}>
            <div style={{ fontFamily:"'Orbitron',monospace", fontSize:13, color:"#7ec8ff", marginBottom:20 }}>NOVO USUARIO</div>
            {[{l:"Nome",k:"name",p:"Nome completo"},{l:"Email",k:"email",p:"usuario@email.com"},{l:"Senha",k:"password",p:"senha123"}].map(c=>(
              <div key={c.k} style={{ marginBottom:14 }}>
                <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>{c.l}</label>
                <input type={c.k==="password"?"password":"text"} value={(novoUser as any)[c.k]} onChange={e=>setNovoUser(p=>({...p,[c.k]:e.target.value}))} placeholder={c.p}
                  style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none", boxSizing:"border-box" }} />
              </div>
            ))}
            <div style={{ marginBottom:14 }}>
              <label style={{ fontSize:10, color:"#5a7a9a", letterSpacing:1, textTransform:"uppercase", display:"block", marginBottom:5 }}>Perfil</label>
              <select value={novoUser.role} onChange={e=>setNovoUser(p=>({...p,role:e.target.value}))}
                style={{ width:"100%", padding:"8px 12px", background:"rgba(0,0,0,0.3)", border:"1px solid rgba(0,160,255,0.2)", borderRadius:6, color:"#e0e8f0", fontSize:13, outline:"none" }}>
                <option value="operator">Operador</option>
                <option value="admin">Administrador</option>
              </select>
            </div>
            <div style={{ display:"flex", gap:8 }}>
              <button onClick={()=>setModalUser(false)} style={{ flex:1, padding:10, border:"1px solid rgba(255,255,255,0.1)", borderRadius:6, background:"transparent", color:"#5a7a9a", cursor:"pointer" }}>Cancelar</button>
              <button onClick={criarUsuario} style={{ flex:1, padding:10, border:"none", borderRadius:6, background:"linear-gradient(135deg,#0066cc,#004499)", color:"#fff", cursor:"pointer", fontFamily:"'Orbitron',monospace", fontWeight:700, fontSize:11 }}>CRIAR</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
'@, [System.Text.Encoding]::UTF8)

Write-Host "Frontend atualizado!" -ForegroundColor Green


# ============================================================
# SIMULADOR DE EVENTOS (backend)
# ============================================================
[System.IO.File]::WriteAllText("$backend\simular.py", @'
"""
Simulador de eventos de placa para testar o sistema
Execute: python simular.py
"""
import sys, time, random
from datetime import datetime
sys.path.append(".")

from app.core.database import SessionLocal, engine, Base
from app.models.event import Event
from app.models.camera import Camera
from app.models.whitelist import Whitelist

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# Placas simuladas
PLACAS_WHITELIST = ["BRA7A23", "ABC1D23", "GHI8J90", "QWE4F56", "ZXC9K87"]
PLACAS_DESCONHECIDAS = ["XYZ0001", "AAA1111", "BBB2222", "CCC3333", "DDD4444"]

# Criar cameras de teste se nao existirem
camaras_nomes = ["Entrada 01", "Portao 02", "Estacionamento 03"]
cameras_ids = []

for nome in camaras_nomes:
    serial = f"SIM-{nome.replace(' ', '-').upper()}"
    cam = db.query(Camera).filter(Camera.serial == serial).first()
    if not cam:
        cam = Camera(name=nome, serial=serial, ip=f"192.168.1.{100+len(cameras_ids)}", is_online=True, is_active=True)
        db.add(cam)
        db.commit()
        db.refresh(cam)
        print(f"Camera criada: {nome}")
    else:
        cam.is_online = True
        db.commit()
    cameras_ids.append(cam.id)

# Adicionar placas na whitelist se nao existirem
for placa in PLACAS_WHITELIST:
    if not db.query(Whitelist).filter(Whitelist.plate == placa).first():
        db.add(Whitelist(plate=placa, owner_name=f"Proprietario {placa}", time_start="00:00", time_end="23:59", is_active=True))
        db.commit()
        print(f"Placa adicionada na whitelist: {placa}")

print("\n" + "="*50)
print("SIMULADOR DE EVENTOS INICIADO")
print("Pressione Ctrl+C para parar")
print("="*50 + "\n")

count = 0
try:
    while True:
        cam_id = random.choice(cameras_ids)
        cam = db.query(Camera).filter(Camera.id == cam_id).first()

        # 70% chance de placa na whitelist
        if random.random() < 0.7:
            placa = random.choice(PLACAS_WHITELIST)
            status = "granted"
            reason = "whitelist"
        else:
            placa = random.choice(PLACAS_DESCONHECIDAS)
            status = "denied"
            reason = "not_in_whitelist"

        evento = Event(
            plate=placa,
            camera_id=cam_id,
            camera_name=cam.name if cam else "Simulador",
            status=status,
            reason=reason,
            detected_at=datetime.now()
        )
        db.add(evento)
        db.commit()
        count += 1

        icone = "V" if status == "granted" else "X"
        print(f"[{icone}] {placa} | {cam.name if cam else '---'} | {status.upper()} | {datetime.now().strftime('%H:%M:%S')}")

        # Intervalo aleatorio entre 2 e 6 segundos
        time.sleep(random.uniform(2, 6))

except KeyboardInterrupt:
    print(f"\n\nSimulador parado. {count} eventos gerados.")
    # Colocar cameras offline
    for cid in cameras_ids:
        c = db.query(Camera).filter(Camera.id == cid).first()
        if c: c.is_online = False
    db.commit()
    db.close()
'@, [System.Text.Encoding]::UTF8)

Write-Host "Simulador criado em: $backend\simular.py" -ForegroundColor Green
Write-Host ""
Write-Host "="*50 -ForegroundColor Cyan
Write-Host "TUDO PRONTO!" -ForegroundColor Green
Write-Host ""
Write-Host "Para testar o sistema completo, abra 3 terminais:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Terminal 1 - Backend:" -ForegroundColor Cyan
Write-Host "  cd fortcam-cloud\backend" -ForegroundColor White
Write-Host "  venv\Scripts\activate" -ForegroundColor White
Write-Host "  uvicorn app.main:app --reload --port 8000" -ForegroundColor White
Write-Host ""
Write-Host "Terminal 2 - Frontend:" -ForegroundColor Cyan
Write-Host "  cd fortcam-cloud\frontend" -ForegroundColor White
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "Terminal 3 - Simulador:" -ForegroundColor Cyan
Write-Host "  cd fortcam-cloud\backend" -ForegroundColor White
Write-Host "  venv\Scripts\activate" -ForegroundColor White
Write-Host "  python simular.py" -ForegroundColor White
Write-Host "="*50 -ForegroundColor Cyan
