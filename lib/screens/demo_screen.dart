import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

/// Pantalla especial para el jurado (Sección 13.7 — CRÍTICA).
/// Mientras el script Python (YOLO26n + OpenCV) procesa el MP4 en
/// la laptop y dibuja bounding boxes en su propia ventana, esta
/// pantalla muestra el lado "Centro de Control": la alerta llegando
/// en vivo vía WebSocket. Es deliberadamente más grande y limpia
/// que las demás — se proyecta en el Congreso.
class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  AlertModel? _lastAlert;
  final int _alertCount = 0;

  // En producción, esta pantalla debe escuchar el mismo socket que
  // MainShell. Para simplicidad de demo se puede inyectar el último
  // AlertModel recibido vía socket_service, o conectar uno propio.

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text('MODO DEMOSTRACIÓN',
                    style: AppTextStyles.label.copyWith(color: AppColors.danger)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Vigía Callao en vivo', style: AppTextStyles.displayLg),
          const SizedBox(height: 4),
          Text(
            'El video se procesa con YOLO26n en esta laptop. Cuando detecta un '
            'vehículo detenido más del umbral configurado, la alerta llega aquí '
            'en tiempo real vía WebSocket.',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel de instrucciones / estado del pipeline
                Expanded(
                  flex: 5,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flujo del sistema', style: AppTextStyles.titleLg),
                        const SizedBox(height: AppSpacing.md),
                        _pipelineStep(
                          icon: Icons.videocam_outlined,
                          title: 'Captura de video',
                          subtitle: 'OpenCV lee el MP4 de tráfico del Callao',
                          done: true,
                        ),
                        _pipelineStep(
                          icon: Icons.crop_free,
                          title: 'Detección YOLO26n',
                          subtitle: 'Bounding boxes + tracking BoT-SORT',
                          done: true,
                        ),
                        _pipelineStep(
                          icon: Icons.timer_outlined,
                          title: 'Cronómetro de zona',
                          subtitle: 'Mide permanencia en zona restringida',
                          done: true,
                        ),
                        _pipelineStep(
                          icon: Icons.send_outlined,
                          title: 'Envío al backend',
                          subtitle: 'HTTP POST + WebSocket "new_alert"',
                          done: _lastAlert != null,
                        ),
                        _pipelineStep(
                          icon: Icons.desktop_windows_outlined,
                          title: 'Recepción en este panel',
                          subtitle: 'Alerta visible sin recargar la app',
                          done: _lastAlert != null,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                // Panel de última alerta recibida
                Expanded(
                  flex: 6,
                  child: _lastAlert == null
                      ? _buildWaitingPanel()
                      : _buildAlertReceivedPanel(_lastAlert!),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pipelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool done,
    bool isLast = false,
  }) {
    final color = done ? AppColors.success : AppColors.textDisabled;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.successBg : AppColors.surfaceElevated,
                  border: Border.all(color: color),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              if (!isLast)
                Container(width: 1.5, height: 28, color: AppColors.border),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLg.copyWith(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14,
                  )),
                  Text(subtitle, style: AppTextStyles.bodySm),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingPanel() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Esperando detecciones...', style: AppTextStyles.titleMd),
            const SizedBox(height: 4),
            Text(
              'Inicia el script de detección en la laptop para ver la\nalerta aparecer aquí en tiempo real.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertReceivedPanel(AlertModel alert) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const StatusBadge(status: AlertStatus.active),
              const Spacer(),
              Text('#$_alertCount detectada', style: AppTextStyles.bodySm),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('${alert.vehicleType.label} detenido',
              style: AppTextStyles.displayMd.copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          Text(alert.zoneName ?? 'Zona #${alert.zoneId}', style: AppTextStyles.bodyLg),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _statBlock('${alert.durationSeconds}s', 'Tiempo detenido'),
              _statBlock('${(alert.confidence * 100).toStringAsFixed(0)}%', 'Confianza'),
              _statBlock('S/. 83', 'Impacto mitigable'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.titleLg.copyWith(color: AppColors.accent)),
        Text(label, style: AppTextStyles.bodySm),
      ],
    );
  }
}
