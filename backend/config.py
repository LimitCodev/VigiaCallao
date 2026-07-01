"""Configuración centralizada, leída una sola vez desde variables de entorno.

Nada en el resto del backend debe llamar a os.getenv directamente — todo
pasa por esta clase para que exista un único lugar donde ver (y auditar)
qué variables usa el sistema.
"""
import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    PORT = int(os.getenv("PORT", "5000"))
    DB_PATH = os.getenv("DB_PATH", "vigiacallao.db")
    ML_API_KEY = os.getenv("ML_API_KEY", "dev_key_change_me")
    VIDEO_SOURCE = os.getenv("VIDEO_SOURCE", "demo.mp4")
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")
