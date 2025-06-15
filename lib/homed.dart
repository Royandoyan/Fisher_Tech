import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'addtocart.dart';
import 'shopping.dart';
import 'notification.dart';
import 'vendor_profile.dart';
import 'profile.dart';
import 'selection_screen.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android
import 'package:webview_flutter_android/webview_flutter_android.dart';
// Import for iOS
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class HomePage extends StatefulWidget {
  final String userType;

  const HomePage({super.key, required this.userType});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // For controlling upload dialog
  final TextEditingController _titleController = TextEditingController();

  // For search functionality
  final TextEditingController _mainSearchController = TextEditingController();
  String _mainSearchText = '';

  // For storing selected file info
  PlatformFile? _selectedFile;
  String? _uploadType; // 'file' or 'video'

  // Collections
  final String filesCollection = 'files';
  final String videosCollection = 'videos';

  // For fisherman profile image cache
  final Map<String, String?> _fishermanProfileImageUrlCache = {};

// Responsive grid count helper
  int _getGridColumnCount(double width) {
    if (width < 600) return 1;
    if (width < 900) return 2;
    if (width < 1400) return 3;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _mainSearchController.addListener(() {
      setState(() {
        _mainSearchText = _mainSearchController.text.trim().toLowerCase();
      });
    });
  }

  Future<String?> _getFishermanProfileImageUrl(String userId) async {
    if (_fishermanProfileImageUrlCache.containsKey(userId)) {
      return _fishermanProfileImageUrlCache[userId];
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
        _fishermanProfileImageUrlCache[userId] = url;
        return url;
      }
    } catch (_) {}
    _fishermanProfileImageUrlCache[userId] = null;
    return null;
  }

  // Open file picker for docs or videos
  Future<void> _pickFile(String type) async {
    _uploadType = type;

    FileType pickType = FileType.any;
    List<String>? allowedExtensions;

    if (type == 'file') {
      allowedExtensions = [
        'pdf',
        'doc',
        'docx',
        'txt',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'rtf',
        'odt'
      ];
      pickType = FileType.custom;
    } else if (type == 'video') {
      pickType = FileType.video;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: pickType,
        allowMultiple: false,
        allowedExtensions: type == 'file' ? allowedExtensions : null,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });

        _titleController.clear();
        _showUploadDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: ${e.toString()}')),
      );
      debugPrint('File picking error: $e');
    }
  }

  // Show dialog to input title/purpose then upload
  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload ${_uploadType == 'file' ? 'Document' : 'Video'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Selected file: ${_selectedFile?.name ?? ''}'),
            const SizedBox(height: 10),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title / Purpose',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedFile = null;
                _titleController.clear();
                _uploadType = null;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = _titleController.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a title')),
                );
                return;
              }
              Navigator.pop(context);
              _uploadFile(title);
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  // Enhanced Cloudinary upload with web/mobile support
  Future<String?> _uploadToCloudinary({
    required String fileName,
    required Uint8List fileBytes,
    bool isVideo = false,
    bool isDocument = false,
  }) async {
    const String cloudName = 'dvkzio03x';
    const String uploadPreset = 'flutter_upload';
    const String apiKey = '944258497648494';

    // Determine resource type
    String resourceType = 'auto';
    if (isVideo) resourceType = 'video';
    if (isDocument) resourceType = 'raw';

    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/$resourceType/upload');

    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', url);

      // Add file to request
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

      // Add other fields
      request.fields.addAll({
        'upload_preset': uploadPreset,
        'api_key': apiKey,
      });

      // Send request
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);
      var jsonResponse = jsonDecode(responseString);

      if (response.statusCode == 200) {
        return jsonResponse['secure_url'] as String?;
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode}');
        debugPrint('Response: $responseString');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<void> _uploadFile(String title) async {
    if (_selectedFile == null) return;

    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('User not logged in')));
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get file bytes - different approach for web vs mobile
      Uint8List fileBytes;
      if (kIsWeb) {
        // Web: use bytes directly
        fileBytes = _selectedFile!.bytes!;
      } else {
        // Mobile: read from file path
        if (_selectedFile!.path == null) {
          throw Exception('File path is null');
        }
        final file = File(_selectedFile!.path!);
        fileBytes = await file.readAsBytes();
      }

      final extension = p.extension(_selectedFile!.name).toLowerCase();

      // Define supported document types
      final documentExtensions = [
        '.pdf',
        '.doc',
        '.docx',
        '.txt',
        '.xls',
        '.xlsx',
        '.ppt',
        '.pptx',
        '.rtf',
        '.odt'
      ];
      final videoExtensions = ['.mp4', '.mov', '.avi', '.mkv'];

      // Validate file type
      if (!documentExtensions.contains(extension) &&
          !videoExtensions.contains(extension)) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported file type')),
        );
        return;
      }

      // Determine file type
      final isVideoFile = videoExtensions.contains(extension);
      final isDocumentFile = documentExtensions.contains(extension);

      // Upload to Cloudinary - documents as raw, videos as video
      final url = await _uploadToCloudinary(
        fileName: _selectedFile!.name,
        fileBytes: fileBytes,
        isVideo: isVideoFile,
        isDocument: isDocumentFile,
      );

      if (url == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload file')),
        );
        return;
      }

      // Prepare metadata
      final metadata = {
        'name': _selectedFile!.name,
        'size': _selectedFile!.size,
        'extension': extension,
        'url': url,
        'type': isVideoFile ? 'video' : 'document',
        'viewable': isDocumentFile,
        'mimeType': _getMimeType(extension),
        'uploadDate': DateTime.now().toIso8601String(),
      };

      // Save to appropriate Firestore collection
      final collectionName = isVideoFile ? videosCollection : filesCollection;
      final fileType = isVideoFile ? 'video' : 'document';

      await _firestore.collection(collectionName).add({
        'email': user.email,
        'uid': user.uid,
        'metadata': metadata,
        'title': title,
        'timestamp': FieldValue.serverTimestamp(),
        'fileType': fileType,
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${isVideoFile ? 'Video' : 'Document'} uploaded successfully!'),
        ),
      );

      // Reset state
      setState(() {
        _selectedFile = null;
        _titleController.clear();
        _uploadType = null;
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('Upload error: $e');
    }
  }

  // Helper function to get MIME type from extension
  String _getMimeType(String extension) {
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      case '.odt':
        return 'application/vnd.oasis.opendocument.text';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }

  // Open file or video in app
  void _openInAppViewer(String url, String extension, String title) async {
    final lowerExtension = extension.toLowerCase();

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      if (['.mp4', '.mov', '.avi', '.mkv']
          .any((ext) => lowerExtension.contains(ext))) {
        // Handle videos
        Navigator.pop(context); // Remove loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                _InAppVideoPlayer(videoUrl: url, title: title),
          ),
        );
      } else if (lowerExtension.contains('.pdf')) {
        // Handle PDFs
        Navigator.pop(context); // Remove loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(pdfUrl: url, title: title),
          ),
        );
      } else {
        // Handle other document types (Word, Excel, etc.)
        Navigator.pop(context); // Remove loading dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DocumentWebView(
              fileUrl: url,
              title: title,
              mimeType: _getMimeType(extension),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Remove loading dialog if still showing
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open file: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint('File opening error: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SelectionScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      debugPrint('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _mainSearchController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F8FB),
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Image.asset('assets/images/logo.png', height: 40),
        centerTitle: false,
        toolbarHeight: 70,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
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
          const SizedBox(width: 10),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gridCount = _getGridColumnCount(constraints.maxWidth);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SINGLE SEARCH BAR FOR ALL
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _mainSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Search Files, Video, or Fisherman ...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),

                // ------ SLIDE INFORMATION -------
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Slide Information',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (widget.userType == 'fisherman')
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Colors.deepPurple, size: 28),
                              onPressed: () => _pickFile('file'),
                              tooltip: 'Upload Document',
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection(filesCollection)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No documents uploaded yet'),
                            );
                          }
                          // ALWAYS lower-case for both field and searchText!
                          final docs = snapshot.data!.docs.where((doc) {
                            final data = doc.data()! as Map<String, dynamic>;
                            final title =
                                (data['title'] ?? '').toString().toLowerCase();
                            return _mainSearchText.isEmpty ||
                                title.contains(_mainSearchText);
                          }).toList();

                          if (docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No documents found for this search'),
                            );
                          }
                          if (gridCount == 1) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: docs.map((doc) {
                                  final data =
                                      doc.data()! as Map<String, dynamic>;
                                  final title =
                                      (data['title'] ?? 'No Title').toString();
                                  final metadata = data['metadata'] ?? {};
                                  final url = metadata['url'] ?? '';
                                  final extension = metadata['extension'] ?? '';
                                  final isVideo =
                                      extension.toString().contains('.mp4') ||
                                          extension.toString().contains('.mov');
                                  return GestureDetector(
                                    onTap: () async {
                                      String viewerUrl;
                                      if (extension == '.pdf') {
                                        viewerUrl =
                                            'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
                                      } else if ([
                                        '.doc',
                                        '.docx',
                                        '.xls',
                                        '.xlsx',
                                        '.ppt',
                                        '.pptx'
                                      ].contains(extension)) {
                                        viewerUrl =
                                            'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(url)}';
                                      } else {
                                        viewerUrl = url;
                                      }
                                      final uri = Uri.parse(viewerUrl);
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri,
                                            mode:
                                                LaunchMode.externalApplication);
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Could not launch document')),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 120,
                                      height: 160,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.deepPurple.shade100),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            isVideo
                                                ? Icons.videocam
                                                : Icons.insert_drive_file,
                                            size: 48,
                                            color: Colors.deepPurple,
                                          ),
                                          const SizedBox(height: 10),
                                          Flexible(
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          } else {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: docs.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemBuilder: (context, index) {
                                final doc = docs[index];
                                final data =
                                    doc.data()! as Map<String, dynamic>;
                                final title =
                                    (data['title'] ?? 'No Title').toString();
                                final metadata = data['metadata'] ?? {};
                                final url = metadata['url'] ?? '';
                                final extension = metadata['extension'] ?? '';
                                final isVideo =
                                    extension.toString().contains('.mp4') ||
                                        extension.toString().contains('.mov');
                                return GestureDetector(
                                  onTap: () async {
                                    String viewerUrl;
                                    if (extension == '.pdf') {
                                      viewerUrl =
                                          'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
                                    } else if ([
                                      '.doc',
                                      '.docx',
                                      '.xls',
                                      '.xlsx',
                                      '.ppt',
                                      '.pptx'
                                    ].contains(extension)) {
                                      viewerUrl =
                                          'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(url)}';
                                    } else {
                                      viewerUrl = url;
                                    }
                                    final uri = Uri.parse(viewerUrl);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Could not launch document')),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: Colors.deepPurple.shade100),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isVideo
                                              ? Icons.videocam
                                              : Icons.insert_drive_file,
                                          size: 48,
                                          color: Colors.deepPurple,
                                        ),
                                        const SizedBox(height: 10),
                                        Flexible(
                                          child: Text(
                                            title,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // ------ VIDEO TUTORIALS -------
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Video Tutorials',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (widget.userType == 'fisherman')
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Colors.deepPurple, size: 28),
                              onPressed: () => _pickFile('video'),
                              tooltip: 'Upload Video',
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection(videosCollection)
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No videos uploaded yet'),
                            );
                          }
                          final videos = snapshot.data!.docs.where((doc) {
                            final data = doc.data()! as Map<String, dynamic>;
                            final title =
                                (data['title'] ?? '').toString().toLowerCase();
                            return _mainSearchText.isEmpty ||
                                title.contains(_mainSearchText);
                          }).toList();

                          if (videos.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No videos found for this search'),
                            );
                          }
                          if (gridCount == 1) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: videos.map((doc) {
                                  final data =
                                      doc.data()! as Map<String, dynamic>;
                                  final title =
                                      (data['title'] ?? 'No Title').toString();
                                  final metadata = data['metadata'] ?? {};
                                  final url = metadata['url'] ?? '';
                                  return GestureDetector(
                                    onTap: () =>
                                        _openInAppViewer(url, '.mp4', title),
                                    child: Container(
                                      width: 120,
                                      height: 160,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.play_circle_fill,
                                              size: 60,
                                              color: Colors.deepPurple),
                                          const SizedBox(height: 8),
                                          Flexible(
                                            child: Text(
                                              title,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          } else {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: videos.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: gridCount,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemBuilder: (context, index) {
                                final doc = videos[index];
                                final data =
                                    doc.data()! as Map<String, dynamic>;
                                final title =
                                    (data['title'] ?? 'No Title').toString();
                                final metadata = data['metadata'] ?? {};
                                final url = metadata['url'] ?? '';
                                return GestureDetector(
                                  onTap: () =>
                                      _openInAppViewer(url, '.mp4', title),
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                      color: Colors.grey.shade100,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.play_circle_fill,
                                            size: 60, color: Colors.deepPurple),
                                        const SizedBox(height: 8),
                                        Flexible(
                                          child: Text(
                                            title,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w500),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                // ------ FISHERMAN PROFILES -------
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fisherman Profiles',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('fisherman').snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            debugPrint(
                                'Fisherman query error: ${snapshot.error}');
                            return Text('Error: ${snapshot.error}');
                          }
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            debugPrint('No fisherman documents found');
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No fisherman profiles available'),
                            );
                          }
                          final fishermen = snapshot.data!.docs.where((doc) {
                            final data = doc.data()! as Map<String, dynamic>;
                            final firstName = (data['firstName'] ?? '')
                                .toString()
                                .toLowerCase();
                            final lastName = (data['lastName'] ?? '')
                                .toString()
                                .toLowerCase();
                            final fullName = '$firstName $lastName';
                            return _mainSearchText.isEmpty ||
                                firstName.contains(_mainSearchText) ||
                                lastName.contains(_mainSearchText) ||
                                fullName.contains(_mainSearchText);
                          }).toList();

                          if (fishermen.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No fisherman found for this search'),
                            );
                          }

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: fishermen.map((doc) {
                                final data =
                                    doc.data()! as Map<String, dynamic>;
                                final userId = doc.id;
                                final firstName =
                                    (data['firstName'] ?? 'No First Name')
                                        .toString();
                                final lastName =
                                    (data['lastName'] ?? 'No Last Name')
                                        .toString();
                                final address =
                                    (data['address'] ?? 'No Address')
                                        .toString();
                                final fullName = '$firstName $lastName';
                                return FutureBuilder<String?>(
                                  future: _getFishermanProfileImageUrl(userId),
                                  builder: (context, profileSnapshot) {
                                    return Container(
                                      width: 140,
                                      height: 180,
                                      margin: const EdgeInsets.only(right: 16),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.blue.shade100),
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                                          String? profileUrl =
                                              profileSnapshot.data;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  VendorProfileScreen(
                                                fishermanId: userId,
                                                fishermanName: fullName,
                                                profileImageUrl: profileUrl,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            profileSnapshot.connectionState ==
                                                        ConnectionState.done &&
                                                    profileSnapshot.data !=
                                                        null &&
                                                    profileSnapshot
                                                        .data!.isNotEmpty
                                                ? CircleAvatar(
                                                    radius: 28,
                                                    backgroundImage:
                                                        NetworkImage(
                                                            profileSnapshot
                                                                .data!),
                                                  )
                                                : const CircleAvatar(
                                                    radius: 28,
                                                  ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 38,
                                              child: Center(
                                                child: Text(
                                                  fullName,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            SizedBox(
                                              height: 30,
                                              child: Center(
                                                child: Text(
                                                  address,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Drawer and logo methods remain unchanged

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
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/coastguard.png',
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
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/map.png',
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
                const SizedBox(height: 30),
                _buildLogoItem(
                  image: 'assets/images/firestation.png',
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
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({required this.pdfUrl, required this.title});

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localPath;
  bool _isLoading = true;
  String? _errorMessage;
  final Dio _dio = Dio();
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      // First verify the URL is accessible
      final headResponse = await _dio.head(widget.pdfUrl);
      if (headResponse.statusCode == 401) {
        throw Exception('Authentication required - check Cloudinary settings');
      }

      // Try to get from cache
      final file = await _cacheManager.getSingleFile(
        widget.pdfUrl,
        headers: {'Accept': 'application/pdf'},
      );

      if (await file.exists()) {
        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
        return;
      }

      // If not in cache, download with proper headers
      final response = await _dio.get(
        widget.pdfUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file =
            File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(response.data as List<int>);

        setState(() {
          _localPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF: Status ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load PDF: ${e.toString()}';
        _isLoading = false;
      });
      debugPrint('PDF loading error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_localPath != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () => OpenFilex.open(_localPath!),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPdf,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPdf,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: 0,
      fitPolicy: FitPolicy.BOTH,
      onError: (error) {
        setState(() {
          _errorMessage = 'PDF rendering error: $error';
        });
      },
    );
  }
}

class _InAppVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const _InAppVideoPlayer({required this.videoUrl, required this.title});

  @override
  State<_InAppVideoPlayer> createState() => _InAppVideoPlayerState();
}

class _InAppVideoPlayerState extends State<_InAppVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    _videoController = VideoPlayerController.network(widget.videoUrl);
    await _videoController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController.value.aspectRatio,
      placeholder: Container(color: Colors.grey),
    );

    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF7A9BAE),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: _isInitialized
            ? Chewie(controller: _chewieController!)
            : const CircularProgressIndicator(),
      ),
    );
  }
}

// New WebView for document viewing
class DocumentWebView extends StatefulWidget {
  final String fileUrl;
  final String title;
  final String mimeType;

  const DocumentWebView({
    required this.fileUrl,
    required this.title,
    required this.mimeType,
    Key? key,
  }) : super(key: key);

  @override
  State<DocumentWebView> createState() => _DocumentWebViewState();
}

class _DocumentWebViewState extends State<DocumentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _webViewInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    if (kIsWeb) {
      // For web platform, we'll handle it differently
      setState(() {
        _webViewInitialized = true;
        _isLoading = false;
      });
      return;
    }

    // Mobile WebView initialization (unchanged)
    try {
      late final PlatformWebViewControllerCreationParams params;

      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      if (controller.platform is AndroidWebViewController) {
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);

      controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('Loading: $progress%');
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
              WebView error:
              code: ${error.errorCode}
              description: ${error.description}
            ''');
            setState(() => _isLoading = false);
          },
        ),
      );

      // Handle different document types
      if (widget.fileUrl.contains('.pdf')) {
        await controller.loadRequest(
          Uri.parse(
              'https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(widget.fileUrl)}'),
        );
      } else if (widget.mimeType.contains('word') ||
          widget.mimeType.contains('excel') ||
          widget.mimeType.contains('powerpoint')) {
        await controller.loadRequest(
          Uri.parse(
              'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeFull(widget.fileUrl)}'),
        );
      } else {
        await controller.loadRequest(Uri.parse(widget.fileUrl));
      }

      setState(() {
        _controller = controller;
        _webViewInitialized = true;
      });
    } catch (e) {
      debugPrint('WebView initialization error: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getViewerUrl() {
    if (widget.fileUrl.contains('.pdf')) {
      return 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(widget.fileUrl)}';
    } else if (widget.mimeType.contains('word') ||
        widget.mimeType.contains('excel') ||
        widget.mimeType.contains('powerpoint') ||
        widget.mimeType.contains('officedocument')) {
      return 'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeFull(widget.fileUrl)}';
    } else {
      return 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeFull(widget.fileUrl)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () {
              if (kIsWeb) {
                launchUrl(Uri.parse(widget.fileUrl),
                    mode: LaunchMode.externalApplication);
              } else {
                OpenFilex.open(widget.fileUrl);
              }
            },
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () => launchUrl(Uri.parse(_getViewerUrl()),
                  mode: LaunchMode.externalApplication),
              tooltip: 'Open in Full Screen',
            ),
        ],
      ),
      body: kIsWeb
          ? _buildWebViewer()
          : (!_webViewInitialized
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    WebViewWidget(controller: _controller),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                )),
    );
  }

  Widget _buildWebViewer() {
    final viewerUrl = _getViewerUrl();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Document is loading...',
                  style: TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ),
              TextButton.icon(
                onPressed: () => launchUrl(Uri.parse(viewerUrl)),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Full Screen'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: _buildIframe(viewerUrl),
          ),
        ),
      ],
    );
  }

  Widget _buildIframe(String url) {
    // Create a simple HTML string with iframe
    final iframeHtml = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { margin: 0; padding: 0; overflow: hidden; }
            iframe { width: 100vw; height: 100vh; border: none; }
          </style>
        </head>
        <body>
          <iframe src="$url" allowfullscreen></iframe>
        </body>
      </html>
    ''';

    // Use data URL to embed the HTML
    final dataUrl =
        'data:text/html;charset=utf-8,${Uri.encodeComponent(iframeHtml)}';

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(url)),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text('Tap to view ${widget.title}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Click here to open the document',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
