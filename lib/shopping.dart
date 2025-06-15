import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notification.dart';
import 'profile.dart';
import 'selection_screen.dart';
import 'addtocart.dart';
import 'homed.dart';


class ShoppingScreen extends StatefulWidget {
  final String userType; // fisherman, customer, etc

  const ShoppingScreen({Key? key, required this.userType}) : super(key: key);

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  OverlayEntry? _overlayEntry;
  GlobalKey cartIconKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isUploading = false;

  // Cache for seller profile image URLs
  final Map<String, String?> _sellerProfileImageUrlCache = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Fetch the latest uploaded profile picture for a fisherman by userId
  Future<String?> _getFishermanProfileImageUrl(String userId) async {
    if (_sellerProfileImageUrlCache.containsKey(userId)) {
      return _sellerProfileImageUrlCache[userId];
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('profile')
          .doc(userId)
          .collection('profile_pictures')
          .orderBy('uploadedAt', descending: true)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final url = snap.docs.first['url'] as String;
        _sellerProfileImageUrlCache[userId] = url;
        return url;
      }
    } catch (_) {}
    _sellerProfileImageUrlCache[userId] = null;
    return null;
  }

  Future<void> _addToCart({
    required String productName,
    required String productPrice,
    required String productImage,
    required String sellerName,
    required String sellerContact,
    required String sellerId,
    required BuildContext productContext,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to add items to cart')),
      );
      return;
    }

    final productImageRenderBox =
        productContext.findRenderObject() as RenderBox?;
    final cartIconRenderBox =
        cartIconKey.currentContext?.findRenderObject() as RenderBox?;

    if (productImageRenderBox == null || cartIconRenderBox == null) return;

    final productImagePosition =
        productImageRenderBox.localToGlobal(Offset.zero);
    final cartIconPosition = cartIconRenderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            final progress =
                Curves.easeInOut.transform(_animationController.value);
            final currentLeft = productImagePosition.dx +
                (cartIconPosition.dx - productImagePosition.dx) * progress;
            final currentTop = productImagePosition.dy +
                (cartIconPosition.dy - productImagePosition.dy) * progress;
            final currentSize =
                80.0 * (1 - progress * 0.7);

            return Positioned(
              left: currentLeft,
              top: currentTop,
              child: Transform.scale(
                scale: 1 - progress * 0.5,
                child: Opacity(
                  opacity: 1 - progress * 0.5,
                  child: Image.network(
                    productImage,
                    width: currentSize,
                    height: currentSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animationController.reset();
    await _animationController.forward();

    _removeOverlay();

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .where('name', isEqualTo: productName)
          .where('sellerId', isEqualTo: sellerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'quantity': FieldValue.increment(1),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$productName quantity increased')),
        );
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .add({
          'name': productName,
          'price': productPrice,
          'image': productImage,
          'sellerName': sellerName,
          'sellerContact': sellerContact,
          'sellerId': sellerId,
          'quantity': 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$productName added to cart')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add to cart: ${e.toString()}')),
      );
    }
  }

  Future<void> _removeProduct({required String productId}) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove product: ${e.toString()}')),
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
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
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

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => SelectionScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  // UPLOAD PRODUCT
  Future<void> _showUploadDialog() async {
    File? imageFile;
    XFile? xfile;
    String? imageUrl;
    String? productName;
    String? productPrice;

    final picker = ImagePicker();

    // 1. Pick image
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload Product Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Pick from Gallery'),
                onPressed: () async {
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    if (kIsWeb) {
                      xfile = pickedFile;
                    } else {
                      imageFile = File(pickedFile.path);
                    }
                    Navigator.of(context).pop();
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take a Photo'),
                onPressed: () async {
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    if (kIsWeb) {
                      xfile = pickedFile;
                    } else {
                      imageFile = File(pickedFile.path);
                    }
                    Navigator.of(context).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );

    if (!kIsWeb && imageFile == null) return;
    if (kIsWeb && xfile == null) return;
    setState(() => _isUploading = true);

    // 2. Upload to Cloudinary
    try {
      final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/dcrr2wlh8/image/upload');
      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = 'product_upload';

      if (kIsWeb) {
        final bytes = await xfile!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: xfile!.name,
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            imageFile!.path,
          ),
        );
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final data = json.decode(resStr);
        imageUrl = data['secure_url'];
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
      return;
    }

    // 3. Name and Price Dialog
    await showDialog(
      context: context,
      builder: (context) {
        String tempName = '';
        String tempPrice = '';
        return AlertDialog(
          title: const Text('Enter Product Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                ),
                onChanged: (value) => tempName = value,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Price',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) => tempPrice = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                productName = tempName;
                productPrice = tempPrice;
                Navigator.of(context).pop();
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    if (productName == null || productPrice == null || productName!.isEmpty || productPrice!.isEmpty) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product details are required.')),
      );
      return;
    }

    // 4. Store to Firestore
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Not logged in");

      final fishermanDocSnap = await FirebaseFirestore.instance.collection('fisherman').doc(user.uid).get();

      if (!fishermanDocSnap.exists) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your fisherman profile is missing. Please complete your profile before uploading products.')),
        );
        return;
      }

      final fishermanData = fishermanDocSnap.data()!;
      await FirebaseFirestore.instance.collection('products').add({
        'name': productName,
        'price': productPrice,
        'image': imageUrl,
        'sellerName': (fishermanData['firstName'] ?? '') + ' ' + (fishermanData['lastName'] ?? ''),
        'sellerContact': fishermanData['cpNumber'] ?? '',
        'sellerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload product: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildProductCard(
    BuildContext context, {
    required String image,
    required String name,
    required String price,
    required String sellerName,
    required String sellerContact,
    required String sellerId,
    String? sellerProfileUrl,
    required bool isMine,
    required String productId,
  }) {
    final productImageKey = GlobalKey();

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
          Row(
            children: [
              (sellerProfileUrl != null && sellerProfileUrl.isNotEmpty)
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(sellerProfileUrl),
                    )
                  : const CircleAvatar(
                      radius: 20,
                    ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    sellerContact,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                key: productImageKey,
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(width: 100, height: 80, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  isMine
                      ? ElevatedButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Remove Product'),
                                content: const Text('Are you sure you want to remove this product?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              _removeProduct(productId: productId);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 35),
                          ),
                          child: const Text("Remove"),
                        )
                      : ElevatedButton(
                          onPressed: () => _addToCart(
                            productName: name,
                            productPrice: price,
                            productImage: image,
                            sellerName: sellerName,
                            sellerContact: sellerContact,
                            sellerId: sellerId,
                            productContext: productImageKey.currentContext!,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 35),
                          ),
                          child: const Text("Add to Cart"),
                        ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
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
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('cart')
                  .snapshots(),
              builder: (context, snapshot) {
                int cartCount = snapshot.data?.docs.length ?? 0;
                return Stack(
                  key: cartIconKey,
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
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No products available.'));
                      }
                      final currentUser = FirebaseAuth.instance.currentUser;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final isMine = currentUser != null && currentUser.uid == doc['sellerId'];
                          return FutureBuilder<String?>(
                            future: _getFishermanProfileImageUrl(doc['sellerId']),
                            builder: (context, profileSnapshot) {
                              return _buildProductCard(
                                context,
                                image: doc['image'],
                                name: doc['name'],
                                price: doc['price'],
                                sellerName: doc['sellerName'],
                                sellerContact: doc['sellerContact'],
                                sellerId: doc['sellerId'],
                                sellerProfileUrl: profileSnapshot.data,
                                isMine: isMine,
                                productId: doc.id,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (widget.userType == 'fisherman')
            Positioned(
              bottom: 24,
              right: 24,
              child: IgnorePointer(
                ignoring: _isUploading,
                child: FloatingActionButton.extended(
                  heroTag: 'upload_button',
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload'),
                  onPressed: _isUploading ? null : _showUploadDialog,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          if (_isUploading)
            const Positioned(
              bottom: 100,
              right: 36,
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}