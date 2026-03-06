#!/bin/bash
# ============================================================
# Script de instalacao do Fortcam Cloud Backend
# Execute como root na VPS: bash setup_vps.sh
# ============================================================

set -e
echo "======================================"
echo " FORTCAM CLOUD - Setup VPS"
echo "======================================"

# 1. Atualizar sistema
echo "[1/7] Atualizando sistema..."
apt update && apt upgrade -y

# 2. Instalar dependencias
echo "[2/7] Instalando dependencias..."
apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib nginx curl git

# 3. Configurar PostgreSQL
echo "[3/7] Configurando PostgreSQL..."
sudo -u postgres psql << EOF
CREATE USER fortcam WITH PASSWORD 'FortcamDB@2024';
CREATE DATABASE fortcamdb OWNER fortcam;
GRANT ALL PRIVILEGES ON DATABASE fortcamdb TO fortcam;
EOF
echo "PostgreSQL configurado!"

# 4. Instalar Mosquitto (MQTT)
echo "[4/7] Instalando Mosquitto MQTT..."
apt install -y mosquitto mosquitto-clients
systemctl enable mosquitto
systemctl start mosquitto
echo "Mosquitto instalado!"

# 5. Configurar projeto
echo "[5/7] Configurando projeto..."
mkdir -p /opt/fortcam
cd /opt/fortcam

# Criar ambiente virtual
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias Python
pip install --upgrade pip
pip install -r /tmp/requirements.txt

# Criar .env
cat > /opt/fortcam/.env << 'ENVEOF'
DATABASE_URL=postgresql://fortcam:FortcamDB@2024@localhost:5432/fortcamdb
SECRET_KEY=MUDE-ESTA-CHAVE-PARA-UMA-SEQUENCIA-ALEATORIA-LONGA
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
MQTT_BROKER=localhost
MQTT_PORT=1883
MQTT_USER=
MQTT_PASSWORD=
MQTT_TOPIC=fortcam/plates/#
APP_NAME=Fortcam Cloud
DEBUG=False
ALLOWED_ORIGINS=http://localhost:3000
ENVEOF

echo "Projeto configurado!"

# 6. Criar servico systemd
echo "[6/7] Criando servico systemd..."
cat > /etc/systemd/system/fortcam.service << 'SERVICEEOF'
[Unit]
Description=Fortcam Cloud API
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/fortcam
Environment=PATH=/opt/fortcam/venv/bin
ExecStart=/opt/fortcam/venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

systemctl daemon-reload
systemctl enable fortcam
echo "Servico criado!"

# 7. Configurar Nginx
echo "[7/7] Configurando Nginx..."
cat > /etc/nginx/sites-available/fortcam << 'NGINXEOF'
server {
    listen 80;
    server_name _;

    location /api {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /docs {
        proxy_pass http://localhost:8000/docs;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/fortcam /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

echo ""
echo "======================================"
echo " INSTALACAO CONCLUIDA!"
echo "======================================"
echo ""
echo "Proximos passos:"
echo "1. Copie os arquivos do backend para /opt/fortcam/"
echo "2. Edite o arquivo /opt/fortcam/.env com suas configuracoes"
echo "3. Execute: cd /opt/fortcam && source venv/bin/activate"
echo "4. Execute: python create_admin.py"
echo "5. Execute: systemctl start fortcam"
echo "6. Acesse: http://SEU-IP/docs para ver a API"
echo ""
