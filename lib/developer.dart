import 'package:flutter/material.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  // Responsive design helpers
  double _getResponsiveFontSize(double width, {double baseSize = 16.0}) {
    if (width < 480) return baseSize - 2;
    if (width < 768) return baseSize - 1;
    if (width < 1024) return baseSize;
    return baseSize + 1;
  }

  double _getResponsiveSpacing(double width) {
    if (width < 480) return 8.0;
    if (width < 768) return 12.0;
    if (width < 1024) return 16.0;
    return 20.0;
  }

  double _getResponsivePadding(double width) {
    if (width < 480) return 8.0;
    if (width < 768) return 12.0;
    if (width < 1024) return 16.0;
    return 20.0;
  }

  double _getResponsiveIconSize(double width) {
    if (width < 480) return 20.0;
    if (width < 768) return 22.0;
    if (width < 1024) return 24.0;
    return 26.0;
  }

  double _getResponsiveContainerWidth(double width) {
    if (width < 480) return width * 0.9;
    if (width < 768) return 350.0;
    if (width < 1024) return 400.0;
    return 450.0;
  }

  double _getResponsiveAvatarRadius(double width) {
    if (width < 480) return 25.0;
    if (width < 768) return 28.0;
    if (width < 1024) return 30.0;
    return 32.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _getResponsiveSpacing(screenWidth);
    final padding = _getResponsivePadding(screenWidth);
    final fontSize = _getResponsiveFontSize(screenWidth);
    final iconSize = _getResponsiveIconSize(screenWidth);
    final containerWidth = _getResponsiveContainerWidth(screenWidth);
    final toolbarHeight = screenWidth < 480 ? 60.0 : 70.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A9BAE),
        elevation: 0,
        toolbarHeight: toolbarHeight,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Developer Contacts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: fontSize + 2,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          width: containerWidth,
          padding: EdgeInsets.symmetric(vertical: spacing * 2, horizontal: padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'INFORMATION OF DEVELOPER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2F3C7E),
                ),
              ),
              SizedBox(height: spacing * 2),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: screenWidth < 480 ? 15 : 20,
                runSpacing: screenWidth < 480 ? 20 : 25,
                children: [
                  DeveloperProfile(
                    imagePath: 'assets/images/rea.png',
                    name: 'Rea Mae Royandoyan',
                    email: 'reamae@example.com',
                    contact: '+63 912 345 6789',
                    screenWidth: screenWidth,
                  ),
                  DeveloperProfile(
                    imagePath: 'assets/images/charisa.png',
                    name: 'Charsa V. Carpon',
                    email: 'carponcharisa22@example.com',
                    contact: '+63 955 750 8437',
                    screenWidth: screenWidth,
                  ),
                  DeveloperProfile(
                    imagePath: 'assets/images/cristin.png',
                    name: 'Cristina Taduyo',
                    email: 'cristina19ashley@example.com',
                    contact: '+63 934 567 8901',
                    screenWidth: screenWidth,
                  ),
                  DeveloperProfile(
                    imagePath: 'assets/images/eman.png',
                    name: 'Jerecho Eman',
                    email: 'jerechovlcrts@example.com',
                    contact: '+63 965 955 4576',
                    screenWidth: screenWidth,
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

class DeveloperProfile extends StatelessWidget {
  final String imagePath;
  final String name;
  final String email;
  final String contact;
  final double screenWidth;

  // Responsive design helpers
  double _getResponsiveFontSize(double width, {double baseSize = 16.0}) {
    if (width < 480) return baseSize - 2;
    if (width < 768) return baseSize - 1;
    if (width < 1024) return baseSize;
    return baseSize + 1;
  }

  double _getResponsiveSpacing(double width) {
    if (width < 480) return 8.0;
    if (width < 768) return 12.0;
    if (width < 1024) return 16.0;
    return 20.0;
  }

  double _getResponsiveAvatarRadius(double width) {
    if (width < 480) return 25.0;
    if (width < 768) return 28.0;
    if (width < 1024) return 30.0;
    return 32.0;
  }

  double _getResponsiveContainerWidth(double width) {
    if (width < 480) return 90.0;
    if (width < 768) return 100.0;
    if (width < 1024) return 110.0;
    return 120.0;
  }

  const DeveloperProfile({
    required this.imagePath,
    required this.name,
    required this.email,
    required this.contact,
    required this.screenWidth,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = _getResponsiveFontSize(screenWidth);
    final spacing = _getResponsiveSpacing(screenWidth);
    final avatarRadius = _getResponsiveAvatarRadius(screenWidth);
    final containerWidth = _getResponsiveContainerWidth(screenWidth);
    
    return SizedBox(
      width: containerWidth,
      child: Column(
        children: [
          // Fallback if image fails to load
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: AssetImage(imagePath),
            child: Image.asset(
              imagePath,
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.person, size: avatarRadius, color: Colors.grey),
            ),
          ),
          SizedBox(height: spacing),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize - 6,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize - 7,
              color: const Color(0xFF7A9BAE),
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: spacing * 0.2),
            padding: EdgeInsets.symmetric(
              horizontal: spacing * 0.4,
              vertical: spacing * 0.2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF7A9BAE),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              contact,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize - 7,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}