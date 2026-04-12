import 'package:argichain/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:argichain/screens/shopkeeper/shopkeeper_register.dart';
import 'package:argichain/screens/shopkeeper/shopkeeper_dashboard.dart';
import 'package:flutter/services.dart';
class ShopkeeperLogin extends StatefulWidget {
  const ShopkeeperLogin({super.key});
  @override
  State<ShopkeeperLogin> createState() => _ShopkeeperLoginState();
}

class _ShopkeeperLoginState extends State<ShopkeeperLogin> {

  final cnicController = TextEditingController();
  final passwordController = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            text: 'Agri',
            style: GoogleFonts.montserrat(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              color: Colors.white,
            ),
            children: [
              TextSpan(
                text: 'Chain',
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: Colors.yellow,
                ),
              ),
            ],
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Shop.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(top: 150),
            child: Column(
              children: [
                Text('Shopkeeper',
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.shade600,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        color: Colors.black.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CNIC No :',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                              ),
                            ),
                            SizedBox(height: 6),
                            TextField(
                              controller: cnicController,
                              keyboardType: TextInputType.number,
                              maxLength: 15,
                              inputFormatters: [CnicFormatter()],
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '12345-1234567-1',
                                counterStyle: TextStyle(color: Colors.white60),
                                hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.white60),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.yellow),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.yellow, width: 2),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text('PASSWORD :',
                              style: GoogleFonts.poppins(
                                fontSize: 18, // ← bara
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                              ),
                            ),
                            SizedBox(height: 6),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: GoogleFonts.poppins(
                                fontSize: 16, // ← bara
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Enter Password',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white60,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: Colors.yellow),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.yellow,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: 16),

                            Wrap(
                              children: [
                                Text("Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16, // ← bara
                                    color: Colors.red.shade300,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => ShopkeeperRegister()));
                                  },
                                  child: Text('REGISTER NOW',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16, // ← bara
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 24),

                SizedBox(
                  width: 250,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () async {
                      var result = await DatabaseService.instance.loginShopkeeper(
                        cnicController.text,
                        passwordController.text,
                      );
                      if (!mounted) return;
                      final ctx = context; // ← ye add karo
                      if (result != null) {
                        Navigator.pushReplacement(ctx,
                            MaterialPageRoute(builder: (_) => ShopkeeperDashboard()));
                      } else {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Wrong CNIC or Password!')),
                        );
                      }
                    },
                    child: Text('LOGIN',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
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