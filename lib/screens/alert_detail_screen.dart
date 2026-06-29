import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';

/// Detalle de alerta (Sección 13.4). Layout dividido: panel izquierdo
/// con el frame capturado por YOLO26n, panel derecho con datos y
/// acciones del fiscalizador (Atendida / Escalar / Compartir).
class AlertDetailScreen extends StatefulWidget {
  final AlertModel alert;
  const AlertDetailScreen({super.key, required this.alert});

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final _api = ApiService();
  late AlertModel _alert;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _alert = widget.alert;
    _notesCtrl.text = _alert.officerNotes ?? '';
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(AlertStatus status) async {
    setState(() => _saving = true);
    try {
      final updated = await _api.updateAlert(
        id: _alert.id,
        status: status,
        officerNotes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      setState(() {
        _alert = _alert.copyWith(status: updated.status, resolvedAt: updated.resolvedAt);
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == AlertStatus.resolved
                ? 'Alerta marcada como atendida.'
                : 'Alerta escalada a supervisión.'),
            backgroundColor: AppColors.surfaceElevated,
          ),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Text('Alerta #${_alert.id}', style: AppTextStyles.titleLg),
                  const SizedBox(width: 12),
                  StatusBadge(status: _alert.status),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Panel izquierdo: frame capturado
                    Expanded(flex: 6, child: _buildFramePanel()),
                    const SizedBox(width: AppSpacing.lg),
                    // Panel derecho: datos y acciones
                    Expanded(flex: 4, child: _buildDataPanel()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFramePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: _alert.thumbnailUrl != null
                ? Image.network(_alert.thumbnailUrl!, fit: BoxFit.contain)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.videocam_off_outlined,
                            size: 48, color: AppColors.textDisabled),
                        const SizedBox(height: 12),
                        Text('Frame no disponible', style: AppTextStyles.bodyMd),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Icon(Icons.bolt_outlined, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              'Confianza de detección: ${(_alert.confidence * 100).toStringAsFixed(1)}%',
              style: AppTextStyles.bodySm,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataPanel() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: 'Datos de la detección',
            children: [
              _dataRow('Zona', _alert.zoneName ?? 'Zona #${_alert.zoneId}'),
              _dataRow('Cámara', _alert.cameraName ?? 'Cámara #${_alert.cameraId}'),
              _dataRow('Vehículo', _alert.vehicleType.label),
              _dataRow('Tiempo detenido', '${_alert.durationSeconds} segundos'),
              _dataRow('Detectado', _formatDateTime(_alert.detectedAt)),
              if (_alert.resolvedAt != null)
                _dataRow('Atendida', _formatDateTime(_alert.resolvedAt!)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionCard(
            title: 'Notas del fiscalizador',
            children: [
              TextField(
                controller: _notesCtrl,
                maxLines: 4,
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Agrega observaciones sobre esta alerta...',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_alert.status == AlertStatus.active) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : () => _updateStatus(AlertStatus.resolved),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Marcar como atendida'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saving ? null : () => _updateStatus(AlertStatus.escalated),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: const BorderSide(color: AppColors.warning),
                ),
                icon: const Icon(Icons.arrow_upward, size: 18),
                label: const Text('Escalar a supervisión'),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función de compartir pendiente de backend.')),
                );
              },
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Compartir'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleMd),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _dataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: AppTextStyles.bodySm)),
          Expanded(child: Text(value, style: AppTextStyles.mono.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} · $h:$min';
  }
}
