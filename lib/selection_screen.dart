import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'selection_loginsignup.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueGrey, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: logoSize,
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF243B5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.symmetric(vertical: fontSize + 2),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectionLoginSignup(userType: 'fisherman'),
                          ),
                        );
                      },
                      child: Text(
                        'Fisherman',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(height: spacing * 0.8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF243B5E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.symmetric(vertical: fontSize + 2),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SelectionLoginSignup(userType: 'customer'),
                          ),
                        );
                      },
                      child: Text(
                        'Customer',
                        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
