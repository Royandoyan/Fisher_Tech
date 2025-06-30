import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login.dart';
import 'signup.dart';
import 'selection_screen.dart'; // <-- Make sure to import this

class SelectionLoginSignup extends StatelessWidget {
  final String userType;

  const SelectionLoginSignup({super.key, required this.userType});

  // Light ocean gradient to highlight the logo
  static const LinearGradient oceanGradient = LinearGradient(
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

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC), // Light sea foam
      Color(0xFFE0F2FE), // Very light blue
      Color(0xFFF0F9FF), // Ice blue
    ],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E40AF), // Deep blue
      Color(0xFF3B82F6), // Ocean blue
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F766E), // Teal
      Color(0xFF14B8A6), // Sea green
    ],
  );

  @override
  Widget build(BuildContext context) {
    // Text changes based on userType
    String promptText =
        userType == 'fisherman' ? 'Are you a Customer?' : 'Are you a Fisherman?';

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive dimensions with better breakpoints
    double containerWidth;
    double logoSize;
    double horizontalPadding;
    double verticalPadding;
    double fontSize;
    double titleFontSize;
    double spacing;
    
    if (screenWidth < 360) {
      // Very small screens (old phones)
      containerWidth = screenWidth * 0.92;
      logoSize = 80.0;
      horizontalPadding = 16.0;
      verticalPadding = 16.0;
      fontSize = 14.0;
      titleFontSize = 20.0;
      spacing = 12.0;
    } else if (screenWidth < 480) {
      // Small screens
      containerWidth = screenWidth * 0.88;
      logoSize = 90.0;
      horizontalPadding = 20.0;
      verticalPadding = 20.0;
      fontSize = 15.0;
      titleFontSize = 21.0;
      spacing = 15.0;
    } else if (screenWidth < 768) {
      // Medium screens (tablets)
      containerWidth = screenWidth * 0.75;
      logoSize = 100.0;
      horizontalPadding = 24.0;
      verticalPadding = 24.0;
      fontSize = 16.0;
      titleFontSize = 22.0;
      spacing = 18.0;
    } else {
      // Large screens (desktop)
      containerWidth = 400.0;
      logoSize = 110.0;
      horizontalPadding = 28.0;
      verticalPadding = 28.0;
      fontSize = 16.0;
      titleFontSize = 24.0;
      spacing = 20.0;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: oceanGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Container(
                width: containerWidth,
                constraints: BoxConstraints(
                  maxWidth: 450,
                  minHeight: screenHeight * 0.4,
                ),
                padding: EdgeInsets.all(horizontalPadding),
                decoration: BoxDecoration(
                  gradient: cardGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      spreadRadius: 2,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo with gradient background
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        gradient: buttonGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
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
                    SizedBox(height: spacing * 0.8),
                    Text(
                      'Fisher Tech',
                      style: GoogleFonts.parisienne(
                        fontSize: titleFontSize + 4,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF243B5E),
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: spacing * 1.5),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: buttonGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: fontSize + 6),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(userType: userType),
                            ),
                          );
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing * 0.8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: accentGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: fontSize + 6),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SignUpScreen(userType: userType),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing * 1.5),
                    Container(
                      padding: EdgeInsets.all(horizontalPadding * 0.5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFffffff),
                            Color(0xFFf0f4ff),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            "$promptText ",
                            style: TextStyle(fontSize: fontSize - 1),
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
                            child: Text(
                              "Click Here",
                              style: TextStyle(
                                fontSize: fontSize - 1,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                color: const Color(0xFF667eea),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}