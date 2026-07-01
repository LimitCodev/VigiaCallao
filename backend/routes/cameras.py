from flask import Blueprint, jsonify

from db import get_db
from models import CAMERA_SELECT, camera_to_json

bp = Blueprint("cameras", __name__)


@bp.get("/api/cameras")
def list_cameras():
    rows = get_db().execute(CAMERA_SELECT).fetchall()
    return jsonify([camera_to_json(r) for r in rows]), 200
