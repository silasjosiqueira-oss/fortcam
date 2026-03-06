"""
Script para criar o primeiro usuario administrador
Execute: python create_admin.py
"""
import sys
sys.path.append(".")

from app.core.database import SessionLocal, engine, Base
from app.core.security import hash_password
from app.models.user import User
from app.models.camera import Camera
from app.models.whitelist import Whitelist
from app.models.event import Event

# Criar todas as tabelas
Base.metadata.create_all(bind=engine)

db = SessionLocal()

# Verificar se ja existe admin
existing = db.query(User).filter(User.email == "admin@fortcam.com").first()
if existing:
    print("Admin ja existe!")
    db.close()
    exit()

# Criar admin
admin = User(
    name="Administrador",
    email="admin@fortcam.com",
    hashed_password=hash_password("admin123"),
    role="admin",
    is_active=True
)
db.add(admin)
db.commit()

print("=" * 40)
print("Admin criado com sucesso!")
print("Email: admin@fortcam.com")
print("Senha: admin123")
print("IMPORTANTE: Troque a senha apos o primeiro login!")
print("=" * 40)

db.close()
