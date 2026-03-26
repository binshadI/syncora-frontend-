import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/socket_service.dart';
import '../models/messagemodel.dart';
import '../services/CallService.dart';
import '../services/baseapiservice.dart';
import '../config/config.dart';
import 'calling_screen.dart';

class ChatPage extends StatefulWidget {
  final String userName;
  final String userAvatar;
  final bool isOnline;
  final String roomId;
  final String senderId;
  final String friendId;
  final String senderName;

  const ChatPage({
    super.key,
    required this.userName,
    required this.roomId,
    required this.senderId,
    required this.friendId,
    required this.senderName,
    this.userAvatar = '',
    this.isOnline   = true,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
  static const Color bgColor          = Color(0xFF101522);
  static const Color senderBubble     = Color(0xFF2563EB);
  static const Color receiverBubble   = Color(0xFF1C2333);
  static const Color inputBg          = Color(0xFF1C2333);
  static const Color dividerColor     = Color(0xFF1F2A3C);
  static const Color iconColor        = Color(0xFF94A3B8);
  static const Color generateBtnColor = Color(0xFF2A3447);
  static const Color sendBtnColor     = Color(0xFF2563EB);

  final TextEditingController _msgController   = TextEditingController();
  final ScrollController       _scrollController = ScrollController();
  final List<MessageModel>     _messages = [];

  bool _isGenerating = false; // ← loading state for AI

  late final AnimationController _entranceCtrl;
  late final Animation<Offset>   _topBarSlide;
  late final Animation<double>   _msgFade;
  late final Animation<Offset>   _msgSlide;
  late final Animation<Offset>   _inputSlide;

  @override
  void initState() {
    super.initState();

    SocketService().joinRoom(widget.roomId);

    SocketService().onReceiveMessage((data) {
      final msg = MessageModel.fromJson(data);
      if (mounted) {
        setState(() => _messages.add(msg));
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _topBarSlide = Tween<Offset>(
      begin: const Offset(0, -0.4), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _msgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceCtrl,
        curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
      ),
    );

    _msgSlide = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
    ));

    _inputSlide = Tween<Offset>(
      begin: const Offset(0, 1.0), end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.1, 0.65, curve: Curves.easeOut),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entranceCtrl.forward();
    });
  }

  // ── AI Generate ───────────────────────────────────────────────────
  Future<void> _generateText() async {
    final prompt = _msgController.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type something first to generate'),
          backgroundColor: Color(0xFF1C2333),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final headers = await ApiService.getHeaders();
      final response = await http.post(
        Uri.parse('${Config.apiURL}${Config.generateText}'),
        headers: headers,
        body: jsonEncode({'prompt': prompt}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final generated = data['text'] ?? '';
        // ✅ Replace input field with generated text
        setState(() {
          _msgController.text = generated;
          _msgController.selection = TextSelection.fromPosition(
            TextPosition(offset: generated.length),
          );
        });
      } else {
        _showError('Generation failed. Try again.');
      }
    } catch (e) {
      print('Generate error: $e');
      _showError('Something went wrong.');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Start a call ──────────────────────────────────────────────────
  void _startCall(String callType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallingScreen(
          friendId  : widget.friendId,
          friendName: widget.userName,
          callRoomId: widget.roomId,
          callType  : callType,
          callerName: widget.senderName,
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    SocketService().sendMessage(
      roomId  : widget.roomId,
      msg     : text,
      senderId: widget.senderId,
    );
    _msgController.clear();
  }

  @override
  void dispose() {
    SocketService().offReceiveMessage();
    SocketService().leaveRoom(widget.roomId);
    _entranceCtrl.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            SlideTransition(
              position: _topBarSlide,
              child: Column(children: [
                _buildTopBar(),
                const Divider(color: dividerColor, height: 1, thickness: 1),
              ]),
            ),
            Expanded(
              child: FadeTransition(
                opacity: _msgFade,
                child: SlideTransition(
                  position: _msgSlide,
                  child: _buildMessageList(),
                ),
              ),
            ),
            SlideTransition(
              position: _inputSlide,
              child: _buildInputArea(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 20,
            backgroundColor: senderBubble,
            backgroundImage: widget.userAvatar.isNotEmpty
                ? NetworkImage(widget.userAvatar)
                : null,
            child: widget.userAvatar.isEmpty
                ? Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Row(children: [
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(
                      color: widget.isOnline
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                        color: widget.isOnline
                            ? const Color(0xFF22C55E)
                            : const Color(0xFF64748B),
                        fontSize: 12),
                  ),
                ]),
              ],
            ),
          ),
          _callIconBtn(Icons.call_rounded,    () => _startCall('audio')),
          const SizedBox(width: 4),
          _callIconBtn(Icons.videocam_rounded, () => _startCall('video')),
        ],
      ),
    );
  }

  Widget _callIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF1C2333),
          shape: BoxShape.circle,
          border: Border.all(color: dividerColor),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  // ─── Message List ─────────────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isSender = msg.senderId == widget.senderId;
        return _buildBubble(
          text    : msg.message,
          time    : msg.timestamp,
          isSender: isSender,
        );
      },
    );
  }

  Widget _buildBubble({
    required String text,
    required String time,
    required bool isSender,
  }) {
    final borderRadius = isSender
        ? const BorderRadius.only(
      topLeft    : Radius.circular(18),
      topRight   : Radius.circular(18),
      bottomLeft : Radius.circular(18),
      bottomRight: Radius.circular(3),
    )
        : const BorderRadius.only(
      topLeft    : Radius.circular(18),
      topRight   : Radius.circular(18),
      bottomLeft : Radius.circular(3),
      bottomRight: Radius.circular(18),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: senderBubble,
              child: Text(
                widget.userName.isNotEmpty
                    ? widget.userName[0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color       : isSender ? senderBubble : receiverBubble,
                borderRadius: borderRadius,
                boxShadow   : [
                  BoxShadow(
                    color     : Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset    : const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          height: 1.4)),
                  const SizedBox(height: 4),
                  Text(time,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input Area ───────────────────────────────────────────────────
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: const BoxDecoration(
        color : bgColor,
        border: Border(top: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color       : inputBg,
                borderRadius: BorderRadius.circular(14),
                border      : Border.all(color: dividerColor),
              ),
              child: Column(
                children: [
                  // Text field
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: TextField(
                      controller : _msgController,
                      style      : const TextStyle(
                          color: Colors.white, fontSize: 14),
                      cursorColor: senderBubble,
                      maxLines   : 4,
                      minLines   : 1,
                      decoration : const InputDecoration(
                        hintText      : 'Type a message...',
                        hintStyle     : TextStyle(
                            color: Color(0xFF4B5568), fontSize: 14),
                        border        : InputBorder.none,
                        isDense       : true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  // ✅ Generate button at bottom of input
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _isGenerating ? null : _generateText,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _isGenerating
                                  ? generateBtnColor.withOpacity(0.5)
                                  : generateBtnColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: dividerColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _isGenerating
                                    ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF94A3B8),
                                  ),
                                )
                                    : const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: Color(0xFF94A3B8),
                                    size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  _isGenerating ? 'Generating...' : 'Generate',
                                  style: TextStyle(
                                    color: _isGenerating
                                        ? const Color(0xFF94A3B8).withOpacity(0.5)
                                        : const Color(0xFF94A3B8),
                                    fontSize  : 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width : 50, height: 50,
              decoration: const BoxDecoration(
                color : sendBtnColor,
                shape : BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color     : Color(0x552563EB),
                    blurRadius: 12,
                    offset    : Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}