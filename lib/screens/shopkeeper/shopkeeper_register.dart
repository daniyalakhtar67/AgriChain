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

class ShopkeeperRegister extends StatefulWidget {
  const ShopkeeperRegister({super.key});

  @override
  State<ShopkeeperRegister> createState() => _ShopkeeperRegisterState();
}

class _ShopkeeperRegisterState extends State<ShopkeeperRegister> {
  final _nameController        = TextEditingController();
  final _cnicController        = TextEditingController();
  final _phoneController       = TextEditingController();
  final _ageController         = TextEditingController();
  final _shopNameController    = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _passwordController    = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Supabase DB Logic ────────────────────────────────────────────────────────
  Future<void> _register() async {
    final name  = _nameController.text.trim();
    final cnic  = _cnicController.text.trim();
    final phone = _phoneController.text.trim();
    final age   = _ageController.text.trim();
    final sName = _shopNameController.text.trim();
    final sAddr = _shopAddressController.text.trim();
    final pass  = _passwordController.text.trim();

    // Validation
    if (name.isEmpty || cnic.isEmpty || phone.isEmpty || age.isEmpty ||
        sName.isEmpty || sAddr.isEmpty || pass.isEmpty) {
      _showSnack('All fields are required', isError: true);
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
      // Check for duplicate CNIC
      final existing = await Supabase.instance.client
          .from('shopkeepers')
          .select()
          .eq('cnic', cnic);

      if (existing.isNotEmpty) {
        _showSnack('This CNIC is already registered!', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      // Insert into Supabase — columns match exact table schema
      await Supabase.instance.client.from('shopkeepers').insert({
        'full_name'   : name,
        'cnic'        : cnic,
        'phone'       : phone,
        'shop_name'   : sName,
        'shop_address': sAddr,
        'password'    : pass,
      });

      _showSnack('Shopkeeper Registered Successfully!');
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Registration failed. Try again.', isError: true);
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

  // ── UI ───────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade900,
        centerTitle: true,
        title: RichText(
          text: TextSpan(
            style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold),
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
            image: AssetImage('assets/images/SR_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Shopkeeper Registration',
                style: GoogleFonts.montserrat(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.yellow),
              ),
              const SizedBox(height: 5),
              Text(
                'Fill in your details to get started',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 25),

              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Column(
                      children: [
                        _buildField(
                          label: 'SHOPKEEPER NAME',
                          controller: _nameController,
                          icon: Icons.person,
                          hint: 'Full Name',
                        ),
                        _buildField(
                          label: 'CNIC',
                          controller: _cnicController,
                          icon: Icons.badge,
                          hint: '12345-1234567-1',
                          keyboardType: TextInputType.number,
                          formatters: [CNICFormatter()],
                          maxLength: 15,
                        ),
                        _buildField(
                          label: 'PHONE NUMBER',
                          controller: _phoneController,
                          icon: Icons.phone,
                          hint: '03XXXXXXXXX',
                          keyboardType: TextInputType.phone,
                        ),
                        _buildField(
                          label: 'AGE',
                          controller: _ageController,
                          icon: Icons.calendar_today,
                          hint: 'e.g. 30',
                          keyboardType: TextInputType.number,
                        ),
                        _buildField(
                          label: 'SHOP NAME',
                          controller: _shopNameController,
                          icon: Icons.store,
                          hint: 'e.g. Madina Mart',
                        ),
                        _buildField(
                          label: 'SHOP ADDRESS',
                          controller: _shopAddressController,
                          icon: Icons.location_on,
                          hint: 'Full Address',
                        ),

                        // Password field with show/hide toggle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PASSWORD',
                              style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow),
                            ),
                            const SizedBox(height: 6),
                            _PasswordField(controller: _passwordController),
                          ],
                        ),

                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
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
                              'REGISTER SHOP',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
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
        Text(
          label,
          style: GoogleFonts.montserrat(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.yellow),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: formatters,
          maxLength: maxLength,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
            prefixIcon: Icon(icon, color: Colors.yellow.withValues(alpha: 0.7), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.yellow.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.yellow),
            ),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
      ],
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
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Enter Password',
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
        prefixIcon:
        Icon(Icons.lock, color: Colors.yellow.withValues(alpha: 0.7), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white54,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.yellow.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.yellow),
        ),
      ),
    );
  }
}