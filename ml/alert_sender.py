"""Envía alertas de vehículo mal estacionado al backend."""
import base64
import cv2
import numpy as np
import requests

from config import ALERT_ENDPOINT, ML_API_KEY


def send_alert(
    track_id: int,
    class_name: str,
    elapsed_seconds: float,
    bbox: tuple[int, int, int, int],
    confidence: float = 0.85,
    frame: np.ndarray | None = None,
) -> bool:
    """
    POST de una alerta al backend. Incluye el frame codificado en base64
    para que el backend lo guarde como thumbnail.
    No lanza excepción si falla la red —
    una alerta perdida no debe tumbar el pipeline de detección.
    Devuelve True si el backend respondió 2xx.
    """
    payload = {
        "track_id": track_id,
        "vehicle_type": class_name,
        "seconds_parked": round(elapsed_seconds, 1),
        "bbox": bbox,
        "confidence": round(confidence, 2),
    }

    if frame is not None:
        _, buffer = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 75])
        payload["frame_b64"] = base64.b64encode(buffer).decode("utf-8")

    headers = {"Authorization": f"Bearer {ML_API_KEY}"}

    try:
        response = requests.post(ALERT_ENDPOINT, json=payload, headers=headers, timeout=5)
        response.raise_for_status()
        return True
    except requests.RequestException as e:
        print(f"[alert_sender] No se pudo enviar alerta (track_id={track_id}): {e}")
        return False
