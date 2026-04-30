import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ShopkeeperDashboard extends StatefulWidget {
  final String shopkeeperName;
  const ShopkeeperDashboard({super.key, required this.shopkeeperName});

  @override
  State<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends State<ShopkeeperDashboard> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    try {
      final data = await supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        allProducts = List<Map<String, dynamic>>.from(data);
        filteredProducts = allProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
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
      body: _currentIndex == 0
          ? _buildBuyItems()
          : _currentIndex == 1
          ? _buildSellItems()
          : _buildInfo(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
        onTap: (i) {
          if (i == 3) {
            _logout();
          } else {
            setState(() => _currentIndex = i);
          }
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey.shade900,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Buy Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Sell Items',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'Info.',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }

  // ── BUY ITEMS TAB ──
  Widget _buildBuyItems() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/images/DS.jpg', fit: BoxFit.cover),
        ),
        SizedBox.expand(
          child: Container(color: Colors.black.withValues(alpha: 0.65)),
        ),
        SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                                    text: 'Shop',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'keeper',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow,
                                    ),
                                  ),
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
                        onTap: () => setState(() => _currentIndex = 1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 26),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // SEARCH
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
                      hintText: 'Search',
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

              const SizedBox(height: 12),

              // TOP SELLING HEADER — GREY
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
                    Text('Top Selling',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                    Text(
                      'See all (${filteredProducts.length})',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // PRODUCT LIST
              Expanded(
                child: isLoading
                    ? const Center(
                    child:
                    CircularProgressIndicator(color: Colors.green))
                    : filteredProducts.isEmpty
                    ? Center(
                    child: Text('No products found',
                        style: GoogleFonts.poppins(
                            color: Colors.white)))
                    : RefreshIndicator(
                  onRefresh: fetchProducts,
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

  // ── SELL ITEMS TAB ──
  Widget _buildSellItems() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/images/Shop.jpg', fit: BoxFit.cover),
        ),
        SizedBox.expand(
          child: Container(color: Colors.black.withValues(alpha: 0.65)),
        ),
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
                                      color: Colors.green,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Items',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.yellow,
                                    ),
                                  ),
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
                        onTap: () => _showAddItemDialog(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                      .eq('seller_type', 'shopkeeper')
                      .order('created_at', ascending: false),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Colors.green));
                    }
                    final items = List<Map<String, dynamic>>.from(
                        snapshot.data ?? []);
                    if (items.isEmpty) {
                      return Center(
                        child: Text(
                          'No items listed yet\nTap + to add',
                          textAlign: TextAlign.center,
                          style:
                          GoogleFonts.poppins(color: Colors.white70),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: item['image_url'] != null
                                  ? CachedNetworkImage(
                                imageUrl: item['image_url'],
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                const Icon(Icons.image,
                                    color: Colors.white),
                              )
                                  : const Icon(Icons.store,
                                  color: Colors.green),
                            ),
                            title: Text(
                              item['title'] ?? '',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${item['category']} • ${item['price']}',
                              style: GoogleFonts.poppins(
                                  color: Colors.white70, fontSize: 12),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => _deleteItem(item['id']),
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

  // ── INFO TAB ──
  Widget _buildInfo() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/images/Shop.jpg', fit: BoxFit.cover),
        ),
        SizedBox.expand(
          child: Container(color: Colors.black.withValues(alpha: 0.65)),
        ),
        SafeArea(
          child: Center(
            child: Text('Info Coming Soon',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 20)),
          ),
        ),
      ],
    );
  }

  // ── ADD ITEM DIALOG ──
  void _showAddItemDialog() {
    final titleC    = TextEditingController();
    final categoryC = TextEditingController();
    final priceC    = TextEditingController();
    final locationC = TextEditingController();
    final imageC    = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Add Item',
              style: GoogleFonts.poppins(
                  color: Colors.yellow, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _dialogField('Title', titleC, Icons.title),
                _dialogField('Category', categoryC, Icons.category),
                _dialogField('Price', priceC, Icons.attach_money),
                _dialogField('Location', locationC, Icons.location_on),
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
                        content:
                        Text('Title, Category, Price required'),
                        backgroundColor: Colors.red),
                  );
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
                    'seller_type': 'shopkeeper',
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    fetchProducts();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Item Added!'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red),
                  );
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
      String label, TextEditingController c, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.yellow),
          prefixIcon: Icon(icon, color: Colors.yellow),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.yellow),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteItem(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      setState(() {});
      fetchProducts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item Removed!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ── PRODUCT CARD ──
class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              bottomLeft: Radius.circular(16),
            ),
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
                      color: Colors.green, strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 110,
                height: 100,
                color: Colors.grey.shade800,
                child: const Icon(Icons.image_not_supported,
                    color: Colors.white54),
              ),
            )
                : Container(
              width: 110,
              height: 100,
              color: Colors.grey.shade800,
              child: const Icon(Icons.image, color: Colors.white54),
            ),
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
                        child: Text(
                          product['title'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        product['price'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['location'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: Colors.white60),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product['category'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}