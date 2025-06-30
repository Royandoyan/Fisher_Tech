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

  // Ocean/Fisherman themed gradients
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A8A), // Deep ocean blue
      Color(0xFF3B82F6), // Ocean blue
      Color(0xFF0EA5E9), // Sky blue
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
        body: Container(
          decoration: const BoxDecoration(gradient: oceanGradient),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: cardGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                'Please sign in to view your products',
                style: TextStyle(
                  fontSize: fontSize,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Determine whose products to show
    final showUid = forVendor ? fishermanId : user!.uid;

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
                  padding: EdgeInsets.symmetric(horizontal: padding, vertical: spacing),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white, size: iconSize),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          forVendor
                              ? (fishermanName.isNotEmpty
                                  ? "$fishermanName's Products"
                                  : "Vendor's Products")
                              : "My Products",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: fontSize + 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: iconSize + 8), // Balance the back button
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
                      .collection('products')
                      .where('sellerId', isEqualTo: showUid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: cardGradient,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(color: Colors.red, fontSize: fontSize),
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                                child: const Icon(Icons.inventory_2, size: 60, color: Colors.white),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                forVendor
                                    ? 'No products found for this vendor.'
                                    : 'No products uploaded.',
                                style: TextStyle(
                                  fontSize: fontSize + 2,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
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
                          leadingWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              data['image'],
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: imageSize,
                                    height: imageSize,
                                    decoration: BoxDecoration(
                                      gradient: cardGradient,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.broken_image, size: imageSize - 10, color: Colors.grey),
                                  ),
                            ),
                          );
                        } else {
                          leadingWidget = Container(
                            width: imageSize,
                            height: imageSize,
                            decoration: BoxDecoration(
                              gradient: cardGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.image, size: imageSize - 10, color: Colors.grey),
                          );
                        }

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: padding, vertical: spacing * 0.5),
                          decoration: BoxDecoration(
                            gradient: cardGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(spacing),
                            leading: leadingWidget,
                            title: Text(
                              data['name']?.toString() ?? 'No Name',
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '₱${data['price']?.toString() ?? ''}',
                              style: TextStyle(
                                fontSize: fontSize - 2,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: forVendor
                                ? Container(
                                    height: buttonHeight,
                                    decoration: BoxDecoration(
                                      gradient: buttonGradient,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
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
                                        backgroundColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Order',
                                        style: TextStyle(
                                          fontSize: fontSize - 4,
                                          fontWeight: FontWeight.w600,
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
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
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
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: buttonGradient,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: ElevatedButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,
                                                ),
                                                child: Text(
                                                  'Remove',
                                                  style: TextStyle(
                                                    fontSize: fontSize - 2,
                                                    color: Colors.white,
                                                  ),
                                                ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}