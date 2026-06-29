import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/alert_card.dart';
import '../widgets/status_badge.dart';

/// Pantalla principal (Sección 13.2). Muestra KPIs en tiempo real:
/// estado de la red de video, monitoreo de tráfico, e impacto
/// económico mitigado — este último con la fórmula y fuente citada
/// explícitamente en pantalla, tal como exige la Sección 2 del
/// documento ("NO se inventa una cifra").
class DashboardScreen extends StatefulWidget {
  final List<AlertModel> liveAlerts;
  const DashboardScreen({super.key, required this.liveAlerts});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  List<AlertModel> _initialAlerts = [];
  bool _loading = true;
  String? _error;

  // Placeholder hasta que el backend expone /api/cameras (Sección 10
  // no lo incluye originalmente). Reemplazar con _api.getCameras().
  final int _activeCameras = 7;
  final int _totalCameras = 8;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final alerts = await _api.getAlerts(limit: 50);
      setState(() {
        _initialAlerts = alerts;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<AlertModel> get _combinedAlerts {
    final map = <int, AlertModel>{};
    for (final a in _initialAlerts) {
      map[a.id] = a;
    }
    for (final a in widget.liveAlerts) {
      map[a.id] = a;
    }
    final list = map.values.toList()
      ..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _combinedAlerts;
    final activeAlerts = alerts.where((a) => a.status == AlertStatus.active).toList();
    final resolvedToday = alerts
        .where((a) =>
            a.status == AlertStatus.resolved &&
            a.resolvedAt != null &&
            _isToday(a.resolvedAt!))
        .length;
    final detectedToday = alerts.where((a) => _isToday(a.detectedAt)).length;
    final impactoMitigado = resolvedToday * AlertModel.impactoPorAlertaResuelta;

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Centro de Control', style: AppTextStyles.displayMd),
                      const SizedBox(height: 4),
                      Text(
                        'Monitoreo en tiempo real de la red de cámaras del Puerto del Callao.',
                        style: AppTextStyles.bodyMd,
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _loadAlerts,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Actualizar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            if (_error != null) _buildErrorBanner(),

            // ---- Fila de KPIs ----
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 900;
              final cards = [
                KpiCard(
                  label: 'RED DE VIDEO',
                  value: '$_activeCameras/$_totalCameras',
                  icon: Icons.videocam_outlined,
                  accentColor: AppColors.success,
                  footnote: 'Cámaras activas sobre el total',
                ),
                KpiCard(
                  label: 'ALERTAS ACTIVAS',
                  value: '${activeAlerts.length}',
                  icon: Icons.error_outline_rounded,
                  accentColor: AppColors.danger,
                  footnote: 'Requieren atención ahora',
                  trailing: activeAlerts.isNotEmpty
                      ? const StatusBadge(status: AlertStatus.active, compact: true)
                      : null,
                ),
                KpiCard(
                  label: 'DETECCIONES HOY',
                  value: '$detectedToday',
                  icon: Icons.local_shipping_outlined,
                  accentColor: AppColors.accent,
                  footnote: 'Infracciones detectadas en el día',
                ),
                _buildImpactoCard(impactoMitigado, resolvedToday),
              ];

              if (isWide) {
                return Row(
                  children: cards
                      .map((c) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.md),
                              child: c,
                            ),
                          ))
                      .toList(),
                );
              }
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: cards.map((c) => SizedBox(width: 260, child: c)).toList(),
              );
            }),

            const SizedBox(height: AppSpacing.xl),

            // ---- Alertas activas recientes ----
            Row(
              children: [
                Text('Alertas activas recientes', style: AppTextStyles.titleLg),
                const Spacer(),
                if (activeAlerts.length > 5)
                  Text('Mostrando 5 de ${activeAlerts.length}', style: AppTextStyles.bodySm),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (activeAlerts.isEmpty)
              _buildEmptyState()
            else
              Column(
                children: activeAlerts
                    .take(5)
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AlertCard(alert: a, onTap: () {}),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Widget _buildImpactoCard(double impacto, int resolvedCount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.accentGlow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.savings_outlined, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text('IMPACTO MITIGADO HOY',
                  style: AppTextStyles.label.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'S/. ${impacto.toStringAsFixed(0)}',
            style: AppTextStyles.kpiNumber.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Tooltip(
            message: 'Base: S/.100/hora por unidad paralizada (Julio Chalco, '
                'Director UNT Callao — Infobae Perú, 24 marzo 2025). '
                'Atender en 10 min en vez de 60 min ahorra 50 min = S/.83 '
                'por alerta resuelta. Estimación conservadora.',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$resolvedCount alertas atendidas × S/.83',
                    style: AppTextStyles.bodySm.copyWith(color: Colors.white70),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.info_outline, size: 12, color: Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No se pudo conectar al backend. Verifica que el servidor Flask '
              'esté corriendo en BACKEND_URL.',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.textPrimary),
            ),
          ),
          TextButton(onPressed: _loadAlerts, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_outlined, size: 36, color: AppColors.success),
          const SizedBox(height: AppSpacing.sm),
          Text('Sin alertas activas', style: AppTextStyles.titleMd),
          const SizedBox(height: 4),
          Text('El tráfico en las zonas monitoreadas está dentro de lo normal.',
              style: AppTextStyles.bodySm),
        ],
      ),
    );
  }
}
