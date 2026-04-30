import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:argichain/screens/farmer/farmer_dashboard.dart';
import 'package:argichain/screens/buyer/buyer_dashboard.dart';
import 'package:argichain/screens/shopkeeper/shopkeeper_dashboard.dart';

class ReusableLogin extends StatefulWidget {
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

class _ReusableLoginState extends State<ReusableLogin> {
  final cnicController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> loginUser() async {
    final cnic = cnicController.text.trim();
    final pass = passwordController.text.trim();

    if (cnic.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter CNIC and Password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String table = '';
      if (widget.role == 'farmer') table = 'farmers';
      else if (widget.role == 'buyer') table = 'buyers';
      else if (widget.role == 'shopkeeper') table = 'shopkeepers';

      final result = await Supabase.instance.client
          .from(table)
          .select()
          .eq('cnic', cnic)
          .eq('password', pass)
          .maybeSingle();

      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid CNIC or Password'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isLoading = false);
        return;
      }

      final name = result['full_name'] ?? '';

      if (widget.role == 'farmer') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => FarmerDashboard(farmerName: name)));
      } else if (widget.role == 'buyer') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => BuyerDashboard(buyerName: "Daniyal")));
      } else if (widget.role == 'shopkeeper') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => ShopkeeperDashboard(shopkeeperName: name)));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => isLoading = false);
  }

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
            image: AssetImage(widget.imagePath),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Column(
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow.shade600,
                  ),
                ),
                const SizedBox(height: 20),
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
                                color: Colors.yellow,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: cnicController,
                              keyboardType: TextInputType.number,
                              maxLength: 15,
                              inputFormatters: [CnicFormatter()],
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '12345-1234567-1',
                                counterStyle: const TextStyle(color: Colors.white60),
                                hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.white60),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.yellow),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('PASSWORD :',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.yellow,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter Password',
                                hintStyle: GoogleFonts.poppins(fontSize: 16, color: Colors.white60),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Colors.yellow),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              children: [
                                Text("Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.red.shade300,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => widget.registerPage));
                                  },
                                  child: Text('REGISTER NOW',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
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
                const SizedBox(height: 24),
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
                    onPressed: isLoading ? null : loginUser,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('LOGIN',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
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