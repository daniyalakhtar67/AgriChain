import 'package:argichain/screens/buyer/buyer_login.dart';
import 'package:argichain/screens/farmer/farmer_login.dart';
import 'package:argichain/screens/shopkeeper/shopkepper_login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/W_bg.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  // ── TOP TITLE ──
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              color: Colors.black.withValues(alpha: 0.3),
                              child: RichText(
                                text: TextSpan(
                                  text: 'WELCOME TO ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'AgriChain',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFFFFD700),
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your Agricultural Marketplace',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white60,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── BUTTONS ──
                  SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        _RoleButton(
                          icon: Icons.agriculture,
                          label: 'Farmer',
                          subtitle: 'Buy & Sell Products',
                          color: const Color(0xFF1B5E20),
                          accentColor: Colors.greenAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FarmerLogin()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RoleButton(
                          icon: Icons.store,
                          label: 'Shopkeeper',
                          subtitle: 'Sell Farming Products',
                          color: const Color(0xFF33691E),
                          accentColor: Colors.yellowAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ShopkeeperLogin()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RoleButton(
                          icon: Icons.shopping_basket,
                          label: 'Buyer',
                          subtitle: 'Purchase Crops & Items',
                          color: const Color(0xFF558B2F),
                          accentColor: Colors.orangeAccent,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BuyerLogin()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── NOTES SECTION ──
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: 24, left: 16, right: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.black.withValues(alpha: 0.35),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _noteRow(Icons.agriculture,
                                  'Farmer — Sell & purchase products'),
                              const SizedBox(height: 8),
                              _noteRow(Icons.store,
                                  'Shopkeeper — Sell farming products'),
                              const SizedBox(height: 8),
                              _noteRow(Icons.shopping_basket,
                                  'Buyer — Purchase crops & items'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _noteRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFD700), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }
}

// ── ROLE BUTTON WIDGET ──
class _RoleButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_RoleButton> createState() => _RoleButtonState();
}

class _RoleButtonState extends State<_RoleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.accentColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ICON CIRCLE
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 28),
              ),
              const SizedBox(width: 16),
              // TEXT
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // ARROW
              Icon(
                Icons.arrow_forward_ios,
                color: widget.accentColor.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}