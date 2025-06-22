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
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions with better breakpoints
    double logoRadius;
    double logoSize;
    
    if (screenWidth < 360) {
      // Very small screens (old phones)
      logoRadius = 60.0;
      logoSize = 120.0;
    } else if (screenWidth < 480) {
      // Small screens
      logoRadius = 70.0;
      logoSize = 140.0;
    } else if (screenWidth < 768) {
      // Medium screens (tablets)
      logoRadius = 80.0;
      logoSize = 160.0;
    } else {
      // Large screens (desktop)
      logoRadius = 100.0;
      logoSize = 200.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF7A9BAE),
      body: SafeArea(
        child: Center(
          child: Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: logoSize * 0.8,
                height: logoSize * 0.8,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
