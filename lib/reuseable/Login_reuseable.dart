import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class CommonLogin extends StatelessWidget {
  final String title;
  final String bgImage;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  final TextEditingController cnicController;
  final TextEditingController passwordController;

  const CommonLogin({
    super.key,
    required this.title,
    required this.bgImage,
    required this.onLogin,
    required this.onRegister,
    required this.cnicController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: TextSpan(
            text: 'Agri',
            style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Colors.white),
            children: [
              TextSpan(
                  text: 'Chain',
                  style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.yellow)),
            ],
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(bgImage),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Column(
              children: [
                Text(title,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellow.shade600,
                      shadows: const [
                        Shadow(
                            blurRadius: 10,
                            color: Colors.black,
                            offset: Offset(2, 2))
                      ],
                    )),
                const SizedBox(height: 20),

                /// FORM BOX
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        color: Colors.black.withValues(alpha: 0.4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('CNIC No :',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow)),
                            const SizedBox(height: 6),

                            TextField(
                              controller: cnicController,
                              keyboardType: TextInputType.number,
                              maxLength: 15,
                              inputFormatters: [CnicFormatter()],
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.white),
                              decoration: inputStyle('12345-1234567-1'),
                            ),

                            const SizedBox(height: 16),

                            Text('PASSWORD :',
                                style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.yellow)),
                            const SizedBox(height: 6),

                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: GoogleFonts.poppins(
                                  fontSize: 16, color: Colors.white),
                              decoration: inputStyle('Enter Password'),
                            ),

                            const SizedBox(height: 16),

                            Wrap(
                              children: [
                                Text("Don't have an account? ",
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                                GestureDetector(
                                  onTap: onRegister,
                                  child: Text('REGISTER NOW',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.yellow)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                /// LOGIN BUTTON
                SizedBox(
                  width: 250,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: onLogin,
                    child: Text('LOGIN',
                        style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      counterStyle: const TextStyle(color: Colors.white60),
      hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.white60),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.yellow),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.yellow, width: 2),
      ),
    );
  }
}

/// CNIC Formatter same reuse
class CnicFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(oldValue, newValue) {
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