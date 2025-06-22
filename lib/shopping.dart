import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'notification.dart';
import 'profile.dart';
import 'selection_screen.dart';
import 'addtocart.dart';
import 'homed.dart';
import 'package:rxdart/rxdart.dart';


class ShoppingScreen extends StatefulWidget {
  final String userType; // fisherman, customer, etc

  const ShoppingScreen({super.key, required this.userType});

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (_) => const SelectionScreen()),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = _getResponsiveImageSize(screenWidth);
    final spacing = _getResponsiveSpacing(screenWidth);
    final padding = _getResponsivePadding(screenWidth);
    final fontSize = _getResponsiveFontSize(screenWidth);
    final buttonHeight = _getResponsiveButtonHeight(screenWidth);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 12.0);

    return Container(
      margin: EdgeInsets.only(bottom: spacing),
      padding: EdgeInsets.all(padding),
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
                      radius: screenWidth < 480 ? 18 : 20,
                      backgroundImage: NetworkImage(sellerProfileUrl),
                    )
                  : CircleAvatar(
                      radius: screenWidth < 480 ? 18 : 20,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: _getResponsiveIconSize(screenWidth) - 8),
                    ),
              SizedBox(width: spacing * 0.8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sellerName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize - 2,
                      ),
                    ),
                    Text(
                      sellerContact,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: fontSize - 4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                key: productImageKey,
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  image,
                  width: imageSize,
                  height: imageSize * 0.8,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Container(
                        width: imageSize,
                        height: imageSize * 0.8,
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image, size: _getResponsiveIconSize(screenWidth)),
                      ),
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                    Text(
                      price,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: fontSize - 2,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  isMine
                      ? Container(
                          width: screenWidth < 480 ? 100 : 120,
                          height: buttonHeight,
                          child: ElevatedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Remove Product', style: TextStyle(fontSize: fontSize)),
                                  content: Text('Are you sure you want to remove this product?', style: TextStyle(fontSize: fontSize - 2)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancel', style: TextStyle(fontSize: fontSize - 2)),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text('Remove', style: TextStyle(fontSize: fontSize - 2)),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              "Remove", 
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : Container(
                          width: screenWidth < 480 ? 120 : 140,
                          height: buttonHeight,
                          child: ElevatedButton(
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
                              backgroundColor: const Color(0xFF3A4A6C),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              "Add To Cart", 
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final logoHeight = screenWidth < 480 ? 32.0 : 40.0;
    final toolbarHeight = screenWidth < 480 ? 60.0 : 70.0;
    final bodyPadding = _getResponsivePadding(screenWidth);
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      appBar: AppBar(
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
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('cart')
                    .snapshots(),
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
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
                  key: cartIconKey,
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
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                FirebaseFirestore.instance
                    .collection('sellers_notification')
                    .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
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
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(bodyPadding),
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
                        return Center(
                          child: Text(
                            'No products available.',
                            style: TextStyle(fontSize: _getResponsiveFontSize(screenWidth, baseSize: 18.0)),
                          ),
                        );
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
              bottom: screenWidth < 480 ? 16 : 24,
              right: screenWidth < 480 ? 16 : 24,
              child: IgnorePointer(
                ignoring: _isUploading,
                child: FloatingActionButton.extended(
                  heroTag: 'upload_button',
                  icon: Icon(Icons.upload, size: _getResponsiveIconSize(screenWidth)),
                  label: Text('Upload', style: TextStyle(fontSize: _getResponsiveFontSize(screenWidth, baseSize: 14.0))),
                  onPressed: _isUploading ? null : _showUploadDialog,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          if (_isUploading)
            Positioned(
              bottom: screenWidth < 480 ? 80 : 100,
              right: screenWidth < 480 ? 28 : 36,
              child: CircularProgressIndicator(
                strokeWidth: screenWidth < 480 ? 2 : 3,
              ),
            ),
        ],
      ),
    );
  }
}