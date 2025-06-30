import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'product.dart';
import 'developer.dart';
import 'chat_screen.dart';
import 'homed.dart';

class VendorProfileScreen extends StatefulWidget {
  final String fishermanId;
  final String? fishermanName;
  final String? profileImageUrl;

  const VendorProfileScreen({
    super.key,
    required this.fishermanId,
    this.fishermanName,
    this.profileImageUrl,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  Map<String, dynamic>? fishermanData;
  bool isLoading = true;
  String? profileImageUrl;

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

  @override
  void initState() {
    super.initState();
    _fetchFishermanData();
    _fetchProfileImage();
  }

  Future<void> _fetchFishermanData() async {
    try {
      final fishermanDoc = await FirebaseFirestore.instance
          .collection('fisherman')
          .doc(widget.fishermanId)
          .get();

      if (fishermanDoc.exists) {
        setState(() {
          fishermanData = fishermanDoc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fisherman data not found')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching fisherman data: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchProfileImage() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profile')
          .doc(widget.fishermanId)
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
          profileImageUrl = widget.profileImageUrl;
        });
      }
    } catch (e) {
      setState(() {
        profileImageUrl = widget.profileImageUrl;
      });
    }
  }

  String _getFullName() {
    if (fishermanData == null) return widget.fishermanName ?? 'No name provided';
    final firstName = fishermanData?['firstName'] ?? '';
    final middleName = fishermanData?['middleName'] ?? '';
    final lastName = fishermanData?['lastName'] ?? '';
    return '$firstName ${middleName.isNotEmpty ? '$middleName ' : ''}$lastName'.trim();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          flexibleSpace: null,
          iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
          title: const Text('Loading...', 
          style: TextStyle(color: Color(0xFF1976D2))),
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: oceanGradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        flexibleSpace: null,
        iconTheme: const IconThemeData(color: Color(0xFF1976D2)),
        title: Text(_getFullName(), 
        style: const TextStyle(color: Color(0xFF1976D2))),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: oceanGradient,
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: cardGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.transparent,
                backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                    ? NetworkImage(profileImageUrl!)
                    : null,
                child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getFullName(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              '${fishermanData?['email'] ?? 'No email'} | ${fishermanData?['cpNumber'] ?? 'No contact number'}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: cardGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.inventory_2, color: Color(0xFF764ba2)),
                    title: const Text('My Products', style: TextStyle(color: Color(0xFF333366))),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductScreen(
                            fishermanId: widget.fishermanId,
                            forVendor: true,
                            fishermanName: _getFullName(),
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.message, color: Color(0xFF764ba2)),
                    title: const Text('Message', style: TextStyle(color: Color(0xFF333366))),
                    onTap: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please sign in to send messages')),
                        );
                        return;
                      }

                      try {
                        // Create chat participants array and sort them
                        final participants = [currentUser.uid, widget.fishermanId]..sort();
                        final chatId = participants.join('_');

                        print('Creating chat with ID: $chatId');
                        print('Participants: $participants');
                        print('Current user: ${currentUser.uid}');
                        print('Fisherman ID: ${widget.fishermanId}');

                        // Check if chat already exists
                        final chatDoc = await FirebaseFirestore.instance
                            .collection('messages')
                            .doc(chatId)
                            .get();

                        if (!chatDoc.exists) {
                          print('Creating new chat document...');
                          // Create new chat document
                          await FirebaseFirestore.instance
                              .collection('messages')
                              .doc(chatId)
                              .set({
                            'participants': participants,
                            'lastMessage': 'Chat started',
                            'lastMessageTime': FieldValue.serverTimestamp(),
                          });
                          print('Chat document created successfully');
                        } else {
                          print('Chat document already exists');
                        }

                        // Navigate to chat screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatId,
                              otherUserId: widget.fishermanId,
                              userType: 'customer', // Assuming this is accessed by customers
                              otherUserName: _getFullName(),
                              otherUserAvatar: profileImageUrl,
                              fromVendorProfile: true, // Indicate this is from vendor profile
                            ),
                          ),
                        );
                      } catch (e) {
                        print('Error creating chat: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating chat: ${e.toString()}')),
                        );
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info, color: Color(0xFF764ba2)),
                    title: const Text('Developer Details', style: TextStyle(color: Color(0xFF333366))),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DeveloperScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}