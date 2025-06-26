import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'shopping.dart';
import 'profile.dart';
import 'addtocart.dart';
import 'homed.dart';
import 'selection_screen.dart';
import 'package:rxdart/rxdart.dart';

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

  double _getResponsiveButtonHeight(double width) {
    if (width < 480) return 32.0;
    if (width < 768) return 35.0;
    if (width < 1024) return 38.0;
    return 40.0;
  }

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

  Future<void> _addFishermanNotificationIfNeeded() async {
    // Only trigger for fisherman userType
    if (widget.userType == 'fisherman') {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Query if notification already exists to avoid duplicates
      final existing = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'product_ordered_builtin')
          .get();

      if (existing.docs.isEmpty) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': user.uid,
          'type': 'product_ordered_builtin',
          'message': 'Your product has been Ordered',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });
      }
    }
  }

  String _formatNotificationMessage(String originalMessage) {
    if (originalMessage.contains('Your Order #') &&
        originalMessage.contains('has been placed successfully!')) {
      return 'Your Order has been placed successfully';
    }
    return originalMessage;
  }

  Future<void> _signOut() async {
    // Show confirmation dialog
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
                  // Icon
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
                  
                  // Title
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
                  
                  // Message
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
                  
                  // Buttons
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
                    // Example: Open city website
                    const url =
                        'https://www.facebook.com/CatbaloganPulis?mibextid=qi2Omg&rdid=bVIUFXyKihSa2wsN&share_url=https%3A%2F%2Fwww.facebook.com%2Fshare%2F1Nhzw2XvMq%2F%3Fmibextid%3Dqi2Omg#; '; // update as needed
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
                    // Example: Open Facebook page
                    const url =
                        'https://www.facebook.com/profile.php?id=100064678504235'; // update as needed
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
                    // Example: Open Google Maps
                    const url =
                        'https://www.google.com/maps/place/City+of+Catbalogan,+Samar/@11.8002446,124.8212436,11z/data=!3m1!4b1!4m6!3m5!1s0x330834d7864d55d7:0xcbc9fd0999445956!8m2!3d11.8568348!4d124.8844867!16s%2Fm%2F02p_dgf?entry=ttu&g_ep=EgoyMDI1MDYxMS4wIKXMDSoASAFQAw%3D%3D'; // update as needed
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
                    // Example: Open Fire Station FB or info
                    const url =
                        'https://www.facebook.com/profile.php?id=100064703287688'; // update as needed
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

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) return _buildUnauthenticatedView(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(context, user),
      body: _buildNotificationBody(user),
    );
  }

  Widget _buildNotificationBody(User user) {
    // For fisherman, listen to both collections
    if (widget.userType == 'fisherman') {
      return StreamBuilder<List<QuerySnapshot>>(
        stream: CombineLatestStream.list([
          _firestore
              .collection('notifications')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          _firestore
              .collection('sellers_notification')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = [
            ...snapshot.data![0].docs,
            ...snapshot.data![1].docs,
          ];
          // Sort by creation time, newest first
          notifications.sort((a, b) {
            final aCreated = a['createdAt'] as Timestamp?;
            final bCreated = b['createdAt'] as Timestamp?;
            if (aCreated == null && bCreated == null) return 0;
            if (aCreated == null) return 1;
            if (bCreated == null) return -1;
            return bCreated.compareTo(aCreated);
          });
          
          // Mark all notifications as read when screen is opened
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markNotificationsAsRead(notifications);
          });
          
          return _buildNotificationLayout(context, notifications);
        },
      );
    } else {
      // For customer, just use notifications
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('notifications')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!.docs;
          // Sort by creation time, newest first
          notifications.sort((a, b) {
            final aCreated = a['createdAt'] as Timestamp?;
            final bCreated = b['createdAt'] as Timestamp?;
            if (aCreated == null && bCreated == null) return 0;
            if (aCreated == null) return 1;
            if (bCreated == null) return -1;
            return bCreated.compareTo(aCreated);
          });
          
          // Mark all notifications as read when screen is opened
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _markNotificationsAsRead(notifications);
          });
          
          return _buildNotificationLayout(context, notifications);
        },
      );
    }
  }

  Widget _buildNotificationLayout(BuildContext context, List notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'ll see your notifications here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final doc = notifications[index];
          final data = doc.data() as Map<String, dynamic>;
          final message = _formatNotificationMessage(data['message'] ?? 'Notification');
          final timestamp = data['createdAt'] as Timestamp?;
          final timeText = timestamp != null
              ? _formatTimestamp(timestamp)
              : 'Recently';

          final type = data['type'] ?? '';
          final orderId = data['orderId'];
          final sellerId = data['sellerId'];
          final userId = data['userId'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  print('🔔 Notification tapped - Type: $type, OrderId: $orderId');
                  print('🔔 Current user: ${_auth.currentUser?.uid}');
                  print('🔔 Seller ID: $sellerId, User ID: $userId');
                  
                  // Mark this notification as read
                  await _markNotificationAsRead(doc);
                  
                  if ((type == 'order_placed' ||
                          type == 'new_order' ||
                          type == 'order_cancelled' ||
                          type == 'order_accepted' ||
                          type == 'order_ready') &&
                      orderId != null &&
                      orderId != "") {
                    
                    // For seller notifications (new_order)
                    if (type == 'new_order' &&
                        sellerId == _auth.currentUser?.uid) {
                      print('🔔 Seller notification clicked - showing order action dialog');
                      // Check if this notification has buyer information (from sellers_notification)
                      if (data.containsKey('buyerFirstName')) {
                        _showSellerOrderActionDialog(context, orderId, data);
                      } else {
                        _showOrderActionDialog(context, orderId, userId, sellerId);
                      }
                    } 
                    // For buyer notifications (order_placed, order_accepted, order_cancelled, order_ready)
                    else if (type == 'order_placed' && userId == _auth.currentUser?.uid) {
                      print('🔔 Buyer order_placed notification clicked - showing order details');
                      _showOrderDetailsDialog(context, orderId, buyerId: userId);
                    }
                    else if (type == 'order_accepted' && userId == _auth.currentUser?.uid) {
                      print('🔔 Buyer order_accepted notification clicked - showing order details');
                      _showOrderDetailsDialog(context, orderId, buyerId: userId);
                    }
                    else if (type == 'order_cancelled' && userId == _auth.currentUser?.uid) {
                      print('🔔 Buyer order_cancelled notification clicked - showing order details');
                      _showOrderDetailsDialog(context, orderId, buyerId: userId);
                    }
                    else if (type == 'order_ready' && userId == _auth.currentUser?.uid) {
                      print('🔔 Buyer order_ready notification clicked - showing order details');
                      _showOrderDetailsDialog(context, orderId, buyerId: userId);
                    }
                    // For seller mark ready functionality
                    else if (type == 'order_accepted' &&
                        userId == _auth.currentUser?.uid &&
                        sellerId != _auth.currentUser?.uid) {
                      print('🔔 Seller mark ready notification clicked');
                      _showMarkReadyDialog(context, orderId, userId, sellerId);
                    } 
                    // Default case
                    else {
                      print('🔔 Default notification clicked - showing order details');
                      _showOrderDetailsDialog(context, orderId);
                    }
                  } else {
                    print('🔔 Notification not clickable - Type: $type, OrderId: $orderId');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3D7C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  timeText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _updateOrderStatus({
    required String buyerId,
    required String orderId,
    required String newStatus,
    required String sellerId,
    required BuildContext context,
  }) async {
    try {
      final orderDoc = await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!mounted) return;

      if (!orderDoc.exists) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Order not found.')),
        );
        return;
      }

      final orderData = orderDoc.data() as Map<String, dynamic>? ?? {};
      if (orderData['sellerId'] != sellerId) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          const SnackBar(
              content: Text(
                  'Permission denied: you are not the seller of this order.')),
        );
        return;
      }

      await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }

  void _showSellerOrderActionDialog(BuildContext context, String orderId, Map<String, dynamic> notificationData) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = _getResponsiveButtonHeight(screenWidth);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    final dialogWidth = screenWidth < 480 ? screenWidth * 0.9 : screenWidth < 768 ? 400.0 : 500.0;
    
    final buyerFirstName = notificationData['buyerFirstName'] ?? '';
    final buyerMiddleName = notificationData['buyerMiddleName'] ?? '';
    final buyerLastName = notificationData['buyerLastName'] ?? '';
    final buyerAddress = notificationData['buyerAddress'] ?? '';
    final buyerMunicipality = notificationData['buyerMunicipality'] ?? '';
    final buyerProvince = notificationData['buyerProvince'] ?? '';
    final productName = notificationData['productName'] ?? '';
    final productImage = notificationData['productImage'] ?? '';
    final quantity = notificationData['quantity'] ?? 1;
    final totalAmount = notificationData['totalAmount'] ?? 0.0;
    final buyerId = notificationData['buyerId'] ?? '';
    final sellerId = notificationData['sellerId'] ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3D7C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: screenWidth < 480 ? 20 : 24,
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Text(
                        'New Order Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (productImage.isNotEmpty)
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                productImage,
                                width: screenWidth < 480 ? 100 : 120,
                                height: screenWidth < 480 ? 80 : 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: screenWidth < 480 ? 12 : 16),
                      _orderDetailRow('Product Name', productName),
                      _orderDetailRow('Total Amount', '₱${totalAmount.toStringAsFixed(2)}'),
                      _orderDetailRow('Quantity', quantity.toString()),
                      _orderDetailRow('Buyer Name', '$buyerFirstName $buyerMiddleName $buyerLastName'),
                      _orderDetailRow('Contact Number', notificationData['buyerCpNumber'] ?? notificationData['cpNumber'] ?? ''),
                      _orderDetailRow('Buyer Address', buyerAddress),
                      _orderDetailRow('Buyer Municipality', buyerMunicipality),
                      _orderDetailRow('Buyer Province', buyerProvince),
                      _orderDetailRow('Order Date', notificationData['createdAt'] != null && 
                          notificationData['createdAt'] is Timestamp
                          ? DateFormat('MMM d, y – hh:mm a')
                              .format((notificationData['createdAt'] as Timestamp).toDate())
                          : ''),
                    ],
                  ),
                ),
              ),
              
              // Buttons
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _acceptOrder(context, orderId, buyerId, sellerId, productName);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await _cancelOrder(context, orderId, buyerId, sellerId, productName);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderActionDialog(BuildContext context, String orderId,
      String? buyerId, String? sellerId) async {
    if (buyerId == null || sellerId == null) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = _getResponsiveButtonHeight(screenWidth);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    final dialogWidth = screenWidth < 480 ? screenWidth * 0.9 : screenWidth < 768 ? 400.0 : 500.0;
    
    DocumentSnapshot? orderDoc;
    try {
      // Try seller_orders first
      orderDoc = await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('seller_orders')
          .doc(orderId)
          .get();

      // If not found, try buyer's orders
      if (!orderDoc.exists) {
        orderDoc = await _firestore
            .collection('users')
            .doc(buyerId)
            .collection('orders')
            .doc(orderId)
            .get();
      }
    } catch (e) {
      orderDoc = null;
    }

    if (orderDoc == null || !orderDoc.exists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Details'),
          content: const Text('Order details not found.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final order = orderDoc.data() as Map<String, dynamic>? ?? {};

    // Get the real buyer's user ID from the order document
    final correctBuyerId = order['buyerId'] ?? order['userId'] ?? buyerId;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3D7C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: screenWidth < 480 ? 20 : 24,
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order['productImage'] != null &&
                          order['productImage'].toString().isNotEmpty)
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                order['productImage'],
                                width: screenWidth < 480 ? 100 : 120,
                                height: screenWidth < 480 ? 80 : 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: screenWidth < 480 ? 12 : 16),
                      _orderDetailRow('Product Name', order['productName']),
                      _orderDetailRow('Total Amount', '₱${((double.tryParse(order['productPrice'].toString().replaceAll('₱', '').replaceAll(',', '')) ?? 0.0) * (order['quantity'] ?? 1)).toStringAsFixed(2)}'),
                      _orderDetailRow('Quantity', order['quantity']),
                      _orderDetailRow('Buyer',
                          '${order['firstName'] ?? ''} ${order['lastName'] ?? ''}'),
                      _orderDetailRow('Contact Number', order['cpNumber'] ?? ''),
                      _orderDetailRow('Address', order['address']),
                      _orderDetailRow('Municipality', order['municipality']),
                      _orderDetailRow('Province', order['province']),
                      _orderDetailRow('Order Status', order['status'] ?? 'Pending'),
                      _orderDetailRow(
                          'Order Date',
                          order['createdAt'] != null &&
                                  order['createdAt'] is Timestamp
                              ? DateFormat('MMM d, y – hh:mm a')
                                  .format((order['createdAt'] as Timestamp).toDate())
                              : ''),
                    ],
                  ),
                ),
              ),
              
              // Buttons
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(dialogContext);
                            await _updateOrderStatus(
                              buyerId: correctBuyerId,
                              orderId: orderId,
                              newStatus: 'Accepted',
                              sellerId: sellerId,
                              context: context,
                            );
                            await _firestore
                                .collection('users')
                                .doc(sellerId)
                                .collection('seller_orders')
                                .doc(orderId)
                                .update({'status': 'Accepted'});
                            await _firestore.collection('accept_cancel_notifications').add({
                              'userId': correctBuyerId,
                              'orderId': orderId,
                              'type': 'order_accepted',
                              'message':
                                  'Your order has been accepted and is ready to deliver.',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (!mounted) return;
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Order accepted and buyer notified.')));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(dialogContext);
                            await _updateOrderStatus(
                              buyerId: correctBuyerId,
                              orderId: orderId,
                              newStatus: 'Cancelled',
                              sellerId: sellerId,
                              context: context,
                            );
                            await _firestore
                                .collection('users')
                                .doc(sellerId)
                                .collection('seller_orders')
                                .doc(orderId)
                                .update({'status': 'Cancelled'});
                            await _firestore.collection('accept_cancel_notifications').add({
                              'userId': correctBuyerId,
                              'orderId': orderId,
                              'type': 'order_cancelled',
                              'message': 'Your order has been cancelled by the seller.',
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            if (!mounted) return;
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Order cancelled and buyer notified.')));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkReadyDialog(BuildContext context, String orderId,
      String? buyerId, String? sellerId) async {
    if (buyerId == null || sellerId == null) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = _getResponsiveButtonHeight(screenWidth);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    final dialogWidth = screenWidth < 480 ? screenWidth * 0.9 : screenWidth < 768 ? 400.0 : 500.0;
    
    DocumentSnapshot? orderDoc;
    try {
      orderDoc = await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .get();
    } catch (e) {
      orderDoc = null;
    }

    if (orderDoc == null || !orderDoc.exists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Details'),
          content: const Text('Order details not found.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final order = orderDoc.data() as Map<String, dynamic>? ?? {};
    final productName = order['productName'] ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3D7C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: screenWidth < 480 ? 20 : 24,
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Mark Order as Ready?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order['productImage'] != null &&
                          order['productImage'].toString().isNotEmpty)
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                order['productImage'],
                                width: screenWidth < 480 ? 100 : 120,
                                height: screenWidth < 480 ? 80 : 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: screenWidth < 480 ? 12 : 16),
                      _orderDetailRow('Product Name', order['productName']),
                      _orderDetailRow('Total Amount', '₱${((double.tryParse(order['productPrice'].toString().replaceAll('₱', '').replaceAll(',', '')) ?? 0.0) * (order['quantity'] ?? 1)).toStringAsFixed(2)}'),
                      _orderDetailRow('Quantity', order['quantity']),
                      _orderDetailRow('Seller', order['sellerName']),
                      _orderDetailRow('Seller Contact', order['sellerContact']),
                      _orderDetailRow('Customer',
                          '${order['firstName'] ?? ''} ${order['lastName'] ?? ''}'),
                      _orderDetailRow('Contact Number', order['cpNumber'] ?? ''),
                      _orderDetailRow('Address', order['address']),
                      _orderDetailRow('Municipality', order['municipality']),
                      _orderDetailRow('Province', order['province']),
                      _orderDetailRow('Order Status', order['status'] ?? 'Pending'),
                      _orderDetailRow(
                          'Order Date',
                          order['createdAt'] != null && order['createdAt'] is Timestamp
                              ? DateFormat('MMM d, y – hh:mm a')
                                  .format((order['createdAt'] as Timestamp).toDate())
                              : ''),
                    ],
                  ),
                ),
              ),
              
              // Buttons
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: buttonHeight,
                        child: ElevatedButton(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(dialogContext);
                            await _firestore
                                .collection('users')
                                .doc(buyerId)
                                .collection('orders')
                                .doc(orderId)
                                .update({'status': 'Ready to Deliver'});
                            await _firestore
                                .collection('users')
                                .doc(sellerId)
                                .collection('seller_orders')
                                .doc(orderId)
                                .update({'status': 'Ready to Deliver'});

                            await _firestore.collection('accept_cancel_notifications').add({
                              'userId': buyerId,
                              'orderId': orderId,
                              'type': 'order_ready',
                              'message': 'Your order for "$productName" is ready to deliver!',
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (!mounted) return;
                            messenger.showSnackBar(const SnackBar(
                                content: Text('Order marked as ready and buyer notified.')));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Mark as Ready',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, String orderId, {String? buyerId}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final theBuyerId = buyerId ?? user.uid;

    DocumentSnapshot? orderDoc;
    try {
      orderDoc = await _firestore
          .collection('users')
          .doc(theBuyerId)
          .collection('orders')
          .doc(orderId)
          .get();
      if (!orderDoc.exists) {
        orderDoc = await _firestore
            .collection('users')
            .doc(theBuyerId)
            .collection('seller_orders')
            .doc(orderId)
            .get();
      }
    } catch (e) {
      orderDoc = null;
    }

    if (orderDoc == null || !orderDoc.exists) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Details'),
          content: const Text('Order details not found.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final order = orderDoc.data() as Map<String, dynamic>? ?? {};
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonHeight = _getResponsiveButtonHeight(screenWidth);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    final dialogWidth = screenWidth < 480 ? screenWidth * 0.9 : screenWidth < 768 ? 400.0 : 500.0;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3D7C),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: screenWidth < 480 ? 20 : 24,
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Order Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18.0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (order['productImage'] != null &&
                          order['productImage'].toString().isNotEmpty)
                        Center(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                order['productImage'],
                                width: screenWidth < 480 ? 100 : 120,
                                height: screenWidth < 480 ? 80 : 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(height: screenWidth < 480 ? 12 : 16),
                      _orderDetailRow('Product Name', order['productName']),
                      _orderDetailRow('Total Amount', '₱${((double.tryParse(order['productPrice'].toString().replaceAll('₱', '').replaceAll(',', '')) ?? 0.0) * (order['quantity'] ?? 1)).toStringAsFixed(2)}'),
                      _orderDetailRow('Quantity', order['quantity']),
                      _orderDetailRow('Seller', order['sellerName']),
                      _orderDetailRow('Seller Contact', order['sellerContact']),
                      _orderDetailRow('Customer',
                          '${order['firstName'] ?? ''} ${order['lastName'] ?? ''}'),
                      _orderDetailRow('Contact Number', order['cpNumber'] ?? ''),
                      _orderDetailRow('Address', order['address']),
                      _orderDetailRow('Municipality', order['municipality']),
                      _orderDetailRow('Province', order['province']),
                      _orderDetailRow('Order Status', order['status'] ?? 'Pending'),
                      _orderDetailRow(
                          'Order Date',
                          order['createdAt'] != null && order['createdAt'] is Timestamp
                              ? DateFormat('MMM d, y – hh:mm a')
                                  .format((order['createdAt'] as Timestamp).toDate())
                              : ''),
                    ],
                  ),
                ),
              ),
              // Buttons
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value?.toString() ?? '')),
        ],
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(context, _auth.currentUser!),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to view notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please log in to see your notifications',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, User user) {
    return AppBar(
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('cart')
                .snapshots(),
            builder: (context, snapshot) {
              int cartCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined,
                        color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddToCart(userType: widget.userType),
                          ));
                    },
                  ),
                  if (cartCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int notificationCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.black),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NotificationScreen(userType: widget.userType),
                          ));
                    },
                  ),
                  if (notificationCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
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
    );
  }

  Future<void> _acceptOrder(BuildContext context, String orderId, String buyerId, String sellerId, String productName) async {
    try {
      print('Accepting order: $orderId');
      print('Buyer ID: $buyerId');
      print('Seller ID: $sellerId');
      print('Current user: ${_auth.currentUser?.uid}');
      
      // First, verify the current user is the seller
      if (_auth.currentUser?.uid != sellerId) {
        throw Exception('Permission denied: You are not the seller of this order');
      }

      // Get the buyer's order to create seller order
      final buyerOrderDoc = await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!buyerOrderDoc.exists) {
        throw Exception('Buyer order not found');
      }

      final buyerOrderData = buyerOrderDoc.data() as Map<String, dynamic>;

      // Update order status in buyer's orders collection
      print('Updating buyer order...');
      await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Accepted'});
      print('Buyer order updated successfully');

      // Create seller order document
      print('Creating seller order...');
      await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('seller_orders')
          .doc(orderId)
          .set({
        ...buyerOrderData,
        'status': 'Accepted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Seller order created successfully');

      // Send notification to customer
      print('Sending notification to customer...');
      await _firestore.collection('notifications').add({
        'userId': buyerId,
        'orderId': orderId,
        'type': 'order_accepted',
        'message': 'Your order for "$productName" has been accepted and is ready to deliver.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Notification sent successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error accepting order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder(BuildContext context, String orderId, String buyerId, String sellerId, String productName) async {
    try {
      print('Cancelling order: $orderId');
      print('Buyer ID: $buyerId');
      print('Seller ID: $sellerId');
      print('Current user: ${_auth.currentUser?.uid}');
      
      // First, verify the current user is the seller
      if (_auth.currentUser?.uid != sellerId) {
        throw Exception('Permission denied: You are not the seller of this order');
      }

      // Get the buyer's order to create seller order
      final buyerOrderDoc = await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .get();

      if (!buyerOrderDoc.exists) {
        throw Exception('Buyer order not found');
      }

      final buyerOrderData = buyerOrderDoc.data() as Map<String, dynamic>;

      // Update order status in buyer's orders collection
      print('Updating buyer order...');
      await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Cancelled'});
      print('Buyer order updated successfully');

      // Create seller order document
      print('Creating seller order...');
      await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('seller_orders')
          .doc(orderId)
          .set({
        ...buyerOrderData,
        'status': 'Cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Seller order created successfully');

      // Send notification to customer
      print('Sending notification to customer...');
      await _firestore.collection('notifications').add({
        'userId': buyerId,
        'orderId': orderId,
        'type': 'order_cancelled',
        'message': 'Your order for "$productName" has been cancelled by the seller.',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Notification sent successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add this new method to mark notifications as read
  Future<void> _markNotificationsAsRead(List notifications) async {
    try {
      for (var doc in notifications) {
        final data = doc.data() as Map<String, dynamic>;
        final isRead = data['isRead'] ?? false;
        
        if (!isRead) {
          // Check which collection this notification belongs to
          if (data.containsKey('buyerFirstName')) {
            // This is from sellers_notification collection
            await _firestore
                .collection('sellers_notification')
                .doc(doc.id)
                .update({'isRead': true});
          } else {
            // This is from notifications collection
            await _firestore
                .collection('notifications')
                .doc(doc.id)
                .update({'isRead': true});
          }
        }
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  // Add this method to mark individual notification as read
  Future<void> _markNotificationAsRead(DocumentSnapshot doc) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(doc.id)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
}
        