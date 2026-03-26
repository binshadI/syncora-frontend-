import 'package:flutter/material.dart';
import '../services/socket_service.dart';
import '../services/CallService.dart';
import 'call_screen.dart';

/// Shown to the RECEIVER when someone calls them.
class IncomingCallScreen extends StatefulWidget {
  final String callerName;
  final String fromSocketId;
  final String callRoomId;
  final String callType;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.fromSocketId,
    required this.callRoomId,
    required this.callType,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _ringAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut),
    );

    // If caller cancels while we're on this screen
    SocketService().onCallPeerHungUp((_) {
      if (mounted) Navigator.pop(context);
    });
    SocketService().onCallPeerLeft((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  // ── Accept call ───────────────────────────────────────────────────
  Future<void> _acceptCall() async {
    try {
      _ringCtrl.stop();

      final callService = CallService();

      await callService.init();
      await callService.startLocalStream(widget.callType);
      callService.callRoomId = widget.callRoomId;
      callService.setupSignalingListeners();

      // Navigate immediately — don't wait for remoteStream
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CallScreen(
              friendName: widget.callerName,
              callType  : widget.callType,
            ),
          ),
        );
      }

      // Join AFTER navigating
      SocketService().callJoin(
        callRoomId: widget.callRoomId,
        callType  : widget.callType,
      );

    } catch (e, stack) {
      print('❌ _acceptCall error: $e');
      print('❌ stack: $stack');
    }
  }

  // ── Reject call ───────────────────────────────────────────────────
  void _rejectCall() {
    SocketService().callReject(target: widget.fromSocketId);
    SocketService().offCallPeerHungUp();
    SocketService().offCallPeerLeft();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    SocketService().offCallPeerHungUp();
    SocketService().offCallPeerLeft();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1E),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            ScaleTransition(
              scale: _ringAnim,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFF2563EB),
                    child: Text(
                      widget.callerName.isNotEmpty
                          ? widget.callerName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              widget.callerName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.callType == 'video'
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: const Color(0xFF94A3B8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.callType == 'video'
                      ? 'Incoming video call'
                      : 'Incoming voice call',
                  style: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 15),
                ),
              ],
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.only(bottom: 56),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _rejectCall,
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
                      const SizedBox(height: 8),
                      const Text('Decline',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),

                  // Accept
                  Column(
                    children: [
                      GestureDetector(
                        onTap: _acceptCall,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.callType == 'video'
                                ? Icons.videocam_rounded
                                : Icons.call_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Accept',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}