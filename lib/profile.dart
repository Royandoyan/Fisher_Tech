import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'developer.dart';
import 'homed.dart';
import 'product.dart';

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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load profile data',
                style: TextStyle(fontSize: fontSize),
              ),
              SizedBox(height: spacing),
              ElevatedButton(
                onPressed: _fetchUserData,
                child: Text('Retry', style: TextStyle(fontSize: fontSize - 2)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A4A6C),
        foregroundColor: Colors.white,
        title: Text(
          'Profile',
          style: TextStyle(fontSize: fontSize + 6, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userType: userType ?? widget.userType),
              ),
            );
          },
        ),
        elevation: 0,
        toolbarHeight: screenWidth < 480 ? 60.0 : 70.0,
      ),
      body: Column(
        children: [
          SizedBox(height: spacing * 0.8),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.grey,
                backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    ? NetworkImage(profileImageUrl!)
                    : const AssetImage('assets/images/woman.png') as ImageProvider,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadProfileImage,
                  child: CircleAvatar(
                    radius: cameraRadius,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, size: cameraIconSize, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing * 0.8),
          Text(
            _getFullName(),
            style: TextStyle(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '${userData?['email'] ?? 'No email'} | ${userData?['cpNumber'] ?? 'No cpNumber'}',
            style: TextStyle(
              fontSize: fontSize - 2,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing * 1.5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.edit, size: iconSize),
                    title: Text(
                      'Edit profile information',
                      style: TextStyle(fontSize: fontSize),
                    ),
                    onTap: () {
                      _navigateToEditProfile();
                    },
                  ),
                  if ((userType ?? widget.userType) == 'fisherman')
                    ListTile(
                      leading: Icon(Icons.inventory_2, size: iconSize),
                      title: Text(
                        'My Products',
                        style: TextStyle(fontSize: fontSize),
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
                    leading: Icon(Icons.info, size: iconSize),
                    title: Text(
                      'Developer Details',
                      style: TextStyle(fontSize: fontSize),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DeveloperScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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