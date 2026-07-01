"""
rtsp_test.py — Prueba de factibilidad: conexión a cámara IP real vía RTSP.

Objetivo: demostrar, con evidencia real (no solo en el papel), que la
arquitectura del prototipo migra a producción sin reescribir código —
solo cambiando VIDEO_SOURCE de un archivo local a una URL RTSP.

Cómo generar la evidencia para el Manual de Arquitectura:
  1. Instala una app de cámara IP en tu celular (ej. "IP Webcam" en
     Android — gratis, activa el servidor RTSP en su configuración).
  2. La app te dará una URL tipo: rtsp://192.168.1.XX:8080/h264_ulaw.sdp
     (usa la IP que muestre la app, dentro de tu misma red WiFi).
  3. Corré: python rtsp_test.py rtsp://192.168.1.XX:8080/h264_ulaw.sdp
  4. Vas a ver una ventana con el feed en vivo de tu celular + las
     detecciones YOLO encima (usa el mismo VehicleDetector del
     pipeline principal — cero cambios de código, es la prueba misma).
  5. Capturá pantalla o grabá 10-15s con esa ventana abierta.
     Eso es tu evidencia de factibilidad para el manual.

Si no tenés forma de generar un RTSP propio, también podés probar
contra un stream RTSP de prueba público (buscá "public RTSP test
stream" — los hay de cámaras de tránsito o demos de fabricantes),
aunque el celular propio es más convincente porque es evidencia
verificable y reproducible en el momento si te preguntan en la
exposición.
"""
import sys
import time

import cv2

from detector import VehicleDetector


def main() -> None:
    if len(sys.argv) < 2:
        print("Uso: python rtsp_test.py <rtsp_url>")
        print("Ejemplo: python rtsp_test.py rtsp://192.168.1.50:8080/h264_ulaw.sdp")
        sys.exit(1)

    rtsp_url = sys.argv[1]
    print(f"[rtsp_test] Conectando a: {rtsp_url}")

    cap = cv2.VideoCapture(rtsp_url)
    if not cap.isOpened():
        print("[rtsp_test] ERROR: no se pudo abrir el stream RTSP.")
        print("  Revisa que el celular y la laptop estén en la misma red WiFi,")
        print("  que la app de cámara IP esté con el servidor RTSP activo,")
        print("  y que la URL tenga el puerto/IP correctos.")
        sys.exit(1)

    print("[rtsp_test] Conexión RTSP exitosa. Cargando modelo YOLO...")
    detector = VehicleDetector()
    print("[rtsp_test] Modelo cargado. Mostrando feed en vivo (q para salir)...")

    frame_count = 0
    start = time.time()

    while True:
        ret, frame = cap.read()
        if not ret:
            print("[rtsp_test] Stream cortado o sin frames nuevos.")
            break

        frame_count += 1
        detections = detector.detect(frame)

        for d in detections:
            x1, y1, x2, y2 = d.bbox
            cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 200, 0), 2)
            label = f"#{d.track_id} {d.class_name} {d.confidence:.2f}"
            cv2.putText(frame, label, (x1, y1 - 8), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 200, 0), 2)

        elapsed = time.time() - start
        fps = frame_count / elapsed if elapsed > 0 else 0
        cv2.putText(frame, f"RTSP en vivo | {fps:.1f} fps | {len(detections)} vehiculos",
                    (10, 25), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 140, 255), 2)

        cv2.imshow("VigiaCallao - Prueba RTSP (evidencia de factibilidad)", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()
    print(f"[rtsp_test] Terminado. {frame_count} frames procesados en {time.time()-start:.1f}s.")


if __name__ == "__main__":
    main()
