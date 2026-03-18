import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/api_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  Function(Map<String, dynamic>)? onFileUpdated;
  Function(Map<String, dynamic>)? onTourApproche;
  Function(Map<String, dynamic>)? onVotreTour;

  void connect() {
    final url = ApiConfig.baseUrl.replaceAll('/api', '');
    _socket = IO.io(url, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) => print('[Socket] Connecte'));
    _socket!.onDisconnect((_) => print('[Socket] Deconnecte'));

    _socket!.on('file_updated', (data) {
      if (onFileUpdated != null) onFileUpdated!(Map<String, dynamic>.from(data));
    });
    _socket!.on('votre_tour_approche', (data) {
      if (onTourApproche != null) onTourApproche!(Map<String, dynamic>.from(data));
    });
    _socket!.on('votre_tour', (data) {
      if (onVotreTour != null) onVotreTour!(Map<String, dynamic>.from(data));
    });
  }

  void joinService(String serviceId) => _socket?.emit('join_service', serviceId);
  void joinUser(String userId) => _socket?.emit('join_user', userId);
  void leaveService(String serviceId) => _socket?.emit('leave_service', serviceId);
  void disconnect() => _socket?.disconnect();
}
