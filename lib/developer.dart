import 'package:flutter/material.dart';

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  // Ocean/Fisherman themed gradients
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

  // Responsive design helpers
  double _getResponsiveFontSize(double width, {double baseSize = 16.0}) {
    if (width < 480) return baseSize - 2;
    if (width < 768) return baseSize - 1;
    if (width < 1024) return baseSize;
    return baseSize + 1;
  }

  double _getResponsiveSpacing(double width) {
    if (width < 480) return 6.0;
    if (width < 768) return 8.0;
    if (width < 1024) return 10.0;
    return 12.0;
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
    if (width < 480) return width * 0.42; // Allow 2 cards per row on mobile
    if (width < 768) return 160.0; // Allow 2 cards per row on tablet
    if (width < 1024) return 180.0; // Allow 2 cards per row on desktop
    return 200.0; // Allow 2 cards per row on large screens
  }

  double _getResponsiveAvatarRadius(double width) {
    if (width < 480) return 20.0;
    if (width < 768) return 22.0;
    if (width < 1024) return 24.0;
    return 26.0;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _getResponsiveSpacing(screenWidth);
    final padding = _getResponsivePadding(screenWidth);
    final fontSize = _getResponsiveFontSize(screenWidth);
    final iconSize = _getResponsiveIconSize(screenWidth);
    final containerWidth = screenWidth < 600
        ? screenWidth * 0.95 // Use almost full width on mobile
        : 400.0; // Fixed width for 2 cards on tablet/desktop
    final toolbarHeight = screenWidth < 480 ? 60.0 : 70.0;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: oceanGradient),
        child: Column(
          children: [
            // Custom AppBar with gradient
            Container(
              decoration: const BoxDecoration(gradient: oceanGradient),
              child: SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black, size: iconSize),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Developer Contacts',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize + 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: iconSize + 8), // Balance the back button
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: containerWidth,
                  margin: EdgeInsets.all(padding),
                  padding: EdgeInsets.symmetric(vertical: spacing * 2, horizontal: padding),
                  decoration: BoxDecoration(
                    gradient: cardGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing * 0.5),
                        decoration: BoxDecoration(
                          gradient: accentGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'INFORMATION OF DEVELOPER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(height: spacing * 2),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: screenWidth < 480 ? 8 : 12,
                        runSpacing: screenWidth < 480 ? 16 : 20,
                        children: [
                          DeveloperProfile(
                            imagePath: 'assets/images/rea.png',
                            name: 'Rea Mae Royandoyan',
                            email: 'reamaeroyandoyan445@gmail.com',
                            contact: '+63 912 345 6789',
                            screenWidth: screenWidth,
                          ),
                          DeveloperProfile(
                            imagePath: 'assets/images/charisa.png',
                            name: 'Charsa V. Carpon',
                            email: 'carponcharisa22@gmail.com',
                            contact: '+63 955 750 8437',
                            screenWidth: screenWidth,
                          ),
                          DeveloperProfile(
                            imagePath: 'assets/images/cristin.png',
                            name: 'Cristina Taduyo',
                            email: 'cristina19ashley@gmail.com',
                            contact: '+63 934 567 8901',
                            screenWidth: screenWidth,
                          ),
                          DeveloperProfile(
                            imagePath: 'assets/images/eman.png',
                            name: 'Jerecho Eman',
                            email: 'jerechovlcrts@gmail.com',
                            contact: '+63 965 955 4576',
                            screenWidth: screenWidth,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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

  // Ocean/Fisherman themed gradients
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

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F766E), // Teal
      Color(0xFF14B8A6), // Sea green
    ],
  );

  // Responsive design helpers
  double _getResponsiveFontSize(double width, {double baseSize = 16.0}) {
    if (width < 480) return baseSize - 2;
    if (width < 768) return baseSize - 1;
    if (width < 1024) return baseSize;
    return baseSize + 1;
  }

  double _getResponsiveSpacing(double width) {
    if (width < 480) return 6.0;
    if (width < 768) return 8.0;
    if (width < 1024) return 10.0;
    return 12.0;
  }

  double _getResponsiveAvatarRadius(double width) {
    if (width < 480) return 20.0;
    if (width < 768) return 22.0;
    if (width < 1024) return 24.0;
    return 26.0;
  }

  double _getResponsiveContainerWidth(double width) {
    if (width < 480) return width * 0.42; // Allow 2 cards per row on mobile
    if (width < 768) return 160.0; // Allow 2 cards per row on tablet
    if (width < 1024) return 180.0; // Allow 2 cards per row on desktop
    return 200.0; // Allow 2 cards per row on large screens
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
    
    return Container(
      width: containerWidth,
      padding: EdgeInsets.all(spacing * 0.3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFffffff),
            Color(0xFFf8f9ff),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fallback if image fails to load
          Container(
            decoration: BoxDecoration(
              gradient: oceanGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage(imagePath),
              child: Image.asset(
                imagePath,
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, size: avatarRadius, color: Colors.white),
              ),
            ),
          ),
          SizedBox(height: spacing * 0.5), // Smaller spacing
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize - 8,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize - 9,
              color: const Color(0xFF7A9BAE),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          Container(
            margin: EdgeInsets.only(top: spacing * 0.2),
            padding: EdgeInsets.symmetric(
              horizontal: spacing * 0.4,
              vertical: spacing * 0.2,
            ),
            decoration: BoxDecoration(
              gradient: accentGradient,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              contact,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize - 9,
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