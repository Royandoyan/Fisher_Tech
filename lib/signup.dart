import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  final String userType;

  const SignUpScreen({super.key, required this.userType});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cpNumberController = TextEditingController(); // Added controller
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
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
                    'Registration Successful!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome to Fisher Tech, ${widget.userType}!',
                    textAlign: TextAlign.center,
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
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(userType: widget.userType),
                          ),
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
                        'Continue to Login',
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
                    'Registration Failed',
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

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    
    // Calculate responsive dimensions with better breakpoints
    double containerWidth;
    double horizontalPadding;
    double verticalPadding;
    double fontSize;
    double titleFontSize;
    double spacing;
    
    if (screenWidth < 360) {
      // Very small screens (old phones)
      containerWidth = screenWidth * 0.95;
      horizontalPadding = 12.0;
      verticalPadding = 12.0;
      fontSize = 13.0;
      titleFontSize = 18.0;
      spacing = 8.0;
    } else if (screenWidth < 480) {
      // Small screens
      containerWidth = screenWidth * 0.92;
      horizontalPadding = 16.0;
      verticalPadding = 16.0;
      fontSize = 14.0;
      titleFontSize = 19.0;
      spacing = 10.0;
    } else if (screenWidth < 768) {
      // Medium screens (tablets)
      containerWidth = screenWidth * 0.85;
      horizontalPadding = 20.0;
      verticalPadding = 20.0;
      fontSize = 15.0;
      titleFontSize = 20.0;
      spacing = 12.0;
    } else {
      // Large screens (desktop)
      containerWidth = 450.0;
      horizontalPadding = 24.0;
      verticalPadding = 24.0;
      fontSize = 15.0;
      titleFontSize = 22.0;
      spacing = 12.0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Center(
            child: Container(
              width: containerWidth,
              constraints: BoxConstraints(
                maxWidth: 500,
              ),
              padding: EdgeInsets.all(horizontalPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Text(
                      "SIGN UP",
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: spacing * 2),
                  _buildResponsiveTextField(
                    "Email or Mobile Number", 
                    _emailController,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing),
                  _buildResponsiveTextField(
                    "First Name", 
                    _firstNameController,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing),
                  _buildResponsiveTextField(
                    "Middle Name", 
                    _middleNameController,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing),
                  _buildResponsiveTextField(
                    "Last Name", 
                    _lastNameController,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing),
                  _buildResponsiveTextField(
                    "Address", 
                    _addressController,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing),
                  _buildResponsiveTextField(
                    "Mobile Number",
                    _cpNumberController,
                    keyboardType: TextInputType.phone,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing),
                  _buildResponsivePasswordField(
                    "Password", 
                    _passwordController, 
                    false,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing),
                  _buildResponsivePasswordField(
                    "Confirm Password", 
                    _confirmPasswordController, 
                    true,
                    fontSize: fontSize,
                  ),
                  SizedBox(height: spacing * 2),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B3A55),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: fontSize + 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                            "Sign Up",
                            style: TextStyle(fontSize: fontSize + 1),
                          ),
                  ),
                  SizedBox(height: spacing),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(fontSize: fontSize - 1),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LoginScreen(userType: widget.userType),
                            ),
                          );
                        },
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2B3A55),
                            fontSize: fontSize - 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing), // Extra space at bottom for safe scrolling
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveTextField(
    String label, 
    TextEditingController controller, 
    {TextInputType? keyboardType, double? fontSize}
  ) {
    final textFontSize = fontSize ?? 15.0;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: textFontSize),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: textFontSize - 1,
        ),
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: textFontSize + 4,
        ),
      ),
    );
  }

  Widget _buildResponsivePasswordField(
    String label, 
    TextEditingController controller, 
    bool isConfirm,
    {double? fontSize}
  ) {
    final textFontSize = fontSize ?? 15.0;
    return TextFormField(
      controller: controller,
      obscureText: isConfirm ? !_showConfirmPassword : !_showPassword,
      style: TextStyle(fontSize: textFontSize),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: textFontSize - 1,
        ),
        border: const OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: textFontSize + 4,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            (isConfirm ? _showConfirmPassword : _showPassword)
                ? Icons.visibility
                : Icons.visibility_off,
            size: textFontSize + 4,
          ),
          onPressed: () {
            setState(() {
              if (isConfirm) {
                _showConfirmPassword = !_showConfirmPassword;
              } else {
                _showPassword = !_showPassword;
              }
            });
          },
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final address = _addressController.text.trim();
    final cpNumber = _cpNumberController.text.trim(); // Get cp number

    // Validate all required fields
    if ([email, password, confirmPassword, firstName, lastName, address, cpNumber]
        .any((e) => e.isEmpty)) {
      _showErrorDialog("Please fill in all required fields.");
      return;
    }

    // Validate email format
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showErrorDialog("Please enter a valid email address.");
      return;
    }

    // Validate password length
    if (password.length < 6) {
      _showErrorDialog("Password must be at least 6 characters long.");
      return;
    }

    if (password != confirmPassword) {
      _showErrorDialog("Passwords do not match.");
      return;
    }

    // Validate mobile number format (basic validation)
    if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(cpNumber)) {
      _showErrorDialog("Please enter a valid mobile number.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await FirebaseFirestore.instance
          .collection(widget.userType)
          .doc(credential.user!.uid)
          .set({
        'firstName': firstName,
        'middleName': middleName,
        'lastName': lastName,
        'address': address,
        'cpNumber': cpNumber, // Store cp number
        'email': email,
        'uid': credential.user!.uid,
        'userType': widget.userType,
        'createdAt': Timestamp.now(),
      });

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
        case 'email-already-in-use':
          errorMessage = 'An account with this email address already exists. Please use a different email or try logging in.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          errorMessage = 'Password is too weak. Please choose a stronger password.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled. Please contact support.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during registration.';
      }
      
      _showErrorDialog(errorMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('An unexpected error occurred. Please try again.');
    }
  }
}