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
      logoRadius = 80.0;
      logoSize = 160.0;
    } else if (screenWidth < 480) {
      // Small screens
      logoRadius = 100.0;
      logoSize = 200.0;
    } else if (screenWidth < 768) {
      // Medium screens (tablets)
      logoRadius = 120.0;
      logoSize = 240.0;
    } else {
      // Large screens (desktop)
      logoRadius = 140.0;
      logoSize = 280.0;
    }

    // Light ocean gradient to highlight the logo
    const LinearGradient oceanGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFe0f7fa), // Light aqua
        Color(0xFFb3e5fc), // Pale blue
        Color(0xFF81d4fa), // Soft blue
        Color(0xFFb2ebf2), // Light teal
        Color(0xFFe1f5fe), // Very light blue
      ],
    );

    const LinearGradient logoGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF06B6D4), // Cyan
        Color(0xFF0891B2), // Ocean cyan
        Color(0xFF0EA5E9), // Sky blue
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: oceanGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              width: logoSize,
              height: logoSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: logoGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    spreadRadius: 2,
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo1.jpg',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
