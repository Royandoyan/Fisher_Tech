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
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
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
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotificationScreen(userType: widget.userType),
                            )),
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
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data!.docs;
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('accept_cancel_notifications')
                .where('userId', isEqualTo: user.uid)
                .snapshots(),
            builder: (context, acceptCancelSnapshot) {
              List<QueryDocumentSnapshot> allNotifications =
                  List.from(notifications);
              if (acceptCancelSnapshot.hasData) {
                allNotifications.addAll(acceptCancelSnapshot.data!.docs);
              }
              allNotifications.sort((a, b) {
                final aCreated = a['createdAt'] as Timestamp?;
                final bCreated = b['createdAt'] as Timestamp?;
                if (aCreated == null && bCreated == null) return 0;
                if (aCreated == null) return 1;
                if (bCreated == null) return -1;
                return bCreated.compareTo(aCreated);
              });

              return LayoutBuilder(
                builder: (context, constraints) {
                  final double maxWidth = constraints.maxWidth > 1200
                      ? 800.0
                      : constraints.maxWidth > 600
                          ? 600.0
                          : constraints.maxWidth * 0.9;
                  return Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: maxWidth, minWidth: 300),
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: constraints.maxWidth > 600 ? 40 : 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 20),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4F8AAE),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Flexible(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: allNotifications.length,
                                itemBuilder: (context, index) {
                                  final doc = allNotifications[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final message = _formatNotificationMessage(
                                      data['message'] ?? 'Notification');
                                  final timestamp =
                                      data['createdAt'] as Timestamp?;
                                  final timeText = timestamp != null
                                      ? _formatTimestamp(timestamp)
                                      : 'Recently';

                                  final type = data['type'] ?? '';
                                  final orderId = data['orderId'];
                                  final sellerId = data['sellerId'];
                                  final userId = data['userId'];

                                  return GestureDetector(
                                    onTap: () async {
                                      if ((type == 'order_placed' ||
                                              type == 'new_order' ||
                                              type == 'order_cancelled' ||
                                              type == 'order_accepted' ||
                                              type == 'order_ready') &&
                                          orderId != null &&
                                          orderId != "") {
                                        if (type == 'new_order' &&
                                            sellerId == user.uid) {
                                          _showOrderActionDialog(context,
                                              orderId, userId, sellerId);
                                        } else if (
                                            // For customer notifications, always show using buyerId (userId from notification)
                                            (type == 'order_accepted' ||
                                                type == 'order_cancelled' ||
                                                type == 'order_ready')) {
                                          _showOrderDetailsDialog(
                                              context, orderId,
                                              buyerId: userId);
                                        } else if (type == 'order_accepted' &&
                                            userId == user.uid &&
                                            sellerId != user.uid) {
                                          _showMarkReadyDialog(context, orderId,
                                              userId, sellerId);
                                        } else {
                                          _showOrderDetailsDialog(
                                              context, orderId);
                                        }
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4E8F6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            margin: const EdgeInsets.only(
                                                right: 12),
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1A3D7C),
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
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.bold,
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
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
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

      final orderData = orderDoc.data() ?? {};
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

  void _showOrderActionDialog(BuildContext context, String orderId,
      String? buyerId, String? sellerId) async {
    if (buyerId == null || sellerId == null) return;
    try {
      final orderDoc = await _firestore
          .collection('users')
          .doc(sellerId)
          .collection('seller_orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
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

      final order = orderDoc.data() ?? {};

      // Get the real buyer's user ID from the order document
      final correctBuyerId = order['buyerId'] ?? order['userId'] ?? buyerId;

      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Order Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order['productImage'] != null &&
                    order['productImage'].toString().isNotEmpty)
                  Center(
                    child: Image.network(order['productImage'],
                        width: 120, height: 100, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 10),
                _orderDetailRow('Product Name', order['productName']),
                _orderDetailRow('Price', '₱${order['productPrice']}'),
                _orderDetailRow('Quantity', order['quantity']),
                _orderDetailRow('Buyer',
                    '${order['firstName'] ?? ''} ${order['lastName'] ?? ''}'),
                _orderDetailRow('Address', order['address']),
                _orderDetailRow('Municipality', order['municipality']),
                _orderDetailRow('Province', order['province']),
                _orderDetailRow('Order Status', order['status']),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            ElevatedButton(
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
              child:
                  const Text('Accept', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            ElevatedButton(
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
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error fetching order: $e');
    }
  }

  void _showMarkReadyDialog(BuildContext context, String orderId,
      String? buyerId, String? sellerId) async {
    if (buyerId == null || sellerId == null) return;
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark Order as Ready?'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order['productImage'] != null &&
                  order['productImage'].toString().isNotEmpty)
                Center(
                  child: Image.network(order['productImage'],
                      width: 120, height: 100, fit: BoxFit.cover),
                ),
              const SizedBox(height: 10),
              _orderDetailRow('Product Name', order['productName']),
              _orderDetailRow('Price', '₱${order['productPrice']}'),
              _orderDetailRow('Quantity', order['quantity']),
              _orderDetailRow('Seller', order['sellerName']),
              _orderDetailRow('Seller Contact', order['sellerContact']),
              _orderDetailRow('Customer',
                  '${order['firstName'] ?? ''} ${order['lastName'] ?? ''}'),
              _orderDetailRow('Address', order['address']),
              _orderDetailRow('Municipality', order['municipality']),
              _orderDetailRow('Province', order['province']),
              _orderDetailRow('Order Status', order['status']),
              _orderDetailRow(
                  'Order Date',
                  order['createdAt'] != null && order['createdAt'] is Timestamp
                      ? DateFormat('MMM d, y – hh:mm a')
                          .format((order['createdAt'] as Timestamp).toDate())
                      : ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton(
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
            child: const Text('Mark as Ready to Deliver'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _showOrderDetailsDialog(BuildContext context, String orderId,
      {String? buyerId}) async {
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

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order['productImage'] != null &&
                  order['productImage'].toString().isNotEmpty)
                Center(
                  child: Image.network(order['productImage'],
                      width: 120, height: 100, fit: BoxFit.cover),
                ),
              const SizedBox(height: 10),
              _orderDetailRow('Product Name', order['productName']),
              _orderDetailRow('Price', '₱${order['productPrice']}'),
              _orderDetailRow('Quantity', order['quantity']),
              _orderDetailRow('Seller', order['sellerName']),
              _orderDetailRow('Seller Contact', order['sellerContact']),
              _orderDetailRow('Customer',
                  '${order['firstName'] ?? ''} ${order['lastName'] ?? ''}'),
              _orderDetailRow('Address', order['address']),
              _orderDetailRow('Municipality', order['municipality']),
              _orderDetailRow('Province', order['province']),
              _orderDetailRow('Order Status', order['status']),
              _orderDetailRow(
                  'Order Date',
                  order['createdAt'] != null && order['createdAt'] is Timestamp
                      ? DateFormat('MMM d, y – hh:mm a')
                          .format((order['createdAt'] as Timestamp).toDate())
                      : ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
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
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          NotificationScreen(userType: widget.userType),
                    ));
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
      ),
      body: const Center(
        child: Text('Please sign in to view notifications'),
      ),
    );
  }
}
