import 'package:flutter/material.dart';
import 'product.dart';
import 'developer.dart';

class VendorProfileScreen extends StatelessWidget {
  final String fishermanId;
  final String? fishermanName;
  final String? profileImageUrl;

  const VendorProfileScreen({
    Key? key,
    required this.fishermanId,
    this.fishermanName,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF7A9BAE),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(fishermanName ?? 'Fisherman Profile', 
        style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          CircleAvatar(
            radius: 50,
            backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty)
                ? NetworkImage(profileImageUrl!)
                : null,
            child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                ? const Icon(Icons.person, size: 50)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            fishermanName ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2),
                  title: const Text('My Products'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductScreen(
                          fishermanId: fishermanId,
                          forVendor: true,
                          fishermanName: fishermanName ?? '',
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Developer Details'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DeveloperScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}