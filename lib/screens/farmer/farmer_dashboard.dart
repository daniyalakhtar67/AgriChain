// lib/screens/farmer/farmer_dashboard.dart
// ── FIXES:
//    1. _ProductCard now has "+ Add" button that adds directly to cart
//    2. Payment method shown correctly on crop listing
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui';
import 'package:argichain/screens/farmer/cart_screen.dart';
import 'package:argichain/screens/farmer/crop_detail_screen.dart';
import 'package:argichain/screens/farmer/cropdetailscreen.dart';
import 'package:argichain/screens/farmer/payment.dart';
import 'package:argichain/screens/farmer/product_details.dart';
import 'package:argichain/utils/payment_methods.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FarmerDashboard extends StatefulWidget {
  final String farmerName;
  const FarmerDashboard({super.key, required this.farmerName});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchShopkeeperProducts();
    searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchShopkeeperProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select()
          .eq('seller_type', 'shopkeeper')
          .order('created_at', ascending: false);
      setState(() {
        allProducts = List<Map<String, dynamic>>.from(data);
        filteredProducts = allProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onSearch() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProducts = allProducts.where((p) {
        return p['title'].toString().toLowerCase().contains(query) ||
            p['category'].toString().toLowerCase().contains(query);
      }).toList();
    });
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_currentIndex == 0) {
      body = _buildBuyItems();
    } else if (_currentIndex == 1) {
      body = _buildSellCrops();
    } else {
      body = _buildFarmerProfile();
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: const Border(top: BorderSide(color: Colors.white12)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 3) {
              _logout();
            } else {
              setState(() => _currentIndex = i);
            }
          },
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle:
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Buy Equipment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grass_outlined),
              activeIcon: Icon(Icons.grass),
              label: 'Sell Crops',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout),
              label: 'Logout',
            ),
          ],
        ),
      ),
    );
  }

  // ── BUY ITEMS TAB ──────────────────────────────────────────────────────────
  Widget _buildBuyItems() {
    return Stack(
      children: [
        SizedBox.expand(
            child: Image.asset('assets/images/DF.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(color: Colors.black.withValues(alpha: 0.65))),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            color: Colors.black.withValues(alpha: 0.3),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                      text: 'Far',
                                      style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  TextSpan(
                                      text: 'mer',
                                      style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.shopping_cart_outlined,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search equipment...',
                      hintStyle: GoogleFonts.poppins(color: Colors.white60),
                      prefixIcon:
                      const Icon(Icons.search, color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade600),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shop Equipment',
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text('See all (${filteredProducts.length})',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: isLoading
                    ? const Center(
                    child:
                    CircularProgressIndicator(color: Colors.green))
                    : filteredProducts.isEmpty
                    ? Center(
                    child: Text('No equipment found',
                        style: GoogleFonts.poppins(
                            color: Colors.white)))
                    : RefreshIndicator(
                  onRefresh: fetchShopkeeperProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _ProductCard(
                          product: filteredProducts[index],
                          onCartUpdate: () => setState(() {}));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── SELL CROPS TAB ─────────────────────────────────────────────────────────
  Widget _buildSellCrops() {
    return Stack(
      children: [
        SizedBox.expand(
            child: Image.asset('assets/images/DF.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(color: Colors.black.withValues(alpha: 0.65))),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            color: Colors.black.withValues(alpha: 0.3),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                      text: 'Sell ',
                                      style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  TextSpan(
                                      text: 'Crops',
                                      style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _showAddCropDialog(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: supabase
                      .from('products')
                      .select()
                      .eq('seller_type', 'farmer')
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.green));
                    }
                    final crops = List<Map<String, dynamic>>.from(
                        snapshot.data ?? []);
                    if (crops.isEmpty) {
                      return Center(
                          child: Text(
                            'No crops listed yet\nTap + to add',
                            textAlign: TextAlign.center,
                            style:
                            GoogleFonts.poppins(color: Colors.white70),
                          ));
                    }
                    return ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: crops.length,
                      itemBuilder: (context, index) {
                        final crop = crops[index];
                        final kgQty = crop['crop_quantity_kg'];
                        final kgVal = (kgQty != null &&
                            double.tryParse(kgQty.toString()) != null)
                            ? double.parse(kgQty.toString())
                            : 0.0;
                        final bool hasStock = kgVal > 0;

                        return GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CropDetailScreen(crop: crop),
                              ),
                            );
                            setState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color:
                              Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border:
                              Border.all(color: Colors.white24),
                            ),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: crop['image_url'] != null
                                    ? CachedNetworkImage(
                                    imageUrl: crop['image_url'],
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                    const Icon(Icons.image,
                                        color: Colors.white))
                                    : const Icon(Icons.grass,
                                    color: Colors.green),
                              ),
                              title: Text(crop['title'] ?? '',
                                  style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${crop['category']} • ${crop['price']}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  if (crop['payment_method'] != null &&
                                      crop['payment_method']
                                          .toString()
                                          .isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 4),
                                      child: Text(
                                        '💳 ${crop['payment_method']}',
                                        style: GoogleFonts.poppins(
                                            color:
                                            Colors.lightBlueAccent,
                                            fontSize: 11),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: hasStock
                                          ? Colors.green
                                          .withValues(alpha: 0.3)
                                          : Colors.red
                                          .withValues(alpha: 0.3),
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      border: Border.all(
                                          color: hasStock
                                              ? Colors.greenAccent
                                              .withValues(alpha: 0.6)
                                              : Colors.redAccent
                                              .withValues(
                                              alpha: 0.6)),
                                    ),
                                    child: Text(
                                      hasStock
                                          ? '📦 Available: ${kgVal.toStringAsFixed(1)} KG'
                                          : '❌ Not Available',
                                      style: GoogleFonts.poppins(
                                          color: hasStock
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () =>
                                    _deleteCrop(crop['id']),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── FARMER PROFILE TAB ────────────────────────────────────────────────────
  Widget _buildFarmerProfile() {
    return Stack(
      children: [
        SizedBox.expand(
            child: Image.asset('assets/images/DF.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(color: Colors.black.withValues(alpha: 0.65))),
        SafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 10),
                      color: Colors.black.withValues(alpha: 0.3),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: 'My ',
                                style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            TextSpan(
                                text: 'Profile',
                                style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green, width: 3),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child:
                  const Icon(Icons.person, color: Colors.green, size: 48),
                ),
                const SizedBox(height: 14),
                Text(widget.farmerName,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text('🌾 Farmer',
                      style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 28),
                _profileInfoCard(
                  icon: Icons.person_outline,
                  label: 'Name',
                  value: widget.farmerName,
                ),
                const SizedBox(height: 12),
                _profileInfoCard(
                  icon: Icons.agriculture_outlined,
                  label: 'Role',
                  value: 'Farmer — Crop Seller',
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditProfileDialog(),
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.yellow),
                    label: Text('Edit Profile',
                        style: GoogleFonts.poppins(
                            color: Colors.yellow,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.yellow),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileInfoCard(
      {required IconData icon,
        required String label,
        required String value}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.greenAccent, size: 22),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 11)),
                  Text(value,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameC = TextEditingController(text: widget.farmerName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Profile',
            style: GoogleFonts.poppins(
                color: Colors.yellow, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            dialogField('Name', nameC, Icons.person_outline,
                accentColor: Colors.yellow),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Profile Updated! ✅'),
                    backgroundColor: Colors.green),
              );
            },
            child: Text('Save',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── ADD CROP DIALOG ───────────────────────────────────────────────────────
  void _showAddCropDialog() {
    final titleC      = TextEditingController();
    final categoryC   = TextEditingController();
    final priceC      = TextEditingController();
    final locationC   = TextEditingController();
    final imageC      = TextEditingController();
    final quantityKgC = TextEditingController();
    final accNumberC  = TextEditingController();

    String? selectedPaymentId;
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final selectedMethod = selectedPaymentId != null
              ? kPaymentMethods
              .firstWhere((m) => m.id == selectedPaymentId)
              : null;
          final needsAccount = selectedMethod?.requiresAccount ?? false;

          return AlertDialog(
            backgroundColor: Colors.grey.shade900,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Text('Add Crop',
                style: GoogleFonts.poppins(
                    color: Colors.yellow, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  dialogField('Title', titleC, Icons.title,
                      accentColor: Colors.yellow),
                  dialogField('Category', categoryC, Icons.category,
                      accentColor: Colors.yellow),
                  dialogField('Price', priceC, Icons.attach_money,
                      accentColor: Colors.yellow),
                  dialogField('Location', locationC, Icons.location_on,
                      accentColor: Colors.yellow),
                  dialogField(
                    'Quantity Available (KG)',
                    quantityKgC,
                    Icons.scale_outlined,
                    accentColor: Colors.yellow,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                  ),
                  dialogField(
                      'Image URL (optional)', imageC, Icons.image,
                      accentColor: Colors.yellow),

                  const SizedBox(height: 10),

                  PaymentSelector(
                    selectedId: selectedPaymentId,
                    onChanged: (id) =>
                        setS(() => selectedPaymentId = id),
                    accountController: accNumberC,
                    accentColor: Colors.yellow,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green),
                onPressed: saving
                    ? null
                    : () async {
                  if (titleC.text.isEmpty ||
                      categoryC.text.isEmpty ||
                      priceC.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Title, Category, Price required'),
                            backgroundColor: Colors.red));
                    return;
                  }
                  if (selectedPaymentId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Payment method select karo!'),
                            backgroundColor: Colors.orange));
                    return;
                  }
                  if (needsAccount &&
                      accNumberC.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Account number daalo!'),
                            backgroundColor: Colors.orange));
                    return;
                  }

                  setS(() => saving = true);
                  try {
                    await supabase.from('products').insert({
                      'title': titleC.text.trim(),
                      'category': categoryC.text.trim(),
                      'price': priceC.text.trim(),
                      'location': locationC.text.trim(),
                      'image_url':
                      imageC.text.trim().isEmpty
                          ? null
                          : imageC.text.trim(),
                      'seller_type': 'farmer',
                      'seller_name': widget.farmerName,
                      'crop_quantity_kg':
                      double.tryParse(
                          quantityKgC.text.trim()) ??
                          0,
                      'payment_method':
                      selectedMethod?.name ?? '',
                      'payment_account': needsAccount
                          ? accNumberC.text.trim()
                          : null,
                    });
                    if (mounted) {
                      Navigator.pop(ctx);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Crop Added! ✅'),
                              backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                  }
                  setS(() => saving = false);
                },
                child: saving
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : Text('Add',
                    style:
                    GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteCrop(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Crop Removed!'),
            backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}

// ── PRODUCT CARD — with + Add button ─────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onCartUpdate;
  const _ProductCard({required this.product, required this.onCartUpdate});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  final supabase = Supabase.instance.client;
  bool _adding = false;

  Future<void> _addToCart() async {
    final stock = widget.product['stock_quantity'];
    final stockVal = (stock != null && int.tryParse(stock.toString()) != null)
        ? int.parse(stock.toString())
        : 0;

    if (stockVal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item out of stock!'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      await supabase.from('farmer_cart').insert({
        'product_id': widget.product['id'],
        'product_title': widget.product['title'],
        'product_price': widget.product['price'],
        'product_image': widget.product['image_url'],
        'seller_name': widget.product['seller_name'],
        'seller_type': widget.product['seller_type'],
        'quantity': 1,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Added to Cart!',
                    style: GoogleFonts.poppins(color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CartScreen()));
                  },
                  child: Text('View Cart',
                      style: GoogleFonts.poppins(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        widget.onCartUpdate();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.product['stock_quantity'];
    final stockVal = (stock != null &&
        int.tryParse(stock.toString()) != null &&
        int.parse(stock.toString()) > 0)
        ? int.parse(stock.toString())
        : 0;
    final bool inStock = stockVal > 0;
    final String? stockText = inStock ? '$stockVal in stock' : null;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ProductDetailScreen(product: widget.product))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          children: [
            // ── Main product row ──
            Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16)),
                  child: widget.product['image_url'] != null
                      ? CachedNetworkImage(
                    imageUrl: widget.product['image_url'],
                    width: 110,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                        width: 110,
                        height: 100,
                        color: Colors.grey.shade800,
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: 2))),
                    errorWidget: (context, url, error) => Container(
                        width: 110,
                        height: 100,
                        color: Colors.grey.shade800,
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white54)),
                  )
                      : Container(
                      width: 110,
                      height: 100,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.image,
                          color: Colors.white54)),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                                child: Text(
                                    widget.product['title'] ?? '',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))),
                            Text(widget.product['price'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.greenAccent)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.product['location'] ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.white60)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: Colors.green
                                      .withValues(alpha: 0.3),
                                  borderRadius:
                                  BorderRadius.circular(8)),
                              child: Text(
                                  widget.product['category'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.w500)),
                            ),
                            if (stockText != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: Colors.blue
                                        .withValues(alpha: 0.25),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.lightBlueAccent
                                            .withValues(alpha: 0.4))),
                                child: Text('📦 $stockText',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.lightBlueAccent,
                                        fontWeight: FontWeight.w500)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── + Add to Cart button at bottom ──
            Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Row(
                children: [
                  // Price repeated for quick scan
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Text(
                        inStock ? '✅ In Stock' : '❌ Out of Stock',
                        style: GoogleFonts.poppins(
                          color:
                          inStock ? Colors.greenAccent : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // + Add Button
                  GestureDetector(
                    onTap: _adding ? null : _addToCart,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: inStock
                            ? Colors.green
                            : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _adding
                          ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text('Add',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}