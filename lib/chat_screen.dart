import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homed.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String userType;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool fromVendorProfile;
  const ChatScreen({super.key, required this.chatId, required this.otherUserId, required this.userType, required this.otherUserName, this.otherUserAvatar, this.fromVendorProfile = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
      Color(0xFFffffff), // Pure white
      Color(0xFFf8f9fa), // Light gray
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
      Color(0xFFe3f2fd), // Light blue
      Color(0xFFf3e5f5), // Light purple
    ],
  );

  static const LinearGradient messageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFffffff), // Pure white
      Color(0xFFf8f9fa), // Light gray
    ],
  );

  @override
  void initState() {
    super.initState();
    _markAllMessagesAsRead();
  }

  void _markAllMessagesAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final chatRef = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .collection('chats');
    final allMessages = await chatRef.get();
    for (final doc in allMessages.docs) {
      final data = doc.data();
      final readBy = (data['readBy'] is List)
          ? List<String>.from(data['readBy'])
          : <String>[];
      if (!readBy.contains(user.uid)) {
        print('[MarkAsRead] Updating message ${doc.id} to add ${user.uid}');
        await doc.reference.update({'readBy': FieldValue.arrayUnion([user.uid])});
      } else {
        print('[MarkAsRead] Message ${doc.id} already read by ${user.uid}');
      }
    }
  }

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _controller.text.trim().isEmpty) return;
    final message = _controller.text.trim();
    _controller.clear();
    final now = DateTime.now();
    final messageData = {
      'senderId': user.uid,
      'receiverId': widget.otherUserId,
      'text': message,
      'timestamp': now,
      'readBy': [user.uid],
    };
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .collection('chats')
        .add(messageData);
    // Update last message for chat list
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .set({
      'participants': [user.uid, widget.otherUserId],
      'lastMessage': message,
      'lastMessageTime': now,
    }, SetOptions(merge: true));
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth < 480 ? 14.0 : 16.0;
    // Determine which collection to use for the other user
    final otherUserCollection = widget.userType == 'fisherman' ? 'customer' : 'fisherman';
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          if (widget.fromVendorProfile) {
                            // Navigate back to home screen when accessed from vendor profile
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => HomePage(userType: widget.userType),
                              ),
                              (route) => false,
                            );
                          } else {
                            // Normal back navigation when accessed from messages screen
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('profile').doc(widget.otherUserId).snapshots(),
          builder: (context, snapshot) {
            String displayName = widget.otherUserName;
            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              displayName = ((data?['firstName'] ?? '') + ' ' + (data?['lastName'] ?? '')).trim();
            }
            return FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                .collection('profile')
                .doc(widget.otherUserId)
                .collection('profile_pictures')
                .orderBy('uploadedAt', descending: true)
                .limit(1)
                .get(),
              builder: (context, picSnap) {
                String? avatarUrl = widget.otherUserAvatar;
                if (picSnap.hasData && picSnap.data!.docs.isNotEmpty) {
                  avatarUrl = picSnap.data!.docs.first['url'] as String?;
                }
                              return Expanded(
                                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: (avatarUrl == null || avatarUrl.isEmpty)
                          ? Text(
                              (displayName.isNotEmpty ? displayName[0] : '?'),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        displayName.isEmpty ? 'Chat' : displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                                ),
                );
              },
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
                  .doc(widget.chatId)
                  .collection('chats')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == user?.uid;
                    final time = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : null;
                    final imageUrl = data['imageUrl'] as String?;
                    return Row(
                      mainAxisAlignment:
                          isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe)
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0, bottom: 2),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.blue[100],
                              backgroundImage: (widget.otherUserAvatar != null && widget.otherUserAvatar!.isNotEmpty)
                                  ? NetworkImage(widget.otherUserAvatar!)
                                  : null,
                              child: (widget.otherUserAvatar == null || widget.otherUserAvatar!.isEmpty)
                                  ? Text(
                                      (widget.otherUserName.isNotEmpty ? widget.otherUserName[0] : '?'),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                    )
                                  : null,
                            ),
                          ),
                        Flexible(
                          child: Container(
                            margin: EdgeInsets.only(
                              top: 4,
                              bottom: 4,
                              left: isMe ? 40 : 0,
                              right: isMe ? 0 : 40,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                                  gradient: isMe ? messageGradient : accentGradient,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                              boxShadow: [
                                BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null && imageUrl.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        width: 120,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          width: 120,
                                          height: 90,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                  ),
                                Text(
                                  data['text'] ?? '',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: fontSize,
                                  ),
                                ),
                                if (time != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: fontSize - 4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (isMe)
                          const SizedBox(width: 32),
                      ],
                    );
                  },
                );
              },
                ),
            ),
          ),
          Container(
              decoration: const BoxDecoration(
                gradient: accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              top: 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: accentGradient,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: buttonGradient,
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
                      backgroundColor: Colors.transparent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                      ),
                  ),
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