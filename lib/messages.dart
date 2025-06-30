import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatelessWidget {
  final String userType;
  const MessagesScreen({super.key, required this.userType});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
                Color(0xFFf093fb),
              ],
            ),
          ),
          child: const Center(
            child: Text(
              'Please sign in to view messages.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      );
    }
    print('[MessagesScreen] Current user UID: \\${user.uid}');
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 480 ? 14.0 : 16.0;

    // Ocean/Fisherman themed gradients
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

    const LinearGradient cardGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFffffff), // Pure white
        Color(0xFFf8f9fa), // Light gray
      ],
    );

    const LinearGradient buttonGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF1E40AF), // Deep blue
        Color(0xFF3B82F6), // Ocean blue
      ],
    );

    const LinearGradient accentGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F766E), // Teal
        Color(0xFF14B8A6), // Sea green
      ],
    );

    const LinearGradient messageGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFffffff), // Pure white
        Color(0xFFf8f9fa), // Light gray
      ],
    );

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Messages',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFf8f9ff),
                      Color(0xFFffffff),
                    ],
                  ),
                ),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('participants', arrayContains: user.uid)
                      //.orderBy('lastMessageTime', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    print('[MessagesScreen] Query snapshot hasData: \\${snapshot.hasData}, docs: \\${snapshot.data?.docs.length}');
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('[MessagesScreen] No chat documents found for user: \\${user.uid}');
                      return Center(
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
                                child: Icon(Icons.mark_chat_unread, size: 60, color: Colors.white),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'No messages yet.',
                                style: TextStyle(
                                  fontSize: fontSize + 2,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a conversation by placing an order or replying to a chat.',
                                style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final chats = snapshot.data!.docs;
                    print('[MessagesScreen] Chat document IDs: \\${chats.map((c) => c.id).toList()}');
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: screenWidth < 480 ? 8 : 24),
                      itemCount: chats.length,
                      separatorBuilder: (context, i) => SizedBox(height: screenWidth < 480 ? 8 : 14),
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final data = chat.data() as Map<String, dynamic>;
                        final participants = List<String>.from(data['participants'] ?? []);
                        print('[MessagesScreen] Chat doc: \\${chat.id}, participants: \\${participants}');
                        final otherUserId = participants.firstWhere((id) => id != user.uid, orElse: () => '');
                        final lastMessage = data['lastMessage'] ?? '';
                        final lastMessageTime = data['lastMessageTime'] != null
                            ? (data['lastMessageTime'] as Timestamp).toDate()
                            : null;
                        // Fetch other user's info for avatar and name
                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('profile').doc(otherUserId).get(),
                          builder: (context, userSnap) {
                            String displayName = 'User';
                            String? avatarUrl;
                            // Determine which collection to use for the other user's name
                            final userTypeCollection = userType == 'fisherman' ? 'customer' : 'fisherman';
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection(userTypeCollection).doc(otherUserId).get(),
                              builder: (context, nameSnap) {
                                if (nameSnap.hasData && nameSnap.data!.exists) {
                                  final data = nameSnap.data!.data() as Map<String, dynamic>?;
                                  displayName = ((data?['firstName'] ?? '') + ' ' + (data?['lastName'] ?? '')).trim();
                                }
                                return FutureBuilder<QuerySnapshot>(
                                  future: FirebaseFirestore.instance
                                    .collection('profile')
                                    .doc(otherUserId)
                                    .collection('profile_pictures')
                                    .orderBy('uploadedAt', descending: true)
                                    .limit(1)
                                    .get(),
                                  builder: (context, picSnap) {
                                    if (picSnap.hasData && picSnap.data!.docs.isNotEmpty) {
                                      avatarUrl = picSnap.data!.docs.first['url'] as String?;
                                    }
                                    return StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                        .collection('messages')
                                        .doc(chat.id)
                                        .collection('chats')
                                        .snapshots(),
                                      builder: (context, chatSnap) {
                                        int unreadCount = 0;
                                        if (chatSnap.hasData) {
                                          final docs = chatSnap.data!.docs;
                                          for (final doc in docs) {
                                            final data = doc.data() as Map<String, dynamic>;
                                            final readBy = (data['readBy'] is List)
                                                ? List<String>.from(data['readBy'])
                                                : <String>[];
                                            if (!readBy.contains(user.uid)) unreadCount++;
                                          }
                                        }
                                        final isUnread = unreadCount > 0;
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(16),
                                            onTap: () async {
                                              // Mark all messages as read immediately on tap
                                              final chatRef = FirebaseFirestore.instance
                                                  .collection('messages')
                                                  .doc(chat.id)
                                                  .collection('chats');
                                              final unread = await chatRef.where('readBy', whereNotIn: [[user.uid]]).get();
                                              for (final doc in unread.docs) {
                                                final data = doc.data() as Map<String, dynamic>;
                                                final readBy = (data['readBy'] is List)
                                                    ? List<String>.from(data['readBy'])
                                                    : <String>[];
                                                if (!readBy.contains(user.uid)) {
                                                  await doc.reference.update({'readBy': FieldValue.arrayUnion([user.uid])});
                                                }
                                              }
                                              // Navigate to chat screen
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ChatScreen(
                                                    chatId: chat.id,
                                                    otherUserId: otherUserId,
                                                    userType: userType,
                                                    otherUserName: displayName.trim(),
                                                    otherUserAvatar: avatarUrl,
                                                    fromVendorProfile: false,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: isUnread ? messageGradient : cardGradient,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(isUnread ? 0.08 : 0.05),
                                                    blurRadius: isUnread ? 12 : 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: isUnread ? Colors.blue.shade200 : Colors.grey.shade200,
                                                  width: 1.2,
                                                ),
                                              ),
                                              padding: EdgeInsets.symmetric(vertical: screenWidth < 480 ? 10 : 16, horizontal: screenWidth < 480 ? 10 : 18),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      gradient: oceanGradient,
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
                                                      radius: screenWidth < 480 ? 22 : 28,
                                                      backgroundColor: Colors.transparent,
                                                      backgroundImage: (avatarUrl != null && avatarUrl?.isNotEmpty == true)
                                                          ? NetworkImage(avatarUrl ?? '')
                                                          : null,
                                                      child: (avatarUrl == null || avatarUrl?.isEmpty == true)
                                                          ? Text(
                                                              displayName.isNotEmpty ? displayName[0] : '?',
                                                              style: TextStyle(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: screenWidth < 480 ? 18 : 22,
                                                              ),
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          displayName.trim().isEmpty ? 'User' : displayName.trim(),
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: fontSize + 2,
                                                            color: Colors.black87,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          lastMessage,
                                                          style: TextStyle(
                                                            fontSize: fontSize - 2,
                                                            color: Colors.grey[700],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      if (lastMessageTime != null)
                                                        Text(
                                                          '${lastMessageTime.hour.toString().padLeft(2, '0')}:${lastMessageTime.minute.toString().padLeft(2, '0')}',
                                                          style: TextStyle(fontSize: fontSize - 4, color: Colors.grey[500]),
                                                        ),
                                                      if (unreadCount > 0)
                                                        Container(
                                                          margin: const EdgeInsets.only(top: 6),
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            gradient: accentGradient,
                                                            borderRadius: BorderRadius.circular(14),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: Colors.black.withOpacity(0.2),
                                                                blurRadius: 6,
                                                                offset: const Offset(0, 3),
                                                              ),
                                                            ],
                                                          ),
                                                          child: Text(
                                                            '$unreadCount',
                                                            style: const TextStyle(
                                                              color: Colors.white,
                                                              fontSize: 13,
                                                              fontWeight: FontWeight.bold,
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
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 