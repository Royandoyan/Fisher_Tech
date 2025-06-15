import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification.dart';
import 'shopping.dart';
import 'homed.dart';
import 'profile.dart';
import 'selection_screen.dart';

class AddToCart extends StatefulWidget {
  final String userType;
  final Map<String, dynamic>? initialOrder;

  const AddToCart({Key? key, required this.userType, this.initialOrder})
      : super(key: key);

  @override
  State<AddToCart> createState() => _AddToCartState();
}

class _AddToCartState extends State<AddToCart> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  String? _selectedProvince;
  final Map<String, String> _orderedItems = {};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, String?> _sellerProfileImageUrlCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder == null) {
      _loadOrderedItems();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _municipalityController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final orders = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('orders')
        .where('status', isNotEqualTo: 'Cancelled')
        .get();

    setState(() {
      for (var order in orders.docs) {
        final cartDocId = order['cartDocId'];
        if (cartDocId != null) {
          _orderedItems[cartDocId] = order.id;
        }
      }
    });
  }

  Future<String?> _getSellerProfileImageUrl(String sellerId) async {
    if (_sellerProfileImageUrlCache.containsKey(sellerId)) {
      return _sellerProfileImageUrlCache[sellerId];
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profile')
          .doc(sellerId)
          .collection('profile_pictures')
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final url = snap.docs.first['url'] as String;
        _sellerProfileImageUrlCache[sellerId] = url;
        return url;
      }
    } catch (_) {}
    _sellerProfileImageUrlCache[sellerId] = null;
    return null;
  }

  Future<bool> _isValidUser(String uid) async {
    final customerDoc =
        await FirebaseFirestore.instance.collection('customer').doc(uid).get();
    final fishermanDoc =
        await FirebaseFirestore.instance.collection('fisherman').doc(uid).get();
    return customerDoc.exists || fishermanDoc.exists;
  }

  Future<void> _placeDirectOrder(Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to place an order')),
        );
      }
      return;
    }

    if (!await _isValidUser(user.uid)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Only registered customers or fishermen can place orders'),
          ),
        );
      }
      return;
    }

    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _municipalityController.text.isEmpty ||
        _selectedProvince == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
      }
      return;
    }

    try {
      final orderData = {
        'userId': user.uid,
        'sellerId': product['sellerId'],
        'productName': product['name'],
        'productPrice': product['price'],
        'productImage': product['image'],
        'quantity': product['quantity'],
        'sellerName': product['sellerName'],
        'sellerContact': product['sellerContact'],
        'firstName': _firstNameController.text,
        'middleName': _middleNameController.text,
        'lastName': _lastNameController.text,
        'address': _addressController.text,
        'municipality': _municipalityController.text,
        'province': _selectedProvince,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final orderRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData);

      // Buyer notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': user.uid,
        'orderId': orderRef.id,
        'type': 'order_placed',
        'message': 'Your order has been placed successfully!',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Seller order and notification
      if (product['sellerId'] != null &&
          product['sellerId'].toString().isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(product['sellerId'])
            .collection('seller_orders')
            .doc(orderRef.id)
            .set(orderData);

        // Seller notification (using buyer's placed order)
        try {
          // Debug print for troubleshooting
          print('Creating seller notification for: ${product['sellerId']}');
          await FirebaseFirestore.instance.collection('notifications').add({
            'userId': product['sellerId'],
            'sellerId': product['sellerId'],
            'buyerId': user.uid,
            'orderId': orderRef.id,
            'type': 'new_order',
            'message': 'New order #${orderRef.id.substring(0, 8)} received for ${product['name']}',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (e) {
          print('Error writing to notifications (for seller): $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cancelOrder(String cartDocId, String orderDocId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .doc(orderDocId)
          .update({'status': 'Cancelled'});

      setState(() {
        _orderedItems.remove(cartDocId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: $e')),
        );
      }
    }
  }

  void _showShippingForm({
    required List<Map<String, dynamic>> items,
    required String sellerId,
    required String sellerName,
    required String sellerContact,
  }) {
    _firstNameController.clear();
    _middleNameController.clear();
    _lastNameController.clear();
    _addressController.clear();
    _municipalityController.clear();
    _selectedProvince = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SHIPPING DETAILS',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                      labelText: 'FIRST NAME',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _middleNameController,
                    decoration: const InputDecoration(
                      labelText: 'MIDDLE NAME',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                      labelText: 'LAST NAME',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'PROVINCE',
                      border: OutlineInputBorder(),
                    ),
                    value: _selectedProvince,
                    hint: const Text('SELECT PROVINCE'),
                    items: const [
                      DropdownMenuItem(value: 'Leyte', child: Text('Leyte')),
                      DropdownMenuItem(
                          value: 'Southern Leyte',
                          child: Text('Southern Leyte')),
                      DropdownMenuItem(value: 'Samar', child: Text('Samar')),
                      DropdownMenuItem(
                          value: 'Eastern Samar', child: Text('Eastern Samar')),
                      DropdownMenuItem(
                          value: 'Northern Samar',
                          child: Text('Northern Samar')),
                      DropdownMenuItem(
                          value: 'Biliran', child: Text('Biliran')),
                    ],
                    onChanged: (value) =>
                        setModalState(() => _selectedProvince = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _municipalityController,
                    decoration: const InputDecoration(
                      labelText: 'MUNICIPALITY',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'ADDRESS',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (_firstNameController.text.isEmpty ||
                              _lastNameController.text.isEmpty ||
                              _addressController.text.isEmpty ||
                              _municipalityController.text.isEmpty ||
                              _selectedProvince == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please fill all required fields')),
                              );
                            }
                            return;
                          }

                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please sign in to place an order')),
                              );
                            }
                            return;
                          }

                          if (!await _isValidUser(user.uid)) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Only registered customers or fishermen can place orders'),
                                ),
                              );
                            }
                            return;
                          }

                          try {
                            Navigator.of(context).pop();

                            for (var item in items) {
                              final orderData = {
                                'userId': user.uid,
                                'sellerId': sellerId,
                                'productName': item['name'],
                                'productPrice': item['price'],
                                'productImage': item['image'],
                                'quantity': item['quantity'],
                                'sellerName': sellerName,
                                'sellerContact': sellerContact,
                                'firstName': _firstNameController.text,
                                'middleName': _middleNameController.text,
                                'lastName': _lastNameController.text,
                                'address': _addressController.text,
                                'municipality': _municipalityController.text,
                                'province': _selectedProvince,
                                'status': 'Pending',
                                'cartDocId': item['cartDocId'],
                                'createdAt': FieldValue.serverTimestamp(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              };

                              final orderRef = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('orders')
                                  .add(orderData);

                              if (item['cartDocId'] != null) {
                                setState(() {
                                  _orderedItems[item['cartDocId']] =
                                      orderRef.id;
                                });
                              }

                              // Buyer notification
                              await FirebaseFirestore.instance
                                  .collection('notifications')
                                  .add({
                                'userId': user.uid,
                                'orderId': orderRef.id,
                                'type': 'order_placed',
                                'message':
                                    'Your order has been placed successfully!',
                                'isRead': false,
                                'createdAt': FieldValue.serverTimestamp(),
                              });

                              if (sellerId.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(sellerId)
                                    .collection('seller_orders')
                                    .doc(orderRef.id)
                                    .set(orderData);

                                // Seller notification (using buyer's placed order)
                                try {
                                  print('Creating seller notification for: $sellerId');
                                  await FirebaseFirestore.instance
                                      .collection('notifications')
                                      .add({
                                    'userId': sellerId,
                                    'sellerId': sellerId,
                                    'buyerId': user.uid,
                                    'orderId': orderRef.id,
                                    'type': 'new_order',
                                    'message':
                                        'New order #${orderRef.id.substring(0, 8)} received for ${item['name']}',
                                    'isRead': false,
                                    'createdAt':
                                        FieldValue.serverTimestamp(),
                                  });
                                } catch (e) {
                                  print(
                                      'Error writing to notifications (for seller): $e');
                                }
                              }
                            }

                            if (items.length > 1) {
                              final cartItems = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('cart')
                                  .get();

                              for (var doc in cartItems.docs) {
                                await doc.reference.delete();
                              }
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Order placed successfully!')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Failed to place order: ${e.toString()}')),
                              );
                            }
                          }
                        },
                        child: const Text('CONFIRM ORDER'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _signOut() async {
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
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/coastguard.png',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/map.png',
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/firestation.png',
                  onTap: () {
                    Navigator.pop(context);
                  },
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
    // If initialOrder is provided, show direct order form for single product
    if (widget.initialOrder != null) {
      final product = widget.initialOrder!;
      return Scaffold(
        appBar: AppBar(
          title: Text('Order ${product['name']}'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // Product info
              Row(
                children: [
                  product['image'] != null &&
                          product['image'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            product['image'],
                            width: 90,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            product['image'] ?? '',
                            width: 90,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('₱${product['price'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Text('Seller: ${product['sellerName'] ?? ''}',
                            style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              // Order quantity (default 1)
              Row(
                children: [
                  const Text('Quantity:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product['quantity']?.toString() ?? '1',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Shipping form fields
              const Text(
                'SHIPPING DETAILS',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'FIRST NAME',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _middleNameController,
                decoration: const InputDecoration(
                  labelText: 'MIDDLE NAME',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'LAST NAME',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'PROVINCE',
                  border: OutlineInputBorder(),
                ),
                value: _selectedProvince,
                hint: const Text('SELECT PROVINCE'),
                items: const [
                  DropdownMenuItem(value: 'Leyte', child: Text('Leyte')),
                  DropdownMenuItem(
                      value: 'Southern Leyte', child: Text('Southern Leyte')),
                  DropdownMenuItem(value: 'Samar', child: Text('Samar')),
                  DropdownMenuItem(
                      value: 'Eastern Samar', child: Text('Eastern Samar')),
                  DropdownMenuItem(
                      value: 'Northern Samar', child: Text('Northern Samar')),
                  DropdownMenuItem(value: 'Biliran', child: Text('Biliran')),
                ],
                onChanged: (value) => setState(() => _selectedProvince = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _municipalityController,
                decoration: const InputDecoration(
                  labelText: 'MUNICIPALITY',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'ADDRESS',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _placeDirectOrder(product),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A3D7C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child:
                    const Text('PLACE ORDER', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      );
    }

    // If not direct order, show regular cart UI
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildUnauthenticatedView(context);
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: _buildAppBar(context, user),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final cartItems = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ...cartItems.map((doc) {
                  final item = doc.data() as Map<String, dynamic>;
                  return FutureBuilder<String?>(
                    future: _getSellerProfileImageUrl(item['sellerId'] ?? ''),
                    builder: (context, profileSnapshot) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Seller Info
                            Row(
                              children: [
                                profileSnapshot.connectionState ==
                                            ConnectionState.done &&
                                        profileSnapshot.data != null &&
                                        profileSnapshot.data!.isNotEmpty
                                    ? CircleAvatar(
                                        radius: 20,
                                        backgroundImage:
                                            NetworkImage(profileSnapshot.data!),
                                      )
                                    : const CircleAvatar(
                                        radius: 20,
                                        backgroundImage: AssetImage(''),
                                      ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['sellerName'] ?? 'Seller',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      item['sellerContact'] ?? 'No contact',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Product Info
                            _buildProductItem(
                              context: context,
                              docId: doc.id,
                              image: item['image'] ?? '',
                              name: item['name'] ?? 'No name',
                              price: item['price'] ?? 'No price',
                              quantity: item['quantity'] ?? 1,
                              sellerId: item['sellerId'] ?? '',
                              sellerName: item['sellerName'] ?? '',
                              sellerContact: item['sellerContact'] ?? '',
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Get all cart items for checkout
                        final cartItems = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .collection('cart')
                            .get();

                        // Group items by seller
                        final itemsBySeller =
                            <String, List<Map<String, dynamic>>>{};
                        for (var doc in cartItems.docs) {
                          final item = doc.data();
                          final sellerId = item['sellerId'] ?? '';
                          if (!itemsBySeller.containsKey(sellerId)) {
                            itemsBySeller[sellerId] = [];
                          }
                          itemsBySeller[sellerId]!.add({
                            ...item,
                            'cartDocId': doc.id,
                          });
                        }

                        if (itemsBySeller.isNotEmpty) {
                          final firstSeller = itemsBySeller.entries.first;
                          _showShippingForm(
                            items: firstSeller.value,
                            sellerId: firstSeller.key,
                            sellerName:
                                firstSeller.value.first['sellerName'] ?? '',
                            sellerContact:
                                firstSeller.value.first['sellerContact'] ?? '',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3D7C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'CHECKOUT',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductItem({
    required BuildContext context,
    required String docId,
    required String image,
    required String name,
    required String price,
    required int quantity,
    required String sellerId,
    required String sellerName,
    required String sellerContact,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final isOrdered = _orderedItems.containsKey(docId);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image.startsWith('http')
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  image,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    '',
                    width: 100,
                    height: 80,
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  image.isNotEmpty ? image : '',
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 20),
                    onPressed: () async {
                      if (quantity > 1) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('cart')
                            .doc(docId)
                            .update({
                          'quantity': FieldValue.increment(-1),
                        });
                      } else {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('cart')
                            .doc(docId)
                            .delete();
                      }
                    },
                  ),
                  Text(
                    quantity.toString(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user?.uid)
                          .collection('cart')
                          .doc(docId)
                          .update({
                        'quantity': FieldValue.increment(1),
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          children: [
            if (!isOrdered) ...[
              SizedBox(
                width: 90,
                height: 35,
                child: ElevatedButton(
                  onPressed: () {
                    _showShippingForm(
                      items: [
                        {
                          'name': name,
                          'price': price,
                          'image': image,
                          'quantity': quantity,
                          'cartDocId': docId,
                        }
                      ],
                      sellerId: sellerId,
                      sellerName: sellerName,
                      sellerContact: sellerContact,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3D7C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Order'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 90,
                height: 35,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user?.uid)
                        .collection('cart')
                        .doc(docId)
                        .delete();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Remove'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: 90,
                height: 35,
                child: ElevatedButton(
                  onPressed: () => _cancelOrder(docId, _orderedItems[docId]!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Cancel Order'),
                ),
              ),
            ],
          ],
        ),
      ],
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
                  ),
                );
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
                  ),
                );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.shopping_cart_outlined, color: Colors.black),
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
              icon: const Icon(Icons.notifications_none, color: Colors.black),
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
              icon: const Icon(Icons.person_outline, color: Colors.black),
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
      body: const Center(child: Text('Please sign in to view your cart')),
    );
  }

  AppBar _buildAppBar(BuildContext context, User user) {
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
                ),
              );
            },
            child: Image.asset(
              'assets/images/logo.png',
              height: 40,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Colors.black),
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
                        ),
                      );
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
                        ),
                      );
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}