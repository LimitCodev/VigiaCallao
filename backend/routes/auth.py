from datetime import datetime, timedelta, timezone

from flask import Blueprint, jsonify, request

bp = Blueprint("auth", __name__)

USERS = {"admin": "callao2026", "operador": "demo1234"}

@bp.post("/api/auth/login")
def login():
    body = request.get_json(silent=True) or {}
    username = body.get("username", "").strip()
    password = body.get("password", "")

    expected = USERS.get(username)
    if expected is None or password != expected:
        return jsonify({"error": "Credenciales inválidas"}), 401

    return jsonify({
        "token": f"tok_{username}_{int(datetime.now(timezone.utc).timestamp())}",
        "user": username,
        "role": "fiscalizador",
    }), 200
