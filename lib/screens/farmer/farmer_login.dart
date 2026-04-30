import 'package:argichain/reuseable/Login_reuseable.dart';
import 'package:flutter/material.dart';
import 'package:argichain/reuseable/login_reusable.dart';
import 'package:argichain/screens/farmer/farmer_register.dart';
import 'package:argichain/screens/farmer/farmer_dashboard.dart';

class FarmerLogin extends StatelessWidget {
  const FarmerLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return ReusableLogin(
      title: "Farmer",
      imagePath: "assets/images/F_bg.jpg",
      registerPage: const FarmerRegister(),
      dashboardPage: FarmerDashboard(farmerName: 'Daniyal'),
      role: "farmer", // 🔥 ADDED
    );
  }
}