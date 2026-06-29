/// Representa una fila de la tabla `cameras` (Sección 11 del documento).
/// Usado en CamerasScreen para el mosaico CCTV y en KPIs del dashboard
/// ("Estado de la Red de Video: Activas / Total").
class CameraModel {
  final int id;
  final String name;
  final String sourceUrl; // RTSP o path de archivo (no se muestra en UI)
  final int zoneId;
  final String? zoneName;
  final bool isActive;
  final String? previewUrl; // último frame / snapshot, si el backend lo expone

  const CameraModel({
    required this.id,
    required this.name,
    required this.sourceUrl,
    required this.zoneId,
    this.zoneName,
    required this.isActive,
    this.previewUrl,
  });

  factory CameraModel.fromJson(Map<String, dynamic> json) {
    return CameraModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Cámara sin nombre',
      sourceUrl: json['source_url'] as String? ?? '',
      zoneId: json['zone_id'] as int? ?? 0,
      zoneName: json['zone_name'] as String?,
      isActive: (json['is_active'] as num?)?.toInt() == 1,
      previewUrl: json['preview_url'] as String?,
    );
  }
}
