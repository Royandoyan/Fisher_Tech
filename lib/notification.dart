import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'shopping.dart';
import 'profile.dart';
import 'addtocart.dart';
import 'homed.dart';
import 'selection_screen.dart';

class NotificationScreen extends StatefulWidget {
  final String userType;

  const NotificationScreen({Key? key, required this.userType})
      : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _builtInFishermanNotifShown = false;

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);
    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _formatNotificationMessage(String originalMessage) {
    if (originalMessage.contains('Your Order #') &&
        originalMessage.contains('has been placed successfully!')) {
      return 'Your Order has been placed successfully';
    }
    if (originalMessage.contains('Your order has been placed successfully!')) {
      return 'Your Order has been placed successfully';
    }
    if (originalMessage.contains('New order #') &&
        originalMessage.contains('received for')) {
      return 'You received a new order';
    }
    if (originalMessage == 'Your product has been ordered!') {
      return 'Your product has been ordered!';
    }
    if (originalMessage.contains('has been confirmed by the seller')) {
      return 'Order confirmed by seller';
    }
    if (originalMessage.contains('has been shipped')) {
      return 'Order shipped';
    }
    if (originalMessage.contains('has been delivered')) {
      return 'Order delivered';
    }
    if (originalMessage.contains('has been cancelled')) {
      return 'Order cancelled';
    }
    return originalMessage;
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  // Built-in notification for fisherman
  Future<void> _addBuiltInFishermanNotification(User user) async {
    // Only insert if not already done in this session
    if (_builtInFishermanNotifShown) return;
    _builtInFishermanNotifShown = true;

    // Check if this notification already exists (avoid duplicates)
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'builtin_product_order')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'type': 'builtin_product_order',
        'message': 'Your product has been ordered!',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SelectionScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 200,
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogoItem(
                  image: 'assets/images/citycatbalogan.png',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/coastguard.png',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/map.png',
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/firestation.png',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout, size: 28, color: Colors.white),
              label:
                  const Text('Logout', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoItem({required String image, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          image,
          height: 70,
          width: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return _buildUnauthenticatedView(context);

    // Built-in notification for fisherman type users
    if (widget.userType.toLowerCase() == 'fisherman' ||
        widget.userType.toLowerCase().contains('fisherman')) {
      _addBuiltInFishermanNotification(user);
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            HomePage(userType: widget.userType),
                      ));
                },
                child: Image.asset('assets/images/logo.png', height: 40),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.shopping_bag_outlined,
                    color: Colors.black),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ShoppingScreen(userType: widget.userType))),
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined,
                    color: Colors.black),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AddToCart(userType: widget.userType))),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.black),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ProfileScreen(userType: widget.userType))),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final notifications = snapshot.data!.docs;
          if (notifications.isEmpty)
            return const Center(child: Text('No notifications.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final message =
                  _formatNotificationMessage(data['message'] ?? 'Notification');
              final timestamp = data['createdAt'] as Timestamp?;
              final timeText = timestamp != null
                  ? _formatTimestamp(timestamp)
                  : 'Recently';
              final isRead = data['isRead'] ?? false;

              return GestureDetector(
                onTap: () {
                  if (!isRead) {
                    _markAsRead(doc.id);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRead ? Colors.white : const Color(0xFFD4E8F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isRead ? Colors.grey : const Color(0xFF1A3D7C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight:
                                    isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomePage(userType: widget.userType),
                    ));
              },
              child: Image.asset(
                'assets/images/logo.png',
                height: 40,
              ),
            ),
            const Spacer(),
            IconButton(
              icon:
                  const Icon(Icons.shopping_bag_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ShoppingScreen(userType: widget.userType),
                    ));
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.shopping_cart_outlined, color: Colors.black),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AddToCart(userType: widget.userType),
                    ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.black),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfileScreen(userType: widget.userType),
                    ));
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Please sign in to view notifications'),
      ),
    );
  }
}