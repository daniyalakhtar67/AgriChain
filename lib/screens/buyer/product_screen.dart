import 'dart:ui';
import 'package:argichain/screens/buyer/cart_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class BuyerProductDetail extends StatefulWidget {
  final Map<String, dynamic> product;
  const BuyerProductDetail({super.key, required this.product});

  @override
  State<BuyerProductDetail> createState() => _BuyerProductDetailState();
}

class _BuyerProductDetailState extends State<BuyerProductDetail>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  int _step = 0;
  final _nameC    = TextEditingController();
  final _phoneC   = TextEditingController();
  final _addressC = TextEditingController();
  final _qtyC     = TextEditingController(text: '1');
  bool _placing   = false;

  // ── KG stock from farmer ──
  double _availableKg = 0;
  double _selectedKg  = 1;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();

    // Parse KG quantity
    final kgRaw = widget.product['crop_quantity_kg'];
    _availableKg = (kgRaw != null && double.tryParse(kgRaw.toString()) != null)
        ? double.parse(kgRaw.toString())
        : 0;
    _selectedKg = _availableKg > 0 ? 1 : 0;
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _qtyC.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (_availableKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This crop is currently unavailable!'),
            backgroundColor: Colors.red),
      );
      return;
    }
    try {
      await supabase.from('cart').insert({
        'product_id'    : widget.product['id'],
        'product_title' : widget.product['title'],
        'product_price' : widget.product['price'],
        'product_image' : widget.product['image_url'],
        'seller_name'   : widget.product['seller_name'],
        'seller_type'   : widget.product['seller_type'],
        'quantity'      : _selectedKg.toInt() > 0 ? _selectedKg.toInt() : 1,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${_selectedKg.toStringAsFixed(1)} KG added to Cart!',
                    style: GoogleFonts.poppins(color: Colors.white)),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BuyerCartScreen()));
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

  Future<void> _placeOrder() async {
    if (_nameC.text.trim().isEmpty ||
        _phoneC.text.trim().isEmpty ||
        _addressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill all fields!'),
              backgroundColor: Colors.red));
      return;
    }
    if (_availableKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('This crop is currently unavailable!'),
              backgroundColor: Colors.red));
      return;
    }
    setState(() => _placing = true);
    try {
      final orderQty = _qtyC.text.trim().isNotEmpty
          ? double.tryParse(_qtyC.text.trim()) ?? _selectedKg
          : _selectedKg;

      await supabase.from('orders').insert({
        'product_id'    : widget.product['id'],
        'product_title' : widget.product['title'],
        'product_price' : widget.product['price'],
        'seller_name'   : widget.product['seller_name'],
        'seller_type'   : widget.product['seller_type'],
        'buyer_name'    : _nameC.text.trim(),
        'buyer_phone'   : _phoneC.text.trim(),
        'buyer_address' : _addressC.text.trim(),
        'quantity'      : orderQty.toInt() > 0 ? orderQty.toInt() : 1,
        'status'        : 'pending',
        'created_at'    : DateTime.now().toIso8601String(),
      });
      setState(() { _placing = false; _step = 2; });
    } catch (e) {
      setState(() => _placing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final title = widget.product['title'] ?? 'this product';
    final price = widget.product['price'] ?? 'N/A';
    final sellerPhone = widget.product['seller_phone'] ?? '';
    final message = Uri.encodeComponent(
        'Hello! I am interested in "$title" priced at $price. I want ${_selectedKg.toStringAsFixed(1)} KG.');
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
              child: Image.asset('assets/images/DB.jpg', fit: BoxFit.cover)),
          SizedBox.expand(
              child: Container(color: Colors.black.withValues(alpha: 0.70))),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: _step == 0
                  ? _buildDetailView()
                  : _step == 1
                  ? _buildBuyerForm()
                  : _buildSuccessScreen(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final p = widget.product;
    final bool isUnavailable = _availableKg <= 0;

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
                    MaterialPageRoute(builder: (_) => const BuyerCartScreen())),
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
                // ── Product Image with KG badge ──
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
                    // ── KG Badge overlay on image ──
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.red.withValues(alpha: 0.85)
                              : Colors.green.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUnavailable
                                  ? Icons.cancel_outlined
                                  : Icons.scale_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isUnavailable
                                  ? 'Not Available'
                                  : '${_availableKg.toStringAsFixed(1)} KG available',
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

                // ── KG AVAILABILITY CARD ──
                _kgAvailabilityCard(),
                const SizedBox(height: 12),

                // ── KG SELECTOR (only if available) ──
                if (!isUnavailable) ...[
                  _kgSelector(),
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
                if (!isUnavailable) ...[
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _step = 1);
                            _fadeCtrl..reset()..forward();
                          },
                          icon: const Icon(Icons.shopping_bag_outlined,
                              color: Colors.white),
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
                    icon:
                    const Icon(Icons.chat, color: Colors.greenAccent),
                    label: Text(
                        isUnavailable
                            ? 'Ask Farmer for Availability'
                            : 'Contact Farmer on WhatsApp',
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

  // ── KG Availability Card ──
  Widget _kgAvailabilityCard() {
    final bool isUnavailable = _availableKg <= 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnavailable
                ? Colors.red.withValues(alpha: 0.10)
                : Colors.green.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUnavailable
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : Colors.greenAccent.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnavailable
                      ? Colors.red.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isUnavailable ? Icons.cancel_outlined : Icons.scale_outlined,
                  color: isUnavailable ? Colors.redAccent : Colors.greenAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUnavailable ? 'Currently Unavailable' : 'Farmer Stock',
                      style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isUnavailable
                          ? 'Contact farmer for availability'
                          : '${_availableKg.toStringAsFixed(1)} KG available',
                      style: GoogleFonts.poppins(
                          color: isUnavailable
                              ? Colors.redAccent
                              : Colors.greenAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (!isUnavailable)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _availableKg > 500
                          ? '🟢 Bulk'
                          : _availableKg > 100
                          ? '🟡 Medium'
                          : '🔴 Limited',
                      style: GoogleFonts.poppins(
                          color: _availableKg > 500
                              ? Colors.greenAccent
                              : _availableKg > 100
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

  // ── KG Selector ──
  Widget _kgSelector() {
    final maxKg = _availableKg;
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
                  const Icon(Icons.scale_outlined,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text('How much KG do you need?',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Max: ${maxKg.toStringAsFixed(1)} KG',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 14),

              // ── KG Slider ──
              Row(
                children: [
                  Text('1',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 11)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.greenAccent,
                        inactiveTrackColor: Colors.white24,
                        thumbColor: Colors.green,
                        overlayColor: Colors.green.withValues(alpha: 0.2),
                        valueIndicatorColor: Colors.green,
                        valueIndicatorTextStyle: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 12),
                      ),
                      child: Slider(
                        value: _selectedKg.clamp(1, maxKg),
                        min: 1,
                        max: maxKg > 1 ? maxKg : 1,
                        divisions: maxKg > 1 ? (maxKg - 1).toInt().clamp(1, 100) : 1,
                        label: '${_selectedKg.toStringAsFixed(1)} KG',
                        onChanged: (val) {
                          setState(() => _selectedKg = val);
                          _qtyC.text = val.toInt().toString();
                        },
                      ),
                    ),
                  ),
                  Text('${maxKg.toStringAsFixed(0)} KG',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 11)),
                ],
              ),

              // ── Selected KG Display ──
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.greenAccent),
                  ),
                  child: Text(
                    '${_selectedKg.toStringAsFixed(1)} KG selected',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Quick KG buttons ──
              Text('Quick Select:',
                  style: GoogleFonts.poppins(
                      color: Colors.white54, fontSize: 11)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [1.0, 5.0, 10.0, 25.0, 50.0, 100.0]
                    .where((v) => v <= maxKg)
                    .map((v) => GestureDetector(
                  onTap: () {
                    setState(() => _selectedKg = v);
                    _qtyC.text = v.toInt().toString();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedKg == v
                          ? Colors.green
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedKg == v
                            ? Colors.greenAccent
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      v >= 1000
                          ? '${(v / 1000).toStringAsFixed(1)}T'
                          : '${v.toStringAsFixed(0)} KG',
                      style: GoogleFonts.poppins(
                          color: _selectedKg == v
                              ? Colors.white
                              : Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required IconData icon, required String title, required String value}) {
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
                        style: GoogleFonts.poppins(
                            color: Colors.white, fontSize: 13)),
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
              Row(
                children: [
                  const Icon(Icons.storefront,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 6),
                  Text('Farmer Information',
                      style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              _sellerRow(Icons.person_outline, 'Name', p['seller_name'] ?? 'N/A'),
              const SizedBox(height: 6),
              _sellerRow(Icons.badge_outlined, 'CNIC', p['seller_cnic'] ?? 'N/A'),
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

  Widget _buildBuyerForm() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  setState(() => _step = 0);
                  _fadeCtrl..reset()..forward();
                },
              ),
              Text('Your Details',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Product + KG summary ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white24)),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: widget.product['image_url'] != null
                                ? CachedNetworkImage(
                                imageUrl: widget.product['image_url'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade800,
                                    child: const Icon(Icons.image,
                                        color: Colors.white54)))
                                : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.image,
                                    color: Colors.white54)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.product['title'] ?? '',
                                    style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(widget.product['price'] ?? '',
                                    style: GoogleFonts.poppins(
                                        color: Colors.greenAccent,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                // ── KG selected summary ──
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.greenAccent
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    '📦 ${_selectedKg.toStringAsFixed(1)} KG selected',
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
                  ),
                ),
                const SizedBox(height: 20),
                Text('Enter Your Details',
                    style: GoogleFonts.poppins(
                        color: Colors.yellow,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                _formField('Your Name', _nameC, Icons.person_outline),
                const SizedBox(height: 12),
                _formField('Phone Number', _phoneC, Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _formField('Delivery Address', _addressC,
                    Icons.location_on_outlined,
                    maxLines: 3),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.yellow.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.yellow.withValues(alpha: 0.4))),
                  child: Row(
                    children: [
                      const Icon(Icons.payment, color: Colors.yellow, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                          child: Text(
                              'Payment: ${widget.product['payment_method'] ?? 'Ask the farmer'}',
                              style: GoogleFonts.poppins(
                                  color: Colors.yellow, fontSize: 12))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _placing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: _placing
                        ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)),
                          SizedBox(width: 12),
                          Text('Placing Order...',
                              style: TextStyle(color: Colors.white))
                        ])
                        : Text('Place Order',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
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

  Widget _formField(String label, TextEditingController c, IconData icon,
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
        fillColor: Colors.white.withValues(alpha: 0.08),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.greenAccent)),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent, width: 2)),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 64),
            ),
            const SizedBox(height: 24),
            Text('Order Placed Successfully!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 12),
            Text('The farmer will contact you shortly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14)),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white24)),
                  child: Column(
                    children: [
                      _summaryRow('Product', widget.product['title'] ?? ''),
                      const SizedBox(height: 8),
                      _summaryRow('Price', widget.product['price'] ?? ''),
                      const SizedBox(height: 8),
                      _summaryRow('Quantity',
                          '${_selectedKg.toStringAsFixed(1)} KG'),
                      const SizedBox(height: 8),
                      _summaryRow('Buyer', _nameC.text),
                      const SizedBox(height: 8),
                      _summaryRow('Phone', _phoneC.text),
                      const SizedBox(height: 8),
                      _summaryRow('Status', '⏳ Pending'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                icon: const Icon(Icons.home_outlined, color: Colors.white),
                label: Text('Back to Dashboard',
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.chat, color: Colors.greenAccent),
              label: Text('Contact Farmer on WhatsApp',
                  style: GoogleFonts.poppins(
                      color: Colors.greenAccent, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.greenAccent),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13)),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
      ],
    );
  }
}