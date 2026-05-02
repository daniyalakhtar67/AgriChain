import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class ShopkeeperDashboard extends StatefulWidget {
  final String shopkeeperName;
  const ShopkeeperDashboard({super.key, required this.shopkeeperName});

  @override
  State<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends State<ShopkeeperDashboard> {
  final supabase = Supabase.instance.client;
  int _currentIndex = 0;

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _SellItemsTab(shopkeeperName: widget.shopkeeperName),
          _OrdersTab(shopkeeperName: widget.shopkeeperName),
          _ProfileTab(
              shopkeeperName: widget.shopkeeperName, onLogout: _logout),
        ],
      ),
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
          selectedItemColor: Colors.greenAccent,
          unselectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle:
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: 'Sell Items',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Orders',
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
}

// ─────────────────────────────────────────────
// TAB 1 — SELL ITEMS
// ─────────────────────────────────────────────
class _SellItemsTab extends StatefulWidget {
  final String shopkeeperName;
  const _SellItemsTab({required this.shopkeeperName});

  @override
  State<_SellItemsTab> createState() => _SellItemsTabState();
}

class _SellItemsTabState extends State<_SellItemsTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> myItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyItems();
  }

  Future<void> fetchMyItems() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('products')
          .select()
          .eq('seller_type', 'shopkeeper')
          .order('created_at', ascending: false);
      setState(() {
        myItems = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchMyItems error: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await supabase.from('products').delete().eq('id', id);
      fetchMyItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item removed!'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final titleC    = TextEditingController();
    final categoryC = TextEditingController();
    final priceC    = TextEditingController();
    final locationC = TextEditingController();
    final imageC    = TextEditingController();
    final descC     = TextEditingController();
    final paymentC  = TextEditingController();
    final phoneC    = TextEditingController();
    // ── NEW: stock quantity ──
    final stockC    = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Add New Item',
              style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _dialogField('Title *', titleC, Icons.title),
                _dialogField('Category *', categoryC, Icons.category),
                _dialogField('Price *', priceC, Icons.attach_money),
                _dialogField('Location', locationC, Icons.location_on),
                _dialogField('Description', descC, Icons.description,
                    maxLines: 2),
                _dialogField(
                    'Payment Method', paymentC, Icons.payment),
                _dialogField(
                    'Your WhatsApp Number (923XXXXXXXXX)',
                    phoneC,
                    Icons.phone,
                    keyType: TextInputType.phone),
                // ── NEW STOCK FIELD ──
                _dialogField(
                  'Stock Quantity (items available)',
                  stockC,
                  Icons.inventory_2_outlined,
                  keyType: TextInputType.number,
                ),
                _dialogField(
                    'Image URL (optional)', imageC, Icons.image),
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
                            'Title, Category, Price zaroori hain!'),
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
                    'description': descC.text.trim(),
                    'payment_method': paymentC.text.trim(),
                    'seller_phone': phoneC.text.trim(),
                    'seller_name': widget.shopkeeperName,
                    'image_url': imageC.text.trim().isEmpty
                        ? null
                        : imageC.text.trim(),
                    'seller_type': 'shopkeeper',
                    // ── NEW: save stock quantity ──
                    'stock_quantity':
                    int.tryParse(stockC.text.trim()) ?? 0,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    fetchMyItems();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Item Added! ✅'),
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
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text('Add',
                  style:
                  GoogleFonts.poppins(color: Colors.white)),
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
        TextInputType keyType = TextInputType.text,
        int maxLines = 1,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
              color: Colors.greenAccent, fontSize: 12),
          prefixIcon:
          Icon(icon, color: Colors.greenAccent, size: 18),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
              const BorderSide(color: Colors.greenAccent)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
            child:
            Image.asset('assets/images/DS.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(
                color: Colors.black.withValues(alpha: 0.70))),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: 'My ',
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          TextSpan(
                              text: 'Items',
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent)),
                        ]),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.greenAccent
                                .withValues(alpha: 0.5)),
                      ),
                      child: Text('${myItems.length} items',
                          style: GoogleFonts.poppins(
                              color: Colors.greenAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showAddItemDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color:
                                Colors.green.withValues(alpha: 0.4),
                                blurRadius: 8)
                          ],
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 22),
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
                    : myItems.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_outlined,
                          color: Colors.white24, size: 80),
                      const SizedBox(height: 16),
                      Text('Koi item nahi hai abhi',
                          style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                          '+ button dabao aur item add karo',
                          style: GoogleFonts.poppins(
                              color: Colors.white38,
                              fontSize: 13)),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: fetchMyItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    itemCount: myItems.length,
                    itemBuilder: (context, index) {
                      final item = myItems[index];
                      return _ItemCard(
                        item: item,
                        onDelete: () =>
                            deleteItem(item['id']),
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
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  const _ItemCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // ── Stock quantity display ──
    final stock = item['stock_quantity'];
    final stockText = (stock != null &&
        int.tryParse(stock.toString()) != null &&
        int.parse(stock.toString()) > 0)
        ? '${stock} pcs'
        : 'N/A';
    final hasStock = stock != null &&
        int.tryParse(stock.toString()) != null &&
        int.parse(stock.toString()) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16)),
            child: item['image_url'] != null
                ? CachedNetworkImage(
                imageUrl: item['image_url'],
                width: 95,
                height: 95,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _imagePlaceholder())
                : _imagePlaceholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['title'] ?? '',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(item['price'] ?? '',
                      style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white38, size: 12),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(item['location'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.white54, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item['category'] ?? '',
                            style: GoogleFonts.poppins(
                                color: Colors.greenAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      // ── Stock badge ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: hasStock
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: hasStock
                                ? Colors.lightBlueAccent
                                .withValues(alpha: 0.5)
                                : Colors.redAccent
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          hasStock
                              ? '📦 Stock: $stockText'
                              : '❌ Out of Stock',
                          style: GoogleFonts.poppins(
                            color: hasStock
                                ? Colors.lightBlueAccent
                                : Colors.redAccent,
                            fontSize: 10,
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 95,
    height: 95,
    color: Colors.grey.shade800,
    child: const Icon(Icons.image, color: Colors.white38),
  );
}

// ─────────────────────────────────────────────
// TAB 2 — ORDERS
// ─────────────────────────────────────────────
class _OrdersTab extends StatefulWidget {
  final String shopkeeperName;
  const _OrdersTab({required this.shopkeeperName});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    try {
      debugPrint(
          'Fetching orders for shopkeeper: "${widget.shopkeeperName}"');

      final data = await supabase
          .from('orders')
          .select()
          .eq('seller_name', widget.shopkeeperName)
          .order('created_at', ascending: false);

      debugPrint('Orders found: ${data.length}');

      if ((data as List).isEmpty) {
        debugPrint(
            'No orders by name — trying seller_type=shopkeeper fallback');
        final fallback = await supabase
            .from('orders')
            .select()
            .eq('seller_type', 'shopkeeper')
            .order('created_at', ascending: false);
        debugPrint('Fallback orders found: ${fallback.length}');
        setState(() {
          orders = List<Map<String, dynamic>>.from(fallback);
          isLoading = false;
        });
      } else {
        setState(() {
          orders = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('fetchOrders error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status}).eq('id', id);
      fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'done'
                ? 'Order complete mark ho gaya! ✅'
                : 'Order pending mark ho gaya!'),
            backgroundColor:
            status == 'done' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openWhatsApp(
      String phone, String buyerName, String productTitle) async {
    final message = Uri.encodeComponent(
        'Assalam o Alaikum $buyerName! Aapka "$productTitle" ka order receive ho gaya hai. Hum aapse jald rabta karein ge.');
    final cleanPhone =
    phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final Uri uri = cleanPhone.isNotEmpty
        ? Uri.parse('https://wa.me/$cleanPhone?text=$message')
        : Uri.parse('https://wa.me/?text=$message');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    if (_filter == 'all') return orders;
    return orders.where((o) => o['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        orders.where((o) => o['status'] == 'pending').length;
    final done = orders.where((o) => o['status'] == 'done').length;

    return Stack(
      children: [
        SizedBox.expand(
            child:
            Image.asset('assets/images/DS.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(
                color: Colors.black.withValues(alpha: 0.70))),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: 'Farmer ',
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          TextSpan(
                              text: 'Orders',
                              style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.greenAccent)),
                        ]),
                      ),
                    ),
                    GestureDetector(
                      onTap: fetchOrders,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                          border:
                          Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.refresh,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatChip(
                        label: 'Total',
                        count: orders.length,
                        color: Colors.blueAccent),
                    const SizedBox(width: 10),
                    _StatChip(
                        label: 'Pending',
                        count: pending,
                        color: Colors.orange),
                    const SizedBox(width: 10),
                    _StatChip(
                        label: 'Done',
                        count: done,
                        color: Colors.greenAccent),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                        label: 'All',
                        active: _filter == 'all',
                        onTap: () => setState(() => _filter = 'all')),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: 'Pending',
                        active: _filter == 'pending',
                        onTap: () =>
                            setState(() => _filter = 'pending'),
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: 'Done',
                        active: _filter == 'done',
                        onTap: () =>
                            setState(() => _filter = 'done'),
                        color: Colors.greenAccent),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.green))
                    : filteredOrders.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      const Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.white24,
                          size: 80),
                      const SizedBox(height: 16),
                      Text(
                        _filter == 'all'
                            ? 'Koi order nahi abhi'
                            : 'Is category mein koi order nahi',
                        style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Logged in as: "${widget.shopkeeperName}"',
                        style: GoogleFonts.poppins(
                            color: Colors.white38,
                            fontSize: 11),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: fetchOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _OrderCard(
                        order: order,
                        onMarkDone: () => updateOrderStatus(
                            order['id'], 'done'),
                        onMarkPending: () =>
                            updateOrderStatus(
                                order['id'], 'pending'),
                        onWhatsApp: () => _openWhatsApp(
                          order['buyer_phone'] ?? '',
                          order['buyer_name'] ?? '',
                          order['product_title'] ?? '',
                        ),
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
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatChip(
      {required this.label,
        required this.count,
        required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  const _FilterChip(
      {required this.label,
        required this.active,
        required this.onTap,
        this.color = Colors.greenAccent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border:
          Border.all(color: active ? color : Colors.white24),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: active ? color : Colors.white60,
                fontSize: 12,
                fontWeight: active
                    ? FontWeight.w600
                    : FontWeight.normal)),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onMarkDone;
  final VoidCallback onMarkPending;
  final VoidCallback onWhatsApp;
  const _OrderCard({
    required this.order,
    required this.onMarkDone,
    required this.onMarkPending,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = order['status'] == 'pending';
    final statusColor =
    isPending ? Colors.orange : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order['product_title'] ?? '',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(order['product_price'] ?? '',
                          style: GoogleFonts.poppins(
                              color: Colors.greenAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    isPending ? '⏳ Pending' : '✅ Done',
                    style: GoogleFonts.poppins(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _orderRow(Icons.person_outline, 'Buyer',
                    order['buyer_name'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(Icons.phone_outlined, 'Phone',
                    order['buyer_phone'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(Icons.location_on_outlined, 'Address',
                    order['buyer_address'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(Icons.production_quantity_limits,
                    'Quantity', '${order['quantity'] ?? 1}'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onWhatsApp,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF25D366)
                                .withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat,
                              color: Color(0xFF25D366), size: 16),
                          const SizedBox(width: 6),
                          Text('WhatsApp',
                              style: GoogleFonts.poppins(
                                  color: const Color(0xFF25D366),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: isPending ? onMarkDone : onMarkPending,
                    child: Container(
                      padding:
                      const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isPending
                                ? Colors.greenAccent
                                .withValues(alpha: 0.5)
                                : Colors.orange
                                .withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPending
                                ? Icons.check_circle_outline
                                : Icons.undo,
                            color: isPending
                                ? Colors.greenAccent
                                : Colors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPending ? 'Mark Done' : 'Undo',
                            style: GoogleFonts.poppins(
                                color: isPending
                                    ? Colors.greenAccent
                                    : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
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

  Widget _orderRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white38, size: 15),
        const SizedBox(width: 8),
        Text('$label: ',
            style: GoogleFonts.poppins(
                color: Colors.white54, fontSize: 12)),
        Flexible(
          child: Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// TAB 3 — PROFILE
// ─────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String shopkeeperName;
  final VoidCallback onLogout;
  const _ProfileTab(
      {required this.shopkeeperName, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
            child:
            Image.asset('assets/images/DS.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(
                color: Colors.black.withValues(alpha: 0.70))),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withValues(alpha: 0.2),
                    border: Border.all(
                        color: Colors.greenAccent, width: 2),
                  ),
                  child: const Icon(Icons.storefront,
                      color: Colors.greenAccent, size: 44),
                ),
                const SizedBox(height: 16),
                Text(shopkeeperName,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('Shopkeeper',
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 32),
                _InfoTile(
                    icon: Icons.store,
                    label: 'Role',
                    value: 'Farming Equipment Seller'),
                const SizedBox(height: 12),
                _InfoTile(
                    icon: Icons.people_alt_outlined,
                    label: 'Customers',
                    value: 'Farmers'),
                const SizedBox(height: 12),
                _InfoTile(
                    icon: Icons.category_outlined,
                    label: 'Products',
                    value: 'Tractor, Fertilizer, Seeds etc.'),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout,
                        color: Colors.white),
                    label: Text('Logout',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
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
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile(
      {required this.icon,
        required this.label,
        required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
            Icon(icon, color: Colors.greenAccent, size: 20),
          ),
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
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}