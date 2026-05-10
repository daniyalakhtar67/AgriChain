  import 'package:argichain/services/user_session.dart';
import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'dart:ui';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'package:argichain/screens/farmer/farmer_dashboard.dart';
  import 'package:argichain/screens/buyer/buyer_dashboard.dart';
  import 'package:argichain/screens/shopkeeper/shopkeeper_dashboard.dart';

  class ReusableLogin extends StatefulWidget {
    // Variable set at runtime
    final String title;
    final String imagePath;
    final Widget registerPage;
    final Widget dashboardPage;
    final String role;

    const ReusableLogin({
      super.key,
      required this.title,
      required this.imagePath,
      required this.registerPage,
      required this.dashboardPage,
      required this.role,
    });

    @override
    State<ReusableLogin> createState() => _ReusableLoginState();
  }

  class _ReusableLoginState extends State<ReusableLogin>
      with SingleTickerProviderStateMixin {
    final cnicController    = TextEditingController();
    final passwordController = TextEditingController();
    bool isLoading       = false;
    bool _obscurePass    = true;
    late AnimationController _animCtrl;
    late Animation<double>   _fadeAnim;
    late Animation<Offset>   _slideAnim;

    @override
    void initState() {
      super.initState();
      _animCtrl = AnimationController(
          vsync: this, duration: const Duration(milliseconds: 700));
      _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
      _slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
      _animCtrl.forward();
    }

    @override
    void dispose() {
      _animCtrl.dispose();
      cnicController.dispose();
      passwordController.dispose();
      super.dispose();
    }

    // Role ke hisaab se accent color
    Color get _accentColor {
      switch (widget.role) {
        case 'farmer':      return const Color(0xFF4CAF50);  // green
        case 'buyer':       return const Color(0xFF2196F3);  // blue
        case 'shopkeeper':  return const Color(0xFFFFC107);  // amber
        default:            return const Color(0xFF4CAF50);
      }
    }

    IconData get _roleIcon {
      switch (widget.role) {
        case 'farmer':     return Icons.agriculture;
        case 'buyer':      return Icons.shopping_basket_outlined;
        case 'shopkeeper': return Icons.storefront_outlined;
        default:           return Icons.person_outline;
      }
    }

    Future<void> loginUser() async {
      final cnic = cnicController.text.trim();
      final pass = passwordController.text.trim();

      if (cnic.isEmpty || pass.isEmpty) {
        _showSnack('Enter CNIC and Password', Colors.red);
        return;
      }

      setState(() => isLoading = true);

      try {
        // Step 1: find in users table
        final userResult = await Supabase.instance.client
            .from('users')
            .select()
            .eq('cnic', cnic)
            .eq('password', pass)
            .maybeSingle();

        if (userResult == null) {
          _showSnack('Invalid CNIC or Password', Colors.red);
          setState(() => isLoading = false);
          return;
        }

        if (userResult['status'] == 'inactive') {
          _showSnack('Your account is inactive.', Colors.orange);
          setState(() => isLoading = false);
          return;
        }

        if (userResult['is_verified'] == false) {
          _showSnack('Account not verified yet.', Colors.orange);
          setState(() => isLoading = false);
          return;
        }

        // Step 2: confirm role
        final userId = userResult['user_id'];
        final roleTable = widget.role == 'farmer' ? 'farmers'
            : widget.role == 'buyer'  ? 'buyers'
            : 'shopkeepers';

        final roleCheck = await Supabase.instance.client
            .from(roleTable)
            .select('user_id')
            .eq('user_id', userId)
            .maybeSingle();

        if (roleCheck == null) {
          _showSnack('No ${widget.role} account found.', Colors.red);
          setState(() => isLoading = false);
          return;
        }

        // Save session
        UserSession.setUser({...userResult, 'user_type': widget.role});

        final name = userResult['name'] ?? '';
        if (!mounted) return;

        final route = switch (widget.role) {
          'farmer'     => MaterialPageRoute(builder: (_) => FarmerDashboard(farmerName: name)),
          'buyer'      => MaterialPageRoute(builder: (_) => BuyerDashboard(buyerName: name)),
        // ✅ FIXED
          'shopkeeper' => MaterialPageRoute(builder: (_) => ShopkeeperDashboard(userId: UserSession.id, shopkeeperName: name)),
          _            => null,
        };

        if (route != null) Navigator.pushReplacement(context, route);

      } catch (e) {
        _showSnack('Error: ${e.toString()}', Colors.red);
      }

      setState(() => isLoading = false);
    }

    void _showSnack(String msg, Color color) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg, style: GoogleFonts.poppins()), backgroundColor: color),
      );
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
                    style: GoogleFonts.montserrat(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic, color: Colors.white,
                    ),
                    children: [
                      TextSpan(
                        text: 'Chain',
                        style: GoogleFonts.montserrat(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic, color: Colors.yellow,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          centerTitle: true,
        ),

        body: Stack(
          children: [
            // Background image
            SizedBox.expand(
              child: Image.asset(widget.imagePath, fit: BoxFit.cover),
            ),
            // Dark overlay
            SizedBox.expand(
              child: Container(color: Colors.black.withValues(alpha: 0.55)),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 28),

                        // ── ROLE BADGE + TITLE ──────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _accentColor.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Icon circle
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _accentColor.withValues(alpha: 0.18),
                                      border: Border.all(color: _accentColor, width: 2),
                                    ),
                                    child: Icon(_roleIcon, color: _accentColor, size: 34),
                                  ),
                                  const SizedBox(height: 14),
                                  // Title
                                  Text(
                                    widget.title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Welcome back! Please sign in.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),


                        // ── LOGIN FORM ──────────────────────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.38),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // CNIC
                                  _fieldLabel('CNIC Number', Icons.badge_outlined),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: cnicController,
                                    hint: '12345-1234567-1',
                                    keyboardType: TextInputType.number,
                                    maxLength: 15,
                                    inputFormatters: [CnicFormatter()],
                                    accentColor: _accentColor,
                                  ),

                                  const SizedBox(height: 20),

                                  // Password
                                  _fieldLabel('Password', Icons.lock_outline),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: passwordController,
                                    hint: 'Enter your password',
                                    obscureText: _obscurePass,
                                    accentColor: _accentColor,
                                    suffixIcon: GestureDetector(
                                      onTap: () => setState(() => _obscurePass = !_obscurePass),
                                      child: Icon(
                                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: Colors.white54, size: 20,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // Login button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _accentColor,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: isLoading ? null : loginUser,
                                      child: isLoading
                                          ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2.5))
                                          : Text('LOGIN',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          )),
                                    ),
                                  ),

                                  const SizedBox(height: 18),

                                  // Register link
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: GoogleFonts.poppins(
                                              fontSize: 13, color: Colors.white60),
                                        ),
                                        GestureDetector(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => widget.registerPage),
                                          ),
                                          child: Text(
                                            'Register Now',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _accentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
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

    Widget _fieldLabel(String label, IconData icon) {
      return Row(
        children: [
          Icon(icon, color: _accentColor, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ],
      );
    }

    Widget _buildTextField({
      required TextEditingController controller,
      required String hint,
      bool obscureText = false,
      TextInputType keyboardType = TextInputType.text,
      int? maxLength,
      List<TextInputFormatter>? inputFormatters,
      required Color accentColor,
      Widget? suffixIcon,
    }) {
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: GoogleFonts.poppins(fontSize: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.white38),
          counterStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 11),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.07),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.8),
          ),
        ),
      );
    }
  }

  class CnicFormatter extends TextInputFormatter {
    @override
    TextEditingValue formatEditUpdate(
        TextEditingValue oldValue,
        TextEditingValue newValue,
        ) {
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