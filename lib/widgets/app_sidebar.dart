import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Sidebar lateral permanente para el shell de escritorio
/// (Sección 13: "Sidebar lateral permanente + Contenido a la derecha").
/// El item activo usa el azul institucional como acento de marca,
/// destacando sobre el fondo grafito neutro del resto de la app.
class AppSidebar extends StatelessWidget {
  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String operatorName;
  final SocketStatusIndicatorData socketStatus;

  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    required this.operatorName,
    required this.socketStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBrandHeader(),
            const SizedBox(height: AppSpacing.md),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Divider(color: AppColors.border, height: 1),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  return _SidebarTile(
                    item: item,
                    selected: selected,
                    onTap: () => onSelect(index),
                  );
                },
              ),
            ),
            _buildSocketStatus(),
            _buildOperatorFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.accentGlow,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VigíaCallao', style: AppTextStyles.titleLg),
                Text('Centro de Control', style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocketStatus() {
    final color = switch (socketStatus.status) {
      'connected' => AppColors.success,
      'connecting' => AppColors.warning,
      _ => AppColors.danger,
    };
    final label = switch (socketStatus.status) {
      'connected' => 'Tiempo real activo',
      'connecting' => 'Conectando...',
      _ => 'Sin conexión',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodySm.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildOperatorFooter() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.navyInstitutional,
            child: Text(
              operatorName.isNotEmpty ? operatorName[0].toUpperCase() : '?',
              style: AppTextStyles.label.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(operatorName,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text('Fiscalizador', style: AppTextStyles.bodySm),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SocketStatusIndicatorData {
  final String status; // 'connected' | 'connecting' | 'disconnected'
  const SocketStatusIndicatorData(this.status);
}

class _SidebarTile extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected ? AppColors.navyInstitutional.withValues(alpha: 0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: const Border(
                      left: BorderSide(color: AppColors.accent, width: 3),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  selected ? item.activeIcon : item.icon,
                  size: 19,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: AppTextStyles.bodyLg.copyWith(
                      color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
