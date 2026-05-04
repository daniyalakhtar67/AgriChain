import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_dashboard.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _userC = TextEditingController();
  final _passC = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userC.dispose();
    _passC.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _userC.text.trim().toLowerCase();
    final password = _passC.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }

    setState(() { _error = null; _loading = true; });

    try {
      final supabase = Supabase.instance.client;

      // Fetch admin from DB
      final res = await supabase
          .from('admins')
          .select()
          .eq('username', username)
          .eq('is_active', true)
          .maybeSingle();

      if (res == null) {
        setState(() { _error = 'Admin not found or inactive.'; _loading = false; });
        return;
      }

      if (res['password'] != password) {
        setState(() { _error = 'Incorrect password.'; _loading = false; });
        return;
      }

      // Update last_login
      await supabase
          .from('admins')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', res['id']);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminDashboard(adminData: res)
          ),
        );
      }
    } catch (e) {
      setState(() { _error = 'Error: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
              child: Image.asset('assets/images/W_bg.webp', fit: BoxFit.cover)),
          SizedBox.expand(
              child: Container(color: Colors.black.withValues(alpha: 0.78))),

          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white70, size: 18),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withValues(alpha: 0.15),
                            border: Border.all(color: Colors.redAccent, width: 2.5),
                          ),
                          child: const Icon(Icons.admin_panel_settings,
                              color: Colors.redAccent, size: 46),
                        ),
                        const SizedBox(height: 20),
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: 'Admin ',
                                style: GoogleFonts.poppins(
                                    fontSize: 28, fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            TextSpan(
                                text: 'Portal',
                                style: GoogleFonts.poppins(
                                    fontSize: 28, fontWeight: FontWeight.bold,
                                    color: Colors.redAccent)),
                          ]),
                        ),
                        const SizedBox(height: 6),
                        Text('Authorized person only',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 36),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                children: [
                                  _inputField(
                                    controller: _userC,
                                    label: 'Admin Username',
                                    icon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 14),
                                  _inputField(
                                    controller: _passC,
                                    label: 'Password',
                                    icon: Icons.lock_outline,
                                    obscure: _obscure,
                                    suffix: IconButton(
                                      icon: Icon(
                                          _obscure ? Icons.visibility_off : Icons.visibility,
                                          color: Colors.white54, size: 18),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  if (_error != null) ...[
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(_error!,
                                            style: GoogleFonts.poppins(
                                                color: Colors.redAccent,
                                                fontSize: 12)),
                                      ),
                                    ]),
                                  ],
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity, height: 50,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: _loading
                                          ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5))
                                          : Text('Login',
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15)),
                                    ),
                                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      onSubmitted: (_) => _login(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.redAccent, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent)),
      ),
    );
  }
}