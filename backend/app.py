"""Punto de entrada. Patrón factory: create_app() arma la instancia de
Flask, en vez de tener un Flask() a nivel de módulo — así los tests
(o un segundo entorno) pueden crear instancias limpias sin pisarse.
"""
from flask import Flask
from flask_cors import CORS

from config import Config
from db import close_db, init_db
from extensions import socketio
from routes import register_blueprints


def create_app() -> Flask:
    app = Flask(__name__)
    CORS(app, origins=Config.CORS_ORIGINS)

    register_blueprints(app)
    app.teardown_appcontext(close_db)

    socketio.init_app(app, cors_allowed_origins=Config.CORS_ORIGINS, async_mode="threading")

    return app


app = create_app()

if __name__ == "__main__":
    init_db()
    print(f"[VigiaCallao backend] http://0.0.0.0:{Config.PORT}  (SQLite: {Config.DB_PATH})")
    socketio.run(app, host="0.0.0.0", port=Config.PORT, debug=True, allow_unsafe_werkzeug=True)
