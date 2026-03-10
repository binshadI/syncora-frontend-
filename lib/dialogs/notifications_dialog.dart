import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/notificationResponsetModel.dart';
import 'package:frontend/services/notification_service.dart';

Future<void> showNotificationsDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black.withOpacity(0.70),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutBack);
      return Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 6 * anim1.value,
              sigmaY: 6 * anim1.value,
            ),
            child: const SizedBox.expand(),
          ),
          FadeTransition(
            opacity: anim1,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(curved),
              child: const _NotificationsDialog(),
            ),
          ),
        ],
      );
    },
  );
}

class _NotificationsDialog extends StatefulWidget {
  const _NotificationsDialog();

  @override
  State<_NotificationsDialog> createState() => _NotificationsDialogState();
}

class _NotificationsDialogState extends State<_NotificationsDialog> {
  late Future<List<Request>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = NotificationService.getPendingRequests(); // 👈 fetch on open
  }

  Future<void> _onAccept(Request request) async {
    final success = await NotificationService.updateFriendRequest(request.id, 'accepted'); // 👈 was 'accept'
    if (success) {
      setState(() {
        _requestsFuture = NotificationService.getPendingRequests();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${request.from.email} added as a friend!'),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onDecline(Request request) async {
    final success = await NotificationService.updateFriendRequest(request.id, 'declined'); // 👈 was 'reject'
    if (success) {
      setState(() {
        _requestsFuture = NotificationService.getPendingRequests();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.88,
          decoration: BoxDecoration(
            color: const Color(0xFF181E32),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF252D45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white70, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              const Text(
                'FRIEND REQUESTS',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              // 👇 FutureBuilder replaces the hardcoded list
              FutureBuilder<List<Request>>(
                future: _requestsFuture,
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Something went wrong',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    );
                  }

                  final requests = snapshot.data ?? [];

                  if (requests.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'No pending friend requests',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: requests.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.grey.withOpacity(0.15),
                      height: 20,
                    ),
                    itemBuilder: (context, index) {
                      return _buildRequestTile(requests[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestTile(Request request) {
    return Row(
      children: [

        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.primaries[request.from.email.hashCode % Colors.primaries.length],
                Colors.primaries[(request.from.email.hashCode + 3) % Colors.primaries.length],
              ],
            ),
          ),
          child: Center(
            child: Text(
              request.from.email[0].toUpperCase(), // 👈 first letter of email
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            request.from.email, // 👈 show email
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(width: 8),

        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: () => _onAccept(request),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(width: 8),

        GestureDetector(
          onTap: () => _onDecline(request),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF252D45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.close, color: Colors.white38, size: 18),
          ),
        ),
      ],
    );
  }
}

class NotificationIcon extends StatefulWidget {
  const NotificationIcon({super.key});

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _fetchCount();
  }

  Future<void> _fetchCount() async {
    final requests = await NotificationService.getPendingRequests();
    if (mounted) {
      setState(() => _count = requests.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showNotificationsDialog(context); // wait for dialog to close
        _fetchCount(); // 👈 refresh badge after user accepts/declines
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications, color: Colors.white),

          // 👇 red dot only shows when there are pending requests
          if (_count > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}