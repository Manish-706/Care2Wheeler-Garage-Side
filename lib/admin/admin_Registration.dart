import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:garage/admin/admin_Login.dart';
import 'package:garage/bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';

// Modern theme colors
const Color primaryColor = Color(0xFF00C897);
const Color secondaryColor = Color(0xFFF6830F);
const Color darkColor = Color(0xFF0A2647);
const Color lightColor = Color(0xFFF5F5F5);

class AdminRegistration extends StatefulWidget {
  const AdminRegistration({Key? key}) : super(key: key);

  @override
  State<AdminRegistration> createState() => _AdminRegistrationState();
}

class _AdminRegistrationState extends State<AdminRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _garageNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _aadharController = TextEditingController();
  final storage = const FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _garageNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _aadharController.dispose();
    super.dispose();
  }

  Future<void> _registerGarage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    String? token = await storage.read(key: 'fcm_token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/garage/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'ownerName': _nameController.text.trim(),
          'garageName': _garageNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'address': _addressController.text.trim(),
          'aadharNumber': _aadharController.text.trim(),
          'fcmToken': token
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storeRegistrationData(data);
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => BottomNavBar(),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      } else {
        _showSnackBar(
            jsonDecode(response.body)['error'] ?? 'Registration failed');
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _storeRegistrationData(Map<String, dynamic> data) async {
    await storage.write(key: 'jwt_token', value: data['token']);
    await storage.write(key: 'garage_id', value: data['GarageId']);
    await storage.write(key: 'owner_name', value: data['ownerName']);
    await storage.write(key: 'garage_name', value: data['garageName']);
    await storage.write(key: 'phone', value: data['phone']);
    await storage.write(key: 'address', value: data['address']);
    await storage.write(key: 'aadhar_number', value: data['aadharNumber']);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: secondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 40),
                    _buildInputFields(),
                    const SizedBox(height: 40),
                    _buildRegisterButton(),
                    const SizedBox(height: 20),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Garage Registration',
          style: GoogleFonts.poppins(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: darkColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join our professional network of workshops',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        _buildFormField(
          controller: _nameController,
          label: 'Owner Name',
          hint: 'John Doe',
          icon: Icons.person_outline_rounded,
          validator: (value) => value!.isEmpty ? 'Required field' : null,
        ),
        const SizedBox(height: 24),
        _buildFormField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '9876543210',
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
          validator: (value) => value!.length != 10 ? 'Invalid number' : null,
        ),
        const SizedBox(height: 24),
        _buildFormField(
          controller: _garageNameController,
          label: 'Garage Name',
          hint: 'Premium Auto Care',
          icon: Icons.garage_rounded,
          validator: (value) => value!.isEmpty ? 'Required field' : null,
        ),
        const SizedBox(height: 24),
        _buildFormField(
          controller: _addressController,
          label: 'Full Address',
          hint: 'Street, City, State - Pincode',
          icon: Icons.location_on_outlined,
          maxLines: 3,
          validator: (value) => value!.isEmpty ? 'Required field' : null,
        ),
        const SizedBox(height: 24),
        _buildFormField(
          controller: _aadharController,
          label: 'Aadhar Number',
          hint: 'XXXX XXXX XXXX',
          icon: Icons.credit_card_rounded,
          keyboardType: TextInputType.number,
          validator: (value) => value!.isEmpty ? 'Required field' : null,
        ),
        const SizedBox(height: 24),
        _buildFormField(
          controller: _emailController,
          label: 'Email (Optional)',
          hint: 'contact@garage.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.poppins(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
            prefixIcon: Container(
              width: 52,
              padding: const EdgeInsets.only(left: 16),
              child: Icon(icon, color: primaryColor),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerGarage,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: primaryColor.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Register Workshop',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const AdminLogin(),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: 'Already registered? '),
              TextSpan(
                text: 'Login here',
                style: GoogleFonts.poppins(
                  color: secondaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
