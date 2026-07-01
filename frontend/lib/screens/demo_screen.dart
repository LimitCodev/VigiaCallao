import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/alert_model.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

class DemoScreen extends StatefulWidget {
  final List<AlertModel> liveAlerts;
  const DemoScreen({super.key, this.liveAlerts = const []});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  AlertModel? _lastAlert;

  @override
  void didUpdateWidget(DemoScreen old) {
    super.didUpdateWidget(old);
    if (widget.liveAlerts.isNotEmpty && widget.liveAlerts.first != _lastAlert) {
      setState(() => _lastAlert = widget.liveAlerts.first);
    }
  }

  Future<void> _startDemo() async {
    try {
      await http
          .post(Uri.parse('${AppConfig.backendUrl}/api/demo/start'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> _triggerAlert() async {
    try {
      await http
          .post(Uri.parse('${AppConfig.backendUrl}/api/demo/trigger'))
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

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
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _startDemo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success.withValues(alpha: 0.15),
                  foregroundColor: AppColors.success,
                  side: BorderSide(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Iniciar demo'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _triggerAlert,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                  foregroundColor: AppColors.accent,
                  side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                icon: const Icon(Icons.add_alert_outlined, size: 18),
                label: const Text('Simular alerta'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Vigía Callao — Demo en vivo', style: AppTextStyles.displayLg),
          const SizedBox(height: 4),
          Text(
            'Las alertas aparecen aquí en tiempo real vía WebSocket.\n'
            'Si el script ML está corriendo, la ventana OpenCV muestra el video con detecciones YOLO.',
            style: AppTextStyles.bodyMd,
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildPipelinePanel(),
                ),
                const SizedBox(width: AppSpacing.lg),
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

  Widget _buildPipelinePanel() {
    final hasAlert = _lastAlert != null;
    return Container(
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
          _step(Icons.videocam_outlined, 'Captura de video',
              'OpenCV lee el MP4 de tráfico del Callao', true),
          _step(Icons.crop_free, 'Detección YOLO26n',
              'Bounding boxes + tracking BoT-SORT', true),
          _step(Icons.timer_outlined, 'Cronómetro de zona',
              'Mide permanencia en zona restringida', true),
          _step(Icons.send_outlined, 'Envío al backend',
              'HTTP POST + WebSocket "new_alert"', hasAlert, isLast: true),
          const SizedBox(height: AppSpacing.lg),
          if (!hasAlert)
            Center(
              child: Text(
                'Ejecuta el ML en otra terminal:\n'
                '~/VigiaCallao/ml/venv/bin/python main.py',
                textAlign: TextAlign.center,
                style: AppTextStyles.mono.copyWith(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _step(IconData icon, String title, String subtitle, bool done,
      {bool isLast = false}) {
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
                  Text(title,
                      style: AppTextStyles.bodyLg.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
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
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Esperando alertas...', style: AppTextStyles.titleMd),
            const SizedBox(height: 4),
            Text(
              'Presiona "Iniciar demo" para alertas automáticas\no corre el script ML para detección con YOLO.',
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
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: alert.thumbnailUrl != null
                ? Image.network(alert.thumbnailUrl!, fit: BoxFit.cover)
                : Container(
                    color: AppColors.surfaceElevated,
                    child: const Center(
                      child: Icon(Icons.videocam_off_outlined,
                          size: 40, color: AppColors.textDisabled),
                    ),
                  ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const StatusBadge(status: AlertStatus.active),
                      const Spacer(),
                      Text('#${widget.liveAlerts.length} detectada',
                          style: AppTextStyles.bodySm),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('${alert.vehicleType.label} detenido',
                      style: AppTextStyles.displayMd.copyWith(fontSize: 22)),
                  const SizedBox(height: 2),
                  Text(alert.zoneName ?? 'Zona #${alert.zoneId}',
                      style: AppTextStyles.bodyLg),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _statBlock('${alert.durationSeconds}s', 'Tiempo detenido'),
                      _statBlock(
                          '${(alert.confidence * 100).toStringAsFixed(0)}%', 'Confianza'),
                      _statBlock('S/. 83', 'Impacto mitigable'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTextStyles.titleLg.copyWith(color: AppColors.accent)),
        Text(label, style: AppTextStyles.bodySm),
      ],
    );
  }
}
