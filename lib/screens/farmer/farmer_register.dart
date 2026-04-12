import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FarmerRegister extends StatefulWidget {
  const FarmerRegister({super.key});

  @override
  State<FarmerRegister> createState() => _FarmerRegisterState();
}

class _FarmerRegisterState extends State<FarmerRegister> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: RichText(text: TextSpan(
          text: 'Agri', style: GoogleFonts.montserrat(
          fontSize: 22,
          fontStyle: FontStyle.italic,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),children: [
          TextSpan(
            text: 'Chain', style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          )
          )
        ]
        )),
      ),
      body: ,

    );
  }
}
