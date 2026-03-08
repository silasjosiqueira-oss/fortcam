"use client";
import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/store/auth";
import api from "@/lib/api";

interface Tenant {
  id: number;
  name: string;
  is_active: boolean;
  created_at: string;
}

interface GlobalStats {
  total_tenants: number;
  total_cameras: number;
  cameras_online: number;
  total_events_today: number;
  total_events_granted: number;
  total_events_denied: number;
}

interface RecentEvent {
  id: number;
  plate: string;
  camera_name: string;
  status: string;
  detected_at: string;
  tenant_name?: string;
}

export default function AdminMonitorPage() {
  const router = useRouter();
  const { user, token } = useAuthStore();
  const [tenants, setTenants] = useState<Tenant[]>([]);
  const [stats, setStats] = useState<GlobalStats | null>(null);
  const [events, setEvents] = useState<RecentEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    if (!token) { router.push("/login"); return; }
    if (user && user.role !== "superadmin") { router.push("/dashboard"); return; }
  }, [token, user]);

  useEffect(() => {
    const tick = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(tick);
  }, []);

  async function loadData() {
    try {
      const [tenantsRes, eventsRes] = await Promise.all([
        api.get("/api/v1/tenants/"),
        api.get("/api/v1/events/?limit=50"),
      ]);

      const tenantsData: Tenant[] = tenantsRes.data || [];
      setTenants(tenantsData);

      const eventsData: RecentEvent[] = eventsRes.data || [];
      setEvents(eventsData);

      const today = new Date().toDateString();
      const todayEvents = eventsData.filter(e =>
        new Date(e.detected_at).toDateString() === today
      );

      setStats({
        total_tenants: tenantsData.length,
        total_cameras: 0,
        cameras_online: 0,
        total_events_today: todayEvents.length,
        total_events_granted: todayEvents.filter(e => e.status === "granted").length,
        total_events_denied: todayEvents.filter(e => e.status === "denied").length,
      });
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (token) {
      loadData();
      const interval = setInterval(loadData, 15000);
      return () => clearInterval(interval);
    }
  }, [token]);

  const timeStr = now.toLocaleTimeString("pt-BR");
  const dateStr = now.toLocaleDateString("pt-BR", { weekday: "long", day: "2-digit", month: "long", year: "numeric" });

  if (loading) {
    return (
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: "100%", flexDirection: "column", gap: 16 }}>
        <div style={{ width: 40, height: 40, border: "2px solid rgba(0,160,255,0.2)", borderTop: "2px solid #0099ff", borderRadius: "50%", animation: "spin 1s linear infinite" }} />
        <div style={{ fontFamily: "'Share Tech Mono',monospace", color: "#4a7aaa", fontSize: 12, letterSpacing: 2 }}>CARREGANDO DADOS...</div>
        <style>{`@keyframes spin{to{transform:rotate(360deg)}}`}</style>
      </div>
    );
  }

  return (
    <div style={{ padding: 24, minHeight: "100%" }}>
      <style>{`
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:0.4} }
        @keyframes slideIn { from{opacity:0;transform:translateY(8px)} to{opacity:1;transform:translateY(0)} }
        .stat-card:hover { border-color: rgba(0,160,255,0.4) !important; transform: translateY(-2px); }
        .stat-card { transition: all 0.2s; }
        .event-row:hover { background: rgba(0,100,200,0.08) !important; }
        .tenant-row:hover { background: rgba(0,100,200,0.06) !important; }
      `}</style>

      {/* Header */}
      <div style={{ display: "flex", alignItems: "flex-start", justifyContent: "space-between", marginBottom: 28 }}>
        <div>
          <div style={{ fontFamily: "'Orbitron',monospace", fontSize: 18, fontWeight: 700, color: "#7ec8ff", letterSpacing: 2, marginBottom: 4 }}>
            MONITOR GLOBAL
          </div>
          <div style={{ fontFamily: "'Share Tech Mono',monospace", fontSize: 11, color: "#4a7aaa", letterSpacing: 1 }}>
            SUPERADMIN — VISÃO COMPLETA DO SISTEMA
          </div>
        </div>
        <div style={{ textAlign: "right" }}>
          <div style={{ fontFamily: "'Orbitron',monospace", fontSize: 22, fontWeight: 700, color: "#e0e8f0", letterSpacing: 3 }}>
            {timeStr}
          </div>
          <div style={{ fontFamily: "'Share Tech Mono',monospace", fontSize: 10, color: "#4a7aaa", marginTop: 2 }}>
            {dateStr}
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      {stats && (
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(160px, 1fr))", gap: 14, marginBottom: 28 }}>
          {[
            { label: "TENANTS", value: stats.total_tenants, color: "#7ec8ff", icon: "🏢" },
            { label: "EVENTOS HOJE", value: stats.total_events_today, color: "#00e5ff", icon: "📊" },
            { label: "LIBERADOS", value: stats.total_events_granted, color: "#00e676", icon: "✅" },
            { label: "NEGADOS", value: stats.total_events_denied, color: "#ff5252", icon: "❌" },
          ].map(s => (
            <div key={s.label} className="stat-card" style={{
              background: "linear-gradient(135deg, #0d1520, #0a1018)",
              border: "1px solid rgba(0,160,255,0.15)",
              borderRadius: 10,
              padding: "18px 20px",
              cursor: "default",
            }}>
              <div style={{ fontSize: 20, marginBottom: 8 }}>{s.icon}</div>
              <div style={{ fontFamily: "'Orbitron',monospace", fontSize: 28, fontWeight: 700, color: s.color, lineHeight: 1 }}>
                {s.value}
              </div>
              <div style={{ fontFamily: "'Share Tech Mono',monospace", fontSize: 10, color: "#4a7aaa", marginTop: 6, letterSpacing: 1 }}>
                {s.label}
              </div>
            </div>
          ))}
        </div>
      )}

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>

        {/* Tenants */}
        <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 12, overflow: "hidden" }}>
          <div style={{ padding: "14px 20px", borderBottom: "1px solid rgba(0,160,255,0.1)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={{ fontFamily: "'Orbitron',monospace", fontSize: 11, color: "#7ec8ff", letterSpacing: 2 }}>TENANTS CADASTRADOS</div>
            <div style={{ background: "rgba(0,100,200,0.2)", borderRadius: 20, padding: "2px 10px", fontSize: 11, color: "#7ec8ff", fontFamily: "'Share Tech Mono',monospace" }}>
              {tenants.length}
            </div>
          </div>
          <div style={{ maxHeight: 320, overflowY: "auto" }}>
            {tenants.length === 0 ? (
              <div style={{ padding: 24, textAlign: "center", color: "#4a6a8a", fontSize: 13 }}>Nenhum tenant cadastrado</div>
            ) : tenants.map((t, i) => (
              <div key={t.id} className="tenant-row" style={{
                display: "flex", alignItems: "center", justifyContent: "space-between",
                padding: "12px 20px",
                borderBottom: i < tenants.length - 1 ? "1px solid rgba(0,160,255,0.06)" : "none",
                cursor: "default",
                animation: `slideIn 0.3s ease ${i * 0.05}s both`,
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <div style={{
                    width: 8, height: 8, borderRadius: "50%",
                    background: t.is_active ? "#00e676" : "#ff5252",
                    boxShadow: t.is_active ? "0 0 6px #00e676" : "0 0 6px #ff5252",
                    animation: t.is_active ? "pulse 2s infinite" : "none",
                  }} />
                  <div>
                    <div style={{ fontSize: 13, fontWeight: 600, color: "#c0d8f0" }}>{t.name}</div>
                    <div style={{ fontSize: 10, color: "#4a6a8a", fontFamily: "'Share Tech Mono',monospace", marginTop: 2 }}>
                      ID #{t.id} · {new Date(t.created_at).toLocaleDateString("pt-BR")}
                    </div>
                  </div>
                </div>
                <div style={{
                  fontSize: 10, fontWeight: 600, letterSpacing: 1,
                  color: t.is_active ? "#00e676" : "#ff5252",
                  fontFamily: "'Share Tech Mono',monospace",
                }}>
                  {t.is_active ? "ATIVO" : "INATIVO"}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Events */}
        <div style={{ background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 12, overflow: "hidden" }}>
          <div style={{ padding: "14px 20px", borderBottom: "1px solid rgba(0,160,255,0.1)", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
            <div style={{ fontFamily: "'Orbitron',monospace", fontSize: 11, color: "#7ec8ff", letterSpacing: 2 }}>EVENTOS RECENTES</div>
            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
              <div style={{ width: 6, height: 6, borderRadius: "50%", background: "#00e676", animation: "pulse 1.5s infinite" }} />
              <div style={{ fontSize: 10, color: "#00e676", fontFamily: "'Share Tech Mono',monospace" }}>AO VIVO</div>
            </div>
          </div>
          <div style={{ maxHeight: 320, overflowY: "auto" }}>
            {events.length === 0 ? (
              <div style={{ padding: 24, textAlign: "center", color: "#4a6a8a", fontSize: 13 }}>Nenhum evento</div>
            ) : events.slice(0, 20).map((e, i) => (
              <div key={e.id} className="event-row" style={{
                display: "flex", alignItems: "center", justifyContent: "space-between",
                padding: "10px 20px",
                borderBottom: "1px solid rgba(0,160,255,0.05)",
                animation: `slideIn 0.3s ease ${i * 0.03}s both`,
              }}>
                <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                  <div style={{
                    width: 7, height: 7, borderRadius: "50%",
                    background: e.status === "granted" ? "#00e676" : "#ff5252",
                    flexShrink: 0,
                  }} />
                  <div>
                    <div style={{ fontFamily: "'Orbitron',monospace", fontSize: 12, fontWeight: 700, color: "#e0e8f0", letterSpacing: 1 }}>
                      {e.plate}
                    </div>
                    <div style={{ fontSize: 10, color: "#4a6a8a", marginTop: 1 }}>{e.camera_name}</div>
                  </div>
                </div>
                <div style={{ textAlign: "right" }}>
                  <div style={{
                    fontSize: 10, fontWeight: 600, letterSpacing: 1,
                    color: e.status === "granted" ? "#00e676" : "#ff5252",
                    fontFamily: "'Share Tech Mono',monospace",
                  }}>
                    {e.status === "granted" ? "LIBERADO" : "NEGADO"}
                  </div>
                  <div style={{ fontSize: 10, color: "#4a6a8a", marginTop: 1, fontFamily: "'Share Tech Mono',monospace" }}>
                    {new Date(e.detected_at).toLocaleTimeString("pt-BR")}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* System Status */}
      <div style={{ marginTop: 20, background: "linear-gradient(135deg, #0d1520, #0a1018)", border: "1px solid rgba(0,160,255,0.15)", borderRadius: 12, padding: "16px 20px", display: "flex", alignItems: "center", gap: 32 }}>
        <div style={{ fontFamily: "'Orbitron',monospace", fontSize: 10, color: "#4a7aaa", letterSpacing: 2 }}>STATUS DO SISTEMA</div>
        {[
          { label: "API", ok: true },
          { label: "BANCO DE DADOS", ok: true },
          { label: "MQTT", ok: true },
          { label: "SSL/TLS", ok: true },
        ].map(s => (
          <div key={s.label} style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ width: 7, height: 7, borderRadius: "50%", background: "#00e676", boxShadow: "0 0 6px #00e676", animation: "pulse 2s infinite" }} />
            <div style={{ fontFamily: "'Share Tech Mono',monospace", fontSize: 10, color: "#7ec8ff" }}>{s.label}</div>
          </div>
        ))}
        <div style={{ marginLeft: "auto", fontFamily: "'Share Tech Mono',monospace", fontSize: 10, color: "#4a6a8a" }}>
          fortcam.com.br · v1.0
        </div>
      </div>
    </div>
  );
}
