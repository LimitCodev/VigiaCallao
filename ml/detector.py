"""
detector.py
Encapsula el modelo YOLO26n + tracker BoT-SORT.

Responsabilidad única: recibir un frame (numpy array BGR de OpenCV) y
devolver una lista de detecciones de vehículos con su track_id, listas
para que zone_monitor.py decida si están en zona restringida.

No conoce nada del video fuente, de la zona restringida ni del backend —
solo hace inferencia + tracking. Esto permite probarlo con cualquier
frame (webcam, video genérico, imagen suelta) sin esperar al video final.
"""
from dataclasses import dataclass

from ultralytics import YOLO

from config import YOLO_MODEL, DETECTION_CONFIDENCE, VEHICLE_CLASSES


@dataclass
class Detection:
    """Una detección individual ya trackeada."""
    track_id: int
    class_id: int
    class_name: str
    confidence: float
    # Bounding box en coordenadas de píxeles: (x1, y1, x2, y2)
    bbox: tuple[int, int, int, int]

    @property
    def center(self) -> tuple[int, int]:
        """Centro del bounding box — usado por zone_monitor para chequear zona."""
        x1, y1, x2, y2 = self.bbox
        return ((x1 + x2) // 2, (y1 + y2) // 2)


class VehicleDetector:
    """
    Wrapper sobre YOLO con tracking BoT-SORT habilitado.

    Mantiene el modelo cargado en memoria (carga es costosa, ~1-2s),
    se instancia una sola vez en main.py y se reutiliza frame a frame.
    """

    def __init__(self) -> None:
        self.model = YOLO(YOLO_MODEL)

    def detect(self, frame) -> list[Detection]:
        """
        Corre detección + tracking sobre un frame.

        Args:
            frame: numpy array BGR (el formato nativo de cv2.VideoCapture.read())

        Returns:
            Lista de Detection, una por cada vehículo trackeado en el frame.
            Vacía si no hay vehículos o si el tracker aún no asignó ID
            (puede pasar en los primeros frames de un track nuevo).
        """
        results = self.model.track(
            frame,
            persist=True,              # mantiene tracks entre llamadas sucesivas
            tracker="botsort.yaml",    # tracker BoT-SORT (incluido en ultralytics)
            classes=VEHICLE_CLASSES,   # solo car/bus/truck, ignora el resto
            conf=DETECTION_CONFIDENCE,
            verbose=False,
        )

        detections: list[Detection] = []
        result = results[0]

        # Si el tracker todavía no asignó IDs (primer frame), boxes.id es None
        if result.boxes is None or result.boxes.id is None:
            return detections

        boxes = result.boxes
        for i in range(len(boxes)):
            track_id = int(boxes.id[i])
            class_id = int(boxes.cls[i])
            confidence = float(boxes.conf[i])
            x1, y1, x2, y2 = boxes.xyxy[i].tolist()

            detections.append(Detection(
                track_id=track_id,
                class_id=class_id,
                class_name=self.model.names[class_id],
                confidence=confidence,
                bbox=(int(x1), int(y1), int(x2), int(y2)),
            ))

        return detections
