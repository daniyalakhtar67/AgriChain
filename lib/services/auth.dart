// import 'package:flutter/cupertino.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// class AuthService {
//   final _nameController = TextEditingController();
//   final _cnicController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _passwordController = TextEditingController();
//
//   final _ageController = TextEditingController();
//   final _shopNameController = TextEditingController();
//   final _shopAddressController = TextEditingController();
//
//   final _emailController = TextEditingController();
//   final _landController = TextEditingController();
//   final _farmLocationController = TextEditingController();
//   final _homeAddressController = TextEditingController();
//   final supabase = Supabase.instance.client;
//   Future<void> buildUserData(String role) async {
//     final Map<String, dynamic> data = {};
//
//     // COMMON FIELDS (must exist in all roles)
//     final name = _nameController.text.trim();
//     final cnic = _cnicController.text.trim();
//     final phone = _phoneController.text.trim();
//     final password = _passwordController.text.trim();
//
//     data.addAll({
//       'name': name,
//       'cnic': cnic,
//       'phone': phone,
//       'password': password,
//       'role': role,
//     });
//
//     // SHOPKEEPER
//     if (role == 'shopkeeper') {
//       final age = _ageController.text.trim();
//       final shopName = _shopNameController.text.trim();
//       final shopAddress = _shopAddressController.text.trim();
//
//       data.addAll({
//         'age': age,
//         'shop_name': shopName,
//         'shop_address': shopAddress,
//       });
//     }
//
//     // FARMER
//     if (role == 'farmer') {
//       final email = _emailController.text.trim();
//       final landAcres = _landController.text.trim();
//       final farmLocation = _farmLocationController.text.trim();
//       final homeAddress = _homeAddressController.text.trim();
//
//       data.addAll({
//         'email': email,
//         'land_acres': landAcres,
//         'farm_location': farmLocation,
//         'home_address': homeAddress,
//       });
//     }
//
//     // BUYER
//     if (role == 'buyer') {
//       final homeAddress = _homeAddressController.text.trim();
//
//       data.addAll({
//         'home_address': homeAddress,
//       });
//     }
//
//     // 🔥 SUPABASE INSERT
//     try {
//       await Supabase.instance.client.from('users').insert(data);
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Registered Successfully")),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error: $e")),
//         );
//       }
//     }
//   }
//   }
// }