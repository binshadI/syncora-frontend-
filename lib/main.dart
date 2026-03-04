import 'package:flutter/material.dart';
import 'package:frontend/pages/register.dart';
import 'pages/login.dart';
import 'pages/homepage.dart';
import 'pages/Getstarted.dart';
import 'services/shared_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Use SharedService (api_cache_manager) — NOT SharedPreferences
  // Because auth_service saves via SharedService.setLoginDetails(), not prefs.setString()
  final isLoggedIn = await SharedService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const ChatHomePage() : const GetStartedPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/SignUp': (context) => const SignUp(),
        '/home': (context) => const ChatHomePage(),
        '/Getstarted': (context) => const GetStartedPage(),
      },
    );
  }
}