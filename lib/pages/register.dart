import 'package:flutter/material.dart';
import 'package:frontend/models/register_request_model.dart';
import 'package:frontend/pages/login.dart';
import 'package:frontend/pages/verificationcondepage.dart';
import 'package:frontend/services/auth_service.dart';


class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //api calling part =======================

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool isApiCallProcess = false;

  Future<void> RegisterUser() async{

    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    print("register button clicked..");

    setState(() {
      isApiCallProcess = true;
    });

    String? errorMessage = await AuthService.register(
      RegisterRequestModel(
        username: username,
        email: email,
        password: password
      ),
    );



    setState(() {
      isApiCallProcess = false;
    });

    if(errorMessage == null){
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => VerificationPage(
                email: email,
              )
          ),
      );
    }else{
      print(errorMessage);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }

  }




//--------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101522),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(50, 50, 50, 0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Sign up to start connecting',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFFA0A0A0),
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  'Username',
                  style: TextStyle(
                    color: Color(0xFFCFCECE),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter your Username',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF181E32),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Email',
                  style: TextStyle(
                    color: Color(0xFFCFCECE),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter your email',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF181E32),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'Password',
                  style: TextStyle(
                    color: Color(0xFFCFCECE),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF181E32),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton( // sign up button +++++++++++++++
                    onPressed: RegisterUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
