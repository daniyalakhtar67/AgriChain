import 'dart:ui';
import 'package:argichain/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BuyerCartScreen extends StatefulWidget {
  const BuyerCartScreen({super.key});

  @override
  State<BuyerCartScreen> createState() => _BuyerCartScreenState();
}

class _BuyerCartScreenState extends State<BuyerCartScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cartItems = [];
  bool isLoading = true;
  final _nameC    = TextEditingController();
  final _phoneC   = TextEditingController();
  final _addressC = TextEditingController();
  bool _placing   = false;
  bool _showForm  = false;

  @override
  void initState() {
    super.initState();
    fetchCart();
  }

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    super.dispose();
  }

  Future<void> fetchCart() async {
    try {
      final data = await supabase
          .from('carts')
          .select('cart_id, quantity, item_id, items(item_id, name, price, price_unit, image_url)')
          .eq('user_id', UserSession.id)
          .order('created_at', ascending: false);
      setState(() {
        cartItems = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchCart error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> removeFromCart(String id) async {
    try {
      await supabase.from('carts').delete().eq('cart_id', id);
      fetchCart();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed!'), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> clearCart() async {
    try {
      await supabase.from('carts').delete().eq('user_id', UserSession.id);
      fetchCart();
    } catch (e) {
      debugPrint('Clear cart error: $e');
    }
  }

  Future<void> placeAllOrders() async {
    if (_nameC.text.trim().isEmpty ||
        _phoneC.text.trim().isEmpty ||
        _addressC.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill all fields!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _placing = true);

    try {
      // Calculate total
      double total = 0;
      for (final item in cartItems) {
        final itemData = item['items'] as Map<String, dynamic>? ?? {};
        final price = double.tryParse(itemData['price']?.toString() ?? '0') ?? 0;
        final qty   = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        total += price * qty;
      }

      // Insert order
      final orderResult = await supabase
          .from('orders')
          .insert({
        'user_id'      : UserSession.id,
        'total_amount' : total,
        'net_amount'   : total,
        'status'       : 'placed',
      })
          .select('order_id')
          .single();

      final orderId = orderResult['order_id'];

      // Insert order_items
      for (final item in cartItems) {
        final itemData = item['items'] as Map<String, dynamic>? ?? {};
        await supabase.from('order_items').insert({
          'order_id' : orderId,
          'item_id'  : itemData['item_id'],
          'quantity' : item['quantity'] ?? 1,
          'price'    : itemData['price'],
        });
      }

      await clearCart();
      setState(() { _placing = false; _showForm = false; });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey.shade900,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 70),
              const SizedBox(height: 16),
              Text('Order Placed!',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Sellers will contact you shortly.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13)),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                child: Text('Back to Dashboard',
                    style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ]),
          ),
        );
      }
    } catch (e) {
      setState(() => _placing = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
              child:
              Container(color: Colors.black.withValues(alpha: 0.70))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white24)),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: 'My ',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          TextSpan(
                              text: 'Cart',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow)),
                        ]),
                      ),
                      const Spacer(),
                      if (cartItems.isNotEmpty)
                        GestureDetector(
                          onTap: () async {
                            await clearCart();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Cart cleared!'),
                                      backgroundColor: Colors.red));
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.red)),
                            child: Text('Clear All',
                                style: GoogleFonts.poppins(
                                    color: Colors.red, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.green))
                      : cartItems.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white38,
                            size: 80),
                        const SizedBox(height: 16),
                        Text('Cart is empty!',
                            style: GoogleFonts.poppins(
                                color: Colors.white60,
                                fontSize: 18)),
                      ],
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    child: Column(
                      children: [
                        ...cartItems.map((item) {
                          // ── FIX: unpack nested 'items' data ──
                          final itemData =
                              item['items'] as Map<String, dynamic>? ?? {};
                          return _CartItem(
                            item: item,
                            onRemove: () =>
                                removeFromCart(item['cart_id']),
                            onQtyChange: (qty) async {
                              await supabase
                                  .from('carts')
                                  .update({'quantity': qty})
                                  .eq('cart_id', item['cart_id']);
                              fetchCart();
                            },
                          );
                        }),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding:
                              const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.10),
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  border: Border.all(
                                      color: Colors.white24)),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text('Total Items:',
                                      style:
                                      GoogleFonts.poppins(
                                          color:
                                          Colors.white60,
                                          fontSize: 14)),
                                  Text(
                                      '${cartItems.length} items',
                                      style:
                                      GoogleFonts.poppins(
                                          color: Colors
                                              .greenAccent,
                                          fontSize: 16,
                                          fontWeight:
                                          FontWeight
                                              .bold)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_showForm) ...[
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding:
                                const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(
                                        alpha: 0.10),
                                    borderRadius:
                                    BorderRadius.circular(
                                        16),
                                    border: Border.all(
                                        color: Colors.white24)),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text('Your Details',
                                        style:
                                        GoogleFonts.poppins(
                                            color: Colors
                                                .yellow,
                                            fontSize: 16,
                                            fontWeight:
                                            FontWeight
                                                .bold)),
                                    const SizedBox(height: 12),
                                    _formField(
                                        'Your Name',
                                        _nameC,
                                        Icons.person_outline),
                                    const SizedBox(height: 10),
                                    _formField(
                                        'Phone Number',
                                        _phoneC,
                                        Icons.phone_outlined,
                                        type: TextInputType
                                            .phone),
                                    const SizedBox(height: 10),
                                    _formField(
                                        'Delivery Address',
                                        _addressC,
                                        Icons
                                            .location_on_outlined,
                                        maxLines: 2),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        16))),
                            onPressed: _placing
                                ? null
                                : () {
                              if (!_showForm) {
                                setState(() =>
                                _showForm = true);
                              } else {
                                placeAllOrders();
                              }
                            },
                            icon: _placing
                                ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2))
                                : Icon(
                                _showForm
                                    ? Icons.check
                                    : Icons
                                    .shopping_bag_outlined,
                                color: Colors.white),
                            label: Text(
                              _placing
                                  ? 'Placing Orders...'
                                  : _showForm
                                  ? 'Confirm Order'
                                  : 'Checkout',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _formField(
      String label, TextEditingController c, IconData icon,
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
}

class _CartItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onRemove;
  final Function(int) onQtyChange;
  const _CartItem(
      {required this.item,
        required this.onRemove,
        required this.onQtyChange});

  @override
  Widget build(BuildContext context) {
    // ── FIX: unpack nested 'items' data and use correct field names ──
    final itemData = item['items'] as Map<String, dynamic>? ?? {};
    int qty = item['quantity'] ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16)),
            child: itemData['image_url'] != null
                ? CachedNetworkImage(
                imageUrl: itemData['image_url'],
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white54)))
                : Container(
                width: 90,
                height: 90,
                color: Colors.grey.shade800,
                child: const Icon(Icons.image, color: Colors.white54)),
          ),
          Expanded(
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(itemData['name'] ?? '',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    '${itemData['price'] ?? ''} ${itemData['price_unit'] ?? ''}',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (qty > 1) onQtyChange(qty - 1);
                        },
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color:
                                Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.remove,
                                color: Colors.white, size: 16)),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10),
                          child: Text('$qty',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                      GestureDetector(
                        onTap: () => onQtyChange(qty + 1),
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                                color:
                                Colors.green.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.add,
                                color: Colors.greenAccent, size: 16)),
                      ),
                      const Spacer(),
                      GestureDetector(
                          onTap: onRemove,
                          child: const Icon(Icons.delete_outline,
                              color: Colors.redAccent, size: 20)),
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