import 'package:flutter/material.dart';
import 'login.dart';
import 'signup.dart';
import 'Selection_screen.dart'; // <-- Make sure to import this

class SelectionLoginSignup extends StatelessWidget {
  final String userType;

  const SelectionLoginSignup({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    // Text changes based on userType
    String promptText =
        userType == 'fisherman' ? 'Are you a Customer?' : 'Are you a Fisherman?';

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blueGrey, width: 1),
          ),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 100,
              ),
              const SizedBox(height: 10),
              const Text(
                'Fisher Tech',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Serif',
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF243B5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(userType: userType),
                      ),
                    );
                  },
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF243B5E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SignUpScreen(userType: userType),
                      ),
                    );
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$promptText ",
                    style: const TextStyle(fontSize: 15),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Go back to SelectionScreen (replace current screen)
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SelectionScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      "Click Here",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        color: Color(0xFF243B5E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}