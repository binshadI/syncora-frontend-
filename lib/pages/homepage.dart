import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/home_response_model.dart';
import '../services/home_service.dart';
import '../services/notification_service.dart';
import '../dialogs/add_contact_dialog.dart';
import '../dialogs/notifications_dialog.dart';
import 'chat_page.dart';
import '../services/ChatService.dart';
import '../services/shared_service.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({Key? key}) : super(key: key);

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  int _selectedIndex = 0;
  List<Contact> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _fetchNotificationCount();
  }

  Future<void> _fetchNotificationCount() async {
    final requests = await NotificationService.getPendingRequests();
    if (mounted) {
      setState(() => _notificationCount = requests.length);
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final contacts = await HomeService.getContacts();
      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddContactDialog() async {
    final result = await showAddContactDialog(context);
    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Friend request sent to $result'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _openNotifications() async {
    await showNotificationsDialog(context);
    _fetchNotificationCount();
  }

  void _onBottomNavTap(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101522),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopView(),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: _buildAddContactButton(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildTopView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade400],
              ),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 15),
          const Text(
            'Syncore',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _openNotifications,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF181E32),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white70,
                    size: 22,
                  ),
                  if (_notificationCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181E32),
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: TextStyle(color: Colors.grey[700]),
            prefixIcon: Icon(Icons.search, color: Colors.grey[700]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 12),
            Text(_errorMessage!,
                style: TextStyle(color: Colors.grey[500], fontSize: 15),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadContacts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }
    if (_contacts.isEmpty) {
      return Center(
          child: Text('No contacts yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _loadContacts,
      color: Colors.blue,
      backgroundColor: const Color(0xFF181E32),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _contacts.length,
        itemBuilder: (context, index) => _buildChatItem(_contacts[index]),
      ),
    );
  }

  Widget _buildChatItem(Contact contact) {
    return GestureDetector(
      onTap: () async {
        final result = await ChatService.getRoomId(contact.friendId);

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              userName: contact.username,
              roomId: result['roomId']!,
              senderId: result['senderId']!,
              isOnline: true,
            ),
          ),
        );
      },
      child: Container( // ✅ fixed: was missing closing ) for GestureDetector
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF181E32),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.primaries[
                    contact.username.hashCode % Colors.primaries.length],
                    Colors.primaries[(contact.username.hashCode + 3) %
                        Colors.primaries.length],
                  ],
                ),
              ),
              child: Center(
                child: Text(
                  contact.username[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Text(
                    'Tap to start chatting',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ), // ✅ closes GestureDetector child
    ); // ✅ closes GestureDetector
  }

  Widget _buildAddContactButton() {
    return FloatingActionButton(
      onPressed: _openAddContactDialog,
      backgroundColor: Colors.blue,
      child: const Icon(Icons.add, color: Colors.white, size: 30),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF181E32),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        backgroundColor: Colors.transparent,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.call_outlined),
              activeIcon: Icon(Icons.call),
              label: 'Calls'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}