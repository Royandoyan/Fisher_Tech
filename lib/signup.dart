import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class SignUpScreen extends StatefulWidget {
  final String userType;

  const SignUpScreen({Key? key, required this.userType}) : super(key: key);

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

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField(
      String label, TextEditingController controller, bool isConfirm) {
    return TextFormField(
      controller: controller,
      obscureText: isConfirm ? !_showConfirmPassword : !_showPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(
            (isConfirm ? _showConfirmPassword : _showPassword)
                ? Icons.visibility
                : Icons.visibility_off,
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

    if ([email, password, confirmPassword, firstName, lastName, address, cpNumber]
        .any((e) => e.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(userType: widget.userType),
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.message}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 350,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: Text(
                          "SIGN UP",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                          "Email or Mobile Number", _emailController),
                      const SizedBox(height: 12),
                      _buildTextField("First Name", _firstNameController),
                      const SizedBox(height: 12),
                      _buildTextField("Middle Name", _middleNameController),
                      const SizedBox(height: 12),
                      _buildTextField("Last Name", _lastNameController),
                      const SizedBox(height: 12),
                      _buildTextField("Address", _addressController),
                      const SizedBox(height: 12),
                      _buildTextField(
                        "Mobile Number",
                        _cpNumberController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                          "Password", _passwordController, false),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                          "Confirm Password", _confirmPasswordController, true),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B3A55),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
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
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B3A55),
                              ),
                            ),
                          ),
                        ],
                      ),          
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Extra space for safe scrolling
              ],
            ),
          ),
        ),
      ),
    );
  }
}