import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────
const _kCategories = [
  'Equipment',
  'Irrigation',
  'Fertilizer',
  'Seeds',
  'Pesticide',
  'Crops',
  'Fruits',
  'Vegetables',
  'Grocery',
  'Other',
];

// Payment method definitions
class _PayMethod {
  final String key;      // e.g. 'Easypaisa'
  final String type;     // 'wallet' | 'bank' | 'cash'
  final Color color;
  final IconData icon;
  const _PayMethod(this.key, this.type, this.color, this.icon);
}

const _kPayMethods = [
  _PayMethod('Easypaisa',        'wallet', Color(0xFF7C3AED), Icons.account_balance_wallet),
  _PayMethod('JazzCash',         'wallet', Color(0xFF7C3AED), Icons.account_balance_wallet),
  _PayMethod('NayaPay',          'wallet', Color(0xFF7C3AED), Icons.account_balance_wallet),
  _PayMethod('Meezan Bank',      'bank',   Color(0xFF1D4ED8), Icons.account_balance),
  _PayMethod('UBL',              'bank',   Color(0xFF1D4ED8), Icons.account_balance),
  _PayMethod('HBL',              'bank',   Color(0xFF1D4ED8), Icons.account_balance),
  _PayMethod('Cash on Delivery', 'cash',   Color(0xFF16A34A), Icons.payments_outlined),
];

// ─────────────────────────────────────────────
// PAYMENT METHOD PICKER MODEL
// ─────────────────────────────────────────────
class _SelectedPayment {
  final String key;
  String accountNumber;
  _SelectedPayment(this.key, {this.accountNumber = ''});

  String get type =>
      _kPayMethods.firstWhere((m) => m.key == key).type;

  String toDisplay() {
    if (type == 'cash') return key;
    return '$key: $accountNumber';
  }

  bool get isValid {
    if (type == 'cash') return true;
    if (type == 'wallet') {
      return accountNumber.length == 11 &&
          RegExp(r'^03\d{9}$').hasMatch(accountNumber);
    }
    if (type == 'bank') {
      return accountNumber.length == 24 &&
          accountNumber.toUpperCase().startsWith('PK');
    }
    return false;
  }

  String get hint {
    if (type == 'wallet') return '03XXXXXXXXX (11 digits)';
    if (type == 'bank')   return 'IBAN: PK36XXXX... (24 chars)';
    return '';
  }

  String get validationError {
    if (type == 'wallet' && accountNumber.isNotEmpty && !isValid) {
      return '11-digit number starting with 03';
    }
    if (type == 'bank' && accountNumber.isNotEmpty && !isValid) {
      return '24-character IBAN starting with PK';
    }
    return '';
  }
}

String _buildPaymentString(List<_SelectedPayment> selected) {
  return selected.map((s) => s.toDisplay()).join(' | ');
}

// ─────────────────────────────────────────────
// MAIN DASHBOARD
// ─────────────────────────────────────────────
class ShopkeeperDashboard extends StatefulWidget {
  final String shopkeeperName;
  const ShopkeeperDashboard({super.key, required this.shopkeeperName});

  @override
  State<ShopkeeperDashboard> createState() => _ShopkeeperDashboardState();
}

class _ShopkeeperDashboardState extends State<ShopkeeperDashboard> {
  final supabase = Supabase.instance.client;
  int _currentIndex = 0;

  late String _displayName;
  String _shopPhone    = '';
  String _shopLocation = '';
  String _shopDesc     = '';

  @override
  void initState() {
    super.initState();
    _displayName = widget.shopkeeperName;
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
  }

  void _onProfileUpdated({
    required String name,
    required String phone,
    required String location,
    required String desc,
  }) {
    setState(() {
      _displayName  = name;
      _shopPhone    = phone;
      _shopLocation = location;
      _shopDesc     = desc;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _SellItemsTab(shopkeeperName: _displayName),
          _OrdersTab(shopkeeperName: _displayName),
          _ProfileTab(
            shopkeeperName: _displayName,
            shopPhone: _shopPhone,
            shopLocation: _shopLocation,
            shopDesc: _shopDesc,
            onLogout: _logout,
            onProfileUpdated: _onProfileUpdated,
          ),
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
      // Primary: match seller_name
      var data = await supabase
          .from('products')
          .select()
          .eq('seller_type', 'shopkeeper')
          .eq('seller_name', widget.shopkeeperName)
          .order('created_at', ascending: false);

      if ((data as List).isEmpty) {
        data = await supabase
            .from('products')
            .select()
            .eq('seller_type', 'shopkeeper')
            .order('created_at', ascending: false);
      }

      setState(() {
        myItems = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchMyItems error: $e');
      setState(() => isLoading = false);
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

  // ── Add Item Dialog ──
  void _showAddItemDialog() {
    final titleC    = TextEditingController();
    final priceC    = TextEditingController();
    final locationC = TextEditingController();
    final imageC    = TextEditingController();
    final descC     = TextEditingController();
    final phoneC    = TextEditingController();
    final stockC    = TextEditingController();

    String? selectedCategory;
    final List<_SelectedPayment> selectedPayments = [];
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add New Item',
              style: GoogleFonts.poppins(
                  color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogField('Title *', titleC, Icons.title),

                // ── Category Dropdown ──
                const SizedBox(height: 10),
                Text('Category *',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      hint: Text('Select Category',
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 13)),
                      dropdownColor: Colors.grey.shade900,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.greenAccent),
                      items: _kCategories
                          .map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13)),
                      ))
                          .toList(),
                      onChanged: (val) => setS(() => selectedCategory = val),
                    ),
                  ),
                ),

                // ── Price (numeric only) ──
                const SizedBox(height: 10),
                _dialogField('Price * (e.g. 1500)', priceC,
                    Icons.attach_money,
                    keyType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

                _dialogField('Location', locationC, Icons.location_on),
                _dialogField('Description', descC, Icons.description,
                    maxLines: 2),

                // ── Phone (max 11 digits) ──
                const SizedBox(height: 10),
                _dialogField('WhatsApp (03XXXXXXXXX)', phoneC, Icons.phone,
                    keyType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]),

                // ── Stock (numeric only) ──
                const SizedBox(height: 10),
                _dialogField('Stock Quantity', stockC,
                    Icons.inventory_2_outlined,
                    keyType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly]),

                // ── Payment Methods ──
                const SizedBox(height: 14),
                Text('Payment Methods',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _PaymentMethodPicker(
                  selected: selectedPayments,
                  onChanged: () => setS(() {}),
                ),

                // ── Image URL ──
                const SizedBox(height: 10),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: saving
                  ? null
                  : () async {
                if (titleC.text.isEmpty ||
                    selectedCategory == null ||
                    priceC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Title, Category and Price are required!'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                // Validate payments
                for (final p in selectedPayments) {
                  if (!p.isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              '${p.key}: ${p.validationError}'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }
                }
                // Phone validation
                if (phoneC.text.isNotEmpty &&
                    (phoneC.text.length != 11 ||
                        !phoneC.text.startsWith('03'))) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Phone must be 11 digits starting with 03'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }

                setS(() => saving = true);
                try {
                  final paymentStr =
                  _buildPaymentString(selectedPayments);
                  await supabase.from('products').insert({
                    'title': titleC.text.trim(),
                    'category': selectedCategory,
                    'price': priceC.text.trim(),
                    'location': locationC.text.trim(),
                    'description': descC.text.trim(),
                    'payment_method': paymentStr,
                    'seller_phone': phoneC.text.trim(),
                    'seller_name': widget.shopkeeperName,
                    'image_url': imageC.text.trim().isEmpty
                        ? null
                        : imageC.text.trim(),
                    'seller_type': 'shopkeeper',
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
        TextInputType keyType = TextInputType.text,
        int maxLines = 1,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: keyType,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
          GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.greenAccent, size: 18),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.greenAccent)),
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
            child: Image.asset('assets/images/DS.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(color: Colors.black.withValues(alpha: 0.70))),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            color: Colors.greenAccent.withValues(alpha: 0.5)),
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
                        ),
                        child:
                        const Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                    : myItems.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_outlined,
                          color: Colors.white24, size: 80),
                      const SizedBox(height: 16),
                      Text('No items listed yet',
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first item',
                          style: GoogleFonts.poppins(
                              color: Colors.white38, fontSize: 13)),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: fetchMyItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: myItems.length,
                    itemBuilder: (context, index) {
                      final item = myItems[index];
                      return _ItemCard(
                        item: item,
                        onDelete: () => deleteItem(item['id']),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _ShopkeeperItemDetail(item: item),
                            ),
                          );
                          fetchMyItems();
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
}

// ─────────────────────────────────────────────
// PAYMENT METHOD PICKER WIDGET
// ─────────────────────────────────────────────
class _PaymentMethodPicker extends StatefulWidget {
  final List<_SelectedPayment> selected;
  final VoidCallback onChanged;
  const _PaymentMethodPicker(
      {required this.selected, required this.onChanged});

  @override
  State<_PaymentMethodPicker> createState() => _PaymentMethodPickerState();
}

class _PaymentMethodPickerState extends State<_PaymentMethodPicker> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Method buttons
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kPayMethods.map((m) {
            final isSelected =
            widget.selected.any((s) => s.key == m.key);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    widget.selected.removeWhere((s) => s.key == m.key);
                  } else {
                    widget.selected.add(_SelectedPayment(m.key));
                  }
                });
                widget.onChanged();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? m.color.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? m.color
                        : Colors.white24,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.icon,
                        color: isSelected ? m.color : Colors.white38,
                        size: 14),
                    const SizedBox(width: 5),
                    Text(m.key,
                        style: GoogleFonts.poppins(
                            color:
                            isSelected ? m.color : Colors.white54,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // Account number fields for selected non-cash methods
        ...widget.selected.where((s) => s.type != 'cash').map((s) {
          final m = _kPayMethods.firstWhere((m) => m.key == s.key);
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextField(
              keyboardType: s.type == 'wallet'
                  ? TextInputType.phone
                  : TextInputType.text,
              inputFormatters: s.type == 'wallet'
                  ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ]
                  : [
                LengthLimitingTextInputFormatter(24),
                _UpperCaseFormatter(),
              ],
              style: const TextStyle(color: Colors.white),
              onChanged: (val) {
                setState(() => s.accountNumber = val);
                widget.onChanged();
              },
              decoration: InputDecoration(
                labelText: '${s.key} — ${s.hint}',
                labelStyle: GoogleFonts.poppins(
                    color: m.color, fontSize: 11),
                prefixIcon:
                Icon(m.icon, color: m.color, size: 16),
                errorText: s.accountNumber.isNotEmpty &&
                    !s.isValid
                    ? s.validationError
                    : null,
                errorStyle: GoogleFonts.poppins(
                    color: Colors.redAccent, fontSize: 10),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: m.color.withValues(alpha: 0.4))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: m.color)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Colors.redAccent)),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: Colors.redAccent)),
                filled: true,
                fillColor: m.color.withValues(alpha: 0.07),
              ),
            ),
          );
        }),
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Selected: ${widget.selected.map((s) => s.key).join(', ')}',
            style: GoogleFonts.poppins(
                color: Colors.white54, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// ─────────────────────────────────────────────
// ITEM CARD
// ─────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  const _ItemCard(
      {required this.item, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stock = item['stock_quantity'];
    final stockVal = int.tryParse(stock?.toString() ?? '0') ?? 0;
    final hasStock = stockVal > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                  errorWidget: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            Expanded(
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? '',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 3),
                    Text('PK ${item['price'] ?? ''}',
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
                                  : Colors.redAccent.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            hasStock ? '📦 Stock: $stockVal' : '❌ Out of Stock',
                            style: GoogleFonts.poppins(
                                color: hasStock
                                    ? Colors.lightBlueAccent
                                    : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
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
                    border:
                    Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: Colors.redAccent, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      width: 95,
      height: 95,
      color: Colors.grey.shade800,
      child: const Icon(Icons.image, color: Colors.white38));
}

// ─────────────────────────────────────────────
// ITEM DETAIL SCREEN  (Set Stock button REMOVED from top bar)
// ─────────────────────────────────────────────
class _ShopkeeperItemDetail extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ShopkeeperItemDetail({required this.item});

  @override
  State<_ShopkeeperItemDetail> createState() => _ShopkeeperItemDetailState();
}

class _ShopkeeperItemDetailState extends State<_ShopkeeperItemDetail> {
  final supabase = Supabase.instance.client;
  late int _stock;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _stock =
        int.tryParse(widget.item['stock_quantity']?.toString() ?? '0') ?? 0;
  }

  Future<void> _updateStock(int newStock) async {
    if (newStock < 0) return;
    setState(() => _updating = true);
    try {
      await supabase
          .from('products')
          .update({'stock_quantity': newStock}).eq('id', widget.item['id'].toString());
      setState(() {
        _stock = newStock;
        _updating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated: $_stock',
                style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _updating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _showCustomStockDialog() {
    final stockC = TextEditingController(text: _stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Stock',
            style: GoogleFonts.poppins(
                color: Colors.yellow, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: stockC,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'New quantity',
            labelStyle: const TextStyle(color: Colors.yellow),
            prefixIcon:
            const Icon(Icons.inventory_2_outlined, color: Colors.yellow),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.yellow)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              final val = int.tryParse(stockC.text.trim());
              if (val == null || val < 0) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Please enter a valid number!'),
                    backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(ctx);
              _updateStock(val);
            },
            child: Text('Update',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Parse payment_method string and show color-coded badges
  Widget _buildPaymentBadges(String? paymentStr) {
    if (paymentStr == null || paymentStr.isEmpty) {
      return Text('Not specified',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12));
    }
    final parts = paymentStr.split('|').map((s) => s.trim()).toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: parts.map((part) {
        _PayMethod? method;
        for (final m in _kPayMethods) {
          if (part.startsWith(m.key)) {
            method = m;
            break;
          }
        }
        final color = method?.color ?? Colors.white38;
        final icon = method?.icon ?? Icons.payment;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 5),
              Text(part,
                  style: GoogleFonts.poppins(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item;
    final bool outOfStock = _stock <= 0;

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
              child: Image.asset('assets/images/DS.jpg', fit: BoxFit.cover)),
          SizedBox.expand(
              child:
              Container(color: Colors.black.withValues(alpha: 0.70))),
          SafeArea(
            child: Column(
              children: [
                // ── App Bar (NO Set Stock button here) ──
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
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
                                          child:
                                          CircularProgressIndicator(
                                              color: Colors.green))),
                                  errorWidget: (_, __, ___) => Container(
                                      height: 220,
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white54,
                                          size: 60)))
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
                                  color: outOfStock
                                      ? Colors.red.withValues(alpha: 0.85)
                                      : Colors.green.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  outOfStock
                                      ? 'Out of Stock'
                                      : '$_stock in stock',
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
                                      color: Colors.white)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(10),
                                border:
                                Border.all(color: Colors.greenAccent),
                              ),
                              child: Text('PK ${p['price'] ?? ''}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment methods display
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(14),
                                border:
                                Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.payment,
                                          color: Colors.amberAccent,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Text('Payment Methods',
                                          style: GoogleFonts.poppins(
                                              color: Colors.amberAccent,
                                              fontSize: 13,
                                              fontWeight:
                                              FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildPaymentBadges(
                                      p['payment_method']),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stock management card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter:
                            ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                Colors.blue.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.lightBlueAccent
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.inventory_2_outlined,
                                          color: Colors.lightBlueAccent,
                                          size: 18),
                                      const SizedBox(width: 8),
                                      Text('Stock Management',
                                          style: GoogleFonts.poppins(
                                              color:
                                              Colors.lightBlueAccent,
                                              fontSize: 14,
                                              fontWeight:
                                              FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      // Decrease button
                                      GestureDetector(
                                        onTap: _updating
                                            ? null
                                            : () => _updateStock(_stock - 1),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.red
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.redAccent
                                                    .withValues(alpha: 0.5)),
                                          ),
                                          child: const Icon(Icons.remove,
                                              color: Colors.redAccent,
                                              size: 22),
                                        ),
                                      ),
                                      // Stock number (tap to set custom)
                                      GestureDetector(
                                        onTap: _showCustomStockDialog,
                                        child: Container(
                                          width: 100,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                          padding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors
                                                    .lightBlueAccent),
                                          ),
                                          child: _updating
                                              ? const Center(
                                              child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2)))
                                              : Column(
                                            children: [
                                              Text('$_stock',
                                                  textAlign:
                                                  TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors
                                                          .lightBlueAccent,
                                                      fontSize: 24,
                                                      fontWeight:
                                                      FontWeight
                                                          .bold)),
                                              Text('tap to set',
                                                  textAlign:
                                                  TextAlign.center,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors
                                                          .white38,
                                                      fontSize: 9)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Increase button
                                      GestureDetector(
                                        onTap: _updating
                                            ? null
                                            : () => _updateStock(_stock + 1),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.green
                                                .withValues(alpha: 0.2),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.greenAccent
                                                    .withValues(alpha: 0.5)),
                                          ),
                                          child: const Icon(Icons.add,
                                              color: Colors.greenAccent,
                                              size: 22),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Text(
                                      _stock > 20
                                          ? '🟢 High Stock'
                                          : _stock > 5
                                          ? '🟡 Limited Stock'
                                          : _stock > 0
                                          ? '🔴 Low Stock'
                                          : '⛔ Out of Stock',
                                      style: GoogleFonts.poppins(
                                          color: _stock > 20
                                              ? Colors.greenAccent
                                              : _stock > 5
                                              ? Colors.yellow
                                              : _stock > 0
                                              ? Colors.redAccent
                                              : Colors.red,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
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
      // Primary: match seller_name
      final data = await supabase
          .from('orders')
          .select()
          .eq('seller_name', widget.shopkeeperName)
          .order('created_at', ascending: false);

      if ((data as List).isEmpty) {
        // Fallback: match seller_type
        final fallback = await supabase
            .from('orders')
            .select()
            .eq('seller_type', 'shopkeeper')
            .order('created_at', ascending: false);
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
      final orderData = await supabase
          .from('orders')
          .select()
          .eq('id', id)
          .single();

      // Status update karo
      await supabase.from('orders').update({'status': status}).eq('id', id);

      // Stock update logic
      final productId = orderData['product_id']?.toString();
      final quantity = int.tryParse(orderData['quantity']?.toString() ?? '1') ?? 1;

      if (productId != null && productId.isNotEmpty) {
        try {
          final productData = await supabase
              .from('products')
              .select('stock_quantity')
              .eq('id', productId)
              .single();

          final currentStock =
              int.tryParse(productData['stock_quantity']?.toString() ?? '0') ?? 0;

          final newStock = status == 'done'
              ? (currentStock - quantity).clamp(0, 99999)
              : currentStock + quantity;

          await supabase
              .from('products')
              .update({'stock_quantity': newStock})
              .eq('id', productId);

          debugPrint('Stock: $currentStock → $newStock');
        } catch (stockErr) {
          debugPrint('Stock update skipped: $stockErr');
        }
      }

      fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'done'
                ? 'Order complete!'
                : 'Order pending!'),
            backgroundColor: status == 'done' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _openWhatsApp(
      String phone, String buyerName, String productTitle) async {
    final message = Uri.encodeComponent(
        'Assalam o Alaikum $buyerName! Your order for "$productTitle" has been received.');
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
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
    final pending = orders.where((o) => o['status'] == 'pending').length;
    final done = orders.where((o) => o['status'] == 'done').length;

    return Stack(
      children: [
        SizedBox.expand(
            child: Image.asset('assets/images/DS.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(color: Colors.black.withValues(alpha: 0.70))),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.refresh,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        label: 'Done', count: done, color: Colors.greenAccent),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        onTap: () => setState(() => _filter = 'pending'),
                        color: Colors.orange),
                    const SizedBox(width: 8),
                    _FilterChip(
                        label: 'Done',
                        active: _filter == 'done',
                        onTap: () => setState(() => _filter = 'done'),
                        color: Colors.greenAccent),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: Colors.green))
                    : filteredOrders.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long_outlined,
                          color: Colors.white24, size: 80),
                      const SizedBox(height: 16),
                      Text(
                          _filter == 'all'
                              ? 'No orders yet'
                              : 'No orders in this category',
                          style: GoogleFonts.poppins(
                              color: Colors.white60, fontSize: 15)),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: fetchOrders,
                  child: ListView.builder(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _OrderCard(
                        order: order,
                        onMarkDone: () =>
                            updateOrderStatus(order['id'], 'done'),
                        onMarkPending: () =>
                            updateOrderStatus(order['id'], 'pending'),
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
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? color.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : Colors.white24),
        ),
        child: Text(label,
            style: GoogleFonts.poppins(
                color: active ? color : Colors.white60,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal)),
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
    final statusColor = isPending ? Colors.orange : Colors.greenAccent;

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
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  child: Text(isPending ? '⏳ Pending' : '✅ Done',
                      style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                _orderRow(
                    Icons.person_outline, 'Buyer', order['buyer_name'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(
                    Icons.phone_outlined, 'Phone', order['buyer_phone'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(Icons.location_on_outlined, 'Address',
                    order['buyer_address'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(Icons.production_quantity_limits, 'Quantity',
                    '${order['quantity'] ?? 1}'),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color:
                        const Color(0xFF25D366).withValues(alpha: 0.15),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isPending
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: isPending
                                ? Colors.greenAccent.withValues(alpha: 0.5)
                                : Colors.orange.withValues(alpha: 0.5)),
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
                              size: 16),
                          const SizedBox(width: 6),
                          Text(isPending ? 'Mark Done' : 'Undo',
                              style: GoogleFonts.poppins(
                                  color: isPending
                                      ? Colors.greenAccent
                                      : Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
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
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
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
  final String shopPhone;
  final String shopLocation;
  final String shopDesc;
  final VoidCallback onLogout;
  final void Function({
  required String name,
  required String phone,
  required String location,
  required String desc,
  }) onProfileUpdated;

  const _ProfileTab({
    required this.shopkeeperName,
    required this.shopPhone,
    required this.shopLocation,
    required this.shopDesc,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  void _showEditDialog(BuildContext context) {
    final nameC     = TextEditingController(text: shopkeeperName);
    final phoneC    = TextEditingController(text: shopPhone);
    final locationC = TextEditingController(text: shopLocation);
    final descC     = TextEditingController(text: shopDesc);
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Profile',
              style: GoogleFonts.poppins(
                  color: Colors.greenAccent, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Shop / Name', nameC, Icons.store_outlined),
                const SizedBox(height: 10),
                _field('Phone (WhatsApp)', phoneC, Icons.phone_outlined,
                    keyType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]),
                const SizedBox(height: 10),
                _field('Location', locationC, Icons.location_on_outlined),
                const SizedBox(height: 10),
                _field('About / Description', descC,
                    Icons.description_outlined,
                    maxLines: 3),
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
                if (nameC.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Name cannot be empty!'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                setS(() => saving = true);
                await Future.delayed(
                    const Duration(milliseconds: 300));
                onProfileUpdated(
                  name: nameC.text.trim(),
                  phone: phoneC.text.trim(),
                  location: locationC.text.trim(),
                  desc: descC.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile Updated! ✅'),
                        backgroundColor: Colors.green),
                  );
                }
                setS(() => saving = false);
              },
              child: saving
                  ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text('Save',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
      String label,
      TextEditingController c,
      IconData icon, {
        TextInputType keyType = TextInputType.text,
        int maxLines = 1,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return TextField(
      controller: c,
      keyboardType: keyType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.greenAccent, size: 18),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.greenAccent)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
            child: Image.asset('assets/images/DS.jpg', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(color: Colors.black.withValues(alpha: 0.70))),
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
                    border: Border.all(color: Colors.greenAccent, width: 2),
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
                const SizedBox(height: 4),
                Text('Shopkeeper',
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 28),
                _InfoTile(
                    icon: Icons.store,
                    label: 'Name',
                    value: shopkeeperName),
                const SizedBox(height: 12),
                _InfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: shopPhone.isEmpty ? 'Not set' : shopPhone),
                const SizedBox(height: 12),
                _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: shopLocation.isEmpty ? 'Not set' : shopLocation),
                const SizedBox(height: 12),
                _InfoTile(
                    icon: Icons.description_outlined,
                    label: 'About',
                    value: shopDesc.isEmpty
                        ? 'Farming Equipment Seller'
                        : shopDesc),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditDialog(context),
                    icon: const Icon(Icons.edit_outlined,
                        color: Colors.greenAccent),
                    label: Text('Edit Profile',
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text('Logout',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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
      {required this.icon, required this.label, required this.value});

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
            child: Icon(icon, color: Colors.greenAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
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
          ),
        ],
      ),
    );
  }
}