import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AdminDashboard({super.key, required this.adminData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _UsersTab(adminData: widget.adminData),
          _StatsTab(),
          _AdminsTab(adminData: widget.adminData),
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
              _confirmLogout();
            } else {
              setState(() => _currentIndex = i);
            }
          },
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle:
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 10),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Users'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Stats'),
            BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings_outlined),
                activeIcon: Icon(Icons.admin_panel_settings),
                label: 'Admins'),
            BottomNavigationBarItem(
                icon: Icon(Icons.logout), label: 'Logout'),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Logout?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (r) => false);
    }
  }
}

// ══════════════════════════════════════════════
//  SHARED BACKGROUND WIDGET
// ══════════════════════════════════════════════
class _Bg extends StatelessWidget {
  final Widget child;
  const _Bg({required this.child});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      SizedBox.expand(
          child: Image.asset('assets/images/W_bg.webp', fit: BoxFit.cover)),
      SizedBox.expand(
          child: Container(color: Colors.black.withValues(alpha: 0.72))),
      child,
    ]);
  }
}

// ══════════════════════════════════════════════
//  TAB 1 — USERS
// ══════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const _UsersTab({required this.adminData});
  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabCtrl;

  List<Map<String, dynamic>> buyers = [];
  List<Map<String, dynamic>> farmers = [];
  List<Map<String, dynamic>> shopkeepers = [];
  bool isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _fetchAllUsers();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAllUsers() async {
    setState(() => isLoading = true);
    try {
      final b = await supabase.from('buyers').select().order('created_at', ascending: false);
      final f = await supabase.from('farmers').select().order('created_at', ascending: false);
      final s = await supabase.from('shopkeepers').select().order('created_at', ascending: false);
      setState(() {
        buyers = List<Map<String, dynamic>>.from(b);
        farmers = List<Map<String, dynamic>>.from(f);
        shopkeepers = List<Map<String, dynamic>>.from(s);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) _showSnack('Error: $e', Colors.red);
    }
  }

  List<Map<String, dynamic>> _filtered(List<Map<String, dynamic>> list) {
    if (_search.isEmpty) return list;
    final q = _search.toLowerCase();
    return list
        .where((u) =>
    (u['full_name'] ?? '').toString().toLowerCase().contains(q) ||
        (u['cnic'] ?? '').toString().contains(q) ||
        (u['phone'] ?? '').toString().contains(q))
        .toList();
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _toggleVerify(String table, String id, bool current) async {
    try {
      await supabase.from(table).update({'is_verified': !current}).eq('id', id);
      _fetchAllUsers();
      _showSnack(
          !current ? '✅ User Verified!' : '❌ Verification Removed',
          !current ? Colors.green : Colors.orange);
    } catch (e) {
      _showSnack('Column missing — run the SQL in your Supabase editor.', Colors.red);
    }
  }

  Future<void> _deleteUser(String table, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete User?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('Permanently delete "$name"? This cannot be undone.',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: GoogleFonts.poppins(color: Colors.white60))),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child:
              Text('Delete', style: GoogleFonts.poppins(color: Colors.white))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await supabase.from(table).delete().eq('id', id);
        _fetchAllUsers();
        _showSnack('User "$name" deleted.', Colors.red);
      } catch (e) {
        _showSnack('Delete failed: $e', Colors.red);
      }
    }
  }

  Future<void> _viewUserDetail(Map<String, dynamic> user, String table) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UserDetailSheet(user: user, table: table),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Bg(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.people, color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'User ',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextSpan(
                          text: 'Management',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                    ]),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetchAllUsers,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Mini stats
            if (!isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _miniStat('Buyers', buyers.length, Colors.blueAccent),
                    const SizedBox(width: 8),
                    _miniStat('Farmers', farmers.length, Colors.greenAccent),
                    const SizedBox(width: 8),
                    _miniStat('Shops', shopkeepers.length, Colors.orangeAccent),
                  ],
                ),
              ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by name, CNIC or phone…',
                  hintStyle: GoogleFonts.poppins(
                      color: Colors.white38, fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Colors.white38, size: 18),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.6)),
                ),
                labelColor: Colors.redAccent,
                unselectedLabelColor: Colors.white60,
                labelStyle:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
                unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: '🛒 Buyers (${buyers.length})'),
                  Tab(text: '🌾 Farmers (${farmers.length})'),
                  Tab(text: '🏪 Shops (${shopkeepers.length})'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: isLoading
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent))
                  : TabBarView(
                controller: _tabCtrl,
                children: [
                  _userList(_filtered(buyers), 'buyers'),
                  _userList(_filtered(farmers), 'farmers'),
                  _userList(_filtered(shopkeepers), 'shopkeepers'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(children: [
          Text('$count',
              style: GoogleFonts.poppins(
                  color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _userList(List<Map<String, dynamic>> users, String table) {
    if (users.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.people_outline, color: Colors.white24, size: 70),
          const SizedBox(height: 12),
          Text('No users found',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 15)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, i) {
          final user = users[i];
          final isVerified = user['is_verified'] == true;
          final name = user['full_name'] ?? 'Unknown';
          final cnic = user['cnic'] ?? 'N/A';
          final phone = user['phone'] ?? 'N/A';
          final joined = user['created_at'] != null
              ? (user['created_at'] as String).substring(0, 10)
              : 'N/A';

          String extra = '';
          if (table == 'farmers') {
            extra = user['farm_location'] ?? user['home_location'] ?? '';
          } else if (table == 'shopkeepers') {
            extra = user['shop_name'] ?? '';
          } else {
            extra = user['address'] ?? '';
          }

          return GestureDetector(
            onTap: () => _viewUserDetail(user, table),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isVerified
                      ? Colors.greenAccent.withValues(alpha: 0.5)
                      : Colors.white12,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isVerified
                                ? Colors.green.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.08),
                            border: Border.all(
                                color: isVerified
                                    ? Colors.greenAccent
                                    : Colors.white30,
                                width: 2),
                          ),
                          child: Icon(
                            table == 'buyers'
                                ? Icons.shopping_basket_outlined
                                : table == 'farmers'
                                ? Icons.agriculture_outlined
                                : Icons.store_outlined,
                            color: isVerified ? Colors.greenAccent : Colors.white60,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Flexible(
                                  child: Text(name,
                                      style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.greenAccent
                                              .withValues(alpha: 0.6)),
                                    ),
                                    child: Text('✅ Verified',
                                        style: GoogleFonts.poppins(
                                            color: Colors.greenAccent,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ]),
                              const SizedBox(height: 3),
                              _infoRow(Icons.badge_outlined, 'CNIC: $cnic'),
                              _infoRow(Icons.phone_outlined, 'Phone: $phone'),
                              if (extra.isNotEmpty)
                                _infoRow(Icons.location_on_outlined, extra),
                              _infoRow(Icons.calendar_today_outlined,
                                  'Joined: $joined'),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: Colors.white24, size: 18),
                      ],
                    ),
                  ),

                  // Action buttons
                  Container(
                    decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.08)))),
                    child: Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleVerify(table, user['id'], isVerified),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? Colors.orange.withValues(alpha: 0.12)
                                  : Colors.green.withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                    isVerified
                                        ? Icons.cancel_outlined
                                        : Icons.verified_outlined,
                                    color: isVerified
                                        ? Colors.orangeAccent
                                        : Colors.greenAccent,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(isVerified ? 'Unverify' : 'Verify',
                                    style: GoogleFonts.poppins(
                                        color: isVerified
                                            ? Colors.orangeAccent
                                            : Colors.greenAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 44,
                          color: Colors.white.withValues(alpha: 0.08)),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _deleteUser(table, user['id'], name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.10),
                              borderRadius: const BorderRadius.only(
                                  bottomRight: Radius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.delete_outline,
                                    color: Colors.redAccent, size: 16),
                                const SizedBox(width: 6),
                                Text('Delete',
                                    style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(children: [
        Icon(icon, color: Colors.white38, size: 12),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text,
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 11)),
        ),
      ]),
    );
  }
}

// ── User Detail Bottom Sheet ──
class _UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final String table;
  const _UserDetailSheet({required this.user, required this.table});

  @override
  Widget build(BuildContext context) {
    final fields = <String, String>{};
    user.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty && k != 'password') {
        fields[k] = v.toString();
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(user['full_name'] ?? 'User Details',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(table.toUpperCase(),
              style: GoogleFonts.poppins(
                  color: Colors.redAccent, fontSize: 11)),
          const SizedBox(height: 16),
          ...fields.entries
              .where((e) => e.key != 'id' && e.key != 'full_name')
              .map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                      e.key.replaceAll('_', ' ').toUpperCase(),
                      style: GoogleFonts.poppins(
                          color: Colors.white38, fontSize: 10)),
                ),
                Expanded(
                  child: Text(e.value,
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
//  TAB 2 — STATS
// ══════════════════════════════════════════════
class _StatsTab extends StatefulWidget {
  const _StatsTab();
  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  final supabase = Supabase.instance.client;

  int totalBuyers = 0, totalFarmers = 0, totalShopkeepers = 0;
  int totalProducts = 0, totalOrders = 0, pendingOrders = 0, doneOrders = 0;
  int verifiedBuyers = 0, verifiedFarmers = 0, verifiedShops = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => isLoading = true);
    try {
      final b  = await supabase.from('buyers').select('id, is_verified');
      final f  = await supabase.from('farmers').select('id, is_verified');
      final s  = await supabase.from('shopkeepers').select('id, is_verified');
      final p  = await supabase.from('products').select('id');
      final o  = await supabase.from('orders').select('id, status');

      final buyers       = List<Map<String, dynamic>>.from(b);
      final farmers      = List<Map<String, dynamic>>.from(f);
      final shops        = List<Map<String, dynamic>>.from(s);
      final orders       = List<Map<String, dynamic>>.from(o);

      setState(() {
        totalBuyers      = buyers.length;
        totalFarmers     = farmers.length;
        totalShopkeepers = shops.length;
        totalProducts    = (p as List).length;
        totalOrders      = orders.length;
        pendingOrders    = orders.where((x) => x['status'] == 'pending').length;
        doneOrders       = orders.where((x) => x['status'] == 'done').length;
        verifiedBuyers   = buyers.where((x) => x['is_verified'] == true).length;
        verifiedFarmers  = farmers.where((x) => x['is_verified'] == true).length;
        verifiedShops    = shops.where((x) => x['is_verified'] == true).length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Bg(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.bar_chart,
                        color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'App ',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextSpan(
                          text: 'Statistics',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                    ]),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetchStats,
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
            Expanded(
              child: isLoading
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _sectionTitle('👥 Total Users'),
                    const SizedBox(height: 10),
                    _bigStatCard(
                      icon: Icons.groups,
                      label: 'Total Registered Users',
                      value: totalBuyers + totalFarmers + totalShopkeepers,
                      color: Colors.purpleAccent,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      _statCard('Buyers', totalBuyers,
                          Icons.shopping_basket_outlined, Colors.blueAccent),
                      const SizedBox(width: 10),
                      _statCard('Farmers', totalFarmers,
                          Icons.agriculture_outlined, Colors.greenAccent),
                      const SizedBox(width: 10),
                      _statCard('Shops', totalShopkeepers,
                          Icons.store_outlined, Colors.orangeAccent),
                    ]),

                    const SizedBox(height: 20),
                    _sectionTitle('✅ Verified Users'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _statCard('Buyers', verifiedBuyers,
                          Icons.verified_outlined, Colors.blueAccent),
                      const SizedBox(width: 10),
                      _statCard('Farmers', verifiedFarmers,
                          Icons.verified_outlined, Colors.greenAccent),
                      const SizedBox(width: 10),
                      _statCard('Shops', verifiedShops,
                          Icons.verified_outlined, Colors.orangeAccent),
                    ]),

                    const SizedBox(height: 20),
                    _sectionTitle('📦 Products & Orders'),
                    const SizedBox(height: 10),
                    Row(children: [
                      _statCard('Products', totalProducts,
                          Icons.inventory_2_outlined, Colors.tealAccent),
                      const SizedBox(width: 10),
                      _statCard('Total Orders', totalOrders,
                          Icons.receipt_long_outlined, Colors.yellowAccent),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _statCard('Pending', pendingOrders,
                          Icons.hourglass_empty, Colors.orange),
                      const SizedBox(width: 10),
                      _statCard('Completed', doneOrders,
                          Icons.check_circle_outline, Colors.greenAccent),
                    ]),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t,
        style: GoogleFonts.poppins(
            color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _statCard(String label, int count, IconData icon, Color color) =>
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Column(children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 6),
                Text('$count',
                    style: GoogleFonts.poppins(
                        color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 10)),
              ]),
            ),
          ),
        ),
      );

  Widget _bigStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 12)),
                Text('$value',
                    style: GoogleFonts.poppins(
                        color: color, fontSize: 26, fontWeight: FontWeight.bold)),
              ]),
            ]),
          ),
        ),
      );
}

// ══════════════════════════════════════════════
//  TAB 3 — ADMINS
// ══════════════════════════════════════════════
class _AdminsTab extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const _AdminsTab({required this.adminData});
  @override
  State<_AdminsTab> createState() => _AdminsTabState();
}

class _AdminsTabState extends State<_AdminsTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> admins = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() => isLoading = true);
    try {
      final res = await supabase
          .from('admins')
          .select()
          .order('created_at', ascending: true);
      setState(() {
        admins = List<Map<String, dynamic>>.from(res);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleActive(String id, bool current) async {
    // Prevent deactivating self
    if (id == widget.adminData['id'] && current) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('You cannot deactivate your own account.'),
          backgroundColor: Colors.orange));
      return;
    }
    await supabase.from('admins').update({'is_active': !current}).eq('id', id);
    _fetchAdmins();
  }

  void _showChangePassword(Map<String, dynamic> admin) {
    final passC = TextEditingController();
    bool obscure = true;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Change Password',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('For: ${admin['full_name']}',
                style:
                GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 14),
            TextField(
              controller: passC,
              obscureText: obscure,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 13),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.07),
                suffixIcon: IconButton(
                  icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white38, size: 18),
                  onPressed: () => setS(() => obscure = !obscure),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24)),
              ),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.poppins(color: Colors.white60))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent),
              onPressed: () async {
                final newPass = passC.text.trim();
                if (newPass.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Password must be at least 4 characters.'),
                      backgroundColor: Colors.red));
                  return;
                }
                await supabase
                    .from('admins')
                    .update({'password': newPass})
                    .eq('id', admin['id']);
                if (mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Password updated!'),
                    backgroundColor: Colors.green));
              },
              child: Text('Save',
                  style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.adminData['id'];

    return _Bg(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.admin_panel_settings,
                        color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text: 'Admin ',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      TextSpan(
                          text: 'Accounts',
                          style: GoogleFonts.poppins(
                              fontSize: 20, fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                    ]),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _fetchAdmins,
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

            // Logged-in info banner
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.account_circle,
                      color: Colors.redAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                      'Logged in as: ${widget.adminData['full_name']} '
                          '(@${widget.adminData['username']})',
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12)),
                ]),
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: isLoading
                  ? const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent))
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: admins.length,
                itemBuilder: (ctx, i) {
                  final admin = admins[i];
                  final isMe = admin['id'] == myId;
                  final isActive = admin['is_active'] == true;
                  final lastLogin = admin['last_login'] != null
                      ? (admin['last_login'] as String).substring(0, 16)
                      : 'Never';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMe
                            ? Colors.redAccent.withValues(alpha: 0.6)
                            : isActive
                            ? Colors.greenAccent.withValues(alpha: 0.3)
                            : Colors.white12,
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            // Avatar
                            Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isMe
                                    ? Colors.red.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.07),
                                border: Border.all(
                                    color: isMe
                                        ? Colors.redAccent
                                        : isActive
                                        ? Colors.greenAccent
                                        : Colors.white24,
                                    width: 2),
                              ),
                              child: Icon(
                                  Icons.admin_panel_settings,
                                  color: isMe
                                      ? Colors.redAccent
                                      : isActive
                                      ? Colors.greenAccent
                                      : Colors.white38,
                                  size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(admin['full_name'] ?? '',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                    if (isMe) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          border: Border.all(
                                              color: Colors.redAccent
                                                  .withValues(alpha: 0.6)),
                                        ),
                                        child: Text('You',
                                            style: GoogleFonts.poppins(
                                                color: Colors.redAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ]),
                                  Text('@${admin['username']}',
                                      style: GoogleFonts.poppins(
                                          color: Colors.white54,
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.access_time,
                                        color: Colors.white38, size: 11),
                                    const SizedBox(width: 4),
                                    Text('Last login: $lastLogin',
                                        style: GoogleFonts.poppins(
                                            color: Colors.white38,
                                            fontSize: 10)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green
                                          .withValues(alpha: 0.15)
                                          : Colors.red
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      border: Border.all(
                                          color: isActive
                                              ? Colors.greenAccent
                                              .withValues(alpha: 0.5)
                                              : Colors.redAccent
                                              .withValues(alpha: 0.5)),
                                    ),
                                    child: Text(
                                        isActive ? '🟢 Active' : '🔴 Inactive',
                                        style: GoogleFonts.poppins(
                                            color: isActive
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ),

                        // Actions
                        Container(
                          decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(
                                      color: Colors.white
                                          .withValues(alpha: 0.08)))),
                          child: Row(children: [
                            // Change Password
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showChangePassword(admin),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          bottomLeft:
                                          Radius.circular(16))),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.key_outlined,
                                          color: Colors.blueAccent,
                                          size: 15),
                                      const SizedBox(width: 6),
                                      Text('Change Password',
                                          style: GoogleFonts.poppins(
                                              color: Colors.blueAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Container(
                                width: 1, height: 44,
                                color: Colors.white.withValues(alpha: 0.08)),
                            // Activate / Deactivate
                            Expanded(
                              child: GestureDetector(
                                onTap: () =>
                                    _toggleActive(admin['id'], isActive),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? Colors.red.withValues(alpha: 0.08)
                                        : Colors.green
                                        .withValues(alpha: 0.08),
                                    borderRadius: const BorderRadius.only(
                                        bottomRight: Radius.circular(16)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                          isActive
                                              ? Icons.block
                                              : Icons.check_circle_outline,
                                          color: isActive
                                              ? Colors.redAccent
                                              : Colors.greenAccent,
                                          size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                          isActive
                                              ? 'Deactivate'
                                              : 'Activate',
                                          style: GoogleFonts.poppins(
                                              color: isActive
                                                  ? Colors.redAccent
                                                  : Colors.greenAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}