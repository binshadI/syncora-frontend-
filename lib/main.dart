import 'package:flutter/material.dart';
import 'package:frontend/pages/register.dart';
import 'pages/login.dart';
import 'pages/homepage.dart';
import 'pages/verificationcondepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/verificationcode',
      routes: {
        '/login' : (context) => const LoginPage(),
        '/SignUp' : (context) => const SignUp(),
        '/home' : (context) => const ChatHomePage(),
        '/verificationcode' : (context) => const VerificationPage()
      },
    );
  }
}
