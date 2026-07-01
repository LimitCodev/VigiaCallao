import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../theme/app_theme.dart';

/// Badge de estado para alertas. Pensado para leerse en 200ms desde
/// el otro lado de una mesa de control — color + texto + punto pulsante
/// si está activa, sin depender solo del color (accesibilidad).
class StatusBadge extends StatelessWidget {
  final AlertStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  ({Color fg, Color bg, IconData icon}) get _visual {
    switch (status) {
      case AlertStatus.active:
        return (fg: AppColors.danger, bg: AppColors.dangerBg, icon: Icons.error_rounded);
      case AlertStatus.escalated:
        return (fg: AppColors.warning, bg: AppColors.warningBg, icon: Icons.arrow_upward_rounded);
      case AlertStatus.resolved:
        return (fg: AppColors.success, bg: AppColors.successBg, icon: Icons.check_circle_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _visual;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: v.bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == AlertStatus.active) _PulsingDot(color: v.fg)
          else Icon(v.icon, size: compact ? 12 : 14, color: v.fg),
          SizedBox(width: compact ? 4 : 6),
          Text(
            status.label,
            style: AppTextStyles.label.copyWith(
              color: v.fg,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Punto animado para alertas activas — comunica "esto está pasando
/// ahora" sin necesidad de leer texto, útil en vistazos rápidos al
/// monitor desde lejos.
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.4 + (_controller.value * 0.6);
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: opacity * 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Indicador simple de cámara online/offline para CamerasScreen.
class CameraStatusDot extends StatelessWidget {
  final bool isActive;
  const CameraStatusDot({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.neutralStatus;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'En línea' : 'Sin señal',
          style: AppTextStyles.bodySm.copyWith(color: color),
        ),
      ],
    );
  }
}
