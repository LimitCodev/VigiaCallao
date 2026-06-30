"""Decide si un vehículo trackeado lleva demasiado tiempo dentro de la zona restringida."""
import time

from config import RESTRICTED_ZONE, PARKING_THRESHOLD_SECONDS


class ZoneMonitor:
    def __init__(self) -> None:
        self.zone = RESTRICTED_ZONE  # (x1, y1, x2, y2)
        self.threshold = PARKING_THRESHOLD_SECONDS
        self._tracked_since: dict[int, float] = {}  # track_id -> timestamp de entrada

    def _in_zone(self, point: tuple[int, int]) -> bool:
        x, y = point
        x1, y1, x2, y2 = self.zone
        return x1 <= x <= x2 and y1 <= y <= y2

    def update(self, track_id: int, center: tuple[int, int]) -> tuple[bool, float]:
        """
        Registra la posición actual de un track y devuelve (alerta, segundos_en_zona).
        alerta=True cuando supera PARKING_THRESHOLD_SECONDS.
        """
        now = time.time()

        if not self._in_zone(center):
            self._tracked_since.pop(track_id, None)
            return False, 0.0

        if track_id not in self._tracked_since:
            self._tracked_since[track_id] = now

        elapsed = now - self._tracked_since[track_id]
        return elapsed >= self.threshold, elapsed

    def remove_stale(self, active_track_ids: set[int]) -> None:
        """Limpia tracks que ya no aparecen (vehículo salió de cuadro)."""
        stale = set(self._tracked_since) - active_track_ids
        for track_id in stale:
            del self._tracked_since[track_id]
