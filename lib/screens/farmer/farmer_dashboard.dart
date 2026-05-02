import 'dart:ui';
import 'package:argichain/screens/farmer/cart_screen.dart';
import 'package:argichain/screens/farmer/cropdetailscreen.dart';
import 'package:argichain/screens/farmer/product_details.dart';
import 'package:argichain/screens/farmer/crop_detail_screen.dart'; // ── NEW ──
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
    return Scaffold(
      body: _currentIndex == 0 ? _buildBuyItems() : _buildSellCrops(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          border: const Border(top: BorderSide(color: Colors.white12)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex > 1 ? 0 : _currentIndex,
          onTap: (i) {
            if (i == 2) {
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
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
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
              icon: Icon(Icons.logout),
              label: 'Logout',
            ),
          ],
        ),
      ),
    );
  }

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
                      hintStyle:
                      GoogleFonts.poppins(color: Colors.white60),
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
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
                          product: filteredProducts[index]);
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
                child: StatefulBuilder(
                  builder: (ctx, setS) => FutureBuilder(
                    future: supabase
                        .from('products')
                        .select()
                        .eq('seller_type', 'farmer')
                        .order('created_at', ascending: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(color: Colors.green));
                      }
                      final crops =
                      List<Map<String, dynamic>>.from(snapshot.data ?? []);
                      if (crops.isEmpty) {
                        return Center(
                            child: Text('No crops listed yet\nTap + to add',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(color: Colors.white70)));
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            // ── Crop pe click → CropDetailScreen ──
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CropDetailScreen(crop: crop),
                                ),
                              );
                              // Wapas aane par list refresh
                              setState(() {});
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white24),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${crop['category']} • ${crop['price']}',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    const SizedBox(height: 4),
                                    // ── KG badge — GREEN if stock, RED if 0 ──
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: hasStock
                                            ? Colors.green.withValues(alpha: 0.3)
                                            : Colors.red.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: hasStock
                                                ? Colors.greenAccent
                                                .withValues(alpha: 0.6)
                                                : Colors.redAccent
                                                .withValues(alpha: 0.6)),
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
                                  onPressed: () => _deleteCrop(crop['id']),
                                ),
                              ),
                            ),
                          );
                        },
                      );
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

  void _showAddCropDialog() {
    final titleC = TextEditingController();
    final categoryC = TextEditingController();
    final priceC = TextEditingController();
    final locationC = TextEditingController();
    final imageC = TextEditingController();
    final quantityKgC = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Crop',
              style: GoogleFonts.poppins(
                  color: Colors.yellow, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _dialogField('Title', titleC, Icons.title),
                _dialogField('Category', categoryC, Icons.category),
                _dialogField('Price', priceC, Icons.attach_money),
                _dialogField('Location', locationC, Icons.location_on),
                _dialogField(
                  'Quantity Available (KG)',
                  quantityKgC,
                  Icons.scale_outlined,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                ),
                _dialogField('Image URL (optional)', imageC, Icons.image),
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
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: saving
                  ? null
                  : () async {
                if (titleC.text.isEmpty ||
                    categoryC.text.isEmpty ||
                    priceC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                          Text('Title, Category, Price required'),
                          backgroundColor: Colors.red));
                  return;
                }
                setS(() => saving = true);
                try {
                  await supabase.from('products').insert({
                    'title': titleC.text.trim(),
                    'category': categoryC.text.trim(),
                    'price': priceC.text.trim(),
                    'location': locationC.text.trim(),
                    'image_url': imageC.text.trim().isEmpty
                        ? null
                        : imageC.text.trim(),
                    'seller_type': 'farmer',
                    'seller_name': widget.farmerName,
                    'crop_quantity_kg':
                    double.tryParse(quantityKgC.text.trim()) ?? 0,
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red));
                }
                setS(() => saving = false);
              },
              child: saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Add',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
      String label,
      TextEditingController c,
      IconData icon, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.yellow),
          prefixIcon: Icon(icon, color: Colors.yellow),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.yellow)),
        ),
      ),
    );
  }

  Future<void> _deleteCrop(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Crop Removed!'), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final stock = product['stock_quantity'];
    final stockText = (stock != null &&
        int.tryParse(stock.toString()) != null &&
        int.parse(stock.toString()) > 0)
        ? '${stock} in stock'
        : null;

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16)),
              child: product['image_url'] != null
                  ? CachedNetworkImage(
                imageUrl: product['image_url'],
                width: 110,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    width: 110,
                    height: 100,
                    color: Colors.grey.shade800,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: Colors.green, strokeWidth: 2))),
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
                  child: const Icon(Icons.image, color: Colors.white54)),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                            child: Text(product['title'] ?? '',
                                style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white))),
                        Text(product['price'] ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.greenAccent)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(product['location'] ?? '',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white60)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(product['category'] ?? '',
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
                                color: Colors.blue.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }
}