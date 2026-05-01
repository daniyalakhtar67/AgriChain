import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_sms/flutter_sms.dart';

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

  // Step: 0 = detail view, 1 = buyer form, 2 = success screen
  int _step = 0;

  // Buyer form controllers
  final _nameC    = TextEditingController();
  final _phoneC   = TextEditingController();
  final _addressC = TextEditingController();
  final _qtyC     = TextEditingController(text: '1');
  bool _placing   = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
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

  // ─── Send SMS to both buyer and seller ───────────────────────────────────
  Future<void> _sendSmsToAll() async {
    final title    = widget.product['title']    ?? 'N/A';
    final price    = widget.product['price']    ?? 'N/A';
    final qty      = _qtyC.text.trim();
    final seller   = widget.product['seller_name']  ?? 'Seller';
    final sellerPh = widget.product['seller_phone'] ?? '';

    // SMS to BUYER — order confirmation
    final buyerMsg =
        'Hello ${_nameC.text}! Your order has been placed successfully.\n'
        'Product : $title\n'
        'Price   : $price\n'
        'Qty     : $qty\n'
        'Seller  : $seller\n'
        'Status  : Pending\n'
        'The seller will contact you shortly.';

    // SMS to SELLER — new order notification
    final sellerMsg =
        'New Order Received!\n'
        'Product : $title\n'
        'Price   : $price\n'
        'Qty     : $qty\n'
        'Buyer   : ${_nameC.text}\n'
        'Phone   : ${_phoneC.text}\n'
        'Address : ${_addressC.text}\n'
        'Please contact the buyer as soon as possible.';

    try {
      // Send confirmation SMS to buyer
      if (_phoneC.text.trim().isNotEmpty) {
        await sendSMS(
          message: buyerMsg,
          recipients: [_phoneC.text.trim()],
          sendDirect: true, // send without opening SMS app
        );
      }

      // Send notification SMS to seller
      if (sellerPh.isNotEmpty) {
        await sendSMS(
          message: sellerMsg,
          recipients: [sellerPh],
          sendDirect: true,
        );
      }
    } catch (e) {
      // SMS sending failed — non-critical, order is already saved
      debugPrint('SMS error: $e');
    }
  }

  // ─── Save order to Supabase then send SMS ────────────────────────────────
  Future<void> _placeOrder() async {
    if (_nameC.text.trim().isEmpty ||
        _phoneC.text.trim().isEmpty ||
        _addressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all fields!'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _placing = true);

    try {
      // 1. Save order to Supabase
      await supabase.from('orders').insert({
        'product_id'    : widget.product['id'],
        'product_title' : widget.product['title'],
        'product_price' : widget.product['price'],
        'seller_name'   : widget.product['seller_name'],
        'seller_type'   : widget.product['seller_type'],
        'buyer_name'    : _nameC.text.trim(),
        'buyer_phone'   : _phoneC.text.trim(),
        'buyer_address' : _addressC.text.trim(),
        'quantity'      : int.tryParse(_qtyC.text.trim()) ?? 1,
        'status'        : 'pending',
        'created_at'    : DateTime.now().toIso8601String(),
      });

      // 2. Send SMS to buyer and seller
      await _sendSmsToAll();

      // 3. Move to success screen
      setState(() {
        _placing = false;
        _step = 2;
      });
    } catch (e) {
      setState(() => _placing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // ─── Open WhatsApp with seller number + product info ─────────────────────
  Future<void> _openWhatsApp() async {
    final title      = widget.product['title'] ?? 'this product';
    final price      = widget.product['price'] ?? 'N/A';
    final sellerPhone = widget.product['seller_phone'] ?? '';

    final message = Uri.encodeComponent(
      'Hello! I am interested in "$title" priced at $price. Please share more details.',
    );

    // Remove spaces, dashes, brackets from phone number
    final cleanPhone = sellerPhone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    final Uri uri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$message')
        : Uri.parse('https://wa.me/?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open WhatsApp. Please try again.'),
            backgroundColor: Colors.red));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────
  // STEP 0: Product Detail View
  // ─────────────────────────────────────────────
  Widget _buildDetailView() {
    final p = widget.product;
    return Column(
      children: [
        // Top navigation bar
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
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image
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
                            color: Colors.white54, size: 60)),
                  )
                      : Container(
                      height: 220,
                      color: Colors.grey.shade800,
                      child: const Icon(Icons.image,
                          color: Colors.white54, size: 60)),
                ),

                const SizedBox(height: 16),

                // Title and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(p['title'] ?? '',
                          style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
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

                // Category chip and location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
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
                              color: Colors.white54, fontSize: 12)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

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

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat, color: Colors.greenAccent),
                        label: Text('Contact Seller',
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _step = 1);
                          _fadeCtrl
                            ..reset()
                            ..forward();
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Reusable info card
  Widget _infoCard(
      {required IconData icon,
        required String title,
        required String value}) {
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

  // Seller information card
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
              _sellerRow(
                  Icons.badge_outlined, 'CNIC', p['seller_cnic'] ?? 'N/A'),
              if (p['seller_phone'] != null &&
                  p['seller_phone'].toString().isNotEmpty) ...[
                const SizedBox(height: 6),
                _sellerRow(
                    Icons.phone_outlined, 'WhatsApp', p['seller_phone']),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Single row inside seller card
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
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1: Buyer Details Form
  // ─────────────────────────────────────────────
  Widget _buildBuyerForm() {
    return Column(
      children: [
        // Header with back button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  setState(() => _step = 0);
                  _fadeCtrl
                    ..reset()
                    ..forward();
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
                // Mini order summary card
                ClipRRect(
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
                                      color: Colors.white54)),
                            )
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

                // Buyer input fields
                _formField('Your Name', _nameC, Icons.person_outline),
                const SizedBox(height: 12),
                _formField('Phone Number', _phoneC, Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _formField(
                    'Delivery Address', _addressC, Icons.location_on_outlined,
                    maxLines: 3),
                const SizedBox(height: 12),
                _formField('Quantity', _qtyC,
                    Icons.production_quantity_limits,
                    type: TextInputType.number),

                const SizedBox(height: 16),

                // SMS notice banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sms_outlined,
                          color: Colors.blueAccent, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'An SMS confirmation will be sent to you and the seller after placing the order.',
                          style: GoogleFonts.poppins(
                              color: Colors.blueAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Payment method reminder banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.yellow.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.yellow.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payment,
                          color: Colors.yellow, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Payment: ${widget.product['payment_method'] ?? 'Ask the seller'}',
                          style: GoogleFonts.poppins(
                              color: Colors.yellow, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Place Order button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _placing ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _placing
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Placing Order & Sending SMS...',
                            style: TextStyle(color: Colors.white)),
                      ],
                    )
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

  // Reusable text field for buyer form
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
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.greenAccent),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2: Order Success Screen
  // ─────────────────────────────────────────────
  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success checkmark
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.greenAccent, width: 2),
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Colors.greenAccent, size: 64),
            ),

            const SizedBox(height: 24),

            Text('Order Successfully Placed!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),

            const SizedBox(height: 12),

            Text(
              'Your order has been placed successfully.\nThe seller will contact you shortly.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
            ),

            const SizedBox(height: 12),

            // SMS sent confirmation badge
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sms, color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 6),
                  Text('SMS sent to you and the seller',
                      style: GoogleFonts.poppins(
                          color: Colors.blueAccent, fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Order summary card
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    children: [
                      _summaryRow('Product', widget.product['title'] ?? ''),
                      const SizedBox(height: 8),
                      _summaryRow('Price', widget.product['price'] ?? ''),
                      const SizedBox(height: 8),
                      _summaryRow('Buyer', _nameC.text),
                      const SizedBox(height: 8),
                      _summaryRow('Phone', _phoneC.text),
                      const SizedBox(height: 8),
                      _summaryRow('Quantity', _qtyC.text),
                      const SizedBox(height: 8),
                      _summaryRow('Status', '⏳ Pending'),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Back to dashboard
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
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // WhatsApp seller after order
            OutlinedButton.icon(
              onPressed: _openWhatsApp,
              icon: const Icon(Icons.chat, color: Colors.greenAccent),
              label: Text('Contact Seller on WhatsApp',
                  style: GoogleFonts.poppins(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.greenAccent),
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Single summary row
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
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}