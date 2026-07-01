"""Endpoints de alertas.

Dos consumidores muy distintos pegan acá:
  - El frontend Flutter: GET (lista + detalle) y PATCH (cambiar estado).
  - El pipeline ML (ml/alert_sender.py): POST, autenticado con un bearer
    token fijo (ML_API_KEY) porque corre en la misma laptop, sin login
    de usuario — es un servicio a servicio, no un endpoint de cara al
    operador.
"""
from datetime import datetime, timezone

from flask import Blueprint, jsonify, request

from config import Config
from db import get_db
from extensions import socketio
from models import ALERT_SELECT, alert_to_json

bp = Blueprint("alerts", __name__)


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


@bp.get("/api/alerts")
def list_alerts():
    status = request.args.get("status")
    limit = request.args.get("limit", default=50, type=int)

    query = ALERT_SELECT
    params: list = []
    if status:
        query += " WHERE a.status = ?"
        params.append(status)
    query += " ORDER BY a.detected_at DESC LIMIT ?"
    params.append(limit)

    rows = get_db().execute(query, params).fetchall()
    return jsonify([alert_to_json(r) for r in rows]), 200


@bp.get("/api/alerts/<int:alert_id>")
def get_alert(alert_id: int):
    row = get_db().execute(ALERT_SELECT + " WHERE a.id = ?", (alert_id,)).fetchone()
    if row is None:
        return jsonify({"error": "No encontrado"}), 404
    return jsonify(alert_to_json(row)), 200


@bp.patch("/api/alerts/<int:alert_id>")
def update_alert(alert_id: int):
    body = request.get_json(silent=True) or {}
    status = body.get("status")
    officer_notes = body.get("officer_notes")

    if status not in (None, "active", "resolved", "escalated"):
        return jsonify({"error": "status inválido"}), 400

    db = get_db()
    row = db.execute("SELECT * FROM alerts WHERE id = ?", (alert_id,)).fetchone()
    if row is None:
        return jsonify({"error": "No encontrado"}), 404

    new_status = status or row["status"]
    resolved_at = _now_iso() if new_status == "resolved" else row["resolved_at"]

    db.execute(
        "UPDATE alerts SET status = ?, officer_notes = COALESCE(?, officer_notes), "
        "resolved_at = ? WHERE id = ?",
        (new_status, officer_notes, resolved_at, alert_id),
    )
    db.commit()

    updated = db.execute(ALERT_SELECT + " WHERE a.id = ?", (alert_id,)).fetchone()
    return jsonify(alert_to_json(updated)), 200


@bp.post("/api/alerts")
def receive_ml_alert():
    """Ingesta desde el pipeline ML.

    Hace upsert por track_id: el pipeline llama a este endpoint en
    cada frame procesado mientras un vehículo sigue en infracción, así
    que sin upsert se generaría una fila nueva por frame en vez de una
    sola alerta que va acumulando duration_seconds.
    """
    if request.headers.get("Authorization") != f"Bearer {Config.ML_API_KEY}":
        return jsonify({"error": "No autorizado"}), 401

    body = request.get_json(silent=True) or {}
    track_id = body.get("track_id")
    if track_id is None:
        return jsonify({"error": "track_id requerido"}), 400

    vehicle_type = body.get("vehicle_type", "truck")
    seconds_parked = int(body.get("seconds_parked", 0))
    confidence = float(body.get("confidence", 0.85))

    db = get_db()
    existing = db.execute(
        "SELECT id FROM alerts WHERE track_id = ? AND status = 'active' "
        "ORDER BY id DESC LIMIT 1",
        (track_id,),
    ).fetchone()

    if existing:
        db.execute(
            "UPDATE alerts SET duration_seconds = ?, confidence = ? WHERE id = ?",
            (seconds_parked, confidence, existing["id"]),
        )
        db.commit()
        row = db.execute(ALERT_SELECT + " WHERE a.id = ?", (existing["id"],)).fetchone()
        # Sin emit: el frontend ya tiene esta alerta listada, solo cambia
        # duration_seconds y no vale la pena empujar un evento por frame.
        return jsonify(alert_to_json(row)), 200

    db.execute(
        "INSERT INTO alerts (camera_id, zone_id, track_id, vehicle_type, confidence, "
        "detected_at, duration_seconds, status) VALUES (1, 1, ?, ?, ?, ?, ?, 'active')",
        (track_id, vehicle_type, confidence, _now_iso(), seconds_parked),
    )
    db.commit()
    new_id = db.execute("SELECT last_insert_rowid()").fetchone()[0]
    row = db.execute(ALERT_SELECT + " WHERE a.id = ?", (new_id,)).fetchone()
    alert_json = alert_to_json(row)

    socketio.emit("new_alert", alert_json)
    return jsonify(alert_json), 201
