import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/alert_model.dart';
import '../models/camera_model.dart';

/// Excepción de dominio para errores de red/API, para que la UI
/// pueda mostrar mensajes claros en vez de stack traces.
class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Cliente REST para el backend Flask. Cubre exactamente los endpoints
/// definidos en la Sección 10 (Contrato de API REST) del documento.
class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  /// GET /api/alerts?status=active&limit=50
  Future<List<AlertModel>> getAlerts({String? status, int limit = 50}) async {
    final uri = Uri.parse(AppConfig.alertsEndpoint).replace(queryParameters: {
      if (status != null) 'status': status,
      'limit': '$limit',
    });

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw ApiException('El servidor respondió ${res.statusCode} al pedir alertas.');
      }
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => AlertModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('No se pudo conectar al backend ($e)');
    }
  }

  /// GET /api/alerts/:id
  Future<AlertModel> getAlertById(int id) async {
    final uri = Uri.parse('${AppConfig.alertsEndpoint}/$id');
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw ApiException('No se encontró la alerta #$id.');
      }
      return AlertModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('No se pudo conectar al backend ($e)');
    }
  }

  /// PATCH /api/alerts/:id
  /// Body: { status: "resolved"|"escalated", officer_notes }
  Future<AlertModel> updateAlert({
    required int id,
    required AlertStatus status,
    String? officerNotes,
  }) async {
    final uri = Uri.parse('${AppConfig.alertsEndpoint}/$id');
    try {
      final res = await _client
          .patch(
            uri,
            headers: _jsonHeaders,
            body: jsonEncode({
              'status': status.apiValue,
              if (officerNotes != null) 'officer_notes': officerNotes,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        throw ApiException('No se pudo actualizar la alerta #$id.');
      }
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      // El PATCH puede devolver solo {id, status, updated_at}; si es así,
      // reconstituimos localmente en vez de re-fetch para UI instantánea.
      return AlertModel(
        id: id,
        cameraId: 0,
        zoneId: 0,
        vehicleType: VehicleType.truck,
        confidence: 0,
        detectedAt: DateTime.now(),
        durationSeconds: 0,
        status: AlertStatusX.fromString(body['status'] as String? ?? status.apiValue),
        officerNotes: officerNotes,
        resolvedAt: status == AlertStatus.resolved ? DateTime.now() : null,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('No se pudo conectar al backend ($e)');
    }
  }

  /// GET /api/health
  Future<bool> checkHealth() async {
    try {
      final res = await _client
          .get(Uri.parse(AppConfig.healthEndpoint))
          .timeout(const Duration(seconds: 5));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// GET /api/cameras — no está en el contrato original pero es necesario
  /// para CamerasScreen; el backend deberá exponerlo con el mismo patrón
  /// que /api/alerts. Si aún no existe, esta llamada falla controladamente
  /// y la pantalla puede mostrar datos mock mientras tanto.
  Future<List<CameraModel>> getCameras() async {
    try {
      final res = await _client
          .get(Uri.parse(AppConfig.camerasEndpoint))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) {
        throw ApiException('El servidor respondió ${res.statusCode} al pedir cámaras.');
      }
      final List<dynamic> data = jsonDecode(res.body) as List<dynamic>;
      return data.map((e) => CameraModel.fromJson(e as Map<String, dynamic>)).toList();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('No se pudo conectar al backend ($e)');
    }
  }

  void dispose() => _client.close();
}
