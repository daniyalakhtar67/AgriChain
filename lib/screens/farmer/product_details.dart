import 'dart:ui';
import 'package:argichain/screens/farmer/cart_screen.dart';
import 'package:argichain/screens/farmer/payment.dart';
import 'package:argichain/utils/payment_methods.dart'; // ← ADDED
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  int _selectedQty = 1;
  int _maxStock = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    final stock = widget.product['stock_quantity'];
    _maxStock = (stock != null && int.tryParse(stock.toString()) != null)
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
            content: Text('Item out of stock!'), backgroundColor: Colors.red),
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
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CartScreen()));
                  },
                  child: Text('View Cart',
                      style: GoogleFonts.poppins(
                          color: Colors.yellow, fontWeight: FontWeight.bold)),
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

  void _navigateToBuyNow() {
    if (_maxStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item out of stock!'), backgroundColor: Colors.red),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyNowScreen(
          product: widget.product,
          selectedQty: _selectedQty,
          onOrderPlaced: (int newStock) {
            setState(() => _maxStock = newStock);
          },
        ),
      ),
    );
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
            child: FadeTransition(opacity: _fadeAnim, child: _buildDetailView()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final p = widget.product;
    final bool isOutOfStock = _maxStock <= 0;

    final String paymentMethod = (p['payment_method'] ?? '').toString().trim();
    final String paymentAccount = (p['payment_account'] ?? '').toString().trim();
    final bool hasPaymentAccount =
        paymentAccount.isNotEmpty && paymentMethod.isNotEmpty;

    return Column(
      children: [
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
                onTap: () => Navigator.push(context,
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
                // Hero Image
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: p['image_url'] != null
                          ? CachedNetworkImage(
                          imageUrl: p['image_url'],
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover)
                          : Container(
                          height: 220,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.image,
                              color: Colors.white54, size: 60)),
                    ),
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
                        child: Text(
                          isOutOfStock ? 'Out of Stock' : '$_maxStock in stock',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
                    const Icon(Icons.location_on, color: Colors.white54, size: 14),
                    Flexible(
                        child: Text(p['location'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isOutOfStock) ...[
                  _stockCard(),
                  const SizedBox(height: 12),
                  _quantitySelector(),
                  const SizedBox(height: 12),
                ] else ...[
                  _outOfStockBanner(),
                  const SizedBox(height: 12),
                ],
                _infoCard(
                    icon: Icons.description_outlined,
                    title: 'Description',
                    value: p['description'] ?? 'No description available.'),
                const SizedBox(height: 10),
                _paymentCard(
                    method: paymentMethod,
                    account: paymentAccount,
                    hasAccount: hasPaymentAccount),
                const SizedBox(height: 10),
                _sellerCard(p),
                const SizedBox(height: 24),
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _navigateToBuyNow,
                          icon: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white, size: 18),
                          label: Text('Buy Now',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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

  Widget _paymentCard(
      {required String method,
        required String account,
        required bool hasAccount}) {
    if (method.isEmpty) {
      return _infoCard(
          icon: Icons.payment,
          title: 'Payment Method',
          value: 'Not specified');
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.yellow.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.yellow.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.payment, color: Colors.yellow, size: 18),
                const SizedBox(width: 8),
                Text('Seller Payment Method',
                    style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.yellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.yellow.withValues(alpha: 0.5)),
                ),
                child: Text(method,
                    style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              if (hasAccount) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account Number',
                          style: GoogleFonts.poppins(
                              color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(account,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2)),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: account));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Account number copied! 📋',
                                        style: GoogleFonts.poppins()),
                                    backgroundColor: Colors.green.shade700,
                                    duration: const Duration(seconds: 2)),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.copy,
                                  color: Colors.white60, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text('⚠️ Payment karne ke baad screenshot zaroor bhejein',
                    style:
                    GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
              ],
            ],
          ),
        ),
      ),
    );
  }

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
            border: Border.all(
                color: Colors.lightBlueAccent.withValues(alpha: 0.4)),
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
        ),
      ),
    );
  }

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
                      style:
                      GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_selectedQty > 1) setState(() => _selectedQty--);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child:
                      const Icon(Icons.remove, color: Colors.white, size: 20),
                    ),
                  ),
                  Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: Text('$_selectedQty',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            color: Colors.greenAccent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_selectedQty < _maxStock) {
                        setState(() => _selectedQty++);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content:
                            Text('Maximum $_maxStock units available!'),
                            backgroundColor: Colors.orange));
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
              if (_maxStock >= 5) ...[
                Text('Quick Select:',
                    style:
                    GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
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
            border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.storefront, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 6),
                Text('Seller Information',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 10),
              _sellerRow(Icons.person_outline, 'Name', p['seller_name'] ?? 'N/A'),
              const SizedBox(height: 6),
              _sellerRow(
                  Icons.location_on_outlined, 'Location', p['location'] ?? 'N/A'),
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

// ════════════════════════════════════════════════════════════════════════════
//  BUY NOW SCREEN — FIXED: buyer payment selector added
// ════════════════════════════════════════════════════════════════════════════
class BuyNowScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int selectedQty;
  final void Function(int newStock) onOrderPlaced;

  const BuyNowScreen({
    super.key,
    required this.product,
    required this.selectedQty,
    required this.onOrderPlaced,
  });

  @override
  State<BuyNowScreen> createState() => _BuyNowScreenState();
}

class _BuyNowScreenState extends State<BuyNowScreen> {
  final supabase = Supabase.instance.client;

  final nameC    = TextEditingController();
  final phoneC   = TextEditingController();
  final addressC = TextEditingController();

  // ── ADDED: buyer payment controllers ──
  final _accNumberC      = TextEditingController();
  String? _selectedPaymentId;

  bool _placing = false;

  @override
  void dispose() {
    nameC.dispose();
    phoneC.dispose();
    addressC.dispose();
    _accNumberC.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (nameC.text.trim().isEmpty ||
        phoneC.text.trim().isEmpty ||
        addressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all fields!'),
          backgroundColor: Colors.red));
      return;
    }

    // ── ADDED: payment validation ──
    if (_selectedPaymentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Apna payment method select karo! 💳'),
          backgroundColor: Colors.orange));
      return;
    }

    final selectedMethod =
    kPaymentMethods.firstWhere((m) => m.id == _selectedPaymentId);

    if (selectedMethod.requiresAccount && _accNumberC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account number daalo!'),
          backgroundColor: Colors.orange));
      return;
    }

    setState(() => _placing = true);

    try {
      await supabase.from('orders').insert({
        'product_id'      : widget.product['id']?.toString().trim() ?? '',
        'product_title'   : widget.product['title'] ?? '',
        'product_price'   : widget.product['price'] ?? '',
        'seller_name'     : widget.product['seller_name'] ?? '',
        'seller_type'     : widget.product['seller_type'] ?? 'shopkeeper',
        'buyer_name'      : nameC.text.trim(),
        'buyer_phone'     : phoneC.text.trim(),
        'buyer_address'   : addressC.text.trim(),
        'payment_method'  : selectedMethod.name,          // ← FIXED
        'payment_account' : selectedMethod.requiresAccount // ← FIXED
            ? _accNumberC.text.trim()
            : null,
        'quantity'        : widget.selectedQty,
        'status'          : 'pending',
        'created_at'      : DateTime.now().toIso8601String(),
      });

      // Stock deduct
      final productId = widget.product['id']?.toString().trim() ?? '';
      int newStock = 0;
      if (productId.isNotEmpty) {
        try {
          final res = await supabase
              .from('products')
              .select('stock_quantity')
              .filter('id', 'eq', productId)
              .maybeSingle();
          if (res != null && res['stock_quantity'] != null) {
            final currentStock =
                int.tryParse(res['stock_quantity'].toString()) ?? 0;
            newStock = (currentStock - widget.selectedQty).clamp(0, 999999);
            await supabase
                .from('products')
                .update({'stock_quantity': newStock})
                .filter('id', 'eq', productId);
          }
        } catch (stockErr) {
          debugPrint('Stock deduct error: $stockErr');
        }
      }

      setState(() => _placing = false);
      widget.onOrderPlaced(newStock);

      if (mounted) {
        // Dialog hatao — seedha dashboard pe jao
        int popCount = 0;
        Navigator.of(context).popUntil((_) => popCount++ >= 2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Order Placed! ✅ Seller will contact you shortly.',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12))),
            ]),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

    // Seller's payment info (for reference card)
    final String sellerPaymentMethod =
    (p['payment_method'] ?? '').toString().trim();
    final String sellerPaymentAccount =
    (p['payment_account'] ?? '').toString().trim();
    final bool sellerHasAccount =
        sellerPaymentAccount.isNotEmpty && sellerPaymentMethod.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
              child:
              Image.asset('assets/images/DF.jpg', fit: BoxFit.cover)),
          SizedBox.expand(
              child: Container(
                  color: Colors.black.withValues(alpha: 0.75))),
          SafeArea(
            child: Column(
              children: [
                // AppBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text('Checkout',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Summary
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A2535),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: p['image_url'] != null
                                    ? CachedNetworkImage(
                                    imageUrl: p['image_url'],
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover)
                                    : Container(
                                    width: 64,
                                    height: 64,
                                    color: const Color(0xFF0D1B2A),
                                    child: const Icon(Icons.image,
                                        color: Colors.white38)),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(p['title'] ?? '',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(height: 4),
                                    Text(p['price'] ?? '',
                                        style: GoogleFonts.poppins(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.greenAccent
                                                .withValues(alpha: 0.6)),
                                      ),
                                      child: Text(
                                        '🛒 ${widget.selectedQty} unit(s) selected',
                                        style: GoogleFonts.poppins(
                                            color: Colors.greenAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Seller Payment Reference Card ──
                        if (sellerPaymentMethod.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color:
                                  Colors.lightBlueAccent.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  const Icon(Icons.storefront,
                                      color: Colors.lightBlueAccent, size: 16),
                                  const SizedBox(width: 6),
                                  Text('Seller Accepts',
                                      style: GoogleFonts.poppins(
                                          color: Colors.lightBlueAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold)),
                                ]),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.lightBlueAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.lightBlueAccent
                                            .withValues(alpha: 0.5)),
                                  ),
                                  child: Text(sellerPaymentMethod,
                                      style: GoogleFonts.poppins(
                                          color: Colors.lightBlueAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600)),
                                ),
                                if (sellerHasAccount) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                      Border.all(color: Colors.white24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text('Seller Account',
                                            style: GoogleFonts.poppins(
                                                color: Colors.white54,
                                                fontSize: 11)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                  sellerPaymentAccount,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                      fontWeight:
                                                      FontWeight.bold,
                                                      letterSpacing: 1.2)),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(ClipboardData(
                                                    text:
                                                    sellerPaymentAccount));
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                  content: Text('Copied! 📋',
                                                      style:
                                                      GoogleFonts.poppins()),
                                                  backgroundColor:
                                                  Colors.green.shade700,
                                                  duration: const Duration(
                                                      seconds: 2),
                                                ));
                                              },
                                              child: Container(
                                                padding:
                                                const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                  BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.copy,
                                                    color: Colors.white60,
                                                    size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '⚠️ Payment karne ke baad screenshot send karein',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white54, fontSize: 11),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Buyer Details ──
                        Text('Enter Your Details',
                            style: GoogleFonts.poppins(
                                color: Colors.yellow,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _field('Your Name', nameC, Icons.person_outline),
                        const SizedBox(height: 12),
                        _field('Phone Number', phoneC, Icons.phone_outlined,
                            type: TextInputType.phone),
                        const SizedBox(height: 12),
                        _field('Delivery Address', addressC,
                            Icons.location_on_outlined,
                            maxLines: 3),
                        const SizedBox(height: 20),

                        // ── ADDED: Buyer Payment Selector ──
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: StatefulBuilder(
                            builder: (ctx, setS) => PaymentSelector(
                              selectedId: _selectedPaymentId,
                              onChanged: (id) {
                                setState(() => _selectedPaymentId = id);
                                setS(() {});
                              },
                              accountController: _accNumberC,
                              accentColor: Colors.greenAccent,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Place Order Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _placing ? null : _placeOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _placing
                                ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                                : Text('Place Order',
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController c, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.greenAccent),
        filled: true,
        fillColor: const Color(0xFF1A2535),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            BorderSide(color: Colors.white.withValues(alpha: 0.12))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.greenAccent)),
      ),
    );
  }
}