import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'notification.dart';
import 'shopping.dart';
import 'homed.dart';
import 'profile.dart';
import 'selection_screen.dart';
import 'package:rxdart/rxdart.dart';

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
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  String? _selectedProvince;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Map<String, String?> _sellerProfileImageUrlCache = {};
  String _shippingChoice = 'saved';
  bool _hasError = false;
  String _errorMessage = '';

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

  double _getResponsiveImageSize(double width) {
    if (width < 480) return 80.0;
    if (width < 768) return 90.0;
    if (width < 1024) return 100.0;
    return 110.0;
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
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _numberController.dispose();
    _addressController.dispose();
    _municipalityController.dispose();
    super.dispose();
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
      print('🚀 Starting direct order placement...');
      print('Product: ${product['name']}');
      print('Seller ID: ${product['sellerId']}');
      print('User ID: ${user.uid}');
      print('Form data validation:');
      print('  First name: "${_firstNameController.text}"');
      print('  Last name: "${_lastNameController.text}"');
      print('  Address: "${_addressController.text}"');
      print('  Municipality: "${_municipalityController.text}"');
      print('  Province: "$_selectedProvince"');
      
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
        'cpNumber': _numberController.text,
        'address': _addressController.text,
        'municipality': _municipalityController.text,
        'province': _selectedProvince,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      print('📝 Creating buyer order...');
      final orderRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData);
      print('✅ Buyer order created with ID: ${orderRef.id}');

      // Calculate total amount for notifications
      double price = 0.0;
      try {
        final priceValue = product['price'];
        if (priceValue is String) {
          price = double.tryParse(priceValue.replaceAll('₱', '').replaceAll(',', '')) ?? 0.0;
        } else if (priceValue is num) {
          price = priceValue.toDouble();
        }
      } catch (e) {
        price = 0.0;
      }
      final totalAmount = price * (product['quantity'] ?? 1);
      print('💰 Total amount: $totalAmount');

      print('🔔 Creating buyer notification...');
      // Buyer notification
      try {
        final buyerNotificationData = {
          'userId': user.uid,
          'orderId': orderRef.id,
          'type': 'order_placed',
          'message':
              'Your order for ₱${totalAmount.toStringAsFixed(2)} has been placed successfully!',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        };
        print('📝 Buyer notification data: $buyerNotificationData');
        
        await FirebaseFirestore.instance
            .collection('notifications')
            .add(buyerNotificationData);
        print('✅ Buyer notification created successfully');
      } catch (e) {
        print('❌ Error creating buyer notification: $e');
        _hasError = true;
        _errorMessage = 'Failed to create buyer notification: $e';
      }

      // Seller order and notification
      if (product['sellerId'] != null &&
          product['sellerId'].toString().isNotEmpty) {
        print('📝 Skipping seller order creation (will be created by seller when they receive notification)');
        
        // Calculate total amount
        double price = 0.0;
        try {
          final priceValue = product['price'];
          if (priceValue is String) {
            price = double.tryParse(priceValue.replaceAll('₱', '').replaceAll(',', '')) ?? 0.0;
          } else if (priceValue is num) {
            price = priceValue.toDouble();
          }
        } catch (e) {
          price = 0.0;
        }
        final totalAmount = price * (product['quantity'] ?? 1);
        print('💰 Total amount: $totalAmount');
        
        print('🔔 Creating seller notification...');
        try {
          final sellerNotificationData = {
            'userId': product['sellerId'],
            'sellerId': product['sellerId'],
            'buyerId': user.uid,
            'orderId': orderRef.id,
            'type': 'new_order',
            'message':
                'Your product "${product['name']}" has been ordered for ₱${totalAmount.toStringAsFixed(2)}!',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            // Add buyer information for seller notification
            'buyerFirstName': _firstNameController.text,
            'buyerMiddleName': _middleNameController.text,
            'buyerLastName': _lastNameController.text,
            'buyerAddress': _addressController.text,
            'buyerMunicipality': _municipalityController.text,
            'buyerProvince': _selectedProvince,
            'productName': product['name'],
            'productPrice': product['price'],
            'productImage': product['image'],
            'quantity': product['quantity'],
            'totalAmount': totalAmount,
            'buyerCpNumber': _numberController.text,
          };
          print('📝 Seller notification data: $sellerNotificationData');
          
          await FirebaseFirestore.instance
              .collection('sellers_notification')
              .add(sellerNotificationData);
          print('✅ Seller notification created successfully');
        } catch (e) {
          print('❌ Error creating seller notification: $e');
          _hasError = true;
          _errorMessage = 'Failed to create seller notification: $e';
        }

        await _sendOrderMessageToSeller(
          sellerId: product['sellerId'],
          sellerName: product['sellerName'] ?? '',
          productName: product['name'] ?? '',
          productPrice: product['price'] ?? '',
          quantity: product['quantity'] ?? 1,
          customerName: '${_firstNameController.text} ${_lastNameController.text}',
          address: _addressController.text,
          municipality: _municipalityController.text,
          province: _selectedProvince ?? '',
          cpNumber: _numberController.text,
        );
      } else {
        print('⚠️ Seller ID is empty, skipping seller order and notifications');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Error placing direct order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
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
    // Don't clear controllers immediately - let the radio buttons handle it
    // _firstNameController.clear();
    // _middleNameController.clear();
    // _lastNameController.clear();
    // _addressController.clear();
    // _municipalityController.clear();
    // _selectedProvince = null;

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
                  
                  // Radio buttons for shipping info choice
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('orders')
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      bool hasSavedInfo = false;
                      String savedFirstName = '';
                      String savedMiddleName = '';
                      String savedLastName = '';
                      String savedCpNumber = '';
                      String savedProvince = '';
                      String savedMunicipality = '';
                      String savedAddress = '';
                      
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final latestOrder = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                        savedFirstName = latestOrder['firstName'] ?? '';
                        savedMiddleName = latestOrder['middleName'] ?? '';
                        savedLastName = latestOrder['lastName'] ?? '';
                        savedCpNumber = latestOrder['cpNumber'] ?? '';
                        savedProvince = latestOrder['province'] ?? '';
                        savedMunicipality = latestOrder['municipality'] ?? '';
                        savedAddress = latestOrder['address'] ?? '';
                        
                        hasSavedInfo = savedFirstName.isNotEmpty && savedLastName.isNotEmpty;
                      }
                      
                      // If no saved info, default to new and clear controllers
                      if (!hasSavedInfo && _shippingChoice == 'saved') {
                        _shippingChoice = 'new';
                        _firstNameController.clear();
                        _middleNameController.clear();
                        _lastNameController.clear();
                        _addressController.clear();
                        _municipalityController.clear();
                        _selectedProvince = null;
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasSavedInfo) ...[
                            const Text(
                              'Choose Shipping Information:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 10),
                            
                            // Saved information option
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'saved',
                                    groupValue: _shippingChoice,
                                    onChanged: (value) {
                                      setModalState(() {
                                        _shippingChoice = value!;
                                        if (value == 'saved') {
                                          _firstNameController.text = savedFirstName;
                                          _middleNameController.text = savedMiddleName;
                                          _lastNameController.text = savedLastName;
                                          _numberController.text = savedCpNumber;
                                          _selectedProvince = savedProvince;
                                          _municipalityController.text = savedMunicipality;
                                          _addressController.text = savedAddress;
                                        }
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Use Previous Information:',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$savedFirstName $savedMiddleName $savedLastName, $savedCpNumber, $savedProvince, $savedMunicipality, $savedAddress',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            
                            // New information option
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: 'new',
                                    groupValue: _shippingChoice,
                                    onChanged: (value) {
                                      setModalState(() {
                                        _shippingChoice = value!;
                                        if (value == 'new') {
                                          _firstNameController.clear();
                                          _middleNameController.clear();
                                          _lastNameController.clear();
                                          _addressController.clear();
                                          _municipalityController.clear();
                                          _selectedProvince = null;
                                        }
                                      });
                                    },
                                  ),
                                  const Expanded(
                                    child: Text(
                                      'Enter New Information',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ] else ...[
                            // If no saved info, default to new information
                            const Text(
                              'Enter Shipping Information:',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ],
                      );
                    },
                  ),
                  
                  // Shipping form fields (show if new is selected or no saved info)
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .collection('orders')
                        .orderBy('createdAt', descending: true)
                        .limit(1)
                        .snapshots(),
                    builder: (context, savedInfoSnapshot) {
                      bool hasSavedInfo = false;
                      if (savedInfoSnapshot.hasData && savedInfoSnapshot.data!.docs.isNotEmpty) {
                        final latestOrder = savedInfoSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                        final savedFirstName = latestOrder['firstName'] ?? '';
                        final savedLastName = latestOrder['lastName'] ?? '';
                        final savedCpNumber = latestOrder['cpNumber'] ?? '';
                        hasSavedInfo = savedFirstName.isNotEmpty && savedLastName.isNotEmpty;
                      }
                      
                      // Show form fields if new is selected OR if there's no saved info
                      if (_shippingChoice != 'saved' || !hasSavedInfo) {
                        return Column(
                          children: [
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
                            TextField(
                              controller: _numberController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'CONTACT NUMBER',
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
                          ],
                        );
                      } else {
                        // Do not render any hidden or zero-height fields when using saved info
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                  
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
                          items.first['quantity']?.toString() ?? '1',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
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
                          print('=== CONFIRM ORDER BUTTON PRESSED ===');
                          print('Form validation check:');
                          print('First name: "${_firstNameController.text}"');
                          print('Last name: "${_lastNameController.text}"');
                          print('Address: "${_addressController.text}"');
                          print('Municipality: "${_municipalityController.text}"');
                          print('Province: "$_selectedProvince"');
                          print('Shipping choice: "$_shippingChoice"');
                          
                          if (_firstNameController.text.isEmpty ||
                              _lastNameController.text.isEmpty ||
                              _addressController.text.isEmpty ||
                              _municipalityController.text.isEmpty ||
                              _selectedProvince == null) {
                            print('❌ Form validation failed - missing required fields');
                            print('  First name empty: ${_firstNameController.text.isEmpty}');
                            print('  Last name empty: ${_lastNameController.text.isEmpty}');
                            print('  Address empty: ${_addressController.text.isEmpty}');
                            print('  Municipality empty: ${_municipalityController.text.isEmpty}');
                            print('  Province null: ${_selectedProvince == null}');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please fill all required fields')),
                              );
                            }
                            return;
                          }
                          
                          print('✅ Form validation passed');

                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            print('❌ User is null');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Please sign in to place an order')),
                              );
                            }
                            return;
                          }

                          print('✅ User authenticated: ${user.uid}');

                          if (!await _isValidUser(user.uid)) {
                            print('❌ User validation failed');
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

                          print('✅ User validation passed');

                          try {
                            print('🚀 Starting order placement process...');
                            
                            // Reset error state
                            _hasError = false;
                            _errorMessage = '';
                            
                            // Store success message to show after navigation
                            String successMessage = 'Order placed successfully!';

                            for (var item in items) {
                              print('📦 Processing order for item: ${item['name']}');
                              print('Seller ID: $sellerId');
                              print('User ID: ${user.uid}');
                              print('Form data validation:');
                              print('  First name: "${_firstNameController.text}"');
                              print('  Last name: "${_lastNameController.text}"');
                              print('  Address: "${_addressController.text}"');
                              print('  Municipality: "${_municipalityController.text}"');
                              print('  Province: "$_selectedProvince"');
                              print('  Shipping choice: "$_shippingChoice"');
                              
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
                                'cpNumber': _numberController.text,
                                'address': _addressController.text,
                                'municipality': _municipalityController.text,
                                'province': _selectedProvince,
                                'cartDocId': item['cartDocId'],
                                'status': 'Pending',
                                'createdAt': FieldValue.serverTimestamp(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              };

                              print('📝 Creating buyer order...');
                              final orderRef = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('orders')
                                  .add(orderData);
                              print('✅ Buyer order created with ID: ${orderRef.id}');

                              if (sellerId.isNotEmpty) {
                                print('📝 Skipping seller order creation (will be created by seller when they receive notification)');
                                
                                // Calculate total amount
                                double price = 0.0;
                                try {
                                  final priceValue = item['price'];
                                  if (priceValue is String) {
                                    price = double.tryParse(priceValue.replaceAll('₱', '').replaceAll(',', '')) ?? 0.0;
                                  } else if (priceValue is num) {
                                    price = priceValue.toDouble();
                                  }
                                } catch (e) {
                                  price = 0.0;
                                }
                                final totalAmount = price * (item['quantity'] ?? 1);
                                print('💰 Total amount: $totalAmount');
                                
                                print('🔔 Creating buyer notification...');
                                // Buyer notification
                                try {
                                  final buyerNotificationData = {
                                    'userId': user.uid,
                                    'orderId': orderRef.id,
                                    'type': 'order_placed',
                                    'message':
                                        'Your order for ₱${totalAmount.toStringAsFixed(2)} has been placed successfully!',
                                    'isRead': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  };
                                  print('📝 Buyer notification data: $buyerNotificationData');
                                  
                                  await FirebaseFirestore.instance
                                      .collection('notifications')
                                      .add(buyerNotificationData);
                                  print('✅ Buyer notification created successfully');
                                } catch (e) {
                                  print('❌ Error creating buyer notification: $e');
                                  _hasError = true;
                                  _errorMessage = 'Failed to create buyer notification: $e';
                                }
                                
                                print('🔔 Creating seller notification...');
                                try {
                                  final sellerNotificationData = {
                                    'userId': sellerId,
                                    'sellerId': sellerId,
                                    'buyerId': user.uid,
                                    'orderId': orderRef.id,
                                    'type': 'new_order',
                                    'message':
                                        'Your product "${item['name']}" has been ordered for ₱${totalAmount.toStringAsFixed(2)}!',
                                    'isRead': false,
                                    'createdAt': FieldValue.serverTimestamp(),
                                    // Add buyer information for seller notification
                                    'buyerFirstName': _firstNameController.text,
                                    'buyerMiddleName': _middleNameController.text,
                                    'buyerLastName': _lastNameController.text,
                                    'buyerAddress': _addressController.text,
                                    'buyerMunicipality': _municipalityController.text,
                                    'buyerProvince': _selectedProvince,
                                    'productName': item['name'],
                                    'productPrice': item['price'],
                                    'productImage': item['image'],
                                    'quantity': item['quantity'],
                                    'totalAmount': totalAmount,
                                    'buyerCpNumber': _numberController.text,
                                  };
                                  print('📝 Seller notification data: $sellerNotificationData');
                                  
                                  await FirebaseFirestore.instance
                                      .collection('sellers_notification')
                                      .add(sellerNotificationData);
                                  print('✅ Seller notification created successfully');
                                } catch (e) {
                                  print('❌ Error creating seller notification: $e');
                                  _hasError = true;
                                  _errorMessage = 'Failed to create seller notification: $e';
                                }

                                await _sendOrderMessageToSeller(
                                  sellerId: sellerId,
                                  sellerName: sellerName,
                                  productName: item['name'] ?? '',
                                  productPrice: item['price'] ?? '',
                                  quantity: item['quantity'] ?? 1,
                                  customerName: '${_firstNameController.text} ${_lastNameController.text}',
                                  address: _addressController.text,
                                  municipality: _municipalityController.text,
                                  province: _selectedProvince ?? '',
                                  cpNumber: _numberController.text,
                                );
                              } else {
                                print('⚠️ Seller ID is empty, skipping seller order and notifications');
                              }
                            }

                            if (items.length > 1) {
                              final cartItems = await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('cart')
                                  .get();

                              for (var doc in cartItems.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final cartDocId = data['cartDocId'];
                                if (cartDocId != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('cart')
                                      .doc(cartDocId)
                                      .delete();
                                }
                              }
                            }

                            // Close the modal first
                            Navigator.of(context).pop();
                            
                            // Show success/error message after navigation
                            if (mounted) {
                              if (_hasError) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(_errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(successMessage),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            print('❌ Error in order placement: $e');
                            // Close the modal first
                            Navigator.of(context).pop();
                            
                            // Show error message after navigation
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to place order: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
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
                      : Container(
                          width: 90,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
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
              
              // Radio buttons for shipping info choice
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, snapshot) {
                  bool hasSavedInfo = false;
                  String savedFirstName = '';
                  String savedMiddleName = '';
                  String savedLastName = '';
                  String savedCpNumber = '';
                  String savedProvince = '';
                  String savedMunicipality = '';
                  String savedAddress = '';
                  
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final latestOrder = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    savedFirstName = latestOrder['firstName'] ?? '';
                    savedMiddleName = latestOrder['middleName'] ?? '';
                    savedLastName = latestOrder['lastName'] ?? '';
                    savedCpNumber = latestOrder['cpNumber'] ?? '';
                    savedProvince = latestOrder['province'] ?? '';
                    savedMunicipality = latestOrder['municipality'] ?? '';
                    savedAddress = latestOrder['address'] ?? '';
                    
                    hasSavedInfo = savedFirstName.isNotEmpty && savedLastName.isNotEmpty;
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasSavedInfo) ...[
                        const Text(
                          'Choose Shipping Information:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        
                        // Saved information option
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'saved',
                                groupValue: _shippingChoice,
                                onChanged: (value) {
                                  setState(() {
                                    _shippingChoice = value!;
                                    if (value == 'saved') {
                                      _firstNameController.text = savedFirstName;
                                      _middleNameController.text = savedMiddleName;
                                      _lastNameController.text = savedLastName;
                                      _numberController.text = savedCpNumber;
                                      _selectedProvince = savedProvince;
                                      _municipalityController.text = savedMunicipality;
                                      _addressController.text = savedAddress;
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Use Previous Information:',
                                      style: TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$savedFirstName $savedMiddleName $savedLastName, $savedCpNumber, $savedProvince, $savedMunicipality, $savedAddress',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // New information option
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'new',
                                groupValue: _shippingChoice,
                                onChanged: (value) {
                                  setState(() {
                                    _shippingChoice = value!;
                                    if (value == 'new') {
                                      _firstNameController.clear();
                                      _middleNameController.clear();
                                      _lastNameController.clear();
                                      _addressController.clear();
                                      _municipalityController.clear();
                                      _selectedProvince = null;
                                    }
                                  });
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Enter New Information',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        // If no saved info, default to new information
                        const Text(
                          'Enter Shipping Information:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  );
                },
              ),
              
              // Shipping form fields (show if new is selected or no saved info)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('orders')
                    .orderBy('createdAt', descending: true)
                    .limit(1)
                    .snapshots(),
                builder: (context, savedInfoSnapshot) {
                  bool hasSavedInfo = false;
                  if (savedInfoSnapshot.hasData && savedInfoSnapshot.data!.docs.isNotEmpty) {
                    final latestOrder = savedInfoSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final savedFirstName = latestOrder['firstName'] ?? '';
                    final savedLastName = latestOrder['lastName'] ?? '';
                    final savedCpNumber = latestOrder['cpNumber'] ?? '';
                    hasSavedInfo = savedFirstName.isNotEmpty && savedLastName.isNotEmpty;
                  }
                  
                  // Show form fields if new is selected OR if there's no saved info
                  if (_shippingChoice != 'saved' || !hasSavedInfo) {
                    return Column(
                      children: [
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
                        TextField(
                          controller: _numberController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'CONTACT NUMBER',
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
                          onChanged: (value) =>
                              setState(() => _selectedProvince = value),
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
                      ],
                    );
                  } else {
                    // Do not render any hidden or zero-height fields when using saved info
                    return const SizedBox.shrink();
                  }
                },
              ),
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
          print('Cart StreamBuilder - Connection state: ${snapshot.connectionState}');
          print('Cart StreamBuilder - Has data: ${snapshot.hasData}');
          print('Cart StreamBuilder - Has error: ${snapshot.hasError}');
          if (snapshot.hasError) {
            print('Cart StreamBuilder - Error: ${snapshot.error}');
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('Cart StreamBuilder - No cart items found');
            return const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final cartItems = snapshot.data!.docs;
          print('Cart StreamBuilder - Found ${cartItems.length} cart items');
          
          for (var doc in cartItems) {
            final data = doc.data() as Map<String, dynamic>;
            print('Cart item: ${data['name']} - ID: ${doc.id}');
          }

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
                                        backgroundColor: Colors.grey,
                                        child: Icon(Icons.person, color: Colors.white),
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

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .collection('orders')
          .where('status', isNotEqualTo: 'Cancelled')
          .snapshots(),
      builder: (context, snapshot) {
        print('Building product item for cart doc: $docId');
        print('Product name: $name');
        print('Seller ID: $sellerId');
        
        // Check for cart orders first
        var isOrdered = false;
        var orderDocId = '';
        var orderStatus = '';
        
        if (snapshot.hasData) {
          print('Found ${snapshot.data!.docs.length} orders');
          
          // Look for cart order with matching cartDocId
          final cartOrder = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final orderCartDocId = data['cartDocId'];
            print('Checking order cartDocId: $orderCartDocId vs current docId: $docId');
            return orderCartDocId == docId;
          }).toList();
          
          if (cartOrder.isNotEmpty) {
            isOrdered = true;
            orderDocId = cartOrder.first.id;
            orderStatus = cartOrder.first['status'] ?? 'Pending';
            print('Found matching cart order with status: $orderStatus');
          } else {
            // Look for direct order with matching product name and seller
            final directOrder = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final orderProductName = data['productName'];
              final orderSellerId = data['sellerId'];
              print('Checking direct order: $orderProductName vs $name, $orderSellerId vs $sellerId');
              return orderProductName == name && orderSellerId == sellerId;
            }).toList();
            
            if (directOrder.isNotEmpty) {
              isOrdered = true;
              orderDocId = directOrder.first.id;
              orderStatus = directOrder.first['status'] ?? 'Pending';
              print('Found matching direct order with status: $orderStatus');
            }
          }
        }
        
        print('Is ordered: $isOrdered, Status: $orderStatus');
        
        // Auto-remove accepted products from cart ONLY if cartDocId matches
        if (isOrdered && orderStatus == 'Accepted') {
          print('Auto-removing accepted product from cart');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .collection('cart')
                .doc(docId)
                .delete();
          });
          return const SizedBox.shrink(); // Don't show accepted products
        }
        
        print('Displaying product in cart');
        return _buildProductRow(isOrdered, orderDocId, docId, name, price, image, quantity, sellerId, sellerName, sellerContact, user, orderStatus);
      },
    );
  }

  Widget _buildProductRow(
    bool isOrdered,
    String? orderDocId,
    String docId,
    String name,
    String price,
    String image,
    int quantity,
    String sellerId,
    String sellerName,
    String sellerContact,
    User? user,
    String orderStatus,
  ) {
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
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 100,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              )
            : Container(
                width: 100,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image, color: Colors.grey),
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
              // Show status-based buttons
              if (orderStatus == 'Pending') ...[
                SizedBox(
                  width: 90,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: orderDocId != null && orderDocId.isNotEmpty 
                        ? () => _cancelOrder(docId, orderDocId)
                        : null,
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
              ] else if (orderStatus == 'Cancelled') ...[
                // For cancelled orders, show Order and Remove buttons again
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
                // Default case for other statuses (like "Ready to Deliver")
                Container(
                  width: 90,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      orderStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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
    final screenWidth = MediaQuery.of(context).size.width;
    final logoHeight = screenWidth < 480 ? 32.0 : 40.0;
    final toolbarHeight = screenWidth < 480 ? 60.0 : 70.0;
    
    return AppBar(
      backgroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.black),
      elevation: 0,
      toolbarHeight: toolbarHeight,
      leading: IconButton(
        icon: Icon(Icons.menu, size: _getResponsiveIconSize(screenWidth)),
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
              height: logoHeight,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.shopping_bag_outlined, color: Colors.black, size: _getResponsiveIconSize(screenWidth)),
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
          StreamBuilder<List<QuerySnapshot>>(
            stream: CombineLatestStream.list([
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('cart')
                  .snapshots(),
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('orders')
                  .where('status', isNotEqualTo: 'Cancelled')
                  .snapshots(),
            ]),
            builder: (context, snapshot) {
              int cartCount = 0;
              if (snapshot.hasData) {
                final cartItems = snapshot.data![0].docs;
                final orders = snapshot.data![1].docs;
                
                // Filter out cart items that have been ordered
                for (var cartDoc in cartItems) {
                  final cartData = cartDoc.data() as Map<String, dynamic>;
                  final cartDocId = cartDoc.id;
                  final productName = cartData['name'];
                  final sellerId = cartData['sellerId'];
                  
                  // Check if this cart item has been ordered
                  bool isOrdered = false;
                  for (var orderDoc in orders) {
                    final orderData = orderDoc.data() as Map<String, dynamic>;
                    final orderCartDocId = orderData['cartDocId'];
                    final orderProductName = orderData['productName'];
                    final orderSellerId = orderData['sellerId'];
                    final orderStatus = orderData['status'];
                    
                    // Check if this order matches the cart item
                    if ((orderCartDocId == cartDocId) || 
                        (orderProductName == productName && orderSellerId == sellerId)) {
                      if (orderStatus == 'Accepted') {
                        isOrdered = true;
                        break;
                      }
                    }
                  }
                  
                  if (!isOrdered) {
                    cartCount++;
                  }
                }
              }
              
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.shopping_cart_outlined, color: Colors.black, size: _getResponsiveIconSize(screenWidth)),
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
                      right: screenWidth < 480 ? 6 : 8,
                      top: screenWidth < 480 ? 6 : 8,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth < 480 ? 1 : 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(screenWidth < 480 ? 8 : 10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: screenWidth < 480 ? 14 : 16,
                          minHeight: screenWidth < 480 ? 14 : 16,
                        ),
                        child: Text(
                          '$cartCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 480 ? 8 : 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          StreamBuilder<List<QuerySnapshot>>(
            stream: CombineLatestStream.list([
              FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: user.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              FirebaseFirestore.instance
                  .collection('sellers_notification')
                  .where('userId', isEqualTo: user.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
            ]),
            builder: (context, snapshot) {
              int notificationCount = 0;
              if (snapshot.hasData) {
                notificationCount = snapshot.data![0].docs.length + snapshot.data![1].docs.length;
              }
              return Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: Colors.black, size: _getResponsiveIconSize(screenWidth)),
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
                      right: screenWidth < 480 ? 6 : 8,
                      top: screenWidth < 480 ? 6 : 8,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth < 480 ? 1 : 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(screenWidth < 480 ? 8 : 10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: screenWidth < 480 ? 14 : 16,
                          minHeight: screenWidth < 480 ? 14 : 16,
                        ),
                        child: Text(
                          '$notificationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth < 480 ? 8 : 10,
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
            icon: Icon(Icons.person_outline, color: Colors.black, size: _getResponsiveIconSize(screenWidth)),
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

  Future<void> _sendOrderMessageToSeller({
    required String sellerId,
    required String sellerName,
    required String productName,
    required dynamic productPrice,
    required int quantity,
    required String customerName,
    required String address,
    required String municipality,
    required String province,
    String? cpNumber,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final chatParticipants = [user.uid, sellerId]..sort();
    final chatId = chatParticipants.join('_');
    final orderSummary =
        'Order placed: $quantity x $productName for ₱$productPrice.\nContact: ${cpNumber ?? ''}. Shipping to: $customerName, $address, $municipality, $province.';
    print('[OrderChat] Creating chat: $chatId with participants: $chatParticipants (type: \${chatParticipants.runtimeType})');
    // Create or update chat doc
    await FirebaseFirestore.instance.collection('messages').doc(chatId).set({
      'participants': chatParticipants,
      'lastMessage': orderSummary,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).then((_) => print('[OrderChat] Chat doc set for $chatId')).catchError((e) => print('[OrderChat] Error setting chat doc: $e'));
    // Add message
    await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('chats')
        .add({
      'senderId': user.uid,
      'receiverId': sellerId,
      'text': orderSummary,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((doc) => print('[OrderChat] Message sent to $chatId: \${doc.id}')).catchError((e) => print('[OrderChat] Error sending message: $e'));
  }
}