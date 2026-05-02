import 'package:argichain/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _mainCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _loaderCtrl;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _taglineFade;
  late Animation<double> _loaderFade;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _mainCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));

    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
        CurvedAnimation(parent: _mainCtrl,
            curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)));

    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainCtrl,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOut)));

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
        CurvedAnimation(parent: _mainCtrl,
            curve: const Interval(0.35, 0.65, curve: Curves.easeOut)));

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainCtrl,
            curve: const Interval(0.60, 0.85, curve: Curves.easeOut)));

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.25, end: 0.65)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _loaderCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _loaderFade = CurvedAnimation(parent: _loaderCtrl, curve: Curves.easeIn);

    _mainCtrl.forward();
    Future.delayed(const Duration(milliseconds: 1500),
            () { if (mounted) _loaderCtrl.forward(); });

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _pulseCtrl.dispose();
    _loaderCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background ────────────────────────────────────────────
          SizedBox.expand(
            child: Image.asset('assets/images/splash_bg.avif', fit: BoxFit.cover),
          ),
          SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.38),
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
            ),
          ),

          // ── Everything centered ───────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // Logo + pulse glow
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: _pulse.value),
                          blurRadius: 90,
                          spreadRadius: 18,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Image.asset(
                        'assets/images/splash_logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // AgriChain
                FadeTransition(
                  opacity: _titleFade,
                  child: SlideTransition(
                    position: _titleSlide,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14)),
                          ),
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              text: 'Agri',
                              style: GoogleFonts.montserrat(
                                fontSize: 56,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Chain',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 56,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.greenAccent,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10)),
                        ),
                        child: Text(
                          'Step Toward Transparent Agriculture',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.raleway(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Loader
                FadeTransition(
                  opacity: _loaderFade,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          color: Colors.greenAccent,
                          strokeWidth: 2.5,
                          backgroundColor:
                          Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'LOADING',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 6,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}