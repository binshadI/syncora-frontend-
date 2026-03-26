import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/CallService.dart';

class CallScreen extends StatefulWidget {
  final String friendName;
  final String callType;

  const CallScreen({
    super.key,
    required this.friendName,
    required this.callType,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _call = CallService();

  @override
  void initState() {
    super.initState();

    // ✅ Set all callbacks — null them in dispose before calling super
    _call.onStateChanged = () {
      if (mounted) setState(() {});
    };

    _call.onCallConnected = () {
      if (mounted) setState(() {});
    };

    _call.onCallEnded = () {
      if (mounted) Navigator.pop(context);
    };

    // ✅ Force rebuild after first frame so renderers are attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });

    // ✅ Poll for remote stream — stops once stream arrives
    _pollForRemoteStream();
  }

  void _pollForRemoteStream() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {});
      if (_call.remoteStream == null) {
        _pollForRemoteStream();
      }
    });
  }

  @override
  void dispose() {
    // ✅ Null callbacks FIRST — prevents setState calls on dead widget
    _call.onStateChanged  = null;
    _call.onCallEnded     = null;
    _call.onCallConnected = null;
    _call.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callType == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          // ── Remote video (full screen) or audio background ────────
          Positioned.fill(
            child: isVideo
                ? Stack(
              children: [
                // ✅ Using textureId as key — forces rebuild when stream changes
                RTCVideoView(
                  _call.remoteRenderer,
                  key: ValueKey('remote_${_call.remoteRenderer.textureId}'),
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
                if (_call.remoteStream == null)
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white54),
                        SizedBox(height: 12),
                        Text(
                          'Connecting video...',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
              ],
            )
                : _buildAudioBackground(),
          ),

          // ── Local video (picture-in-picture) — video only ─────────
          if (isVideo)
            Positioned(
              top: 48, right: 16,
              width: 110, height: 160,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _call.localRenderer,
                  key: ValueKey('local_${_call.localRenderer.textureId}'),
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // ── Top info bar ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.friendName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Controls at bottom ────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.85),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  _CtrlBtn(
                    icon  : _call.isMuted
                        ? Icons.mic_off_rounded
                        : Icons.mic_rounded,
                    label : _call.isMuted ? 'Unmute' : 'Mute',
                    active: _call.isMuted,
                    onTap : () => setState(() => _call.toggleMute()),
                  ),

                  _CtrlBtn(
                    icon    : Icons.call_end_rounded,
                    label   : 'End',
                    isEndBtn: true,
                    onTap   : () => _call.hangUp(),
                  ),

                  if (isVideo)
                    _CtrlBtn(
                      icon  : _call.isCamOff
                          ? Icons.videocam_off_rounded
                          : Icons.videocam_rounded,
                      label : _call.isCamOff ? 'Cam Off' : 'Camera',
                      active: _call.isCamOff,
                      onTap : () => setState(() => _call.toggleCamera()),
                    )
                  else
                    _CtrlBtn(
                      icon : Icons.volume_up_rounded,
                      label: 'Speaker',
                      onTap: () {},
                    ),

                  if (isVideo)
                    _CtrlBtn(
                      icon : Icons.flip_camera_ios_rounded,
                      label: 'Flip',
                      onTap: () => _call.switchCamera(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBackground() {
    return Container(
      color: const Color(0xFF0F1729),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: const Color(0xFF2563EB),
              child: Text(
                widget.friendName.isNotEmpty
                    ? widget.friendName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.friendName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Voice call in progress',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable control button ───────────────────────────────────────────
class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool isEndBtn;

  const _CtrlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active   = false,
    this.isEndBtn = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isEndBtn
        ? const Color(0xFFDC2626)
        : active
        ? const Color(0xFFDC2626)
        : Colors.white.withOpacity(0.15);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width : isEndBtn ? 64 : 54,
            height: isEndBtn ? 64 : 54,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: Colors.white, size: isEndBtn ? 28 : 22),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}