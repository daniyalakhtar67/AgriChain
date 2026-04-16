import 'package:argichain/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/splash_bg.avif'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
          
              Column(
                children: [
                  SizedBox(height: 90),
          
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/splash_logo.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          
                  SizedBox(height: 23),
          
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        color: Colors.white.withValues(alpha: 0.1),
                        child: RichText(
                          text: TextSpan(
                            text: 'Agri',
                            style: GoogleFonts.montserrat(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Chain',
                                style: GoogleFonts.montserrat(
                                  fontSize: 60,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          
                  SizedBox(height: 15),
          
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        color: Colors.white.withValues(alpha: 0.1),
                        child: Text(
                          'Step Toward Transparent Agriculture',
                          style: GoogleFonts.raleway(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          
              Padding(
                padding: EdgeInsets.only(bottom: 50),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'LOADING.....',
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
          
            ],
          ),
        ),
      ),
    );
  }
}