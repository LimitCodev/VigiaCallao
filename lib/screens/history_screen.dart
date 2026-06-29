import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import 'alert_detail_screen.dart';

/// Historial cronológico (Sección 13.5): data table con búsqueda y
/// exportación. Usa DataTable nativo de Flutter, ideal para escritorio
/// donde hay espacio horizontal de sobra.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  List<AlertModel> _all = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final alerts = await _api.getAlerts(limit: 200);
      setState(() {
        _all = alerts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<AlertModel> get _filtered {
    if (_search.trim().isEmpty) return _all;
    final q = _search.toLowerCase();
    return _all.where((a) {
      return (a.zoneName ?? 'zona ${a.zoneId}').toLowerCase().contains(q) ||
          (a.cameraName ?? 'camara ${a.cameraId}').toLowerCase().contains(q) ||
          a.vehicleType.label.toLowerCase().contains(q) ||
          a.status.label.toLowerCase().contains(q);
    }).toList();
  }

  void _exportCsv() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exportación a CSV pendiente de implementar con backend.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

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
                    Text('Historial', style: AppTextStyles.displayMd),
                    const SizedBox(height: 4),
                    Text('Registro cronológico completo de detecciones.',
                        style: AppTextStyles.bodyMd),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Exportar CSV'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 320,
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Buscar por zona, cámara, tipo o estado...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : rows.isEmpty
                    ? Center(child: Text('Sin resultados.', style: AppTextStyles.bodyMd))
                    : Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SingleChildScrollView(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(AppColors.surfaceElevated),
                              dataRowColor: WidgetStateProperty.all(AppColors.surface),
                              columnSpacing: 28,
                              columns: [
                                DataColumn(label: Text('ID', style: AppTextStyles.label)),
                                DataColumn(label: Text('ZONA', style: AppTextStyles.label)),
                                DataColumn(label: Text('VEHÍCULO', style: AppTextStyles.label)),
                                DataColumn(label: Text('DURACIÓN', style: AppTextStyles.label)),
                                DataColumn(label: Text('DETECTADO', style: AppTextStyles.label)),
                                DataColumn(label: Text('ESTADO', style: AppTextStyles.label)),
                              ],
                              rows: rows
                                  .map((a) => DataRow(
                                        onSelectChanged: (_) => Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => AlertDetailScreen(alert: a)),
                                        ),
                                        cells: [
                                          DataCell(Text('#${a.id}', style: AppTextStyles.mono)),
                                          DataCell(Text(a.zoneName ?? 'Zona #${a.zoneId}',
                                              style: AppTextStyles.bodyMd
                                                  .copyWith(color: AppColors.textPrimary))),
                                          DataCell(Text(a.vehicleType.label,
                                              style: AppTextStyles.bodyMd)),
                                          DataCell(
                                              Text('${a.durationSeconds}s', style: AppTextStyles.mono)),
                                          DataCell(Text(_formatDate(a.detectedAt),
                                              style: AppTextStyles.bodySm)),
                                          DataCell(StatusBadge(status: a.status, compact: true)),
                                        ],
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $h:$m';
  }
}
