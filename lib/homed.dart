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
import 'package:video_thumbnail/video_thumbnail.dart';
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

  // For video thumbnail cache
  final Map<String, String?> _videoThumbnailCache = {};

  // Light ocean gradient to highlight the logo
  static const LinearGradient oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFe0f7fa), // Light aqua
      Color(0xFFb3e5fc), // Pale blue
      Color(0xFF81d4fa), // Soft blue
      Color(0xFFb2ebf2), // Light teal
      Color(0xFFe1f5fe), // Very light blue
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

  static const LinearGradient searchGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF0F9FF), // Ice blue
      Color(0xFFE0F2FE), // Light blue
      Color(0xFFF8FAFC), // Sea foam
    ],
  );

  // Generate video thumbnail
  Future<String?> _generateVideoThumbnail(String videoUrl) async {
    if (_videoThumbnailCache.containsKey(videoUrl)) {
      return _videoThumbnailCache[videoUrl];
    }

    // Skip thumbnail generation on web platform
    if (kIsWeb) {
      _videoThumbnailCache[videoUrl] = null;
      return null;
    }

    try {
      final directory = await getTemporaryDirectory();
      final thumbnailPath = '${directory.path}/thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        quality: 75,
        maxWidth: 200,
        maxHeight: 200,
        timeMs: 1000, // Take thumbnail at 1 second
      );

      if (thumbnail != null) {
        _videoThumbnailCache[videoUrl] = thumbnail;
        return thumbnail;
      }
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
    }

    _videoThumbnailCache[videoUrl] = null;
    return null;
  }

// Responsive grid count helper
  int _getGridColumnCount(double width) {
    if (width < 480) return 1;
    if (width < 768) return 2;
    if (width < 1024) return 3;
    if (width < 1400) return 4;
    return 5;
  }

  // Responsive spacing helper
  double _getResponsiveSpacing(double width) {
    if (width < 480) return 8.0;
    if (width < 768) return 12.0;
    if (width < 1024) return 16.0;
    return 20.0;
  }

  // Responsive font size helper
  double _getResponsiveFontSize(double width, {double baseSize = 16.0}) {
    if (width < 480) return baseSize - 2;
    if (width < 768) return baseSize - 1;
    if (width < 1024) return baseSize;
    return baseSize + 1;
  }

  // Responsive container height helper
  double _getResponsiveContainerHeight(double width) {
    if (width < 480) return 140.0;
    if (width < 768) return 150.0;
    if (width < 1024) return 160.0;
    return 170.0;
  }

  // Responsive icon size helper
  double _getResponsiveIconSize(double width) {
    if (width < 480) return 20.0;
    if (width < 768) return 22.0;
    if (width < 1024) return 24.0;
    return 26.0;
  }

  // Responsive card width helper - designed to show exactly 3 items
  double _getResponsiveCardWidth(double width) {
    // Calculate width to show exactly 3 items with spacing
    final availableWidth = width - 48; // Account for padding and margins
    final itemWidth = (availableWidth - 16) / 3; // 3 items with 8px spacing between each
    return itemWidth.clamp(80.0, 120.0); // Minimum 80px, maximum 120px for better visibility
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
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = _getResponsiveFontSize(screenWidth, baseSize: 16.0);
    final buttonFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    final dialogWidth = screenWidth < 480 ? screenWidth * 0.9 : screenWidth < 768 ? 400.0 : 500.0;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              // Header with gradient
              Container(
                padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: buttonGradient,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _uploadType == 'file' ? Icons.upload_file : Icons.video_library,
                      color: Colors.white,
                      size: screenWidth < 480 ? 20 : 24,
                    ),
                    SizedBox(width: screenWidth < 480 ? 8 : 12),
                    Expanded(
                      child: Text(
                        'Upload ${_uploadType == 'file' ? 'Document' : 'Video'}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize + 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: Container(
                  padding: EdgeInsets.all(screenWidth < 480 ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: cardGradient,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth < 480 ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.file_present,
                              color: Colors.blue.shade600,
                              size: screenWidth < 480 ? 16 : 20,
                            ),
                            SizedBox(width: screenWidth < 480 ? 8 : 12),
                            Expanded(
                              child: Text(
                                'Selected file: ${_selectedFile?.name ?? ''}',
                                style: TextStyle(
                                  fontSize: fontSize - 2,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenWidth < 480 ? 16 : 20),
            TextField(
              controller: _titleController,
                        decoration: InputDecoration(
                labelText: 'Title / Purpose',
                          labelStyle: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: fontSize - 2,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth < 480 ? 12 : 16,
                            vertical: screenWidth < 480 ? 12 : 16,
                          ),
                        ),
                        style: TextStyle(fontSize: fontSize),
                      ),
                      SizedBox(height: screenWidth < 480 ? 20 : 24),
                      
                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: screenWidth < 480 ? 40 : 44,
                              margin: EdgeInsets.only(right: screenWidth < 480 ? 6 : 8),
                              child: OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedFile = null;
                _titleController.clear();
                _uploadType = null;
              });
            },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.grey.shade400),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
                                    color: Colors.grey.shade700,
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Upload',
                                  style: TextStyle(
                                    fontSize: buttonFontSize,
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
            ],
          ),
        ),
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
      await _auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SelectionScreen()),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    
    // Calculate responsive dimensions
    final gridCount = _getGridColumnCount(screenWidth);
    final spacing = _getResponsiveSpacing(screenWidth);
    final titleFontSize = _getResponsiveFontSize(screenWidth, baseSize: 20.0);
    final bodyFontSize = _getResponsiveFontSize(screenWidth, baseSize: 14.0);
    final containerHeight = _getResponsiveContainerHeight(screenWidth);
    final iconSize = _getResponsiveIconSize(screenWidth);
    final cardWidth = _getResponsiveCardWidth(screenWidth);
    final horizontalPadding = screenWidth < 480 ? 12.0 : screenWidth < 768 ? 16.0 : 20.0;
    final verticalPadding = screenWidth < 480 ? 8.0 : screenWidth < 768 ? 12.0 : 16.0;

    return Scaffold(
      key: _scaffoldKey,
      body: Column(
        children: [
          // Custom AppBar with white background
          Container(
            decoration: const BoxDecoration(color: Colors.white),
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFF1976D2)),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
                    Image.asset(
                      'assets/images/logo1.jpg', 
                      height: screenWidth < 480 ? 32 : 40
                    ),
                    const Spacer(),
          IconButton(
                      icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF1976D2)),
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
                      icon: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF1976D2)),
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
                      icon: const Icon(Icons.notifications_none, color: Color(0xFF1976D2)),
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
                      icon: const Icon(Icons.person_outline, color: Color(0xFF1976D2)),
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
          SizedBox(width: horizontalPadding * 0.5),
        ],
      ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(gradient: oceanGradient),
              child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SINGLE SEARCH BAR FOR ALL
                Container(
                margin: EdgeInsets.symmetric(vertical: verticalPadding),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  decoration: BoxDecoration(
                          gradient: searchGradient,
                          borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                    ),
                  ],
                  ),
                  child: TextField(
                    controller: _mainSearchController,
                  style: TextStyle(fontSize: bodyFontSize),
                  decoration: InputDecoration(
                      hintText: 'Search Files, Video, or Fisherman ...',
                    hintStyle: TextStyle(fontSize: bodyFontSize - 1),
                      border: InputBorder.none,
                    icon: Icon(Icons.search, size: bodyFontSize + 4),
                    contentPadding: EdgeInsets.symmetric(vertical: bodyFontSize + 4),
                    ),
                  ),
                ),

                // ------ SLIDE INFORMATION -------
              _buildSectionContainer(
                title: 'Slide Information',
                titleFontSize: titleFontSize,
                spacing: spacing,
                child: _buildSlideInformationSection(gridCount, containerHeight, iconSize, cardWidth, bodyFontSize),
              ),

              // ------ VIDEO TUTORIALS -------
              _buildSectionContainer(
                title: 'Video Tutorials',
                titleFontSize: titleFontSize,
                spacing: spacing,
                child: _buildVideoTutorialsSection(gridCount, containerHeight, iconSize, cardWidth, bodyFontSize),
              ),

              // ------ FISHERMAN PROFILES -------
              _buildSectionContainer(
                title: 'Fisherman Profiles',
                titleFontSize: titleFontSize,
                spacing: spacing,
                child: _buildFishermanProfilesSection(bodyFontSize),
              ),
            ],
          ),
        ),
      ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required double titleFontSize,
    required double spacing,
    required Widget child,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: spacing),
      padding: EdgeInsets.all(spacing),
                  decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFffffff),
            Color(0xFFf8f9ff),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
              Text(
                title,
                style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
              if (widget.userType == 'fisherman' && title == 'Slide Information')
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                              onPressed: () => _pickFile('file'),
                              tooltip: 'Upload Document',
                  ),
                            ),
              if (widget.userType == 'fisherman' && title == 'Video Tutorials')
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667eea),
                        Color(0xFF764ba2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                  onPressed: () => _pickFile('video'),
                  tooltip: 'Upload Video',
                  ),
                            ),
                        ],
                      ),
          SizedBox(height: spacing * 0.8),
          child,
        ],
      ),
    );
  }

  Widget _buildSlideInformationSection(int gridCount, double containerHeight, double iconSize, double cardWidth, double bodyFontSize) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(filesCollection)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No documents uploaded yet'),
          );
        }
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          return _mainSearchText.isEmpty || title.contains(_mainSearchText);
        }).toList();

        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No documents found for this search'),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: docs.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final title = (data['title'] ?? 'No Title').toString();
              final metadata = data['metadata'] ?? {};
              final url = metadata['url'] ?? '';
              final extension = metadata['extension'] ?? '';
              final isVideo = extension.toString().contains('.mp4') || extension.toString().contains('.mov');
              return GestureDetector(
                onTap: () async {
                  String viewerUrl;
                  if (extension == '.pdf') {
                    viewerUrl = 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
                  } else if ([
                    '.doc',
                    '.docx',
                    '.xls',
                    '.xlsx',
                    '.ppt',
                    '.pptx'
                  ].contains(extension)) {
                    viewerUrl = 'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeComponent(url)}';
                  } else {
                    viewerUrl = url;
                  }
                  final uri = Uri.parse(viewerUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('Could not launch document')));
                  }
                },
                child: Container(
                  width: cardWidth,
                  height: containerHeight,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.deepPurple.shade100),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isVideo ? Icons.videocam : Icons.insert_drive_file,
                        size: iconSize,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: bodyFontSize,
                          ),
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
      },
    );
  }

  Widget _buildVideoTutorialsSection(int gridCount, double containerHeight, double iconSize, double cardWidth, double bodyFontSize) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection(videosCollection)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No videos uploaded yet'),
          );
        }
        final videos = snapshot.data!.docs.where((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          return _mainSearchText.isEmpty || title.contains(_mainSearchText);
        }).toList();

        if (videos.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('No videos found for this search'),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: videos.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final title = (data['title'] ?? 'No Title').toString();
              final metadata = data['metadata'] ?? {};
              final url = metadata['url'] ?? '';
              return GestureDetector(
                onTap: () => _openInAppViewer(url, '.mp4', title),
                child: Container(
                  width: cardWidth,
                  height: containerHeight,
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.grey.shade100,
                  ),
                  child: FutureBuilder<String?>(
                    future: _generateVideoThumbnail(url),
                    builder: (context, thumbnailSnapshot) {
                      return Stack(
                        children: [
                          // Thumbnail or fallback
                          if (thumbnailSnapshot.connectionState == ConnectionState.done && 
                              thumbnailSnapshot.data != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.file(
                                File(thumbnailSnapshot.data!),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Icon(
                                Icons.videocam,
                                size: iconSize,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          // Play button overlay
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.play_arrow,
                                  size: iconSize - 4,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // Title overlay at bottom
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                ),
                              ),
                              child: Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: bodyFontSize - 1,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildFishermanProfilesSection(double bodyFontSize) {
    return StreamBuilder<QuerySnapshot>(
                        stream: _firestore.collection('fisherman').snapshots(),
                        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
          debugPrint('Fisherman query error: ${snapshot.error}');
                            return Text('Error: ${snapshot.error}');
                          }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            debugPrint('No fisherman documents found');
                            return const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('No fisherman profiles available'),
                            );
                          }
                          final fishermen = snapshot.data!.docs.where((doc) {
                            final data = doc.data()! as Map<String, dynamic>;
          final firstName = (data['firstName'] ?? '').toString().toLowerCase();
          final lastName = (data['lastName'] ?? '').toString().toLowerCase();
                            final fullName = '$firstName $lastName';
          return _mainSearchText.isEmpty || firstName.contains(_mainSearchText) || lastName.contains(_mainSearchText) || fullName.contains(_mainSearchText);
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
              final data = doc.data()! as Map<String, dynamic>;
                                final userId = doc.id;
              final firstName = (data['firstName'] ?? 'No First Name').toString();
              final lastName = (data['lastName'] ?? 'No Last Name').toString();
              final address = (data['address'] ?? 'No Address').toString();
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
                      border: Border.all(color: Colors.blue.shade100),
                                      ),
                                      child: GestureDetector(
                                        onTap: () async {
                        String? profileUrl = profileSnapshot.data;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                            builder: (context) => VendorProfileScreen(
                                                fishermanId: userId,
                                                fishermanName: fullName,
                                                profileImageUrl: profileUrl,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                          profileSnapshot.connectionState == ConnectionState.done &&
                              profileSnapshot.data != null &&
                              profileSnapshot.data!.isNotEmpty
                                                ? CircleAvatar(
                                                    radius: 28,
                                  backgroundImage: NetworkImage(profileSnapshot.data!),
                                                  )
                              : const CircleAvatar(radius: 28),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              height: 38,
                                              child: Center(
                                                child: Text(
                                                  fullName,
                                                  textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                                  maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                  maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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
    );
  }

  // Drawer and logo methods remain unchanged

  Widget _buildDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = screenWidth < 480 ? 180.0 : 200.0;
    final logoSize = screenWidth < 480 ? 60.0 : 70.0;
    final spacing = screenWidth < 480 ? 20.0 : 30.0;
    
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
                    const url = 'https://www.facebook.com/CatbaloganPulis?mibextid=qi2Omg&rdid=bVIUFXyKihSa2wsN&share_url=https%3A%2F%2Fwww.facebook.com%2Fshare%2F1Nhzw2XvMq%2F%3Fmibextid%3Dqi2Omg#; ';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                SizedBox(height: spacing),
                _buildLogoItem(
                  image: 'assets/images/coastguard.png',
                  logoSize: logoSize,
                  onTap: () async {
                    Navigator.pop(context);
                    const url = 'https://www.facebook.com/profile.php?id=100064678504235';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                SizedBox(height: spacing),
                _buildLogoItem(
                  image: 'assets/images/map.png',
                  logoSize: logoSize,
                  onTap: () async {
                    Navigator.pop(context);
                    const url = 'https://www.google.com/maps/place/City+of+Catbalogan,+Samar/@11.8002446,124.8212436,11z/data=!3m1!4b1!4m6!3m5!1s0x330834d7864d55d7:0xcbc9fd0999445956!8m2!3d11.8568348!4d124.8844867!16s%2Fm%2F02p_dgf?entry=ttu&g_ep=EgoyMDI1MDYxMS4wIKXMDSoASAFQAw%3D%3D';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                SizedBox(height: spacing),
                _buildLogoItem(
                  image: 'assets/images/firestation.png',
                  logoSize: logoSize,
                  onTap: () async {
                    Navigator.pop(context);
                    const url = 'https://www.facebook.com/profile.php?id=100064703287688';
                    if (await canLaunchUrl(Uri.parse(url))) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth < 480 ? 16.0 : 20.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.logout, size: screenWidth < 480 ? 24 : 28, color: Colors.white),
              label: Text(
                'Logout', 
                style: TextStyle(
                  color: Colors.white,
                  fontSize: screenWidth < 480 ? 14 : 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(double.infinity, screenWidth < 480 ? 45 : 50),
              ),
              onPressed: _signOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoItem({
    required String image, 
    required double logoSize,
    required VoidCallback onTap,
  }) {
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
}

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({super.key, required this.pdfUrl, required this.title});

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
        final file = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf');
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
        backgroundColor: const Color(0xFF7A9BAE),
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
    super.key,
  });

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
                launchUrl(Uri.parse(widget.fileUrl), mode: LaunchMode.externalApplication);
              } else {
                OpenFilex.open(widget.fileUrl);
              }
            },
          ),
          if (kIsWeb)
            IconButton(
              icon: const Icon(Icons.fullscreen),
              onPressed: () => launchUrl(Uri.parse(_getViewerUrl()), mode: LaunchMode.externalApplication),
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
          child: SizedBox(
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
    final dataUrl = 'data:text/html;charset=utf-8,${Uri.encodeComponent(iframeHtml)}';

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
