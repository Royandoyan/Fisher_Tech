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

  const ProfileScreen({Key? key, required this.userType}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? userType;
  String? profileImageUrl;

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
        SnackBar(content: Text('Failed to upload image. Try again.')),
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
              const Text('Failed to load profile data'),
              ElevatedButton(
                onPressed: _fetchUserData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userType: userType ?? widget.userType),
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
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
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.camera_alt, size: 20, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _getFullName(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${userData?['email'] ?? 'No email'} | ${userData?['cpNumber'] ?? 'No cpNumber'}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Edit profile information'),
                    onTap: () {
                      _navigateToEditProfile();
                    },
                  ),
                  if ((userType ?? widget.userType) == 'fisherman')
                    ListTile(
                      leading: const Icon(Icons.inventory_2),
                      title: const Text('My Products'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductScreen(),
                          ),
                        );
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Developer Details'),
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

  EditProfileScreen({
    Key? key,
    required this.userData,
    required this.userType,
  }) : super(key: key) {
    _firstNameController.text = userData['firstName'] ?? '';
    _middleNameController.text = userData['middleName'] ?? '';
    _lastNameController.text = userData['lastName'] ?? '';
    _cpNumberController.text = userData['cpNumber'] ?? '';
    _addressController.text = userData['address'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              _saveProfileChanges(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name',
                labelStyle: TextStyle(color: Colors.grey[600]),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _middleNameController,
              decoration: InputDecoration(
                labelText: 'Middle Name',
                labelStyle: TextStyle(color: Colors.grey[600]),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name',
                labelStyle: TextStyle(color: Colors.grey[600]),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _cpNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Contact Number',
                labelStyle: TextStyle(color: Colors.grey[600]),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: TextStyle(color: Colors.grey[600]),
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
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(fontSize: 16),
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