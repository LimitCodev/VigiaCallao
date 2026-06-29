import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lee las variables de entorno definidas en `frontend/.env`.
/// Coincide con la sección "FRONTEND — Flutter" del .env.example
/// del documento maestro (Sección 9).
class AppConfig {
  AppConfig._();

  static String get backendUrl =>
      dotenv.env['FLUTTER_APP_BACKEND_URL'] ?? 'http://localhost:5000';

  static String get socketUrl =>
      dotenv.env['FLUTTER_APP_SOCKET_URL'] ?? 'http://localhost:5000';

  static String get appName =>
      dotenv.env['FLUTTER_APP_NAME'] ?? 'VigíaCallao';

  static String get appVersion =>
      dotenv.env['FLUTTER_APP_VERSION'] ?? '0.1.0';

  // Endpoints REST (prefijo /api obligatorio, Sección 10).
  static String get alertsEndpoint => '$backendUrl/api/alerts';
  static String get healthEndpoint => '$backendUrl/api/health';
  static String get camerasEndpoint => '$backendUrl/api/cameras';

  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }
}
