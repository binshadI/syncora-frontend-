import 'package:flutter/material.dart';
import 'package:frontend/pages/register.dart';
import 'package:frontend/services/socket_service.dart';
import 'pages/login.dart';
import 'pages/homepage.dart';
import 'pages/Getstarted.dart';
import 'services/shared_service.dart';
import 'pages/chat_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isLoggedIn = await SharedService.isLoggedIn();

  // ✅ only init socket if logged in
  if (isLoggedIn) {
    final details = await SharedService.loginDetails();
    if (details != null) {
      SocketService().init(details.accessToken);
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