"""Serialización: fila de SQLite -> dict con el shape exacto que espera
el frontend (ver lib/models/alert_model.dart y camera_model.dart).

Mantener esto separado de routes/ significa que si mañana cambia el
motor de base de datos, solo se toca este archivo y db.py — las rutas
no saben ni les importa de dónde viene la fila.
"""
import sqlite3

ALERT_SELECT = """
    SELECT a.*, c.name AS camera_name, z.name AS zone_name
    FROM alerts a
    JOIN cameras c ON c.id = a.camera_id
    JOIN zones z ON z.id = a.zone_id
"""

CAMERA_SELECT = """
    SELECT c.*, z.name AS zone_name
    FROM cameras c
    JOIN zones z ON z.id = c.zone_id
"""


def alert_to_json(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "camera_id": row["camera_id"],
        "zone_id": row["zone_id"],
        "camera_name": row["camera_name"],
        "zone_name": row["zone_name"],
        "vehicle_type": row["vehicle_type"],
        "confidence": row["confidence"],
        "detected_at": row["detected_at"],
        "duration_seconds": row["duration_seconds"],
        "status": row["status"],
        "officer_notes": row["officer_notes"],
        "resolved_at": row["resolved_at"],
        "thumbnail_url": row["thumbnail_url"],
    }


def camera_to_json(row: sqlite3.Row) -> dict:
    return {
        "id": row["id"],
        "name": row["name"],
        "source_url": row["source_url"],
        "zone_id": row["zone_id"],
        "zone_name": row["zone_name"],
        "is_active": row["is_active"],
        "preview_url": row["preview_url"],
    }
