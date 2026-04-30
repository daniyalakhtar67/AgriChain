import 'package:argichain/reuseable/Login_reuseable.dart';
import 'package:flutter/material.dart';
import 'package:argichain/screens/shopkeeper/shopkeeper_register.dart';
import 'package:argichain/screens/shopkeeper/shopkeeper_dashboard.dart';

class ShopkeeperLogin extends StatelessWidget {
  const ShopkeeperLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return ReusableLogin(
      title: "Shopkeeper",
      imagePath: "assets/images/SH.avif",
      registerPage: const ShopkeeperRegister(),
      dashboardPage:  ShopkeeperDashboard(shopkeeperName: 'Daniyal'),
      role: "shopkeeper",
    );
  }
}