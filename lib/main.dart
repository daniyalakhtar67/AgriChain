import 'package:argichain/screens/buyer/buyer_register.dart';
import 'package:argichain/screens/farmer/farmer_login.dart';
import 'package:argichain/screens/welcome.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://srapvyhjbflepjttvbag.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNyYXB2eWhqYmZsZXBqdHR2YmFnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcwMjIxNTksImV4cCI6MjA5MjU5ODE1OX0.o6neJCR-RAV9SABa7s3RoN7NpBwB7pVU3ptElTOtzWo',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriChain',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/buyerRegister': (context) => const BuyerRegister(),
        '/farmerLogin': (context) => const FarmerLogin(),
      },
    );
  }
}
