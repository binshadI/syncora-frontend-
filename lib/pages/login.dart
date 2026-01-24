import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101522),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 50, 50, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15)
                ),
                child: const Icon(
                    Icons.videocam,
                    size: 50,
                    color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'login to continue connecting with your friends and family',
                style: TextStyle(
                  fontSize: 15,
                  color:  Color(0xFFA0A0A0 ),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                  'Email or Username',
                style: TextStyle(
                  color: Color(0xFFCFCECE)
                ),
              ),
              const SizedBox(height: 12,),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)
                  ),
                  hintText: 'Enter you email',
                  hintStyle: TextStyle(
                    color: Colors.grey[700],
                  ),
                  filled: true,
                  fillColor: Color(0xFF181E32),
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Password',
                style: TextStyle(
                    color: Color(0xFFCFCECE)
                ),
              ),
              const SizedBox(height: 12,),
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  hintText: 'Enter you password',
                  hintStyle: TextStyle(
                    color: Colors.grey[700],
                  ),
                  filled: true,
                  fillColor: Color(0xFF181E32),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
