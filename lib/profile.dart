import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

import 'developer.dart';
import 'homed.dart';
import 'product.dart';
import 'messages.dart';
import 'shopping.dart';
import 'addtocart.dart';
import 'notification.dart';
import 'selection_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userType;

  const ProfileScreen({super.key, required this.userType});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? userType;
  String? profileImageUrl;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

  static const LinearGradient avatarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9), // Sky blue
      Color(0xFF3B82F6), // Ocean blue
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

  double _getResponsiveAvatarRadius(double width) {
    if (width < 480) return 40.0;
    if (width < 768) return 45.0;
    if (width < 1024) return 50.0;
    return 55.0;
  }

  double _getResponsiveButtonHeight(double width) {
    if (width < 480) return 32.0;
    if (width < 768) return 35.0;
    if (width < 1024) return 38.0;
    return 40.0;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchProfileImage();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(userType: widget.userType),
          ),
        );
        return;
      }

      // First check fisherman collection
      final fishermanDoc = await FirebaseFirestore.instance
          .collection('fisherman')
          .doc(user.uid)
          .get();

      if (fishermanDoc.exists) {
        setState(() {
          userData = fishermanDoc.data();
          userType = 'fisherman';
          isLoading = false;
        });
        return;
      }

      // Then check customer collection
      final customerDoc = await FirebaseFirestore.instance
          .collection('customer')
          .doc(user.uid)
          .get();

      if (customerDoc.exists) {
        setState(() {
          userData = customerDoc.data();
          userType = 'customer';
          isLoading = false;
        });
        return;
      }

      throw Exception('User data not found');
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('profile')
        .doc(user.uid)
        .collection('profile_pictures')
        .orderBy('uploadedAt', descending: true)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      setState(() {
        profileImageUrl = snap.docs.first['url'];
      });
    } else {
      setState(() {
        profileImageUrl = null;
      });
    }
  }

  Future<void> _pickAndUploadProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();

    XFile? pickedFile;
    File? file;

    // Show choice dialog
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pick from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
          ],
        ),
      ),
    );

    if (source == null) return;

    pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;
    if (!kIsWeb) file = File(pickedFile.path);

    // Upload to Cloudinary
    final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/dcrr2wlh8/image/upload');
    final request = http.MultipartRequest('POST', uploadUrl)
      ..fields['upload_preset'] = 'product_upload';

    if (kIsWeb) {
      final bytes = await pickedFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', file!.path));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = json.decode(resStr);
      final cloudinaryUrl = data['secure_url'];

      // Save metadata to Firestore (profile/{uid}/profile_pictures)
      await FirebaseFirestore.instance
          .collection('profile')
          .doc(user.uid)
          .collection('profile_pictures')
          .add({
        'url': cloudinaryUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        profileImageUrl = cloudinaryUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload image. Try again.')),
      );
    }
  }

  String _getFullName() {
    if (userData == null) return 'No name provided';
    final firstName = userData?['firstName'] ?? '';
    final middleName = userData?['middleName'] ?? '';
    final lastName = userData?['lastName'] ?? '';
    return '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();
  }

  Widget _buildLogoItem({required String image, required double logoSize, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(logoSize * 0.15),
        child: Image.asset(
          image,
          height: logoSize,
          width: logoSize * 1.4,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth < 480 ? 180.0 : 200.0;
    final logoSize = screenWidth < 480 ? 60.0 : 70.0;
    final spacing = screenWidth < 480 ? 20.0 : 30.0;
    final buttonHeight = _getResponsiveButtonHeight(screenWidth);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    
    return Drawer(
      width: drawerWidth,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoItem(
                  image: 'assets/images/citycatbalogan.png',
                  logoSize: logoSize,
                  onTap: () async {
                    Navigator.pop(context);
                    const url =
                        'https://www.facebook.com/CatbaloganPulis?mibextid=qi2Omg&rdid=bVIUFXyKihSa2wsN&share_url=https%3A%2F%2Fwww.facebook.com%2Fshare%2F1Nhzw2XvMq%2F%3Fmibextid%3Dqi2Omg#; ';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                SizedBox(height: spacing),
                _buildLogoItem(
                  image: 'assets/images/coastguard.png',
                  logoSize: logoSize,
                  onTap: () async {
                    Navigator.pop(context);
                    const url =
                        'https://www.facebook.com/profile.php?id=100064678504235';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                SizedBox(height: spacing),
                _buildLogoItem(
                  image: 'assets/images/map.png',
                  logoSize: logoSize,
                  onTap: () async {
                    Navigator.pop(context);
                    const url =
                        'https://www.google.com/maps/place/City+of+Catbalogan,+Samar/@11.8002446,124.8212436,11z/data=!3m1!4b1!4m6!3m5!1s0x330834d7864d55d7:0xcbc9fd0999445956!8m2!3d11.8568348!4d124.8844867!16s%2Fm%2F02p_dgf?entry=ttu&g_ep=EgoyMDI1MDYxMS4wIKXMDSoASAFQAw%3D%3D';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                SizedBox(height: spacing),
                _buildLogoItem(
                  image: 'assets/images/firestation.png',
                  logoSize: logoSize,
                  onTap: () async {
                    Navigator.pop(context);
                    const url =
                        'https://www.facebook.com/profile.php?id=100064703287688';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(_getResponsivePadding(screenWidth)),
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout, size: _getResponsiveIconSize(screenWidth), color: Colors.white),
              label: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: buttonFontSize,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(double.infinity, buttonHeight),
              ),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoHeight = screenWidth < 480 ? 32.0 : 40.0;
    final toolbarHeight = screenWidth < 480 ? 60.0 : 70.0;
    final user = FirebaseAuth.instance.currentUser;
    return AppBar(
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      elevation: 0,
      toolbarHeight: toolbarHeight,
      leading: IconButton(
        icon: Icon(Icons.menu, color: Color(0xFF1976D2), size: _getResponsiveIconSize(screenWidth)),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(userType: userType ?? widget.userType),
                ),
              );
            },
            child: Image.asset(
              'assets/images/logo1.jpg',
              height: logoHeight,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: Color(0xFF1976D2), size: _getResponsiveIconSize(screenWidth)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingScreen(userType: userType ?? widget.userType),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF1976D2), size: _getResponsiveIconSize(screenWidth)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddToCart(userType: userType ?? widget.userType),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: Color(0xFF1976D2), size: _getResponsiveIconSize(screenWidth)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationScreen(userType: userType ?? widget.userType),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline, color: Color(0xFF1976D2), size: _getResponsiveIconSize(screenWidth)),
            onPressed: () {}, // Already on profile
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final fontSize = _getResponsiveFontSize(screenWidth, baseSize: 16.0);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    final dialogWidth = (screenWidth < 480 ? screenWidth * 0.75 : screenWidth < 768 ? 320.0 : 380.0);
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.4,
              minHeight: 160,
            ),
            padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(screenWidth < 480 ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout,
                      size: screenWidth < 480 ? 24 : 32,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: screenWidth < 480 ? 12 : 16),
                  Text(
                    'Confirm Logout',
                    style: TextStyle(
                      fontSize: fontSize + 1,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenWidth < 480 ? 6 : 8),
                  Text(
                    'Are you sure you want to logout?',
                    style: TextStyle(
                      fontSize: fontSize - 2,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenWidth < 480 ? 20 : 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Container(
                          height: screenWidth < 480 ? 40 : 44,
                          margin: EdgeInsets.only(right: screenWidth < 480 ? 6 : 8),
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: buttonFontSize - 1,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: screenWidth < 480 ? 40 : 44,
                          margin: EdgeInsets.only(left: screenWidth < 480 ? 6 : 8),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: buttonFontSize - 1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
      },
    );
    if (shouldLogout != true) return;
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => SelectionScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _getResponsiveSpacing(screenWidth);
    final padding = _getResponsivePadding(screenWidth);
    final fontSize = _getResponsiveFontSize(screenWidth);
    final iconSize = _getResponsiveIconSize(screenWidth);
    final avatarRadius = _getResponsiveAvatarRadius(screenWidth);
    final cameraIconSize = screenWidth < 480 ? 16.0 : 20.0;
    final cameraRadius = screenWidth < 480 ? 15.0 : 18.0;
    
    if (isLoading) {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _buildDrawer(),
        body: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              // Custom AppBar with white background
              Container(
                decoration: const BoxDecoration(color: Colors.white),
                child: SafeArea(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.menu, color: Color(0xFF1976D2), size: iconSize),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HomePage(userType: widget.userType),
                              ),
                            );
                          },
                          child: Image.asset(
                            'assets/images/logo1.jpg',
                            height: 40,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.shopping_bag_outlined, color: Color(0xFF1976D2)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ShoppingScreen(userType: widget.userType),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF1976D2)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddToCart(userType: widget.userType),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.notifications_none, color: Color(0xFF1976D2)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    NotificationScreen(userType: widget.userType),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.person_outline, color: Color(0xFF1976D2)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfileScreen(userType: widget.userType),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: cardGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: oceanGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Loading profile...',
                          style: TextStyle(
                            fontSize: fontSize + 2,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
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

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          children: [
            // Custom AppBar with white background
            Container(
              decoration: const BoxDecoration(color: Colors.white),
              child: SafeArea(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.menu, color: Color(0xFF1976D2), size: iconSize),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HomePage(userType: widget.userType),
                            ),
                          );
                        },
                        child: Image.asset(
                          'assets/images/logo1.jpg',
                          height: 40,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.shopping_bag_outlined, color: Color(0xFF1976D2)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ShoppingScreen(userType: widget.userType),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF1976D2)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddToCart(userType: widget.userType),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.notifications_none, color: Color(0xFF1976D2)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationScreen(userType: widget.userType),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.person_outline, color: Color(0xFF1976D2)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(userType: widget.userType),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(gradient: oceanGradient),
                child: Column(
                  children: [
                    SizedBox(height: spacing * 0.8),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF667eea),
                                Color(0xFF764ba2),
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: avatarRadius,
                            backgroundColor: Colors.transparent,
                            backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                                ? NetworkImage(profileImageUrl!)
                                : const AssetImage('assets/images/woman.png') as ImageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadProfileImage,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFffffff),
                                    Color(0xFFf8f9ff),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: cameraRadius,
                                backgroundColor: Colors.transparent,
                                child: Icon(Icons.camera_alt, size: cameraIconSize, color: Colors.grey[700]),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: spacing * 0.8),
                    Text(
                      _getFullName(),
                      style: TextStyle(
                        fontSize: fontSize + 8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${userData?['email'] ?? 'No email'} | ${userData?['cpNumber'] ?? 'No cpNumber'}',
                      style: TextStyle(
                        fontSize: fontSize + 2,
                        color: Colors.blueGrey[700],
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: spacing * 1.5),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFffffff),
                              Color(0xFFf8f9ff),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit, size: iconSize - 4, color: Colors.white),
                              ),
                              title: Text(
                                'Edit profile information',
                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                              ),
                              onTap: () {
                                _navigateToEditProfile();
                              },
                            ),
                            if ((userType ?? widget.userType) == 'fisherman')
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF667eea),
                                        Color(0xFF764ba2),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.inventory_2, size: iconSize - 4, color: Colors.white),
                                ),
                                title: Text(
                                  'My Products',
                                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ProductScreen(),
                                    ),
                                  );
                                },
                              ),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.info, size: iconSize - 4, color: Colors.white),
                              ),
                              title: Text(
                                'Developer Details',
                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const DeveloperScreen()),
                                );
                              },
                            ),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.message, size: iconSize - 4, color: Colors.white),
                              ),
                              title: Text(
                                'Messages',
                                style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
                              ),
                              trailing: StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('messages')
                                    .where('participants', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const SizedBox.shrink();
                                  final chats = snapshot.data!.docs;
                                  final user = FirebaseAuth.instance.currentUser;
                                  if (user == null || chats.isEmpty) return const SizedBox.shrink();
                                  // Listen to all chats' subcollections as streams
                                  return StreamBuilder<List<QuerySnapshot>>(
                                    stream: CombineLatestStream.list(
                                      chats.map((chat) =>
                                        FirebaseFirestore.instance
                                          .collection('messages')
                                          .doc(chat.id)
                                          .collection('chats')
                                          .snapshots()
                                      ).toList(),
                                    ),
                                    builder: (context, chatSnaps) {
                                      if (!chatSnaps.hasData) return const SizedBox.shrink();
                                      int totalUnread = 0;
                                      for (final chatSnap in chatSnaps.data!) {
                                        for (final doc in chatSnap.docs) {
                                          final data = doc.data() as Map<String, dynamic>;
                                          final readBy = (data['readBy'] is List)
                                              ? List<String>.from(data['readBy'])
                                              : <String>[];
                                          if (!readBy.contains(user.uid)) totalUnread++;
                                        }
                                      }
                                      return totalUnread > 0
                                          ? Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                            gradient: const LinearGradient(
                                                              begin: Alignment.topLeft,
                                                              end: Alignment.bottomRight,
                                                              colors: [
                                                                Color(0xFF667eea),
                                                                Color(0xFF764ba2),
                                                              ],
                                                            ),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            '$totalUnread',
                                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                    },
                                  );
                                },
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MessagesScreen(userType: userType ?? widget.userType),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          userData: userData!,
          userType: userType ?? widget.userType,
        ),
      ),
    ).then((_) {
      _fetchUserData();
      _fetchProfileImage();
    });
  }
}

class EditProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userType;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cpNumberController = TextEditingController();

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

  EditProfileScreen({
    super.key,
    required this.userData,
    required this.userType,
  }) {
    _firstNameController.text = userData['firstName'] ?? '';
    _middleNameController.text = userData['middleName'] ?? '';
    _lastNameController.text = userData['lastName'] ?? '';
    _cpNumberController.text = userData['cpNumber'] ?? '';
    _addressController.text = userData['address'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _getResponsiveSpacing(screenWidth);
    final padding = _getResponsivePadding(screenWidth);
    final fontSize = _getResponsiveFontSize(screenWidth);
    final iconSize = _getResponsiveIconSize(screenWidth);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A4A6C),
        foregroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(fontSize: fontSize + 2, color: Colors.white),
        ),
        toolbarHeight: screenWidth < 480 ? 60.0 : 70.0,
        actions: [
          IconButton(
            icon: Icon(Icons.save, size: iconSize, color: Colors.white),
            onPressed: () {
              _saveProfileChanges(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            SizedBox(height: spacing * 1.5),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: fontSize - 2),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: padding * 0.8),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
            SizedBox(height: spacing * 1.5),
            TextFormField(
              controller: _middleNameController,
              decoration: InputDecoration(
                labelText: 'Middle Name',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: fontSize - 2),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: padding * 0.8),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
            SizedBox(height: spacing * 1.5),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: fontSize - 2),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: padding * 0.8),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
            SizedBox(height: spacing * 1.5),
            TextFormField(
              controller: _cpNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: fontSize - 2),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: padding * 0.8),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
            SizedBox(height: spacing * 1.5),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: TextStyle(color: Colors.grey[600], fontSize: fontSize - 2),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                    horizontal: padding, vertical: padding * 0.8),
              ),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfileChanges(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final collection = userType == 'fisherman' ? 'fisherman' : 'customer';

      await FirebaseFirestore.instance
          .collection(collection)
          .doc(user.uid)
          .update({
        'firstName': _firstNameController.text,
        'middleName': _middleNameController.text,
        'lastName': _lastNameController.text,
        'cpNumber': _cpNumberController.text,
        'address': _addressController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: ${e.toString()}')),
      );
    }
  }
}