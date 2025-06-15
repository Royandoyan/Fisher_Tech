import 'dart:async';
import 'package:flutter/material.dart';
import 'selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SelectionScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF7A9BAE),
      body: Center(
        child: CircleAvatar(
          radius: 80,
          backgroundImage: AssetImage('assets/images/logo.png'),
          backgroundColor: Colors.white, 
        ),
      ),
    );
  }
}
