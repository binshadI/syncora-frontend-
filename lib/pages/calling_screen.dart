import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/CallService.dart';
import 'call_screen.dart';

/// Shown to the CALLER while waiting for the receiver to accept.
class CallingScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String callRoomId;
  final String callType;
  final String callerName;

  const CallingScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    required this.callRoomId,
    required this.callType,
    required this.callerName,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _setupListeners();
    _startCall();
  }

  Future<void> _startCall() async {
    final callService = CallService();

    await callService.init();
    await callService.startLocalStream(widget.callType);
    callService.callRoomId = widget.callRoomId;

    // ✅ onStateChanged must be set — local stream fires this on ready
    callService.onStateChanged = () {
      // No UI to update on CallingScreen, but callback must exist
      // so CallService doesn't silently drop the event
    };

    callService.onCallConnected = () {
      print('✅ onCallConnected fired — navigating to CallScreen');
      if (mounted && !_navigated) {
        _navigated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              friendName: widget.friendName,
              callType  : widget.callType,
            ),
          ),
        );
      }
    };

    callService.onCallEnded = () {
      if (mounted) Navigator.pop(context);
    };

    callService.setupSignalingListeners();

    SocketService().callInvite(
      friendId  : widget.friendId,
      callRoomId: widget.callRoomId,
      callType  : widget.callType,
      callerName: widget.callerName,
    );

    SocketService().callJoin(
      callRoomId: widget.callRoomId,
      callType  : widget.callType,
    );
  }

  void _setupListeners() {
    SocketService().onCallRejected((_) {
      if (mounted) {
        _showEndDialog(
            'Call Declined', '${widget.friendName} declined your call.');
      }
    });

    SocketService().onCallBusy((_) {
      if (mounted) {
        _showEndDialog('User Busy',
            '${widget.friendName} is currently in another call.');
      }
    });

    SocketService().onCallPeerLeft((_) {
      if (mounted) {
        _showEndDialog(
            'Unavailable', '${widget.friendName} is unavailable.');
      }
    });
  }

  void _showEndDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C2333),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message,
            style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK',
                style: TextStyle(color: Color(0xFF2563EB))),
          ),
        ],
      ),
    );
  }

  void _cancelCall() {
    SocketService().callHangUp(target: CallService().remotePeerId ?? '');
    CallService().dispose();
    SocketService().offCallRejected();
    SocketService().offCallBusy();
    SocketService().offCallPeerLeft();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101522),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _cancelCall,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  Text(
                    widget.callType == 'video' ? 'Video Call' : 'Voice Call',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            const Spacer(),

            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.15),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(0.4),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      widget.friendName.isNotEmpty
                          ? widget.friendName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              widget.friendName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            const Text(
              'Calling...',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: GestureDetector(
                onTap: _cancelCall,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_end_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}