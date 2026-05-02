import 'dart:ui';
import 'package:argichain/screens/farmer/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Quantity selector
  int _selectedQty = 1;
  int _maxStock = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    // Parse stock quantity
    final stock = widget.product['stock_quantity'];
    _maxStock =
    (stock != null && int.tryParse(stock.toString()) != null)
        ? int.parse(stock.toString())
        : 0;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_maxStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item out of stock!'),
            backgroundColor: Colors.red),
      );
      return;
    }
    try {
      await supabase.from('farmer_cart').insert({
        'product_id': widget.product['id'],
        'product_title': widget.product['title'],
        'product_price': widget.product['price'],
        'product_image': widget.product['image_url'],
        'seller_name': widget.product['seller_name'],
        'seller_type': widget.product['seller_type'],
        'quantity': _selectedQty,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('$_selectedQty item(s) added to Cart!',
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final title = widget.product['title'] ?? 'this product';
    final price = widget.product['price'] ?? 'N/A';
    final sellerPhone = widget.product['seller_phone'] ?? '';
    final message = Uri.encodeComponent(
        'Hello! I am interested in "$title" priced at $price. I want to order $_selectedQty unit(s).');
    final cleanPhone = sellerPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final Uri uri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$message')
        : Uri.parse('https://wa.me/?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
              child: Image.asset('assets/images/DF.jpg', fit: BoxFit.cover)),
          SizedBox.expand(
              child: Container(color: Colors.black.withValues(alpha: 0.70))),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _buildDetailView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final p = widget.product;
    final bool isOutOfStock = _maxStock <= 0;

    return Column(
      children: [
        // ── App Bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(p['title'] ?? '',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen())),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(Icons.shopping_cart_outlined,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product Image ──
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: p['image_url'] != null
                          ? CachedNetworkImage(
                          imageUrl: p['image_url'],
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              height: 220,
                              color: Colors.grey.shade800,
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.green))),
                          errorWidget: (_, __, ___) => Container(
                              height: 220,
                              color: Colors.grey.shade800,
                              child: const Icon(Icons.image_not_supported,
                                  color: Colors.white54, size: 60)))
                          : Container(
                          height: 220,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.image,
                              color: Colors.white54, size: 60)),
                    ),
                    // ── Stock overlay badge on image ──
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.withValues(alpha: 0.85)
                              : Colors.green.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isOutOfStock
                                  ? Icons.cancel_outlined
                                  : Icons.inventory_2_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isOutOfStock
                                  ? 'Out of Stock'
                                  : '$_maxStock in stock',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Title & Price ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                        child: Text(p['title'] ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.greenAccent),
                      ),
                      child: Text(p['price'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent)),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ── Category & Location ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(p['category'] ?? '',
                          style: GoogleFonts.poppins(
                              color: Colors.greenAccent, fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.location_on,
                        color: Colors.white54, size: 14),
                    Flexible(
                        child: Text(p['location'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 12))),
                  ],
                ),

                const SizedBox(height: 16),

                // ── STOCK INFO CARD ──
                if (!isOutOfStock) ...[
                  _stockCard(),
                  const SizedBox(height: 12),
                  // ── QUANTITY SELECTOR ──
                  _quantitySelector(),
                  const SizedBox(height: 12),
                ] else ...[
                  _outOfStockBanner(),
                  const SizedBox(height: 12),
                ],

                // ── Info Cards ──
                _infoCard(
                    icon: Icons.description_outlined,
                    title: 'Description',
                    value: p['description'] ?? 'No description available.'),
                const SizedBox(height: 10),
                _infoCard(
                    icon: Icons.payment,
                    title: 'Payment Method',
                    value: p['payment_method'] ?? 'Not specified'),
                const SizedBox(height: 10),
                _sellerCard(p),
                const SizedBox(height: 24),

                // ── Action Buttons ──
                if (!isOutOfStock) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addToCart,
                          icon: const Icon(Icons.shopping_cart_outlined,
                              color: Colors.yellow),
                          label: Text('Add to Cart',
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
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openWhatsApp,
                    icon: const Icon(Icons.chat, color: Colors.greenAccent),
                    label: Text('Contact Seller on WhatsApp',
                        style: GoogleFonts.poppins(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.greenAccent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Stock Info Card ──
  Widget _stockCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Colors.lightBlueAccent, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Available Stock',
                      style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  Text('$_maxStock units available',
                      style: GoogleFonts.poppins(
                          color: Colors.lightBlueAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              // ── Stock level indicator ──
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _maxStock > 20
                        ? '🟢 High Stock'
                        : _maxStock > 5
                        ? '🟡 Limited'
                        : '🔴 Low Stock',
                    style: GoogleFonts.poppins(
                        color: _maxStock > 20
                            ? Colors.greenAccent
                            : _maxStock > 5
                            ? Colors.yellow
                            : Colors.redAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Quantity Selector ──
  Widget _quantitySelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.add_shopping_cart,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text('Select Quantity',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Max: $_maxStock',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Minus Button ──
                  GestureDetector(
                    onTap: () {
                      if (_selectedQty > 1) {
                        setState(() => _selectedQty--);
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.remove,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  // ── Qty Display ──
                  Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Text(
                      '$_selectedQty',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  // ── Plus Button ──
                  GestureDetector(
                    onTap: () {
                      if (_selectedQty < _maxStock) {
                        setState(() => _selectedQty++);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Maximum $_maxStock units available!'),
                              backgroundColor: Colors.orange),
                        );
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.greenAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.add,
                          color: Colors.greenAccent, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // ── Quick select buttons ──
              if (_maxStock >= 5) ...[
                Text('Quick Select:',
                    style: GoogleFonts.poppins(
                        color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [1, 2, 5, 10]
                      .where((v) => v <= _maxStock)
                      .map((v) => GestureDetector(
                    onTap: () => setState(() => _selectedQty = v),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedQty == v
                            ? Colors.green
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedQty == v
                              ? Colors.greenAccent
                              : Colors.white24,
                        ),
                      ),
                      child: Text('$v',
                          style: GoogleFonts.poppins(
                              color: _selectedQty == v
                                  ? Colors.white
                                  : Colors.white60,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Out of Stock Banner ──
  Widget _outOfStockBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Out of Stock',
                    style: GoogleFonts.poppins(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                Text('This item is currently unavailable. Contact seller.',
                    style:
                    GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
      {required IconData icon, required String title, required String value}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.greenAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 11,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(value,
                        style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sellerCard(Map<String, dynamic> p) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border:
            Border.all(color: Colors.green.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storefront,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 6),
                  Text('Seller Information',
                      style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              _sellerRow(Icons.person_outline, 'Name',
                  p['seller_name'] ?? 'N/A'),
              const SizedBox(height: 6),
              _sellerRow(Icons.location_on_outlined, 'Location',
                  p['location'] ?? 'N/A'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sellerRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 15),
        const SizedBox(width: 6),
        Text('$label: ',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
        Flexible(
            child: Text(value,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600))),
      ],
    );
  }
}