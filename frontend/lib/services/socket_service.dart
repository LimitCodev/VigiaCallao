import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../models/alert_model.dart';

/// Estado de la conexión, para que la UI muestre un indicador honesto
/// ("Conectado" / "Reconectando" / "Sin conexión") en vez de fingir
/// que todo siempre funciona.
enum SocketStatus { connecting, connected, disconnected }

/// Envuelve socket_io_client para escuchar el evento "new_alert" emitido
/// por Flask-SocketIO (Sección 10 del documento). El payload tiene el
/// mismo shape que GET /api/alerts/:id, así que reusamos AlertModel.fromJson.
class SocketService {
  io.Socket? _socket;

  final void Function(AlertModel alert) onNewAlert;
  final void Function(AlertModel alert)? onUpdateAlert;
  final void Function(SocketStatus status) onStatusChange;

  SocketService({
    required this.onNewAlert,
    this.onUpdateAlert,
    required this.onStatusChange,
  });

  void connect() {
    onStatusChange(SocketStatus.connecting);

    _socket = io.io(
      AppConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!
      ..onConnect((_) => onStatusChange(SocketStatus.connected))
      ..onDisconnect((_) => onStatusChange(SocketStatus.disconnected))
      ..onConnectError((_) => onStatusChange(SocketStatus.disconnected))
      ..onReconnectAttempt((_) => onStatusChange(SocketStatus.connecting))
      ..on('new_alert', (data) {
        try {
          final json = data is Map<String, dynamic> ? data : <String, dynamic>{};
          onNewAlert(AlertModel.fromJson(json));
        } catch (_) {
          // Payload inesperado: lo ignoramos en vez de tumbar la app.
        }
      })
      ..on('update_alert', (data) {
        try {
          final json = data is Map<String, dynamic> ? data : <String, dynamic>{};
          onUpdateAlert?.call(AlertModel.fromJson(json));
        } catch (_) {}
      });
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
