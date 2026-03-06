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