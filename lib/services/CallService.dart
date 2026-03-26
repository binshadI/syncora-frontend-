import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'socket_service.dart';

class CallService {
  // ── Singleton ────────────────────────────────────────────────────
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  // ── WebRTC state ─────────────────────────────────────────────────
  RTCPeerConnection? _pc;
  MediaStream? localStream;
  MediaStream? remoteStream;

  late RTCVideoRenderer localRenderer  = RTCVideoRenderer();
  late RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  // ── Init guard ───────────────────────────────────────────────────
  bool _initialized = false;

  // ── Call state ───────────────────────────────────────────────────
  String? remotePeerId;
  String? callRoomId;
  String  callType = 'video';

  bool _muted  = false;
  bool _camOff = false;
  bool get isMuted  => _muted;
  bool get isCamOff => _camOff;

  // ── Callbacks ────────────────────────────────────────────────────
  Function()? onStateChanged;
  Function()? onCallEnded;
  Function()? onCallConnected;

  // ── ICE servers — STUN + TURN (fixes black remote video) ─────────
  final Map<String, dynamic> _iceConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  // ────────────────────────────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) {
      print('[CallService] already initialized — skipping');
      return;
    }

    localRenderer  = RTCVideoRenderer();
    remoteRenderer = RTCVideoRenderer();

    await localRenderer.initialize();
    await remoteRenderer.initialize();

    _initialized = true;
    print('[CallService] initialized');
  }

  // ────────────────────────────────────────────────────────────────
  // REQUEST PERMISSIONS
  // ────────────────────────────────────────────────────────────────
  Future<bool> _requestPermissions(String type) async {
    final micStatus = await Permission.microphone.request();
    print('[CallService] mic permission: $micStatus');

    if (type == 'video') {
      final camStatus = await Permission.camera.request();
      print('[CallService] camera permission: $camStatus');

      if (camStatus.isDenied || camStatus.isPermanentlyDenied) {
        print('[CallService] ❌ camera permission denied');
        return false;
      }
    }

    if (micStatus.isDenied || micStatus.isPermanentlyDenied) {
      print('[CallService] ❌ microphone permission denied');
      return false;
    }

    return true;
  }

  // ────────────────────────────────────────────────────────────────
  // START LOCAL STREAM
  // ────────────────────────────────────────────────────────────────
  Future<void> startLocalStream(String type) async {
    callType = type;

    final granted = await _requestPermissions(type);
    if (!granted) {
      print('[CallService] ❌ permissions not granted — cannot start stream');
      return;
    }

    final constraints = {
      'audio': true,
      'video': type == 'video'
          ? {'facingMode': 'user', 'width': 1280, 'height': 720}
          : false,
    };

    localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = localStream;

    // ✅ Notify UI that local stream is ready
    onStateChanged?.call();
    print('[CallService] ✅ local stream started');
  }

  // ────────────────────────────────────────────────────────────────
  // SETUP SIGNALING LISTENERS
  // ────────────────────────────────────────────────────────────────
  void setupSignalingListeners() {
    final socket = SocketService();

    socket.onCallPeerJoined((data) async {
      remotePeerId = data['peerId'];
      callType     = data['callType'] ?? callType;
      print('[call] peer joined: $remotePeerId — creating offer');
      await _createOffer();
    });

    socket.onCallOffer((data) async {
      remotePeerId = data['from'];
      final sdp    = data['sdp'];
      print('[call] received offer from $remotePeerId');
      await _handleOffer(sdp);
    });

    socket.onCallAnswer((data) async {
      final sdp = data['sdp'];
      print('[call] received answer');
      await _pc?.setRemoteDescription(
        RTCSessionDescription(sdp['sdp'], sdp['type']),
      );
      onCallConnected?.call();
    });

    socket.onCallIceCandidate((data) async {
      final c = data['candidate'];
      if (c != null && _pc != null) {
        try {
          await _pc!.addCandidate(RTCIceCandidate(
            c['candidate'],
            c['sdpMid'],
            c['sdpMLineIndex'],
          ));
        } catch (e) {
          print('[call] ICE candidate error: $e');
        }
      }
    });

    socket.onCallPeerHungUp((_) {
      print('[call] peer hung up');
      _cleanupConnection();
      onCallEnded?.call();
    });

    socket.onCallPeerLeft((_) {
      print('[call] peer left');
      _cleanupConnection();
      onCallEnded?.call();
    });
  }

  // ────────────────────────────────────────────────────────────────
  // CREATE PEER CONNECTION
  // ────────────────────────────────────────────────────────────────
  Future<RTCPeerConnection> _createPC() async {
    if (_pc != null) {
      await _pc!.close();
      _pc = null;
    }

    // ✅ Reset remoteStream so onTrack always fires correctly
    remoteStream = null;
    remoteRenderer.srcObject = null;

    _pc = await createPeerConnection(_iceConfig);

    localStream?.getTracks().forEach((track) {
      _pc!.addTrack(track, localStream!);
    });

    _pc!.onTrack = (event) {
      print('[call] onTrack fired — streams: ${event.streams.length}');
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams.first;
        remoteRenderer.srcObject = remoteStream;
        print('[call] ✅ remote stream set — textureId: ${remoteRenderer.textureId}');
        onStateChanged?.call();
      }
    };

    _pc!.onIceCandidate = (candidate) {
      if (candidate.candidate != null && remotePeerId != null) {
        SocketService().callIceCandidate(
          target   : remotePeerId!,
          candidate: candidate.toMap(),
        );
      }
    };

    _pc!.onIceConnectionState = (state) {
      print('[call] ICE connection state: $state');
      onStateChanged?.call();
    };

    _pc!.onConnectionState = (state) {
      print('[call] connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        onCallConnected?.call();
      }
      onStateChanged?.call();
    };

    return _pc!;
  }

  // ────────────────────────────────────────────────────────────────
  // CALLER: create and send offer
  // ────────────────────────────────────────────────────────────────
  Future<void> _createOffer() async {
    await _createPC();

    final offer = await _pc!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': callType == 'video',
    });

    await _pc!.setLocalDescription(offer);

    SocketService().callOffer(
      target  : remotePeerId!,
      sdp     : offer.toMap(),
      callType: callType,
    );

    print('[call] offer sent to $remotePeerId');
  }

  // ────────────────────────────────────────────────────────────────
  // RECEIVER: handle offer and send answer
  // ────────────────────────────────────────────────────────────────
  Future<void> _handleOffer(Map sdp) async {
    await _createPC();

    await _pc!.setRemoteDescription(
      RTCSessionDescription(sdp['sdp'], sdp['type']),
    );

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);

    SocketService().callAnswer(
      target: remotePeerId!,
      sdp   : answer.toMap(),
    );

    print('[call] answer sent to $remotePeerId');
    onCallConnected?.call();
  }

  // ────────────────────────────────────────────────────────────────
  // CONTROLS
  // ────────────────────────────────────────────────────────────────
  void toggleMute() {
    _muted = !_muted;
    localStream?.getAudioTracks().forEach((t) => t.enabled = !_muted);
    onStateChanged?.call();
  }

  void toggleCamera() {
    _camOff = !_camOff;
    localStream?.getVideoTracks().forEach((t) => t.enabled = !_camOff);
    onStateChanged?.call();
  }

  Future<void> switchCamera() async {
    final tracks = localStream?.getVideoTracks();
    if (tracks != null && tracks.isNotEmpty) {
      await Helper.switchCamera(tracks.first);
    }
  }

  // ────────────────────────────────────────────────────────────────
  // HANG UP
  // ────────────────────────────────────────────────────────────────
  void hangUp() {
    if (remotePeerId != null) {
      SocketService().callHangUp(target: remotePeerId!);
    }
    _cleanupConnection();
    onCallEnded?.call();
  }

  // ────────────────────────────────────────────────────────────────
  // CLEANUP
  // ────────────────────────────────────────────────────────────────
  void _cleanupConnection() {
    _pc?.close();
    _pc          = null;
    remoteStream = null;
    remoteRenderer.srcObject = null;
    remotePeerId = null;
    callRoomId   = null;
    _muted       = false;
    _camOff      = false;
  }

  Future<void> dispose() async {
    _initialized = false;

    // ✅ Null callbacks first — prevents setState on dead widgets
    onStateChanged  = null;
    onCallEnded     = null;
    onCallConnected = null;

    _cleanupConnection();

    localStream?.getTracks().forEach((t) => t.stop());
    localStream?.dispose();
    localStream = null;

    try {
      localRenderer.srcObject  = null;
      remoteRenderer.srcObject = null;
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (e) {
      print('[CallService] renderer dispose error: $e');
    }

    final s = SocketService();
    s.offCallPeerJoined();
    s.offCallOffer();
    s.offCallAnswer();
    s.offCallIceCandidate();
    s.offCallPeerHungUp();
    s.offCallPeerLeft();

    print('[CallService] disposed');
  }
}