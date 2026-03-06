# Configurar PWA no Fortcam
$frontend = "C:\Users\Camera 3\fortcam-cloud\frontend"
$public = "$frontend\public"

Write-Host "Configurando PWA..." -ForegroundColor Cyan

# Criar pasta public se nao existir
New-Item -ItemType Directory -Force -Path $public | Out-Null

# ============================================================
# MANIFEST.JSON
# ============================================================
[System.IO.File]::WriteAllText("$public\manifest.json", @'
{
  "name": "Fortcam Cloud",
  "short_name": "Fortcam",
  "description": "Sistema de controle de acesso veicular",
  "start_url": "/dashboard",
  "display": "standalone",
  "background_color": "#080d14",
  "theme_color": "#0066cc",
  "orientation": "portrait",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "screenshots": [],
  "categories": ["security", "utilities"]
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# SERVICE WORKER
# ============================================================
[System.IO.File]::WriteAllText("$public\sw.js", @'
const CACHE_NAME = "fortcam-v1";
const STATIC_CACHE = ["/", "/login", "/dashboard", "/plates", "/whitelist", "/cameras", "/portoes"];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(STATIC_CACHE))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.url.includes("/api/")) return;
  event.respondWith(
    fetch(event.request).catch(() => caches.match(event.request))
  );
});

// Notificacoes push
self.addEventListener("push", (event) => {
  const data = event.data ? event.data.json() : {};
  const title = data.title || "Fortcam";
  const options = {
    body: data.body || "Nova deteccao de placa",
    icon: "/icon-192.png",
    badge: "/icon-192.png",
    vibrate: [200, 100, 200],
    data: { url: data.url || "/plates" },
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(clients.openWindow(event.notification.data.url));
});
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# LAYOUT - adicionar meta tags PWA e registrar SW
# ============================================================
$rootLayout = "$frontend\app\layout.tsx"
if (Test-Path $rootLayout) {
  $content = Get-Content $rootLayout -Raw
  Write-Host "layout.tsx raiz encontrado" -ForegroundColor Green
} else {
  Write-Host "Criando app/layout.tsx raiz..." -ForegroundColor Yellow
}

[System.IO.File]::WriteAllText("$frontend\app\layout.tsx", @'
import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Fortcam Cloud",
  description: "Sistema de controle de acesso veicular inteligente",
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "Fortcam",
  },
};

export const viewport: Viewport = {
  themeColor: "#0066cc",
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <head>
        <link rel="manifest" href="/manifest.json" />
        <link rel="apple-touch-icon" href="/icon-192.png" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
        <meta name="apple-mobile-web-app-title" content="Fortcam" />
        <meta name="mobile-web-app-capable" content="yes" />
      </head>
      <body style={{ margin:0, padding:0, background:"#080d14" }}>
        {children}
        <script dangerouslySetInnerHTML={{ __html: `
          if ('serviceWorker' in navigator) {
            window.addEventListener('load', function() {
              navigator.serviceWorker.register('/sw.js')
                .then(function(reg) { console.log('SW registrado'); })
                .catch(function(err) { console.log('SW erro:', err); });
            });
          }
        `}} />
      </body>
    </html>
  );
}
'@, [System.Text.Encoding]::UTF8)

# ============================================================
# CRIAR ICONES SIMPLES (SVG convertido para referencia)
# ============================================================
# Icone SVG simples para referencia - precisa converter para PNG
[System.IO.File]::WriteAllText("$public\icon.svg", @'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="80" fill="#0066cc"/>
  <text x="256" y="320" font-family="Arial" font-weight="bold" font-size="200" fill="#7ec8ff" text-anchor="middle">FC</text>
</svg>
'@, [System.Text.Encoding]::UTF8)

Write-Host ""
Write-Host "PWA configurado!" -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Precisa criar os icones PNG:" -ForegroundColor Yellow
Write-Host "  - public/icon-192.png (192x192px)" -ForegroundColor White
Write-Host "  - public/icon-512.png (512x512px)" -ForegroundColor White
Write-Host "  Acesse: https://realfavicongenerator.net e use o icon.svg" -ForegroundColor Cyan
Write-Host ""
Write-Host "Depois execute:" -ForegroundColor Yellow
Write-Host "  npm run build" -ForegroundColor White
Write-Host "  scp -r out\* root@187.77.231.19:/var/www/fortcam/" -ForegroundColor White
Write-Host "  scp public\manifest.json root@187.77.231.19:/var/www/fortcam/" -ForegroundColor White
Write-Host "  scp public\sw.js root@187.77.231.19:/var/www/fortcam/" -ForegroundColor White
