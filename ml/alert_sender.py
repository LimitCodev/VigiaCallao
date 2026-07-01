"""Envía alertas de vehículo mal estacionado al backend."""
import requests

from config import ALERT_ENDPOINT, ML_API_KEY


def send_alert(
    track_id: int,
    class_name: str,
    elapsed_seconds: float,
    bbox: tuple[int, int, int, int],
    confidence: float = 0.85,
) -> bool:
    """
    POST de una alerta al backend. No lanza excepción si falla la red —
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
    headers = {"Authorization": f"Bearer {ML_API_KEY}"}

    try:
        response = requests.post(ALERT_ENDPOINT, json=payload, headers=headers, timeout=5)
        response.raise_for_status()
        return True
    except requests.RequestException as e:
        print(f"[alert_sender] No se pudo enviar alerta (track_id={track_id}): {e}")
        return False
