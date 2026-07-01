"""Endpoints de alertas.

Dos consumidores muy distintos pegan acá:
  - El frontend Flutter: GET (lista + detalle) y PATCH (cambiar estado).
  - El pipeline ML (ml/alert_sender.py): POST, autenticado con un bearer
    token fijo (ML_API_KEY) porque corre en la misma laptop, sin login
    de usuario — es un servicio a servicio, no un endpoint de cara al
    operador.
"""
import base64
import csv
import os
import random
import sqlite3
import threading
import time as time_module
from datetime import datetime, timezone
from io import StringIO

from flask import Blueprint, jsonify, request, Response

from config import Config
from db import get_db
from extensions import socketio
from models import ALERT_SELECT, alert_to_json

DEMO_VIDEO_PATH = os.path.join(os.path.dirname(__file__), "..", "static", "demo", "demo.mp4")

bp = Blueprint("alerts", __name__)


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _save_thumbnail(track_id: int, frame_b64: str | None) -> str | None:
    if not frame_b64:
        return None
    try:
        thumb_dir = os.path.join(os.path.dirname(__file__), "..", "static", "thumbnails")
        os.makedirs(thumb_dir, exist_ok=True)
        filename = f"alert_{track_id}.jpg"
        filepath = os.path.join(thumb_dir, filename)
        with open(filepath, "wb") as f:
            f.write(base64.b64decode(frame_b64))
        return f"http://localhost:{Config.PORT}/static/thumbnails/{filename}"
    except Exception as e:
        print(f"[alerts] Error guardando thumbnail: {e}")
        return None


def _demo_frame_b64() -> str | None:
    import cv2
    try:
        cap = cv2.VideoCapture(DEMO_VIDEO_PATH)
        total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        cap.set(cv2.CAP_PROP_POS_FRAMES, random.randint(0, max(total - 1, 0)))
        ret, frame = cap.read()
        cap.release()
        if not ret:
            return None
        _, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 75])
        return base64.b64encode(buffer).decode("utf-8")
    except Exception as e:
        print(f"[alerts] Error capturando frame demo: {e}")
        return None


@bp.get("/api/alerts/export/csv")
def export_alerts_csv():
    rows = get_db().execute(ALERT_SELECT + " ORDER BY a.detected_at DESC").fetchall()
    si = StringIO()
    writer = csv.writer(si)
    writer.writerow(["id", "zona", "camara", "vehiculo", "confianza", "detectado", "duracion_s", "estado", "notas"])
    for r in rows:
        writer.writerow([r["id"], r["zone_name"], r["camera_name"], r["vehicle_type"],
                         r["confidence"], r["detected_at"], r["duration_seconds"],
                         r["status"], r["officer_notes"] or ""])
    return Response(si.getvalue(), mimetype="text/csv",
                    headers={"Content-Disposition": "attachment; filename=alertas_vigiacallao.csv"})

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
    alert_json = alert_to_json(updated)
    socketio.emit("update_alert", alert_json)
    return jsonify(alert_json), 200


_demo_cap = None
_demo_sim_running = False
_demo_sim_lock = threading.Lock()


@bp.get("/api/demo/frame")
def demo_frame():
    """Devuelve el siguiente frame del video como JPEG. Hace loop al final."""
    import cv2
    global _demo_cap
    if _demo_cap is None or not _demo_cap.isOpened():
        _demo_cap = cv2.VideoCapture(DEMO_VIDEO_PATH)
    ret, frame = _demo_cap.read()
    if not ret:
        _demo_cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
        ret, frame = _demo_cap.read()
        if not ret:
            return Response("", status=500)
    _, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 60])
    return Response(buffer.tobytes(), mimetype="image/jpeg")


@bp.post("/api/demo/start")
def demo_start():
    """Inicia la simulación completa: alertas automáticas cada ~5s."""
    global _demo_sim_running
    with _demo_sim_lock:
        if _demo_sim_running:
            return jsonify({"status": "ya en ejecución"}), 200
        _demo_sim_running = True
    threading.Thread(target=_demo_simulation, daemon=True).start()
    return jsonify({"status": "simulación iniciada"}), 200


@bp.post("/api/demo/trigger")
def demo_trigger():
    """Genera una alerta individual de demostración con thumbnail real."""
    track_id = random.randint(200, 999)
    vehicle_type = random.choice(["truck", "bus", "car"])
    seconds_parked = random.randint(10, 60)
    confidence = round(random.uniform(0.75, 0.98), 2)
    thumbnail_url = _save_thumbnail(track_id, _demo_frame_b64())

    db = get_db()
    db.execute(
        "INSERT INTO alerts (camera_id, zone_id, track_id, vehicle_type, confidence, "
        "detected_at, duration_seconds, status, thumbnail_url) "
        "VALUES (1, 1, ?, ?, ?, ?, ?, 'active', ?)",
        (track_id, vehicle_type, confidence, _now_iso(), seconds_parked, thumbnail_url),
    )
    db.commit()
    new_id = db.execute("SELECT last_insert_rowid()").fetchone()[0]
    row = db.execute(ALERT_SELECT + " WHERE a.id = ?", (new_id,)).fetchone()
    alert_json = alert_to_json(row)

    socketio.emit("new_alert", alert_json)
    return jsonify(alert_json), 201


def _demo_simulation():
    """Genera alertas automáticas en intervalos para la demo, cada una con thumbnail."""
    global _demo_sim_running
    conn = sqlite3.connect(Config.DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")

    try:
        for i in range(10):
            track_id = 300 + i
            vehicle_type = random.choice(["truck", "bus", "car"])
            seconds_parked = random.randint(10, 45)
            confidence = round(random.uniform(0.78, 0.96), 2)
            thumbnail_url = _save_thumbnail(track_id, _demo_frame_b64())

            conn.execute(
                "INSERT INTO alerts (camera_id, zone_id, track_id, vehicle_type, "
                "confidence, detected_at, duration_seconds, status, thumbnail_url) "
                "VALUES (1, 1, ?, ?, ?, ?, ?, 'active', ?)",
                (track_id, vehicle_type, confidence, _now_iso(), seconds_parked, thumbnail_url),
            )
            conn.commit()
            new_id = conn.execute("SELECT last_insert_rowid()").fetchone()[0]
            row = conn.execute("SELECT a.*, c.name AS camera_name, z.name AS zone_name FROM alerts a JOIN cameras c ON c.id = a.camera_id JOIN zones z ON z.id = a.zone_id WHERE a.id = ?", (new_id,)).fetchone()
            alert_json = alert_to_json(row)
            socketio.emit("new_alert", alert_json)
            print(f"[demo] Alerta #{new_id}: {vehicle_type} track={track_id}")
            time_module.sleep(random.uniform(5, 10))
    except Exception as e:
        print(f"[demo] Error en simulación: {e}")
    finally:
        with _demo_sim_lock:
            _demo_sim_running = False
        conn.close()


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

    frame_b64 = body.get("frame_b64")

    db = get_db()
    existing = db.execute(
        "SELECT id FROM alerts WHERE track_id = ? AND status = 'active' "
        "ORDER BY id DESC LIMIT 1",
        (track_id,),
    ).fetchone()

    if existing:
        thumbnail_url = _save_thumbnail(track_id, frame_b64)
        db.execute(
            "UPDATE alerts SET duration_seconds = ?, confidence = ?, "
            "thumbnail_url = COALESCE(?, thumbnail_url) WHERE id = ?",
            (seconds_parked, confidence, thumbnail_url, existing["id"]),
        )
        db.commit()
        row = db.execute(ALERT_SELECT + " WHERE a.id = ?", (existing["id"],)).fetchone()
        # Sin emit: el frontend ya tiene esta alerta listada, solo cambia
        # duration_seconds y no vale la pena empujar un evento por frame.
        return jsonify(alert_to_json(row)), 200

    thumbnail_url = _save_thumbnail(track_id, frame_b64)
    db.execute(
        "INSERT INTO alerts (camera_id, zone_id, track_id, vehicle_type, confidence, "
        "detected_at, duration_seconds, status, thumbnail_url) "
        "VALUES (1, 1, ?, ?, ?, ?, ?, 'active', ?)",
        (track_id, vehicle_type, confidence, _now_iso(), seconds_parked, thumbnail_url),
    )
    db.commit()
    new_id = db.execute("SELECT last_insert_rowid()").fetchone()[0]
    row = db.execute(ALERT_SELECT + " WHERE a.id = ?", (new_id,)).fetchone()
    alert_json = alert_to_json(row)

    socketio.emit("new_alert", alert_json)
    return jsonify(alert_json), 201
