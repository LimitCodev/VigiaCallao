import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import 'dashboard_screen.dart';
import 'alerts_list_screen.dart';
import 'history_screen.dart';
import 'cameras_screen.dart';
import 'demo_screen.dart';

/// Shell principal de la app de escritorio: sidebar lateral permanente
/// + contenido a la derecha (Sección 13). Mantiene una única conexión
/// WebSocket viva mientras el operador navega entre pantallas, y
/// acumula el conteo de alertas activas para el badge del sidebar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  late final SocketService _socketService;
  String _socketStatus = 'connecting';
  final List<AlertModel> _liveAlerts = [];

  late final List<NavItem> _navItems;

  @override
  void initState() {
    super.initState();
    _navItems = const [
      NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
      NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertas'),
      NavItem(icon: Icons.history_outlined, activeIcon: Icons.history, label: 'Historial'),
      NavItem(icon: Icons.videocam_outlined, activeIcon: Icons.videocam, label: 'Cámaras'),
      NavItem(icon: Icons.play_circle_outline, activeIcon: Icons.play_circle, label: 'Demo'),
    ];

    _socketService = SocketService(
      onNewAlert: (alert) {
        setState(() {
          _liveAlerts.removeWhere((a) => a.id == alert.id);
          _liveAlerts.insert(0, alert);
        });
      },
      onUpdateAlert: (alert) {
        setState(() {
          final idx = _liveAlerts.indexWhere((a) => a.id == alert.id);
          if (idx >= 0) {
            _liveAlerts[idx] = alert;
          } else {
            _liveAlerts.insert(0, alert);
          }
        });
      },
      onStatusChange: (status) {
        setState(() {
          _socketStatus = switch (status) {
            SocketStatus.connected => 'connected',
            SocketStatus.connecting => 'connecting',
            SocketStatus.disconnected => 'disconnected',
          };
        });
      },
    );
    _socketService.connect();
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }

  int get _activeAlertCount =>
      _liveAlerts.where((a) => a.status == AlertStatus.active).length;

  @override
  Widget build(BuildContext context) {
    final navItemsWithBadge = [
      _navItems[0],
      NavItem(
        icon: _navItems[1].icon,
        activeIcon: _navItems[1].activeIcon,
        label: _navItems[1].label,
        badgeCount: _activeAlertCount,
      ),
      _navItems[2],
      _navItems[3],
      _navItems[4],
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AppSidebar(
            items: navItemsWithBadge,
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
            operatorName: 'Operador',
            socketStatus: SocketStatusIndicatorData(_socketStatus),
          ),
          Container(width: 1, color: AppColors.border),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardScreen(liveAlerts: _liveAlerts),
                AlertsListScreen(liveAlerts: _liveAlerts),
                const HistoryScreen(),
                const CamerasScreen(),
                DemoScreen(liveAlerts: _liveAlerts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
