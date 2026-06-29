import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Tarjeta de indicador clave para DashboardScreen. El acento de color
/// es opcional y se usa para KPIs que representan alertas/dinero,
/// reservando el color de marca para los KPIs neutrales.
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final IconData icon;
  final Color accentColor;
  final String? footnote;
  final Widget? trailing;

  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    required this.icon,
    this.accentColor = AppColors.accent,
    this.footnote,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 18, color: accentColor),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: AppTextStyles.kpiNumber),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit!, style: AppTextStyles.bodyMd),
                ),
              ],
            ],
          ),
          if (footnote != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(footnote!, style: AppTextStyles.bodySm),
          ],
        ],
      ),
    );
  }
}
