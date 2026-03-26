import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/pages/register.dart';
import 'package:frontend/services/socket_service.dart';
import 'pages/login.dart';
import 'pages/homepage.dart';
import 'pages/Getstarted.dart';
import 'services/shared_service.dart';
import 'pages/chat_page.dart';

// ── Extract userId from JWT token (no extra package needed) ──────────
String? _userIdFromToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final map = jsonDecode(payload) as Map<String, dynamic>;
    print('🔑 JWT payload: $map');
    return map['userid'] ?? map['id'] ?? map['_id'] ?? map['userId'] ?? map['sub'];
  } catch (e) {
    print('❌ JWT decode error: $e');
    return null;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await SharedService.isLoggedIn();

  if (isLoggedIn) {
    final details = await SharedService.loginDetails();
    if (details != null) {
      final userId = _userIdFromToken(details.accessToken);
      print('👤 userId from token: $userId');
      SocketService().init(details.accessToken, userId ?? '');
    }
  }

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ← from socket_service.dart
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const ChatHomePage() : const GetStartedPage(),
      routes: {
        '/login'     : (context) => const LoginPage(),
        '/SignUp'    : (context) => const SignUp(),
        '/home'      : (context) => const ChatHomePage(),
        '/Getstarted': (context) => const GetStartedPage(),
      },
    );
  }
}