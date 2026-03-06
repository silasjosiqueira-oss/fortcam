"""
Cria o superadmin e um tenant de demonstracao
Execute: python create_superadmin.py
"""
import sys
sys.path.append(".")

from app.core.database import SessionLocal, engine, Base
from app.core.security import hash_password
from app.models.user import User
from app.models.tenant import Tenant
from app.models.camera import Camera
from app.models.whitelist import Whitelist
from app.models.event import Event

Base.metadata.create_all(bind=engine)
db = SessionLocal()

# Superadmin
if not db.query(User).filter(User.email == "super@fortcam.com").first():
    super_user = User(
        tenant_id=None,
        name="Super Admin",
        email="super@fortcam.com",
        hashed_password=hash_password("super123"),
        role="superadmin"
    )
    db.add(super_user)
    db.commit()
    print("Superadmin criado: super@fortcam.com / super123")

# Tenant demo
tenant = db.query(Tenant).filter(Tenant.slug == "demo").first()
if not tenant:
    tenant = Tenant(name="Cliente Demo", slug="demo", plan="pro", max_cameras=10, max_users=5)
    db.add(tenant)
    db.commit()
    db.refresh(tenant)
    print(f"Tenant demo criado (ID: {tenant.id})")

    # Admin do tenant
    if not db.query(User).filter(User.email == "admin@fortcam.com").first():
        admin = User(
            tenant_id=tenant.id,
            name="Administrador",
            email="admin@fortcam.com",
            hashed_password=hash_password("admin123"),
            role="admin"
        )
        db.add(admin)
        db.commit()
        print("Admin demo criado: admin@fortcam.com / admin123")

print("")
print("="*40)
print("Contas criadas:")
print("SUPERADMIN: super@fortcam.com / super123")
print("ADMIN DEMO: admin@fortcam.com / admin123")
print("="*40)

db.close()