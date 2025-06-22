import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'homed.dart';
import 'Selection_screen.dart'; // <-- Import this!

class LoginScreen extends StatefulWidget {
  final String userType;

  const LoginScreen({super.key, required this.userType});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Login Successful!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome back, ${widget.userType}!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomePage(userType: widget.userType)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Login Failed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Try Again',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      final userDoc = await FirebaseFirestore.instance
          .collection(widget.userType)
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No ${widget.userType} record found. Please check your account type.',
        );
      }

      setState(() {
        _isLoading = false;
      });

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email address.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during login.';
      }
      
      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which text to show based on the userType
    String promptText =
        widget.userType == 'fisherman' ? 'Are you a Customer?' : 'Are you a Fisherman?';

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    
    // Calculate responsive dimensions with better breakpoints
    double containerWidth;
    double logoSize;
    double horizontalPadding;
    double verticalPadding;
    double fontSize;
    
    if (screenWidth < 360) {
      // Very small screens (old phones)
      containerWidth = screenWidth * 0.95;
      logoSize = 80.0;
      horizontalPadding = 12.0;
      verticalPadding = 16.0;
      fontSize = 13.0;
    } else if (screenWidth < 480) {
      // Small screens
      containerWidth = screenWidth * 0.92;
      logoSize = 90.0;
      horizontalPadding = 16.0;
      verticalPadding = 20.0;
      fontSize = 14.0;
    } else if (screenWidth < 768) {
      // Medium screens (tablets)
      containerWidth = screenWidth * 0.85;
      logoSize = 100.0;
      horizontalPadding = 24.0;
      verticalPadding = 24.0;
      fontSize = 15.0;
    } else {
      // Large screens (desktop)
      containerWidth = 400.0;
      logoSize = 120.0;
      horizontalPadding = 32.0;
      verticalPadding = 32.0;
      fontSize = 15.0;
    }

    // Calculate available height for the form
    final availableHeight = screenHeight - padding.top - padding.bottom;
    final minFormHeight = availableHeight * 0.6;
    final maxFormHeight = availableHeight * 0.85;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minFormHeight,
                maxHeight: maxFormHeight,
              ),
              child: Container(
                width: containerWidth,
                constraints: BoxConstraints(
                  maxWidth: 450,
                  minHeight: minFormHeight,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section
                      ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: logoSize,
                          height: logoSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: horizontalPadding * 1.5),
                      
                      // Email field
                      TextField(
                        controller: _emailController,
                        style: TextStyle(fontSize: fontSize),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: fontSize - 1,
                          ),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueGrey.shade700),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: fontSize + 4,
                          ),
                        ),
                      ),
                      SizedBox(height: horizontalPadding),
                      
                      // Password field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        style: TextStyle(fontSize: fontSize),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: Colors.grey[700],
                            fontSize: fontSize - 1,
                          ),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueGrey.shade700),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: fontSize + 4,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                              color: Colors.blueGrey,
                              size: fontSize + 4,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: horizontalPadding * 0.5),
                      
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3A4A6C),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: fontSize + 6),
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  height: fontSize + 6,
                                  width: fontSize + 6,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Login',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: fontSize,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: horizontalPadding * 1.5),

                      // User type switch text
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            "$promptText ",
                            style: TextStyle(fontSize: fontSize),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Go back to SelectionScreen
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SelectionScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            child: Text(
                              "Click Here",
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                                color: const Color(0xFF243B5E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}