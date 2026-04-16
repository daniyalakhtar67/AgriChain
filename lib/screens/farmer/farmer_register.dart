import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:argichain/services/database_service.dart';

class CNICFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 13) digits = digits.substring(0, 13);
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i == 5 || i == 12) formatted += '-';
      formatted += digits[i];
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class FarmerRegister extends StatefulWidget {
  const FarmerRegister({super.key});

  @override
  State<FarmerRegister> createState() => _FarmerRegisterState();
}

class _FarmerRegisterState extends State<FarmerRegister> {
  final _nameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _landOwnedController = TextEditingController();
  final _farmLocController = TextEditingController();
  final _homeLocController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _landOwnedController.dispose();
    _farmLocController.dispose();
    _homeLocController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final cnicVal = _idNumberController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final land = _landOwnedController.text.trim();
    final farmLoc = _farmLocController.text.trim();
    final homeLoc = _homeLocController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || cnicVal.isEmpty || phone.isEmpty || email.isEmpty ||
        land.isEmpty || farmLoc.isEmpty || homeLoc.isEmpty || password.isEmpty) {
      _showSnack('All fields are required', isError: true);
      return;
    }

    if (cnicVal.length != 15) {
      _showSnack('Enter complete 13-digit ID number', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final id = await DatabaseService.instance.insertFarmer({
        'full_name': name,
        'cnic': cnicVal,
        'email': email,
        'land_owned': land,
        'farm_location': farmLoc,
        'home_location': homeLoc,
        'password': password,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (id > 0) {
        _showSnack('Registration Successful!');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnack(e.toString().contains('UNIQUE')
          ? 'This ID is already registered!'
          : 'Something went wrong.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.yellow)),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLength: maxLength,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          decoration: _decor(hint: hint, icon: icon),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  InputDecoration _decor({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.yellow.withValues(alpha: 0.7), size: 20),
      counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.yellow.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.yellow, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade800,
        centerTitle: true,
        title: Text('AgriChain', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/FR_bg.avif'), fit: BoxFit.cover),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('FARMER REGISTRATION', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.yellow)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black.withValues(alpha: 0.4),
                    child: Column(
                      children: [
                        _buildField(label: 'FULL NAME', controller: _nameController, icon: Icons.person_outline, hint: 'Muhammad Ali'),
                        _buildField(label: 'CNIC', controller: _idNumberController, icon: Icons.credit_card, hint: '12345-1234567-1', keyboardType: TextInputType.number, formatters: [CNICFormatter()], maxLength: 15),
                        _buildField(label: 'PHONE', controller: _phoneController, icon: Icons.phone, hint: '03XX-XXXXXXX', keyboardType: TextInputType.phone),
                        _buildField(label: 'EMAIL', controller: _emailController, icon: Icons.email, hint: 'email@gmail.com', keyboardType: TextInputType.emailAddress),
                        _buildField(label: 'LAND (ACRES)', controller: _landOwnedController, icon: Icons.landscape, hint: 'e.g. 5', keyboardType: TextInputType.number),
                        _buildField(label: 'FARM LOCATION', controller: _farmLocController, icon: Icons.location_on, hint: 'Village name'),
                        _buildField(label: 'HOME ADDRESS', controller: _homeLocController, icon: Icons.home, hint: 'Home address'),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PASSWORD', style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.yellow)),
                            const SizedBox(height: 7),
                            _PasswordField(controller: _passwordController),
                          ],
                        ),

                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('REGISTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordField({required this.controller});
  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Min. 6 characters',
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.yellow),
        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white54), onPressed: () => setState(() => _obscure = !_obscure)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.yellow)),
      ),
    );
  }
}