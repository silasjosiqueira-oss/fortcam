# Fortcam Cloud - Backend

## Estrutura
```
fortcam-backend/
├── app/
│   ├── api/v1/
│   │   ├── auth.py       # Login, usuarios
│   │   ├── whitelist.py  # Gerenciar placas liberadas
│   │   ├── events.py     # Historico de eventos
│   │   ├── cameras.py    # Gerenciar cameras
│   │   └── gate.py       # Controle do portao
│   ├── core/
│   │   ├── config.py     # Configuracoes
│   │   ├── database.py   # Conexao PostgreSQL
│   │   └── security.py   # JWT + bcrypt
│   ├── models/           # Tabelas do banco
│   ├── schemas/          # Validacao de dados
│   └── main.py           # App principal
├── create_admin.py        # Criar primeiro admin
├── setup_vps.sh          # Instalacao na VPS
├── requirements.txt
└── .env.example
```

## Endpoints da API

### Autenticacao
- POST /api/v1/auth/login       - Fazer login
- GET  /api/v1/auth/me          - Dados do usuario logado
- POST /api/v1/auth/users       - Criar usuario (admin)

### Whitelist
- GET    /api/v1/whitelist/         - Listar placas
- POST   /api/v1/whitelist/         - Adicionar placa
- PUT    /api/v1/whitelist/{id}     - Editar placa
- DELETE /api/v1/whitelist/{id}     - Remover placa
- GET    /api/v1/whitelist/check/{placa} - Verificar placa

### Eventos
- GET /api/v1/events/           - Historico de eventos
- GET /api/v1/events/dashboard  - Estatisticas
- GET /api/v1/events/last       - Ultimo evento

### Cameras
- GET    /api/v1/cameras/       - Listar cameras
- POST   /api/v1/cameras/       - Cadastrar camera
- DELETE /api/v1/cameras/{id}   - Remover camera

### Portao
- POST /api/v1/gate/command     - Abrir/fechar portao

## Instalacao na VPS

```bash
# 1. Enviar arquivos para VPS
scp -r fortcam-backend/ root@SEU-IP:/opt/fortcam

# 2. Rodar script de instalacao
ssh root@SEU-IP
bash /opt/fortcam/setup_vps.sh

# 3. Criar admin
cd /opt/fortcam
source venv/bin/activate
python create_admin.py

# 4. Iniciar servico
systemctl start fortcam

# 5. Ver documentacao
# http://SEU-IP/docs
```

## Documentacao interativa
Acesse http://SEU-IP/docs para testar todos os endpoints pela interface do Swagger.
