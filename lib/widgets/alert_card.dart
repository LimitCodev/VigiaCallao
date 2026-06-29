import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Tarjeta de alerta para AlertsListScreen. Pensada para escanearse
/// rápido en una lista larga: zona y tiempo transcurrido son lo
/// primero que se lee, el thumbnail confirma visualmente sin
/// necesidad de abrir el detalle.
class AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onTap;

  const AlertCard({super.key, required this.alert, this.onTap});

  String _elapsed() {
    final diff = DateTime.now().difference(alert.detectedAt);
    if (diff.inMinutes < 1) return 'hace instantes';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    return 'hace ${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final isUrgent = alert.status == AlertStatus.active && alert.durationSeconds > 120;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: isUrgent ? AppColors.danger.withValues(alpha: 0.4) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              // Thumbnail del frame capturado por YOLO26n
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  width: 72,
                  height: 56,
                  color: AppColors.surfaceElevated,
                  child: alert.thumbnailUrl != null
                      ? Image.network(
                          alert.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholderThumb(),
                        )
                      : _placeholderThumb(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.zoneName ?? 'Zona #${alert.zoneId}',
                            style: AppTextStyles.titleMd,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        StatusBadge(status: alert.status, compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(alert.vehicleType.label, style: AppTextStyles.bodySm),
                        const SizedBox(width: 10),
                        const Icon(Icons.timer_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text('${alert.durationSeconds}s detenido', style: AppTextStyles.bodySm),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(_elapsed(), style: AppTextStyles.monoSm),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return const Center(
      child: Icon(Icons.videocam_outlined, size: 20, color: AppColors.textDisabled),
    );
  }
}
