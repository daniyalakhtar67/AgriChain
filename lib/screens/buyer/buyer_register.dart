import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

class BuyerRegister extends StatefulWidget {
  const BuyerRegister({super.key});

  @override
  State<BuyerRegister> createState() => _BuyerRegisterState();
}

class _BuyerRegisterState extends State<BuyerRegister> {
  final _nameController     = TextEditingController();
  final _cnicController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _addressController  = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Supabase DB Logic ────────────────────────────────────────────────────────
  Future<void> _register() async {
    final name    = _nameController.text.trim();
    final cnic    = _cnicController.text.trim();
    final phone   = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final pass    = _passwordController.text.trim();

    if (name.isEmpty || cnic.isEmpty || phone.isEmpty || address.isEmpty || pass.isEmpty) {
      _showSnack('Please fill all required fields', isError: true);
      return;
    }
    if (cnic.length != 15) {
      _showSnack('Enter complete 13-digit CNIC', isError: true);
      return;
    }
    if (pass.length < 6) {
      _showSnack('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check duplicate CNIC
      final existing = await Supabase.instance.client
          .from('buyers')
          .select()
          .eq('cnic', cnic);

      if (existing.isNotEmpty) {
        _showSnack('CNIC already exists!', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Insert — columns match exact SQL schema
      await Supabase.instance.client.from('buyers').insert({
        'full_name': name,
        'cnic'     : cnic,
        'phone'    : phone,
        'address'  : address,
        'password' : pass,
      });

      _showSnack('Buyer Registered Successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Registration failed.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.montserrat()),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────────
  Widget _buildField(
      String label,
      TextEditingController controller,
      IconData icon,
      String hint, {
        TextInputType keyboard = TextInputType.text,
        List<TextInputFormatter>? formatters,
        int? maxLength,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.montserrat(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.yellow)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: formatters,
          maxLength: maxLength,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.yellow.withValues(alpha: 0.7)),
            counterText: '',
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.yellow)),
          ),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.bold),
            children: const [
              TextSpan(text: 'Agri',  style: TextStyle(color: Colors.white)),
              TextSpan(text: 'Chain', style: TextStyle(color: Colors.yellow)),
            ],
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BR_bg.avif'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Buyer Registration',
                  style: GoogleFonts.montserrat(
                      fontSize: 24, fontWeight: FontWeight.bold, color: Colors.yellow)),
              Text('Fill in your details to get started',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Column(
                      children: [
                        _buildField('FULL NAME', _nameController, Icons.person, 'Enter your name'),
                        _buildField('CNIC', _cnicController, Icons.badge, '12345-1234567-1',
                            keyboard: TextInputType.number,
                            formatters: [CNICFormatter()],
                            maxLength: 15),
                        _buildField('PHONE', _phoneController, Icons.phone, '03XXXXXXXXX',
                            keyboard: TextInputType.phone),
                        _buildField('ADDRESS', _addressController, Icons.home, 'Home Address'),

                        // Password with show/hide toggle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PASSWORD',
                                style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow)),
                            const SizedBox(height: 5),
                            _PasswordField(controller: _passwordController),
                          ],
                        ),

                        const SizedBox(height: 25),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                              'REGISTER AS BUYER',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
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

// ── Password Field with visibility toggle ────────────────────────────────────
class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  const _PasswordField({required this.controller});

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obs = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obs,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Create Password',
        hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: const Icon(Icons.lock, color: Colors.yellow),
        suffixIcon: IconButton(
          icon: Icon(_obs ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54),
          onPressed: () => setState(() => _obs = !_obs),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.yellow)),
      ),
    );
  }
}