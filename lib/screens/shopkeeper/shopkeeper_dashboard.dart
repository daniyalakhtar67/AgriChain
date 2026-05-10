// lib/screens/shopkeeper/shopkeeper_dashboard.dart
import 'dart:ui';
import 'package:argichain/services/user_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────
// CONSTANTS
// ─────────────────────────────────────────────
// Categories match the categories table
const _kCategoryNames = [
  'Crops',
  'Fruits',
  'Vegetables',
  'Seeds',
  'Fertilizer',
  'Pesticide',
  'Equipment',
  'Irrigation',
];

const _kPriceUnits = [
  'per kg',
  'per maund',
  'per piece',
  'per bag',
  'per litre',
  'per dozen',
];

class _PayMethod {
  final String key;
  final String type;
  final Color color;
  final IconData icon;
  const _PayMethod(this.key, this.type, this.color, this.icon);
}

const _kPayMethods = [
  _PayMethod('easypaisa', 'wallet', Color(0xFF7C3AED),
      Icons.account_balance_wallet),
  _PayMethod('jazzcash', 'wallet', Color(0xFF7C3AED),
      Icons.account_balance_wallet),
  _PayMethod('nayapay', 'wallet', Color(0xFF7C3AED),
      Icons.account_balance_wallet),
  _PayMethod('netbanking', 'bank', Color(0xFF1D4ED8),
      Icons.account_balance),
  _PayMethod('cod', 'cash', Color(0xFF16A34A), Icons.payments_outlined),
];

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
    if (type == 'bank') return 'IBAN: PK36XXXX... (24 chars)';
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
  final String userId;      // NEW: users.user_id (UUID)
  final String shopkeeperName;

  const ShopkeeperDashboard({
    super.key,
    required this.userId,
    required this.shopkeeperName,
  });

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
    _loadProfile();
  }

  // Load full profile from users + shopkeepers
  Future<void> _loadProfile() async {
    try {
      final user = await supabase
          .from('users')
          .select('contact_number, location')
          .eq('user_id', widget.userId)
          .maybeSingle();

      if (user != null) {
        setState(() {
          _shopPhone    = user['contact_number'] ?? '';
          _shopLocation = user['location'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
  }

  void _logout() {
    UserSession.clear();
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
          _SellItemsTab(userId: widget.userId, shopkeeperName: _displayName),
          _OrdersTab(userId: widget.userId, shopkeeperName: _displayName),
          _ProfileTab(
            userId: widget.userId,
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
                label: 'Sell Items'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Orders'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
            BottomNavigationBarItem(
                icon: Icon(Icons.logout), label: 'Logout'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 1 — SELL ITEMS
// Now uses: items + products tables (and categories for category_id lookup)
// ─────────────────────────────────────────────
class _SellItemsTab extends StatefulWidget {
  final String userId;
  final String shopkeeperName;
  const _SellItemsTab({required this.userId, required this.shopkeeperName});

  @override
  State<_SellItemsTab> createState() => _SellItemsTabState();
}

class _SellItemsTabState extends State<_SellItemsTab> {
  final supabase = Supabase.instance.client;

  // We use view_shopkeeper_items for display (joined view)
  List<Map<String, dynamic>> myItems = [];
  Map<String, String> categoryMap = {}; // name -> id
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories().then((_) => fetchMyItems());
  }

  Future<void> _loadCategories() async {
    try {
      final data = await supabase
          .from('categories')
          .select('category_id, category_name')
          .eq('status', 'active');
      setState(() {
        categoryMap = {
          for (var c in data as List)
            c['category_name'] as String: c['category_id'] as String
        };
      });
    } catch (e) {
      debugPrint('Category load error: $e');
    }
  }

  // Fetch this shopkeeper's items via view_shopkeeper_items
  Future<void> fetchMyItems() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('view_shopkeeper_items')
          .select()
          .eq('user_id', widget.userId)
          .order('listed_date', ascending: false);

      setState(() {
        myItems = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchMyItems error: $e');
      setState(() => isLoading = false);
    }
  }

  // Delete: remove from items table (cascades to products)
  Future<void> deleteItem(String itemId) async {
    try {
      await supabase.from('items').delete().eq('item_id', itemId);
      fetchMyItems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Item removed!'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddItemDialog() {
    final titleC    = TextEditingController();
    final priceC    = TextEditingController();
    final descC     = TextEditingController();
    final quantityC = TextEditingController(); // display quantity e.g. "20 pieces"
    final imageC    = TextEditingController();
    final stockC    = TextEditingController();
    final expiryC   = TextEditingController();

    String? selectedCategory;
    String selectedPriceUnit = _kPriceUnits.first;
    final List<_SelectedPayment> selectedPayments = [];
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogField('Title *', titleC, Icons.title),

                const SizedBox(height: 10),
                Text('Category *',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent, fontSize: 12)),
                const SizedBox(height: 6),
                _dropdownField<String>(
                  value: selectedCategory,
                  hint: 'Select Category',
                  items: _kCategoryNames,
                  onChanged: (v) => setS(() => selectedCategory = v),
                ),

                const SizedBox(height: 10),
                _dialogField(
                    'Price * (numbers only)', priceC, Icons.attach_money,
                    keyType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ]),

                const SizedBox(height: 10),
                Text('Price Unit',
                    style: GoogleFonts.poppins(
                        color: Colors.greenAccent, fontSize: 12)),
                const SizedBox(height: 6),
                _dropdownField<String>(
                  value: selectedPriceUnit,
                  hint: 'per kg',
                  items: _kPriceUnits,
                  onChanged: (v) =>
                      setS(() => selectedPriceUnit = v ?? _kPriceUnits.first),
                ),

                const SizedBox(height: 10),
                _dialogField(
                    'Quantity (e.g. 20 pieces)', quantityC,
                    Icons.inventory_2_outlined),
                _dialogField(
                    'Stock Quantity (numbers)', stockC,
                    Icons.warehouse_outlined,
                    keyType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ]),

                _dialogField('Description', descC, Icons.description,
                    maxLines: 2),
                _dialogField(
                    'Expiry Date (optional, YYYY-MM-DD)', expiryC,
                    Icons.calendar_today_outlined),

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

                const SizedBox(height: 10),
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
                    selectedCategory == null ||
                    priceC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Title, Category aur Price zaroori hain!'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                for (final p in selectedPayments) {
                  if (!p.isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                          Text('${p.key}: ${p.validationError}'),
                          backgroundColor: Colors.red),
                    );
                    return;
                  }
                }

                setS(() => saving = true);
                try {
                  final categoryId =
                      categoryMap[selectedCategory] ?? '';

                  // Step 1: items table mein insert
                  final itemInsert = await supabase
                      .from('items')
                      .insert({
                    'user_id':     widget.userId,
                    'category_id': categoryId.isEmpty
                        ? null
                        : categoryId,
                    'name':        titleC.text.trim(),
                    'description': descC.text.trim().isEmpty
                        ? null
                        : descC.text.trim(),
                    'price':
                    double.tryParse(priceC.text.trim()) ??
                        0,
                    'price_unit': selectedPriceUnit,
                    'quantity':
                    quantityC.text.trim().isEmpty
                        ? null
                        : quantityC.text.trim(),
                    'image_url':
                    imageC.text.trim().isEmpty
                        ? null
                        : imageC.text.trim(),
                    'status': 'active',
                  })
                      .select('item_id')
                      .single();

                  final itemId = itemInsert['item_id'];

                  // Step 2: products table mein insert
                  await supabase.from('products').insert({
                    'item_id':        itemId,
                    'user_id':        widget.userId,
                    'shop_id':        widget.userId,
                    'stock_quantity':
                    int.tryParse(stockC.text.trim()) ?? 0,
                    'payment_method':
                    _buildPaymentString(selectedPayments),
                    'expiry_date':
                    expiryC.text.trim().isEmpty
                        ? null
                        : expiryC.text.trim(),
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

  Widget _dropdownField<T>({
    required T? value,
    required String hint,
    required List<String> items,
    required Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value as String?,
          hint: Text(hint,
              style: GoogleFonts.poppins(
                  color: Colors.white38, fontSize: 13)),
          dropdownColor: Colors.grey.shade900,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down,
              color: Colors.greenAccent),
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 13)),
          ))
              .toList(),
          onChanged: (val) => onChanged(val as T?),
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
                            color:
                            Colors.greenAccent.withValues(alpha: 0.5)),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.store_outlined,
                          color: Colors.white24, size: 80),
                      const SizedBox(height: 16),
                      Text('No items listed yet',
                          style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first item',
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
                            deleteItem(item['item_id']),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  _ShopkeeperItemDetail(
                                      item: item),
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
// PAYMENT METHOD PICKER (unchanged logic)
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
                    widget.selected
                        .removeWhere((s) => s.key == m.key);
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
                      color: isSelected ? m.color : Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(m.icon,
                        color:
                        isSelected ? m.color : Colors.white38,
                        size: 14),
                    const SizedBox(width: 5),
                    Text(m.key,
                        style: GoogleFonts.poppins(
                            color: isSelected
                                ? m.color
                                : Colors.white54,
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
        ...widget.selected.where((s) => s.type != 'cash').map((s) {
          final m =
          _kPayMethods.firstWhere((m) => m.key == s.key);
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
                  : [LengthLimitingTextInputFormatter(24)],
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
                errorText:
                s.accountNumber.isNotEmpty && !s.isValid
                    ? s.validationError
                    : null,
                errorStyle: GoogleFonts.poppins(
                    color: Colors.redAccent, fontSize: 10),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: m.color.withValues(alpha: 0.4))),
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
          Text('Selected: ${widget.selected.map((s) => s.key).join(', ')}',
              style: GoogleFonts.poppins(
                  color: Colors.white54, fontSize: 10)),
        ],
      ],
    );
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

    // Price display — new schema has numeric price + price_unit
    final price = item['price']?.toString() ?? '';
    final priceUnit = item['price_unit'] ?? '';

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? '',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 3),
                    Text(
                        'PK $price${priceUnit.isNotEmpty ? ' / $priceUnit' : ''}',
                        style: GoogleFonts.poppins(
                            color: Colors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                              item['seller_location'] ?? '',
                              style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11)),
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
                            color:
                            Colors.green.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(item['category_name'] ?? '',
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
                                  : Colors.redAccent
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            hasStock
                                ? '📦 Stock: $stockVal'
                                : '❌ Out of Stock',
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
// ITEM DETAIL SCREEN
// Stock update: products table via item_id
// ─────────────────────────────────────────────
class _ShopkeeperItemDetail extends StatefulWidget {
  final Map<String, dynamic> item;
  const _ShopkeeperItemDetail({required this.item});

  @override
  State<_ShopkeeperItemDetail> createState() =>
      _ShopkeeperItemDetailState();
}

class _ShopkeeperItemDetailState extends State<_ShopkeeperItemDetail> {
  final supabase = Supabase.instance.client;
  late int _stock;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _stock = int.tryParse(
        widget.item['stock_quantity']?.toString() ?? '0') ??
        0;
  }

  Future<void> _updateStock(int newStock) async {
    if (newStock < 0) return;
    setState(() => _updating = true);
    try {
      // products table mein item_id se update karo
      await supabase
          .from('products')
          .update({'stock_quantity': newStock})
          .eq('item_id', widget.item['item_id'].toString());

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _showCustomStockDialog() {
    final stockC = TextEditingController(text: _stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
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
            prefixIcon: const Icon(Icons.inventory_2_outlined,
                color: Colors.yellow),
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
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green),
            onPressed: () {
              final val = int.tryParse(stockC.text.trim());
              if (val == null || val < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                        Text('Valid number daalo!'),
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

  Widget _buildPaymentBadges(String? paymentStr) {
    if (paymentStr == null || paymentStr.isEmpty) {
      return Text('Not specified',
          style: GoogleFonts.poppins(
              color: Colors.white54, fontSize: 12));
    }
    final parts =
    paymentStr.split('|').map((s) => s.trim()).toList();
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
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: color.withValues(alpha: 0.5)),
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
    final price = p['price']?.toString() ?? '';
    final priceUnit = p['price_unit'] ?? '';

    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
              child: Image.asset('assets/images/DS.jpg',
                  fit: BoxFit.cover)),
          SizedBox.expand(
              child: Container(
                  color: Colors.black.withValues(alpha: 0.70))),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(p['name'] ?? '',
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius:
                              BorderRadius.circular(20),
                              child: p['image_url'] != null
                                  ? CachedNetworkImage(
                                  imageUrl: p['image_url'],
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(
                                          height: 220,
                                          color: Colors
                                              .grey.shade800,
                                          child: const Center(
                                              child:
                                              CircularProgressIndicator(
                                                  color: Colors
                                                      .green))),
                                  errorWidget: (_, __, ___) =>
                                      Container(
                                          height: 220,
                                          color: Colors
                                              .grey.shade800,
                                          child: const Icon(
                                              Icons
                                                  .image_not_supported,
                                              color: Colors
                                                  .white54,
                                              size: 60)))
                                  : Container(
                                  height: 220,
                                  color: Colors.grey.shade800,
                                  child: const Icon(Icons.image,
                                      color: Colors.white54,
                                      size: 60)),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6),
                                decoration: BoxDecoration(
                                  color: outOfStock
                                      ? Colors.red
                                      .withValues(alpha: 0.85)
                                      : Colors.green
                                      .withValues(alpha: 0.85),
                                  borderRadius:
                                  BorderRadius.circular(20),
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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(p['name'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withValues(alpha: 0.25),
                                borderRadius:
                                BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.greenAccent),
                              ),
                              child: Text(
                                  'PK $price${priceUnit.isNotEmpty ? ' / $priceUnit' : ''}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.greenAccent)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment Methods
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(alpha: 0.07),
                                borderRadius:
                                BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
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
                                  ]),
                                  const SizedBox(height: 12),
                                  _buildPaymentBadges(
                                      p['payment_method']),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stock Management
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue
                                    .withValues(alpha: 0.12),
                                borderRadius:
                                BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.lightBlueAccent
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Column(
                                children: [
                                  Row(children: [
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
                                  ]),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      _stockBtn(
                                          icon: Icons.remove,
                                          color: Colors.redAccent,
                                          bgColor: Colors.red,
                                          onTap: _updating
                                              ? null
                                              : () => _updateStock(
                                              _stock - 1)),
                                      GestureDetector(
                                        onTap: _showCustomStockDialog,
                                        child: Container(
                                          width: 100,
                                          margin: const EdgeInsets
                                              .symmetric(
                                              horizontal: 16),
                                          padding:
                                          const EdgeInsets
                                              .symmetric(
                                              vertical: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.blue
                                                .withValues(
                                                alpha: 0.2),
                                            borderRadius:
                                            BorderRadius.circular(
                                                12),
                                            border: Border.all(
                                                color: Colors
                                                    .lightBlueAccent),
                                          ),
                                          child: _updating
                                              ? const Center(
                                              child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                  CircularProgressIndicator(
                                                      color: Colors
                                                          .white,
                                                      strokeWidth:
                                                      2)))
                                              : Column(
                                            children: [
                                              Text('$_stock',
                                                  textAlign:
                                                  TextAlign
                                                      .center,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors
                                                          .lightBlueAccent,
                                                      fontSize:
                                                      24,
                                                      fontWeight:
                                                      FontWeight
                                                          .bold)),
                                              Text('tap to set',
                                                  textAlign:
                                                  TextAlign
                                                      .center,
                                                  style: GoogleFonts.poppins(
                                                      color: Colors
                                                          .white38,
                                                      fontSize:
                                                      9)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      _stockBtn(
                                          icon: Icons.add,
                                          color: Colors.greenAccent,
                                          bgColor: Colors.green,
                                          onTap: _updating
                                              ? null
                                              : () => _updateStock(
                                              _stock + 1)),
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

  Widget _stockBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TAB 2 — ORDERS
// Now uses: view_orders + order_items joined
// ─────────────────────────────────────────────
class _OrdersTab extends StatefulWidget {
  final String userId;
  final String shopkeeperName;
  const _OrdersTab(
      {required this.userId, required this.shopkeeperName});

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

  // Fetch orders where order has items belonging to this shopkeeper
  // Uses orders + order_items + items to match this shopkeeper's user_id
  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    try {
      // Get order_ids that contain this shopkeeper's items
      final orderItemsData = await supabase
          .from('order_items')
          .select('order_id, items!inner(user_id)')
          .eq('items.user_id', widget.userId);

      final orderIds = (orderItemsData as List)
          .map((e) => e['order_id'] as String)
          .toSet()
          .toList();

      if (orderIds.isEmpty) {
        setState(() {
          orders = [];
          isLoading = false;
        });
        return;
      }

      // Get full order details via view_orders
      final ordersData = await supabase
          .from('view_orders')
          .select()
          .inFilter('order_id', orderIds)
          .order('order_date', ascending: false);

      // For each order, get its items (filtered to this shopkeeper)
      final List<Map<String, dynamic>> enriched = [];
      for (final o in ordersData as List) {
        final oi = await supabase
            .from('order_items')
            .select('quantity, price, unit, items!inner(name, user_id)')
            .eq('order_id', o['order_id'])
            .eq('items.user_id', widget.userId);

        enriched.add({
          ...Map<String, dynamic>.from(o),
          'order_items': List<Map<String, dynamic>>.from(oi),
        });
      }

      setState(() {
        orders = enriched;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('fetchOrders error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await supabase
          .from('orders')
          .update({'status': status}).eq('order_id', orderId);

      // Stock update when delivered
      if (status == 'delivered') {
        final order = orders.firstWhere(
                (o) => o['order_id'] == orderId,
            orElse: () => {});
        final items = order['order_items'] as List? ?? [];
        for (final oi in items) {
          try {
            final itemId = oi['items']['item_id']?.toString();
            if (itemId == null) continue;
            final productData = await supabase
                .from('products')
                .select('stock_quantity')
                .eq('item_id', itemId)
                .single();
            final currentStock =
                int.tryParse(
                    productData['stock_quantity']?.toString() ??
                        '0') ??
                    0;
            final qty =
                int.tryParse(oi['quantity']?.toString() ?? '1') ??
                    1;
            final newStock = (currentStock - qty).clamp(0, 99999);
            await supabase
                .from('products')
                .update({'stock_quantity': newStock})
                .eq('item_id', itemId);
          } catch (_) {}
        }
      }

      fetchOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $status!'),
            backgroundColor: status == 'delivered'
                ? Colors.green
                : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _openWhatsApp(
      String phone, String buyerName) async {
    final message = Uri.encodeComponent(
        'Assalam o Alaikum $buyerName! Aapka order receive ho gaya hai.');
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
        orders.where((o) => o['status'] == 'placed').length;
    final done =
        orders.where((o) => o['status'] == 'delivered').length;

    return Stack(
      children: [
        SizedBox.expand(
            child: Image.asset('assets/images/DS.jpg',
                fit: BoxFit.cover)),
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
                        label: 'Placed',
                        count: pending,
                        color: Colors.orange),
                    const SizedBox(width: 10),
                    _StatChip(
                        label: 'Delivered',
                        count: done,
                        color: Colors.greenAccent),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Filter chips — match new status values
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                          label: 'All',
                          active: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all')),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Placed',
                          active: _filter == 'placed',
                          onTap: () =>
                              setState(() => _filter = 'placed'),
                          color: Colors.orange),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Processing',
                          active: _filter == 'processing',
                          onTap: () =>
                              setState(() => _filter = 'processing'),
                          color: Colors.yellow),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Shipped',
                          active: _filter == 'shipped',
                          onTap: () =>
                              setState(() => _filter = 'shipped'),
                          color: Colors.lightBlueAccent),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Delivered',
                          active: _filter == 'delivered',
                          onTap: () =>
                              setState(() => _filter = 'delivered'),
                          color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      _FilterChip(
                          label: 'Cancelled',
                          active: _filter == 'cancelled',
                          onTap: () =>
                              setState(() => _filter = 'cancelled'),
                          color: Colors.redAccent),
                    ],
                  ),
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
                              ? 'No orders yet'
                              : 'No $_filter orders',
                          style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 15)),
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
                        onStatusChange: (newStatus) =>
                            updateOrderStatus(
                                order['order_id'],
                                newStatus),
                        onWhatsApp: () => _openWhatsApp(
                          order['buyer_phone'] ?? '',
                          order['buyer_name'] ?? '',
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
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color = Colors.greenAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
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

// Order card — now uses new status values + order_items list
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusChange;
  final VoidCallback onWhatsApp;

  const _OrderCard({
    required this.order,
    required this.onStatusChange,
    required this.onWhatsApp,
  });

  // Status flow: placed → processing → shipped → delivered
  static const _statusFlow = [
    'placed',
    'processing',
    'shipped',
    'delivered',
  ];

  @override
  Widget build(BuildContext context) {
    final status = order['status'] ?? 'placed';
    final currentIdx = _statusFlow.indexOf(status);
    final canAdvance =
        currentIdx >= 0 && currentIdx < _statusFlow.length - 1;
    final canUndo = currentIdx > 0;
    final isCancelled = status == 'cancelled';

    Color statusColor;
    switch (status) {
      case 'placed':
        statusColor = Colors.orange;
        break;
      case 'processing':
        statusColor = Colors.yellow;
        break;
      case 'shipped':
        statusColor = Colors.lightBlueAccent;
        break;
      case 'delivered':
        statusColor = Colors.greenAccent;
        break;
      case 'cancelled':
        statusColor = Colors.redAccent;
        break;
      default:
        statusColor = Colors.white54;
    }

    final orderItems =
        order['order_items'] as List? ?? [];

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
          // Header
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
                      Text(
                          'Order #${(order['order_id'] as String).substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                      Text(
                          'PKR ${order['net_amount']?.toString() ?? '0'}',
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
                        color:
                        statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(status.toUpperCase(),
                      style: GoogleFonts.poppins(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Buyer info + items
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _orderRow(Icons.person_outline, 'Buyer',
                    order['buyer_name'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(Icons.phone_outlined, 'Phone',
                    order['buyer_phone'] ?? 'N/A'),
                const SizedBox(height: 6),
                _orderRow(Icons.location_on_outlined, 'Address',
                    order['buyer_address'] ?? 'N/A'),
                if (orderItems.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Items:',
                      style: GoogleFonts.poppins(
                          color: Colors.white54, fontSize: 11)),
                  const SizedBox(height: 4),
                  ...orderItems.map((oi) {
                    final name =
                        oi['items']?['name'] ?? 'Item';
                    final qty = oi['quantity'] ?? 1;
                    final price =
                        oi['price']?.toString() ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '• $name x$qty${price.isNotEmpty ? ' — PKR $price' : ''}',
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 12),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Actions
          if (!isCancelled)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  // WhatsApp
                  Expanded(
                    child: GestureDetector(
                      onTap: onWhatsApp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366)
                              .withValues(alpha: 0.15),
                          borderRadius:
                          BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF25D366)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat,
                                color: Color(0xFF25D366),
                                size: 16),
                            const SizedBox(width: 6),
                            Text('WhatsApp',
                                style: GoogleFonts.poppins(
                                    color: const Color(0xFF25D366),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (canAdvance) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onStatusChange(
                            _statusFlow[currentIdx + 1]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            color:
                            Colors.green.withValues(alpha: 0.15),
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.greenAccent
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.greenAccent,
                                  size: 14),
                              const SizedBox(width: 4),
                              Text(
                                _statusFlow[currentIdx + 1]
                                    .toUpperCase(),
                                style: GoogleFonts.poppins(
                                    color: Colors.greenAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (canUndo) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onStatusChange(
                          _statusFlow[currentIdx - 1]),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                          Colors.orange.withValues(alpha: 0.15),
                          borderRadius:
                          BorderRadius.circular(12),
                          border: Border.all(
                              color:
                              Colors.orange.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.undo,
                            color: Colors.orange, size: 16),
                      ),
                    ),
                  ],
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
// Now saves to users table via user_id
// ─────────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final String userId;
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
    required this.userId,
    required this.shopkeeperName,
    required this.shopPhone,
    required this.shopLocation,
    required this.shopDesc,
    required this.onLogout,
    required this.onProfileUpdated,
  });

  void _showEditDialog(BuildContext context) {
    final supabase = Supabase.instance.client;
    final nameC     = TextEditingController(text: shopkeeperName);
    final phoneC    = TextEditingController(text: shopPhone);
    final locationC = TextEditingController(text: shopLocation);
    final shopNameC = TextEditingController(text: shopDesc);
    bool saving = false;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Profile',
              style: GoogleFonts.poppins(
                  color: Colors.greenAccent,
                  fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Full Name', nameC, Icons.person_outlined),
                const SizedBox(height: 10),
                _field('Phone (WhatsApp)', phoneC,
                    Icons.phone_outlined,
                    keyType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ]),
                const SizedBox(height: 10),
                _field('Location', locationC,
                    Icons.location_on_outlined),
                const SizedBox(height: 10),
                _field('Shop Name', shopNameC, Icons.store_outlined),
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
                        content: Text('Name khali nahi ho sakta!'),
                        backgroundColor: Colors.red),
                  );
                  return;
                }
                setS(() => saving = true);
                try {
                  // Update users table
                  await supabase.from('users').update({
                    'name':           nameC.text.trim(),
                    'contact_number': phoneC.text.trim(),
                    'location':       locationC.text.trim(),
                  }).eq('user_id', userId);

                  // Update shopkeepers table
                  await supabase
                      .from('shopkeepers')
                      .update({
                    'shop_name': shopNameC.text.trim(),
                  }).eq('user_id', userId);

                  onProfileUpdated(
                    name:     nameC.text.trim(),
                    phone:    phoneC.text.trim(),
                    location: locationC.text.trim(),
                    desc:     shopNameC.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Profile Updated! ✅'),
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
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : Text('Save',
                  style:
                  GoogleFonts.poppins(color: Colors.white)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
            child: Image.asset('assets/images/DS.jpg',
                fit: BoxFit.cover)),
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
                    value: shopLocation.isEmpty
                        ? 'Not set'
                        : shopLocation),
                const SizedBox(height: 12),
                _InfoTile(
                    icon: Icons.store_outlined,
                    label: 'Shop Name',
                    value: shopDesc.isEmpty
                        ? 'Not set'
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
                      side: const BorderSide(
                          color: Colors.greenAccent),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
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
                    icon: const Icon(Icons.logout,
                        color: Colors.white),
                    label: Text('Logout',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
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