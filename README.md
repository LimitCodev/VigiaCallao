# VigíaCallao — Frontend (Flutter Desktop)

Centro de Control para el sistema de analítica de video VigíaCallao.
App de escritorio (Windows/Linux/macOS) que consume el backend Flask
vía REST + WebSocket.

## Setup rápido

```bash
cd frontend
flutter pub get
cp .env.example .env
flutter run -d windows   # o -d linux / -d macos según tu SO
```

Asegúrate de que el backend Flask esté corriendo en `http://localhost:5000`
(o ajusta `FLUTTER_APP_BACKEND_URL` en tu `.env`) antes de abrir la app,
o verás el banner de "No se pudo conectar al backend" en el Dashboard.

## Estructura

```
lib/
├── main.dart                  ← entry point
├── config/
│   └── app_config.dart        ← lee variables del .env
├── theme/
│   └── app_theme.dart         ← colores, tipografía, ThemeData
├── models/
│   ├── alert_model.dart       ← coincide con tabla `alerts`
│   └── camera_model.dart      ← coincide con tabla `cameras`
├── services/
│   ├── api_service.dart       ← REST: GET/POST/PATCH /api/alerts
│   └── socket_service.dart    ← WebSocket: evento "new_alert"
├── screens/
│   ├── login_screen.dart
│   ├── main_shell.dart        ← sidebar + navegación + socket global
│   ├── dashboard_screen.dart  ← KPIs + impacto económico
│   ├── alerts_list_screen.dart
│   ├── alert_detail_screen.dart
│   ├── history_screen.dart
│   ├── cameras_screen.dart
│   └── demo_screen.dart       ← pantalla para el jurado (3 julio)
└── widgets/
    ├── app_sidebar.dart
    ├── alert_card.dart
    ├── kpi_card.dart
    └── status_badge.dart
```

## Decisión de diseño: por qué el fondo NO es azul marino

La paleta original del documento maestro define `#1B3A6B` (azul marino
institucional) como color de fondo. En esta implementación se usó como
**acento de marca** (sidebar activo, gradientes, gráficos) en lugar de
fondo, por estas razones:

1. **Es una app de monitoreo de larga duración.** Un fondo azul saturado
   cansa la vista en sesiones de varias horas; el estándar en software
   de centros de control (NOC, salas de tráfico) es un grafito neutro
   casi negro.
2. **Los badges de estado necesitan máximo contraste.** Rojo/ámbar/verde
   compiten en temperatura de color con un fondo azul. Sobre grafito
   neutro, cada estado "salta" sin ambigüedad.
3. **Comunica la identidad del producto.** Un dashboard oscuro tipo
   "sala de vigilancia" refuerza el concepto de "Vigía" mejor que un
   fondo de color institucional plano.

El azul marino institucional sigue presente en todo el producto: logo,
item activo del sidebar, panel de marca del login, gradientes de los
KPIs destacados. No se descartó la identidad — se reubicó donde realmente
suma contraste.

## Conexión con el backend (pendiente del equipo)

Estos puntos del contrato original requieren coordinación con la rama
`backend` antes de la demo:

- `/api/cameras` **no está en el contrato original** (Sección 10) pero
  `CamerasScreen` y el KPI de "Red de Video" del Dashboard lo necesitan.
  Mientras no exista, `CamerasScreen` cae a datos de ejemplo automáticamente.
- El campo `thumbnail_url` en el payload de alertas (frame capturado)
  no está confirmado en el esquema de la Sección 11. Si el backend no
  lo envía, `AlertCard` y `AlertDetailScreen` muestran un placeholder
  en vez de romperse.
- Autenticación: `LoginScreen` actualmente solo valida que los campos
  no estén vacíos y navega directo al `MainShell`. Falta el endpoint
  real de login (no estaba en el contrato de la Sección 10).
