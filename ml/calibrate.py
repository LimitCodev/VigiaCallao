"""
calibrate.py
Herramienta interactiva para definir RESTRICTED_ZONE.
Abrí el video, hacé click en dos esquinas del área a vigilar
y el script imprime las coordenadas listas para pegar en .env.

Uso: python calibrate.py
"""
import cv2
import sys
from config import VIDEO_SOURCE

points: list[tuple[int, int]] = []

def _on_click(event, x, y, flags, param):
    if event == cv2.EVENT_LBUTTONDOWN:
        points.append((x, y))
        print(f"  Punto {len(points)}: ({x}, {y})")
        if len(points) == 2:
            x1, y1 = points[0]
            x2, y2 = points[1]
            zone = f"{min(x1,x2)},{min(y1,y2)},{max(x1,x2)},{max(y1,y2)}"
            print(f"\n  Copiá esto en tu .env:")
            print(f"  RESTRICTED_ZONE={zone}\n")

def main():
    cap = cv2.VideoCapture(VIDEO_SOURCE)
    if not cap.isOpened():
        print(f"[calibrate] No se pudo abrir: {VIDEO_SOURCE}")
        sys.exit(1)

    ret, frame = cap.read()
    cap.release()
    if not ret:
        print("[calibrate] No se pudo leer el primer frame.")
        sys.exit(1)

    print("Instrucciones:")
    print("  1. Hacé click en la esquina SUPERIOR IZQUIERDA de la zona")
    print("  2. Hacé click en la esquina INFERIOR DERECHA")
    print("  3. Copiá RESTRICTED_ZONE al .env")
    print("  Presioná 'r' para reiniciar, 'q' para salir\n")

    cv2.namedWindow("calibrate — VigiaCallao")
    cv2.setMouseCallback("calibrate — VigiaCallao", _on_click)

    while True:
        display = frame.copy()

        # Dibujar puntos y zona si hay selección parcial o completa
        for p in points:
            cv2.circle(display, p, 5, (0, 255, 0), -1)
        if len(points) == 2:
            cv2.rectangle(display, points[0], points[1], (0, 140, 255), 2)
            cv2.putText(display, "ZONA OK — presiona 'q'",
                        (points[0][0], points[0][1] - 10),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 140, 255), 2)

        cv2.imshow("calibrate — VigiaCallao", display)
        key = cv2.waitKey(20) & 0xFF
        if key == ord('q'):
            break
        if key == ord('r'):
            points.clear()
            print("Reiniciado. Volvé a clickear.")

    cv2.destroyAllWindows()

if __name__ == "__main__":
    main()
