import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'addtocart.dart';

class ProductScreen extends StatelessWidget {
  // If fishermanId is passed, show vendor products, else show current user products
  final String? fishermanId;
  final bool forVendor;
  final String fishermanName;

  const ProductScreen({
    super.key,
    this.fishermanId,
    this.forVendor = false,
    this.fishermanName = '',
  });

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
    if (width < 480) return 45.0;
    if (width < 768) return 50.0;
    if (width < 1024) return 55.0;
    return 60.0;
  }

  double _getResponsiveButtonHeight(double width) {
    if (width < 480) return 32.0;
    if (width < 768) return 35.0;
    if (width < 1024) return 38.0;
    return 40.0;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final spacing = _getResponsiveSpacing(screenWidth);
    final padding = _getResponsivePadding(screenWidth);
    final fontSize = _getResponsiveFontSize(screenWidth);
    final iconSize = _getResponsiveIconSize(screenWidth);
    final imageSize = _getResponsiveImageSize(screenWidth);
    final buttonHeight = _getResponsiveButtonHeight(screenWidth);
    final toolbarHeight = screenWidth < 480 ? 60.0 : 70.0;

    // If not vendor mode, check user login
    if (!forVendor && user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Products',
            style: TextStyle(fontSize: fontSize),
          ),
          toolbarHeight: toolbarHeight,
        ),
        body: Center(
          child: Text(
            'Not logged in',
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      );
    }

    // Determine whose products to show
    final showUid = forVendor ? fishermanId : user!.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3A4A6C),
        foregroundColor: Colors.white,
        title: Text(
          forVendor
              ? (fishermanName.isNotEmpty
                  ? "$fishermanName's Products"
                  : "Vendor's Products")
              : "My Products",
          style: TextStyle(fontSize: fontSize + 2, color: Colors.white),
        ),
        toolbarHeight: toolbarHeight,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: showUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: Colors.red, fontSize: fontSize),
                ));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(
                  forVendor
                      ? 'No products found for this vendor.'
                      : 'No products uploaded.',
                  style: TextStyle(fontSize: fontSize),
                ));
          }
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(padding),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              Widget leadingWidget;
              if (data['image'] != null &&
                  data['image'] is String &&
                  (data['image'] as String).isNotEmpty) {
                leadingWidget = Image.network(
                  data['image'],
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.broken_image, size: imageSize - 10),
                );
              } else {
                leadingWidget = Icon(Icons.image, size: imageSize - 10);
              }

              return Card(
                margin: EdgeInsets.symmetric(horizontal: padding, vertical: spacing * 0.5),
                child: ListTile(
                  leading: leadingWidget,
                  title: Text(
                    data['name']?.toString() ?? 'No Name',
                    style: TextStyle(fontSize: fontSize),
                  ),
                  subtitle: Text(
                    '₱${data['price']?.toString() ?? ''}',
                    style: TextStyle(fontSize: fontSize - 2),
                  ),
                  trailing: forVendor
                      ? SizedBox(
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () {
                              // Go to AddToCart and prefill details for single product order
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddToCart(
                                    userType: 'customer',
                                    initialOrder: {
                                      'name': data['name'] ?? '',
                                      'price': data['price'] ?? '',
                                      'image': data['image'] ?? '',
                                      'sellerId': data['sellerId'] ?? '',
                                      'sellerName': data['sellerName'] ?? '',
                                      'sellerContact': data['sellerContact'] ?? '',
                                      'quantity': 1,
                                    },
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3A4A6C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              'Order',
                              style: TextStyle(
                                fontSize: fontSize - 4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )
                      : IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: iconSize),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Remove Product',
                                  style: TextStyle(fontSize: fontSize),
                                ),
                                content: Text(
                                  'Are you sure you want to remove this product?',
                                  style: TextStyle(fontSize: fontSize - 2),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(fontSize: fontSize - 2),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                      'Remove',
                                      style: TextStyle(fontSize: fontSize - 2),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await FirebaseFirestore.instance
                                  .collection('products')
                                  .doc(docs[index].id)
                                  .delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Product removed',
                                    style: TextStyle(fontSize: fontSize - 2),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}