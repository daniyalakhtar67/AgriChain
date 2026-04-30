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

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/W_bg.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 60),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      color: Colors.black.withValues(alpha: 0.25),
                      child: RichText(
                        text: TextSpan(
                          text: 'WELCOME TO ',
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          children: [
                            TextSpan(
                              text: 'AgriChain',
                              style: GoogleFonts.montserrat(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              Column(
                children: [

                  ElevatedButton.icon(
                    icon: Icon(Icons.agriculture, color: Colors.white, size: 26),
                    label: Text('Farmer', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32).withValues(alpha: 0.85),
                      minimumSize: Size(280, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => FarmerLogin(),)),
                  ),

                  SizedBox(height: 16),

                  ElevatedButton.icon(
                    icon: Icon(Icons.store, color: Colors.white, size: 26),
                    label: Text('Shopkeeper', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32).withValues(alpha: 0.85),
                      minimumSize: Size(280, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShopkeeperLogin(),)),
                  ),

                  SizedBox(height: 16),

                  ElevatedButton.icon(
                    icon: Icon(Icons.shopping_basket, color: Colors.white, size: 26),
                    label: Text('Buyer', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2E7D32).withValues(alpha: 0.85),
                      minimumSize: Size(280, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BuyerLogin())),
                  ),

                ],
              ),

              Padding(
                padding: EdgeInsets.only(bottom: 20, left: 16, right: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.black.withValues(alpha: 0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(text: TextSpan(children: [
                            TextSpan(text: 'Note: ', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                            TextSpan(text: 'Press Farmer if you want to sell & purchase products.', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
                          ])),
                          SizedBox(height: 8),
                          RichText(text: TextSpan(children: [
                            TextSpan(text: 'Note: ', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                            TextSpan(text: 'Press Shopkeeper if you want to sell products.', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
                          ])),
                          SizedBox(height: 8),
                          RichText(text: TextSpan(children: [
                            TextSpan(text: 'Note: ', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFD700))),
                            TextSpan(text: 'Press Buyer if you want to purchase products.', style: GoogleFonts.poppins(fontSize: 20, color: Colors.white)),
                          ])),
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
    );
  }
}