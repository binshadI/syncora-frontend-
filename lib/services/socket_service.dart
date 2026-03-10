import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/config.dart';


class SocketService {
  // ── Singleton setup ──────────────────────────────────────────────
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // ── Socket instance ──────────────────────────────────────────────
  late IO.Socket _socket;
  bool _isConnected = false;

  // ── Connect with auth token ──────────────────────────────────────
  void init(String token) {
    if (_isConnected) return; // prevent duplicate connections

    _socket = IO.io(
      '${Config.apiURL}',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      _isConnected = true;
      print('✅ Socket connected: ${_socket.id}');
    });

    _socket.onDisconnect((_) {
      _isConnected = false;
      print('❌ Socket disconnected');
    });

    _socket.on('error', (data) {
      print('⚠️ Socket error: $data');
    });
  }

  // ── Join a room ──────────────────────────────────────────────────
  void joinRoom(String roomId) {
    _socket.emit('join_room', {'roomId': roomId});
    print('🚪 Joined room: $roomId');
  }

  // ── Leave a room ─────────────────────────────────────────────────
  void leaveRoom(String roomId) {
    _socket.emit('leave_room', {'roomId': roomId});
    print('🚪 Left room: $roomId');
  }

  // ── Send a message ───────────────────────────────────────────────
  void sendMessage({
    required String roomId,
    required String msg,
    required String senderId,
  }) {
    _socket.emit('send_message', {
      'roomId': roomId,
      'msg': msg,
      'senderId': senderId,
    });
  }

  // ── Listen for incoming messages ─────────────────────────────────
  void onReceiveMessage(Function(dynamic) callback) {
    _socket.on('receive_msg', callback);
  }

  // ── Stop listening for messages ──────────────────────────────────
  void offReceiveMessage() {
    _socket.off('receive_msg');
  }

  // ── Disconnect (call on logout) ──────────────────────────────────
  void disconnect() {
    _socket.disconnect();
    _isConnected = false;
    print('🔌 Socket disconnected by user');
  }

  // ── Check connection status ──────────────────────────────────────
  bool get isConnected => _isConnected;
}