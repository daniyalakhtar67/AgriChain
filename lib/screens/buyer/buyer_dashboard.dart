import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BuyerDashboard extends StatefulWidget {
  final String buyerName;
  const BuyerDashboard({super.key, required this.buyerName});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  final supabase = Supabase.instance.client;
  final searchController = TextEditingController();

  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  int _currentIndex = 0;
  String _filter = 'all'; // all, farmer, shopkeeper

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
      var query = supabase.from('products').select();
      if (_filter != 'all') {
        query = query.eq('seller_type', _filter) as dynamic;
      }
      final data = await query.order('created_at', ascending: false);
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
      body: _currentIndex == 0 ? _buildBuyScreen() : _buildInfo(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex > 1 ? 0 : _currentIndex,
        onTap: (i) {
          if (i == 2) {
            _logout();
          } else {
            setState(() => _currentIndex = i);
          }
        },
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Buy Crops',
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

  Widget _buildBuyScreen() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/images/DB.jpg', fit: BoxFit.cover),
        ),
        SizedBox.expand(
          child: Container(color: Colors.black.withValues(alpha: 0.65)),
        ),
        SafeArea(
          child: Column(
            children: [
              // ── HEADER ──
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
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            color: Colors.black.withValues(alpha: 0.3),
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Buy',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'er',
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
                  ],
                ),
              ),

              // ── SEARCH BAR ──
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
                      hintText: 'Search crops, equipment...',
                      hintStyle: GoogleFonts.poppins(color: Colors.white60),
                      prefixIcon: const Icon(Icons.search, color: Colors.white60),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── FILTER CHIPS ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Farmers', 'farmer'),
                    const SizedBox(width: 8),
                    _filterChip('Shops', 'shopkeeper'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── TRENDING HEADER ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Trending',
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

              // ── PRODUCT LIST ──
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.green))
                    : filteredProducts.isEmpty
                    ? Center(
                    child: Text('No products found',
                        style: GoogleFonts.poppins(color: Colors.white)))
                    : RefreshIndicator(
                  onRefresh: fetchProducts,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return _ProductCard(product: filteredProducts[index]);
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

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
          isLoading = true;
        });
        fetchProducts();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.green : Colors.white24),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset('assets/images/Buyer_bg.jpg', fit: BoxFit.cover),
        ),
        SizedBox.expand(
          child: Container(color: Colors.black.withValues(alpha: 0.65)),
        ),
        SafeArea(
          child: Center(
            child: Text('Info Coming Soon',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 20)),
          ),
        ),
      ],
    );
  }
}

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product['seller_type'] == 'farmer' ? '🌾 Farmer' : '🏪 Shop',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
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