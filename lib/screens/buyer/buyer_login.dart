import 'package:argichain/reuseable/Login_reuseable.dart';
import 'package:flutter/material.dart';
import 'package:argichain/screens/buyer/buyer_register.dart';
import 'package:argichain/screens/buyer/buyer_dashboard.dart';

class BuyerLogin extends StatelessWidget {
  const BuyerLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return ReusableLogin(
      title: "Buyer",
      imagePath: "assets/images/B_BG.avif",
      registerPage: const BuyerRegister(),
      dashboardPage: BuyerDashboard(buyerName: 'Daniyal'),
      role: "buyer",
    );
  }
}