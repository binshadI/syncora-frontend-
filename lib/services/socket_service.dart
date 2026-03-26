import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/config.dart';
import '../pages/incoming_call_screen.dart';

// ── Global navigator key ─────────────────────────────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ── Helper: socket_io_client wraps data in a List — always unwrap ────
Map _unwrap(dynamic data) {
  return (data is List ? data[0] : data) as Map;
}

class SocketService {
  // ── Singleton ────────────────────────────────────────────────────
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // ── Socket instance (nullable — safe before init) ────────────────
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentUserId; // ← stores userId for register event

  // ── Init with token AND userId ───────────────────────────────────
  void init(String token, String userId) {
    _currentUserId = userId;

    if (_isConnected) {
      // Already connected — just re-register userId
      _socket?.emit('register', _currentUserId);
      print('📋 re-registered userId: $_currentUserId');
      return;
    }

    _socket = IO.io(
      Config.apiURL,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      _isConnected = true;
      print('✅ Socket connected: ${_socket!.id}');

      // ✅ Register MongoDB userId with server
      _socket!.emit('register', _currentUserId);
      print('📋 registered userId: $_currentUserId');

      // ── Log all events for debugging ─────────────────────────────
      _socket!.onAny((event, data) {
        print('🔔 EVENT: $event | DATA: $data');
      });

      // ── Global incoming call listener ─────────────────────────────
      _socket!.on('call:incoming', (raw) {
        print('📞 RAW DATA: $raw');
        print('📞 DATA TYPE: ${raw.runtimeType}');
        final data = _unwrap(raw);
        print('📞 FROM: ${data['from']}');
        print('📞 callerName: ${data['callerName']}');
        print('📞 navigatorKey state: ${navigatorKey.currentState}');

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => IncomingCallScreen(
              callerName   : data['callerName']  ?? 'Unknown',
              fromSocketId : data['from']        ?? '',
              callRoomId   : data['callRoomId']  ?? '',
              callType     : data['callType']    ?? 'video',
            ),
          ),
        );
      });
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      print('❌ Socket disconnected');
    });

    _socket!.on('error', (data) {
      print('⚠️ Socket error: $data');
    });
  }

  // ── Room ─────────────────────────────────────────────────────────
  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
    print('🚪 Joined room: $roomId');
  }

  void leaveRoom(String roomId) {
    _socket?.emit('leave_room', {'roomId': roomId});
    print('🚪 Left room: $roomId');
  }

  // ── Chat ─────────────────────────────────────────────────────────
  void sendMessage({
    required String roomId,
    required String msg,
    required String senderId,
  }) {
    _socket?.emit('send_message', {
      'roomId'  : roomId,
      'msg'     : msg,
      'senderId': senderId,
    });
  }

  void onReceiveMessage(Function(dynamic) callback) {
    _socket?.on('receive_msg', callback);
  }

  void offReceiveMessage() {
    _socket?.off('receive_msg');
  }

  // ── Call emitters ─────────────────────────────────────────────────
  void callInvite({
    required String friendId,
    required String callRoomId,
    required String callType,
    required String callerName,
  }) {
    _socket?.emit('call:invite', {
      'friendId'  : friendId,
      'callRoomId': callRoomId,
      'callType'  : callType,
      'callerName': callerName,
    });
    print('📞 call:invite → friendId=$friendId type=$callType');
  }

  void callJoin({required String callRoomId, required String callType}) {
    _socket?.emit('call:join', {
      'callRoomId': callRoomId,
      'callType'  : callType,
    });
    print('📞 call:join → room=$callRoomId');
  }

  void callOffer({
    required String target,
    required Map<String, dynamic> sdp,
    required String callType,
  }) {
    _socket?.emit('call:offer', {
      'target'  : target,
      'sdp'     : sdp,
      'callType': callType,
    });
  }

  void callAnswer({
    required String target,
    required Map<String, dynamic> sdp,
  }) {
    _socket?.emit('call:answer', {'target': target, 'sdp': sdp});
  }

  void callIceCandidate({
    required String target,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit('call:ice_candidate', {
      'target'   : target,
      'candidate': candidate,
    });
  }

  void callHangUp({required String target}) {
    _socket?.emit('call:hang_up', {'target': target});
    print('📵 call:hang_up → target=$target');
  }

  void callReject({required String target}) {
    _socket?.emit('call:reject', {'target': target});
    print('🚫 call:reject → target=$target');
  }

  // ── Call listeners (all with List unwrap fix) ────────────────────
  void onCallIncoming(Function(dynamic) cb) {
    _socket?.on('call:incoming', (raw) => cb(_unwrap(raw)));
  }
  void offCallIncoming() => _socket?.off('call:incoming');

  void onCallJoined(Function(dynamic) cb) {
    _socket?.on('call:joined', (raw) => cb(_unwrap(raw)));
  }
  void offCallJoined() => _socket?.off('call:joined');

  void onCallPeerJoined(Function(dynamic) cb) {
    _socket?.on('call:peer_joined', (raw) => cb(_unwrap(raw)));
  }
  void offCallPeerJoined() => _socket?.off('call:peer_joined');

  void onCallOffer(Function(dynamic) cb) {
    _socket?.on('call:offer', (raw) => cb(_unwrap(raw)));
  }
  void offCallOffer() => _socket?.off('call:offer');

  void onCallAnswer(Function(dynamic) cb) {
    _socket?.on('call:answer', (raw) => cb(_unwrap(raw)));
  }
  void offCallAnswer() => _socket?.off('call:answer');

  void onCallIceCandidate(Function(dynamic) cb) {
    _socket?.on('call:ice_candidate', (raw) => cb(_unwrap(raw)));
  }
  void offCallIceCandidate() => _socket?.off('call:ice_candidate');

  void onCallPeerHungUp(Function(dynamic) cb) {
    _socket?.on('call:peer_hung_up', (raw) => cb(raw));
  }
  void offCallPeerHungUp() => _socket?.off('call:peer_hung_up');

  void onCallRejected(Function(dynamic) cb) {
    _socket?.on('call:rejected', (raw) => cb(raw));
  }
  void offCallRejected() => _socket?.off('call:rejected');

  void onCallPeerLeft(Function(dynamic) cb) {
    _socket?.on('call:peer_left', (raw) => cb(raw));
  }
  void offCallPeerLeft() => _socket?.off('call:peer_left');

  void onCallBusy(Function(dynamic) cb) {
    _socket?.on('call:busy', (raw) => cb(raw));
  }
  void offCallBusy() => _socket?.off('call:busy');

  // ── Getters ──────────────────────────────────────────────────────
  bool   get isConnected => _isConnected;
  String get socketId    => _socket?.id ?? '';

  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }
}