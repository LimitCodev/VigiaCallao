import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/alert_card.dart';
import 'alert_detail_screen.dart';

/// Lista de alertas (Sección 13.3). Combina el snapshot inicial vía
/// REST con las actualizaciones en vivo que llegan por WebSocket
/// (propagadas desde MainShell), con filtro por estado.
class AlertsListScreen extends StatefulWidget {
  final List<AlertModel> liveAlerts;
  const AlertsListScreen({super.key, required this.liveAlerts});

  @override
  State<AlertsListScreen> createState() => _AlertsListScreenState();
}

class _AlertsListScreenState extends State<AlertsListScreen> {
  final _api = ApiService();
  List<AlertModel> _initialAlerts = [];
  bool _loading = true;
  AlertStatus? _filter; // null = todas

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final alerts = await _api.getAlerts(limit: 100);
      setState(() {
        _initialAlerts = alerts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<AlertModel> get _combined {
    final map = <int, AlertModel>{};
    for (final a in _initialAlerts) {
      map[a.id] = a;
    }
    for (final a in widget.liveAlerts) {
      map[a.id] = a;
    }
    var list = map.values.toList()..sort((a, b) => b.detectedAt.compareTo(a.detectedAt));
    if (_filter != null) {
      list = list.where((a) => a.status == _filter).toList();
    }
    return list;
  }

  void _openDetail(AlertModel alert) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AlertDetailScreen(alert: alert)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _combined;

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
                    Text('Alertas', style: AppTextStyles.displayMd),
                    const SizedBox(height: 4),
                    Text('Detecciones de YOLO26n en zonas restringidas, en vivo.',
                        style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _filterChip('Todas', null),
              const SizedBox(width: 8),
              _filterChip('Activas', AlertStatus.active),
              const SizedBox(width: 8),
              _filterChip('Escaladas', AlertStatus.escalated),
              const SizedBox(width: 8),
              _filterChip('Atendidas', AlertStatus.resolved),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : alerts.isEmpty
                    ? Center(
                        child: Text('No hay alertas con este filtro.',
                            style: AppTextStyles.bodyMd),
                      )
                    : ListView.separated(
                        itemCount: alerts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, i) => AlertCard(
                          alert: alerts[i],
                          onTap: () => _openDetail(alerts[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, AlertStatus? status) {
    final selected = _filter == status;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = status),
      labelStyle: AppTextStyles.bodySm.copyWith(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.accent,
      side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      showCheckmark: false,
    );
  }
}
