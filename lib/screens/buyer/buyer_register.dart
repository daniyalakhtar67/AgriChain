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

class _BuyerRegisterState extends State<BuyerRegister>
    with SingleTickerProviderStateMixin {
  final _nameController     = TextEditingController();
  final _cnicController     = TextEditingController();
  final _phoneController    = TextEditingController();
  final _addressController  = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // Buyer accent color — blue
  static const Color _accent = Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name    = _nameController.text.trim();
    final cnic    = _cnicController.text.trim();
    final phone   = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final pass    = _passwordController.text.trim();

    if (name.isEmpty || cnic.isEmpty || phone.isEmpty || address.isEmpty || pass.isEmpty) {
      _showSnack('Please fill all required fields', isError: true); return;
    }
    if (cnic.length != 15) { _showSnack('Enter complete 13-digit CNIC', isError: true); return; }
    if (phone.length != 11) { _showSnack('Phone number must be exactly 11 digits', isError: true); return; }
    if (pass.length < 6)   { _showSnack('Password must be at least 6 characters', isError: true); return; }

    setState(() => _isLoading = true);
    try {
      final existing = await Supabase.instance.client.from('buyers').select().eq('cnic', cnic);
      if (existing.isNotEmpty) {
        _showSnack('CNIC already exists!', isError: true);
        setState(() => _isLoading = false); return;
      }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          ),
        ),
        title: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.black.withValues(alpha: 0.30),
              child: RichText(
                text: TextSpan(
                  text: 'Agri',
                  style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.white),
                  children: [TextSpan(text: 'Chain', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.yellow))],
                ),
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SizedBox.expand(child: Image.asset('assets/images/BR_bg.avif', fit: BoxFit.cover)),
          SizedBox.expand(child: Container(color: Colors.black.withValues(alpha: 0.55))),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // ── HEADER CARD ──────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _accent.withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 68, height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _accent.withValues(alpha: 0.18),
                                    border: Border.all(color: _accent, width: 2),
                                  ),
                                  child: const Icon(Icons.shopping_basket_outlined, color: _accent, size: 32),
                                ),
                                const SizedBox(height: 12),
                                Text('Buyer Registration',
                                    style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 4),
                                Text('Fill in your details to get started',
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── FORM CARD ────────────────────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Column(
                              children: [
                                _buildField('Full Name',  _nameController,    Icons.person_outline,       'Enter your name'),
                                _buildField('CNIC',       _cnicController,    Icons.credit_card_outlined, '12345-1234567-1',
                                    keyboardType: TextInputType.number, formatters: [CNICFormatter()], maxLength: 15),
                                _buildField('Phone',      _phoneController,   Icons.phone_outlined,        '03XXXXXXXXX',
                                    keyboardType: TextInputType.number,
                                    formatters: [FilteringTextInputFormatter.digitsOnly],
                                    maxLength: 11),
                                _buildField('Address',    _addressController, Icons.home_outlined,         'Home Address'),
                                _buildPasswordField(),
                                const SizedBox(height: 24),
                                _buildRegisterButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, String hint, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: _accent, size: 14),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
          ]),
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
              prefixIcon: Icon(icon, color: _accent.withValues(alpha: 0.8), size: 20),
              counterText: '',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.lock_outline, color: _accent, size: 14),
            const SizedBox(width: 6),
            Text('Password', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
          ]),
          const SizedBox(height: 6),
          _PasswordField(controller: _passwordController, accentColor: _accent),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text('REGISTER AS BUYER', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor;
  const _PasswordField({required this.controller, required this.accentColor});

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
      style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Create Password',
        hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.white38),
        prefixIcon: Icon(Icons.lock_outline, color: widget.accentColor.withValues(alpha: 0.8), size: 20),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obs = !_obs),
          child: Icon(_obs ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.white54, size: 20),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: widget.accentColor, width: 1.8)),
      ),
    );
  }
}