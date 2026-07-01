import 'package:flutter/material.dart';
import '../models/camera_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

/// Grid de cámaras / mosaico CCTV (Sección 13.6). Como /api/cameras
/// no está en el contrato original de la Sección 10, esta pantalla
/// cae a datos mock si el backend aún no expone el endpoint —
/// así el frontend no se bloquea esperando al equipo de backend.
class CamerasScreen extends StatefulWidget {
  const CamerasScreen({super.key});

  @override
  State<CamerasScreen> createState() => _CamerasScreenState();
}

class _CamerasScreenState extends State<CamerasScreen> {
  final _api = ApiService();
  List<CameraModel> _cameras = [];
  bool _loading = true;
  bool _usingMockData = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cameras = await _api.getCameras();
      setState(() {
        _cameras = cameras;
        _loading = false;
        _usingMockData = false;
      });
    } catch (_) {
      setState(() {
        _cameras = _mockCameras();
        _loading = false;
        _usingMockData = true;
      });
    }
  }

  List<CameraModel> _mockCameras() => [
        const CameraModel(id: 1, name: 'Av. Gambetta — Acceso Norte', sourceUrl: '', zoneId: 1, zoneName: 'Zona Restringida A', isActive: true),
        const CameraModel(id: 2, name: 'Av. Néstor Gambetta — Puente', sourceUrl: '', zoneId: 2, zoneName: 'Zona Restringida B', isActive: true),
        const CameraModel(id: 3, name: 'Garita Muelle Norte', sourceUrl: '', zoneId: 3, zoneName: 'Patio de Espera', isActive: true),
        const CameraModel(id: 4, name: 'Av. Argentina — Cruce', sourceUrl: '', zoneId: 4, zoneName: 'Zona Restringida C', isActive: false),
        const CameraModel(id: 5, name: 'Terminal Portuario — Salida', sourceUrl: '', zoneId: 5, zoneName: 'Zona Restringida A', isActive: true),
        const CameraModel(id: 6, name: 'Av. Colonial — Acceso', sourceUrl: '', zoneId: 6, zoneName: 'Patio de Espera', isActive: true),
        const CameraModel(id: 7, name: 'Óvalo 200 Millas', sourceUrl: '', zoneId: 7, zoneName: 'Zona Restringida B', isActive: true),
        const CameraModel(id: 8, name: 'Av. Faucett — Cruce Sur', sourceUrl: '', zoneId: 8, zoneName: 'Zona Restringida C', isActive: false),
      ];

  @override
  Widget build(BuildContext context) {
    final activeCount = _cameras.where((c) => c.isActive).length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Red de Cámaras', style: AppTextStyles.displayMd),
                    const SizedBox(height: 4),
                    Text('$activeCount de ${_cameras.length} cámaras en línea.',
                        style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          if (_usingMockData) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text('Mostrando datos de ejemplo — /api/cameras aún no responde',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.warning)),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: _cameras.length,
                    itemBuilder: (context, i) => _CameraTile(camera: _cameras[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CameraTile extends StatelessWidget {
  final CameraModel camera;
  const _CameraTile({required this.camera});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: camera.isActive ? AppColors.border : AppColors.danger.withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.surfaceElevated,
              child: camera.isActive
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        const Center(
                          child: Icon(Icons.videocam_outlined,
                              size: 28, color: AppColors.textDisabled),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('REC',
                                style: AppTextStyles.label
                                    .copyWith(color: AppColors.danger, fontSize: 10)),
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(Icons.videocam_off_outlined,
                          size: 28, color: AppColors.textDisabled),
                    ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  camera.name,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(camera.zoneName ?? '—',
                          style: AppTextStyles.bodySm, overflow: TextOverflow.ellipsis),
                    ),
                    CameraStatusDot(isActive: camera.isActive),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
