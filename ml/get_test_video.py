"""
get_test_video.py
Verifica que exista un video de prueba en ml/test_video/demo.mp4.
Si no existe, imprime instrucciones para conseguir uno apto para YOLO.

No descarga nada automáticamente (las URLs públicas cambian o caen);
el video real se agrega manualmente más adelante, una vez grabado/editado.

Uso: python get_test_video.py
"""
import sys
from pathlib import Path

EXPECTED_PATH = Path(__file__).parent / "test_video" / "demo.mp4"

RECOMENDACIONES = """
Características recomendadas para el video de prueba:

  - Resolución:   1280x720 o superior (no exagerar, más peso = más lento)
  - Duración:     30-90 segundos es suficiente para probar el pipeline
  - FPS fuente:   24-30 fps (no afecta mucho, igual se procesa a PROCESSING_FPS)
  - Formato:      .mp4 (h264), evitar .mkv/.avi si se puede
  - Contenido:    vista fija de cámara (no handheld), ángulo similar al que
                  tendrá la cámara real en Puerto del Callao — vehículos
                  pesados (camiones/buses) entrando/saliendo o estacionados
                  en una zona delimitada
  - Iluminación:  preferible diurna para la primera validación; luego
                  probar con condiciones más difíciles (noche, lluvia)

Una vez que tengas el archivo:
  1. Colocalo en: ml/test_video/demo.mp4
  2. Corré: python calibrate.py   (para definir RESTRICTED_ZONE)
  3. Pegá el RESTRICTED_ZONE resultante en tu .env
"""

def main() -> None:
    if EXPECTED_PATH.exists():
        size_mb = EXPECTED_PATH.stat().st_size / (1024 * 1024)
        print(f"[get_test_video] OK — encontrado: {EXPECTED_PATH} ({size_mb:.1f} MB)")
        return

    print(f"[get_test_video] No se encontró video en: {EXPECTED_PATH}")
    print(RECOMENDACIONES)
    sys.exit(1)

if __name__ == "__main__":
    main()
