"""Punto de entrada: procesa VIDEO_SOURCE frame a frame y dispara alertas."""
import cv2

from config import VIDEO_SOURCE, PROCESSING_FPS, RESTRICTED_ZONE
from config import COLOR_OK, COLOR_WARNING, COLOR_ALERT, COLOR_ZONE
from detector import VehicleDetector
from zone_monitor import ZoneMonitor
from alert_sender import send_alert


def _draw(frame, detections, monitor: ZoneMonitor) -> None:
    x1, y1, x2, y2 = RESTRICTED_ZONE
    cv2.rectangle(frame, (x1, y1), (x2, y2), COLOR_ZONE, 2)

    for d in detections:
        alert, elapsed = monitor.update(d.track_id, d.center)
        if elapsed == 0.0:
            color = COLOR_OK
        elif alert:
            color = COLOR_ALERT
        else:
            color = COLOR_WARNING

        bx1, by1, bx2, by2 = d.bbox
        cv2.rectangle(frame, (bx1, by1), (bx2, by2), color, 2)
        label = f"#{d.track_id} {d.class_name} {elapsed:.0f}s"
        cv2.putText(frame, label, (bx1, by1 - 8), cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)

        if alert:
            send_alert(d.track_id, d.class_name, elapsed, d.bbox)


def main() -> None:
    cap = cv2.VideoCapture(VIDEO_SOURCE)
    if not cap.isOpened():
        print(f"[main] No se pudo abrir VIDEO_SOURCE: {VIDEO_SOURCE}")
        return

    detector = VehicleDetector()
    monitor = ZoneMonitor()

    source_fps = cap.get(cv2.CAP_PROP_FPS) or 30
    frame_skip = max(1, round(source_fps / PROCESSING_FPS))
    frame_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame_count += 1
        if frame_count % frame_skip != 0:
            continue

        detections = detector.detect(frame)
        monitor.remove_stale({d.track_id for d in detections})
        _draw(frame, detections, monitor)

        cv2.imshow("VigiaCallao", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
