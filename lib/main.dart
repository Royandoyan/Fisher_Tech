import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';
// For Android
import 'package:webview_flutter_android/webview_flutter_android.dart';
// For iOS
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:html' as html;

void main() async {
  try {
    debugPrint('Fisher Tech App - Starting initialization...');
    
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Fisher Tech App - Flutter binding initialized');
    
    // Initialize WebView platform
    _initializeWebViewPlatform();
    debugPrint('Fisher Tech App - WebView platform initialized');
    
    // Initialize Firebase
    await _initializeFirebase();
    debugPrint('Fisher Tech App - Firebase initialized');
    
    debugPrint('Fisher Tech App - Running app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('Fisher Tech App - Error during initialization: $e');
    debugPrint('Fisher Tech App - Stack trace: $stackTrace');
    
    // Show error screen instead of crashing
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'App Initialization Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Reload the page
                  if (kIsWeb) {
                    // For web, reload the page
                    html.window.location.reload();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Fisher Tech App - Firebase initialized successfully');
  } catch (e) {
    debugPrint("Fisher Tech App - Firebase initialization error: $e");
    // Don't rethrow - let the app continue without Firebase
  }
}

void _initializeWebViewPlatform() {
  try {
    if (WebViewPlatform.instance == null) {
      if (defaultTargetPlatform == TargetPlatform.android) {
        WebViewPlatform.instance = AndroidWebViewPlatform();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        WebViewPlatform.instance = WebKitWebViewPlatform();
      }
    }
    debugPrint('Fisher Tech App - WebView platform initialized successfully');
  } catch (e) {
    debugPrint('Fisher Tech App - WebView platform initialization error: $e');
    // Don't rethrow - let the app continue without WebView
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('Fisher Tech App - Building MyApp widget');
    return MaterialApp(
      title: 'Fisher Tech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WelcomeScreen(),
    );
  }
}