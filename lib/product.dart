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
    Key? key,
    this.fishermanId,
    this.forVendor = false,
    this.fishermanName = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // If not vendor mode, check user login
    if (!forVendor && user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Products')),
        body: const Center(child: Text('Not logged in')),
      );
    }

    // Determine whose products to show
    final showUid = forVendor ? fishermanId : user!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          forVendor
              ? (fishermanName.isNotEmpty
                  ? "$fishermanName's Products"
                  : "Vendor's Products")
              : "My Products",
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: showUid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text(forVendor
                    ? 'No products found for this vendor.'
                    : 'No products uploaded.'));
          }
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              Widget leadingWidget;
              if (data['image'] != null &&
                  data['image'] is String &&
                  (data['image'] as String).isNotEmpty) {
                leadingWidget = Image.network(
                  data['image'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 40),
                );
              } else {
                leadingWidget = const Icon(Icons.image, size: 40);
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: leadingWidget,
                  title: Text(data['name']?.toString() ?? 'No Name'),
                  subtitle: Text('₱${data['price']?.toString() ?? ''}'),
                  trailing: forVendor
                      ? ElevatedButton(
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
                          child: const Text('Order'),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove Product'),
                                content: const Text(
                                    'Are you sure you want to remove this product?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Remove'),
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
                                const SnackBar(
                                    content: Text('Product removed')),
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