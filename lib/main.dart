import 'package:flutter/material.dart';
import 'package:frontend/pages/register.dart';
import 'pages/login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login' : (context) => const LoginPage(),
        'SignUp' : (context) => const SignUp()
      },
    );
  }
}
