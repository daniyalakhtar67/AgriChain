import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CropDetailScreen extends StatefulWidget {
  final Map<String, dynamic> crop;
  const CropDetailScreen({super.key, required this.crop});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final supabase = Supabase.instance.client;
  late double _kgQty;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.crop['crop_quantity_kg'];
    _kgQty = (raw != null && double.tryParse(raw.toString()) != null)
        ? double.parse(raw.toString())
        : 0.0;
  }

  String get _stockLabel {
    if (_kgQty <= 0) return 'Not Available';
    if (_kgQty <= 50) return 'Limited Stock';
    if (_kgQty <= 200) return 'Medium Stock';
    return 'Bulk Available';
  }

  Color get _stockColor {
    if (_kgQty <= 0) return Colors.redAccent;
    if (_kgQty <= 50) return Colors.yellow;
    if (_kgQty <= 200) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  Future<void> _updateQty(double newQty) async {
    setState(() => _saving = true);
    try {
      await supabase
          .from('products')
          .update({'crop_quantity_kg': newQty}).eq('id', widget.crop['id']);
      setState(() {
        _kgQty = newQty;
        _saving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Stock updated! ✅'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCustomAmountDialog() {
    final controller = TextEditingController(text: _kgQty.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Custom Amount',
            style: GoogleFonts.poppins(
                color: Colors.yellow, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Enter KG amount',
            labelStyle: GoogleFonts.poppins(color: Colors.yellow),
            prefixIcon: const Icon(Icons.scale_outlined, color: Colors.yellow),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.yellow)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 0) {
                Navigator.pop(context);
                _updateQty(val);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter a valid number'),
                      backgroundColor: Colors.red),
                );
              }
            },
            child: Text('Set',
                style: GoogleFonts.poppins(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.crop;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
              child: Image.asset('assets/images/DF.jpg', fit: BoxFit.cover)),
          SizedBox.expand(
              child: Container(color: Colors.black.withValues(alpha: 0.70))),
          SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(p['title'] ?? '',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                            overflow: TextOverflow.ellipsis),
                      ),
                      // ── Set Stock button top right ──
                      GestureDetector(
                        onTap: _showCustomAmountDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.yellow),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.edit,
                                  color: Colors.yellow, size: 14),
                              const SizedBox(width: 6),
                              Text('Set Stock',
                                  style: GoogleFonts.poppins(
                                      color: Colors.yellow,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: p['image_url'] != null
                              ? CachedNetworkImage(
                              imageUrl: p['image_url'],
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                  height: 200,
                                  color: Colors.grey.shade800,
                                  child: const Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.green))),
                              errorWidget: (_, __, ___) => Container(
                                  height: 200,
                                  color: Colors.grey.shade800,
                                  child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white54,
                                      size: 60)))
                              : Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Center(
                                  child: Icon(Icons.grass,
                                      color: Colors.green, size: 60))),
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
                                      fontSize: 15,
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
                                      color: Colors.white54, fontSize: 12)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Stock Management Card ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border:
                                Border.all(color: Colors.lightBlueAccent.withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.inventory_2_outlined,
                                          color: Colors.lightBlueAccent,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text('Stock Management',
                                          style: GoogleFonts.poppins(
                                              color: Colors.lightBlueAccent,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // ── +/- controls ──
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      // Minus button
                                      GestureDetector(
                                        onTap: _saving
                                            ? null
                                            : () {
                                          if (_kgQty >= 1) {
                                            _updateQty(_kgQty - 1);
                                          }
                                        },
                                        child: Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.25),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            border: Border.all(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.5)),
                                          ),
                                          child: const Icon(Icons.remove,
                                              color: Colors.redAccent,
                                              size: 24),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // KG Display
                                      Container(
                                        width: 100,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: Colors.lightBlueAccent
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                          BorderRadius.circular(14),
                                          border: Border.all(
                                              color: Colors.lightBlueAccent
                                                  .withValues(alpha: 0.5)),
                                        ),
                                        child: Center(
                                          child: _saving
                                              ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child:
                                              CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2))
                                              : Text(
                                              _kgQty >= 1000
                                                  ? '${(_kgQty / 1000).toStringAsFixed(1)}T'
                                                  : '${_kgQty.toStringAsFixed(0)}',
                                              style: GoogleFonts.poppins(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight:
                                                  FontWeight.bold)),
                                        ),
                                      ),

                                      const SizedBox(width: 16),

                                      // Plus button
                                      GestureDetector(
                                        onTap: _saving
                                            ? null
                                            : () => _updateQty(_kgQty + 1),
                                        child: Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.25),
                                            borderRadius:
                                            BorderRadius.circular(14),
                                            border: Border.all(
                                                color: Colors.greenAccent
                                                    .withValues(alpha: 0.5)),
                                          ),
                                          child: const Icon(Icons.add,
                                              color: Colors.greenAccent,
                                              size: 24),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // ── Stock Label ──
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                              color: _stockColor,
                                              shape: BoxShape.circle),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(_stockLabel,
                                            style: GoogleFonts.poppins(
                                                color: _stockColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // ── Custom Amount Button ──
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _showCustomAmountDialog,
                                      icon: const Icon(Icons.edit,
                                          color: Colors.yellow, size: 16),
                                      label: Text('Custom Amount Set Karo',
                                          style: GoogleFonts.poppins(
                                              color: Colors.yellow,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: Colors.yellow),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Description ──
                        _infoCard(
                          icon: Icons.description_outlined,
                          title: 'Description',
                          value: p['description'] ?? 'No description available.',
                        ),

                        const SizedBox(height: 10),

                        // ── Payment Method ──
                        _infoCard(
                          icon: Icons.payment,
                          title: 'Payment Method',
                          value: p['payment_method'] ?? 'Not specified',
                        ),

                        const SizedBox(height: 10),

                        // ── Seller Info ──
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                Colors.green.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.green
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront,
                                          color: Colors.greenAccent,
                                          size: 18),
                                      const SizedBox(width: 6),
                                      Text('Seller Info',
                                          style: GoogleFonts.poppins(
                                              color: Colors.greenAccent,
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _sellerRow(Icons.person_outline,
                                      'Name', p['seller_name'] ?? 'N/A'),
                                  const SizedBox(height: 6),
                                  _sellerRow(Icons.phone_outlined,
                                      'Phone', p['seller_phone'] ?? 'N/A'),
                                  const SizedBox(height: 6),
                                  _sellerRow(
                                      Icons.location_on_outlined,
                                      'Location',
                                      p['location'] ?? 'N/A'),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),
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

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
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
                            color: Colors.white54,
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
}