"""Acceso a datos: conexión SQLite por request + esquema + seed inicial.

Se usa SQLite en desarrollo local (USE_ORACLE=False en el .env original
del proyecto). Las funciones de este módulo son la única frontera entre
el resto del backend y el motor de base de datos real, así que migrar a
Oracle Cloud más adelante implica reescribir este archivo, no tocar las
rutas.
"""
import sqlite3

from flask import g

from config import Config

SCHEMA = """
CREATE TABLE IF NOT EXISTS zones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS cameras (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    source_url TEXT NOT NULL,
    zone_id INTEGER NOT NULL REFERENCES zones(id),
    is_active INTEGER NOT NULL DEFAULT 1,
    preview_url TEXT
);

CREATE TABLE IF NOT EXISTS alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    camera_id INTEGER NOT NULL REFERENCES cameras(id),
    zone_id INTEGER NOT NULL REFERENCES zones(id),
    track_id INTEGER,
    vehicle_type TEXT NOT NULL,
    confidence REAL NOT NULL DEFAULT 0.0,
    detected_at TEXT NOT NULL,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    officer_notes TEXT,
    resolved_at TEXT,
    thumbnail_url TEXT
);
"""


def get_db() -> sqlite3.Connection:
    """Devuelve la conexión de este request, creándola si no existe.

    Flask's `g` vive solo durante el request actual, así que cada
    petición HTTP obtiene su propia conexión y no hay que preocuparse
    por compartir cursores entre threads.
    """
    if "db" not in g:
        g.db = sqlite3.connect(Config.DB_PATH)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


def close_db(_exc=None) -> None:
    db = g.pop("db", None)
    if db is not None:
        db.close()


def init_db() -> None:
    """Crea el esquema si no existe y siembra una cámara/zona demo.

    Se corre una sola vez al arrancar el proceso (fuera del ciclo de
    request), por eso abre su propia conexión en vez de usar get_db().
    """
    conn = sqlite3.connect(Config.DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.executescript(SCHEMA)
    conn.commit()

    if conn.execute("SELECT COUNT(*) FROM zones").fetchone()[0] == 0:
        conn.execute(
            "INSERT INTO zones (id, name) VALUES (1, ?)",
            ("Zona Restringida - Muelle 5",),
        )
        conn.execute(
            "INSERT INTO cameras (id, name, source_url, zone_id, is_active) "
            "VALUES (1, ?, ?, 1, 1)",
            ("Cámara Puerto del Callao 1", Config.VIDEO_SOURCE),
        )
        conn.commit()
        print("[db] Esquema creado. Sembrado: zona 1 + cámara 1.")

    conn.close()
