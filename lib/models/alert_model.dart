/// Estado de una alerta — coincide con la columna `status` de la tabla
/// `alerts` (VARCHAR2(20): "active" | "resolved" | "escalated").
enum AlertStatus { active, resolved, escalated }

extension AlertStatusX on AlertStatus {
  static AlertStatus fromString(String value) {
    switch (value) {
      case 'resolved':
        return AlertStatus.resolved;
      case 'escalated':
        return AlertStatus.escalated;
      default:
        return AlertStatus.active;
    }
  }

  String get apiValue {
    switch (this) {
      case AlertStatus.active:
        return 'active';
      case AlertStatus.resolved:
        return 'resolved';
      case AlertStatus.escalated:
        return 'escalated';
    }
  }

  String get label {
    switch (this) {
      case AlertStatus.active:
        return 'Activa';
      case AlertStatus.resolved:
        return 'Atendida';
      case AlertStatus.escalated:
        return 'Escalada';
    }
  }
}

/// Tipo de vehículo detectado por YOLO26n.
/// Coincide con `vehicle_type` VARCHAR2(50): "truck" | "bus" | "car".
enum VehicleType { truck, bus, car }

extension VehicleTypeX on VehicleType {
  static VehicleType fromString(String value) {
    switch (value) {
      case 'bus':
        return VehicleType.bus;
      case 'car':
        return VehicleType.car;
      default:
        return VehicleType.truck;
    }
  }

  String get label {
    switch (this) {
      case VehicleType.truck:
        return 'Camión';
      case VehicleType.bus:
        return 'Bus';
      case VehicleType.car:
        return 'Auto';
    }
  }
}

/// Representa una fila de la tabla `alerts` (Sección 11 del documento).
/// Se construye tanto desde GET /api/alerts como desde el payload
/// del evento WebSocket "new_alert" (mismo shape).
class AlertModel {
  final int id;
  final int cameraId;
  final int zoneId;
  final String? cameraName; // join opcional que puede mandar el backend
  final String? zoneName; // join opcional que puede mandar el backend
  final VehicleType vehicleType;
  final double confidence; // 0.0 a 1.0
  final DateTime detectedAt;
  final int durationSeconds;
  final AlertStatus status;
  final String? officerNotes;
  final DateTime? resolvedAt;
  final String? thumbnailUrl; // frame capturado, si el backend lo expone

  const AlertModel({
    required this.id,
    required this.cameraId,
    required this.zoneId,
    this.cameraName,
    this.zoneName,
    required this.vehicleType,
    required this.confidence,
    required this.detectedAt,
    required this.durationSeconds,
    required this.status,
    this.officerNotes,
    this.resolvedAt,
    this.thumbnailUrl,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as int,
      cameraId: json['camera_id'] as int,
      zoneId: json['zone_id'] as int,
      cameraName: json['camera_name'] as String?,
      zoneName: json['zone_name'] as String?,
      vehicleType: VehicleTypeX.fromString(json['vehicle_type'] as String? ?? 'truck'),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      detectedAt: DateTime.tryParse(json['detected_at'] as String? ?? '') ?? DateTime.now(),
      durationSeconds: (json['duration_seconds'] as num?)?.toInt() ?? 0,
      status: AlertStatusX.fromString(json['status'] as String? ?? 'active'),
      officerNotes: json['officer_notes'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  AlertModel copyWith({
    AlertStatus? status,
    String? officerNotes,
    DateTime? resolvedAt,
  }) {
    return AlertModel(
      id: id,
      cameraId: cameraId,
      zoneId: zoneId,
      cameraName: cameraName,
      zoneName: zoneName,
      vehicleType: vehicleType,
      confidence: confidence,
      detectedAt: detectedAt,
      durationSeconds: durationSeconds,
      status: status ?? this.status,
      officerNotes: officerNotes ?? this.officerNotes,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      thumbnailUrl: thumbnailUrl,
    );
  }

  /// Impacto económico mitigado por ESTA alerta si se atiende ahora,
  /// según la fórmula validada en la Sección 2 del documento:
  /// Base S/.100/hora por unidad. Si se atiende en 10 min en vez de
  /// 60 min → 50 min ahorrados = S/.83 por alerta.
  static const double impactoPorAlertaResuelta = 83.0;
}
