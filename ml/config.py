"""
config.py
Lee variables de entorno y las expone como constantes tipadas.
Centraliza toda la configuración del módulo ML en un solo lugar.
"""
import os
from dotenv import load_dotenv

load_dotenv()

# Video
VIDEO_SOURCE: str = os.getenv("VIDEO_SOURCE", "./test_video/demo.mp4")

# Modelo
YOLO_MODEL: str = os.getenv("YOLO_MODEL", "yolo11n.pt")
DETECTION_CONFIDENCE: float = float(os.getenv("DETECTION_CONFIDENCE", "0.45"))
PROCESSING_FPS: int = int(os.getenv("PROCESSING_FPS", "10"))

# Zona restringida — se calibra con calibrate.py
_zone_raw = os.getenv("RESTRICTED_ZONE", "100,200,800,600")
try:
    _p = [int(x.strip()) for x in _zone_raw.split(",")]
    RESTRICTED_ZONE: tuple[int, int, int, int] = (_p[0], _p[1], _p[2], _p[3])
except Exception:
    print("[config] RESTRICTED_ZONE inválido, usando default")
    RESTRICTED_ZONE = (100, 200, 800, 600)

# Umbral de permanencia antes de generar alerta
PARKING_THRESHOLD_SECONDS: int = int(os.getenv("PARKING_THRESHOLD_SECONDS", "30"))

# Backend
ALERT_ENDPOINT: str = os.getenv("ALERT_ENDPOINT", "http://localhost:5000/api/alerts")
ML_API_KEY: str = os.getenv("ML_API_KEY", "dev_key_change_me")

# Clases COCO que nos interesan: 2=car, 5=bus, 7=truck
VEHICLE_CLASSES: list[int] = [2, 5, 7]

# Colores BGR para OpenCV
COLOR_OK      = (0, 200, 0)    # verde  — en zona, tiempo OK
COLOR_WARNING = (0, 165, 255)  # ámbar  — acercándose al umbral
COLOR_ALERT   = (0, 0, 220)    # rojo   — alerta disparada
COLOR_ZONE    = (0, 140, 255)  # naranja — rectángulo zona restringida
