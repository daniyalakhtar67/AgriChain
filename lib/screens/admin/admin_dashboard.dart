// lib/screens/admin/admin_dashboard.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

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
        children: const [
          _UsersTab(),
          _StatsTab(),
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
            if (i == 2) {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/welcome', (r) => false);
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
          GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Stats',
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

// ══════════════════════════════════════════════
//  TAB 1 — USERS
// ══════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  const _UsersTab();

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
      final b = await supabase
          .from('buyers')
          .select()
          .order('created_at', ascending: false);
      final f = await supabase
          .from('farmers')
          .select()
          .order('created_at', ascending: false);
      final s = await supabase
          .from('shopkeepers')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        buyers = List<Map<String, dynamic>>.from(b);
        farmers = List<Map<String, dynamic>>.from(f);
        shopkeepers = List<Map<String, dynamic>>.from(s);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Toggle Verify ──
  Future<void> _toggleVerify(
      String table, String id, bool currentStatus) async {
    try {
      await supabase
          .from(table)
          .update({'is_verified': !currentStatus}).eq('id', id);
      _fetchAllUsers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                !currentStatus ? '✅ User Verified!' : '❌ Verification Removed'),
            backgroundColor:
            !currentStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      // Column nahi hai — SQL dialog dikhao
      if (mounted) _showSqlDialog();
    }
  }

  // ── Delete User ──
  Future<void> _deleteUser(
      String table, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('User Delete?',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to permanently delete "$name"?',
            style: GoogleFonts.poppins(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from(table).delete().eq('id', id);
        _fetchAllUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User deleted!'),
                backgroundColor: Colors.red),
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
  }

  // ── SQL hint dialog ──
  void _showSqlDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18)),
        title: Text('Run This SQL First',
            style: GoogleFonts.poppins(
                color: Colors.yellow, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Run these 3 lines in Supabase SQL Editor:',
                style: GoogleFonts.poppins(
                    color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: SelectableText(
                'ALTER TABLE buyers ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;\n\n'
                    'ALTER TABLE farmers ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;\n\n'
                    'ALTER TABLE shopkeepers ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;',
                style: GoogleFonts.sourceCodePro(
                    color: Colors.greenAccent, fontSize: 10),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context),
            child: Text('OK',
                style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
            child:
            Image.asset('assets/images/W_bg.webp', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(
                color: Colors.black.withValues(alpha: 0.72))),
        SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                            Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(Icons.admin_panel_settings,
                          color: Colors.redAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                            text: 'User ',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        TextSpan(
                            text: 'Management',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
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
                        child: const Icon(Icons.refresh,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Mini Stats Row ──
              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _miniStat(
                          'Buyers', buyers.length, Colors.blueAccent),
                      const SizedBox(width: 8),
                      _miniStat(
                          'Farmers', farmers.length, Colors.greenAccent),
                      const SizedBox(width: 8),
                      _miniStat('Shops', shopkeepers.length,
                          Colors.orangeAccent),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              // ── Tab Bar ──
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
                        color:
                        Colors.redAccent.withValues(alpha: 0.6)),
                  ),
                  labelColor: Colors.redAccent,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 12),
                  unselectedLabelStyle:
                  GoogleFonts.poppins(fontSize: 12),
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: '🛒 Buyers (${buyers.length})'),
                    Tab(text: '🌾 Farmers (${farmers.length})'),
                    Tab(text: '🏪 Shops (${shopkeepers.length})'),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Tab Views ──
              Expanded(
                child: isLoading
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: Colors.redAccent))
                    : TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _userList(buyers, 'buyers'),
                    _userList(farmers, 'farmers'),
                    _userList(shopkeepers, 'shopkeepers'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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

  Widget _userList(
      List<Map<String, dynamic>> users, String table) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                color: Colors.white24, size: 70),
            const SizedBox(height: 12),
            Text('Koi user registered nahi',
                style: GoogleFonts.poppins(
                    color: Colors.white54, fontSize: 15)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchAllUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final isVerified = user['is_verified'] == true;
          final name = user['full_name'] ?? 'Unknown';
          final cnic = user['cnic'] ?? 'N/A';
          final phone = user['phone'] ?? 'N/A';
          final createdAt = user['created_at'] != null
              ? (user['created_at'] as String).substring(0, 10)
              : 'N/A';

          String extra = '';
          if (table == 'farmers') {
            extra = user['farm_location'] ??
                user['home_location'] ??
                '';
          } else if (table == 'shopkeepers') {
            extra = user['shop_name'] ?? '';
          } else {
            extra = user['address'] ?? '';
          }

          return Container(
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
                // ── User Info ──
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isVerified
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: isVerified
                                ? Colors.greenAccent
                                : Colors.white30,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          table == 'buyers'
                              ? Icons.shopping_basket_outlined
                              : table == 'farmers'
                              ? Icons.agriculture_outlined
                              : Icons.store_outlined,
                          color: isVerified
                              ? Colors.greenAccent
                              : Colors.white60,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
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
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green
                                          .withValues(alpha: 0.2),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.greenAccent
                                              .withValues(
                                              alpha: 0.6)),
                                    ),
                                    child: Text('✅ Verified',
                                        style: GoogleFonts.poppins(
                                            color:
                                            Colors.greenAccent,
                                            fontSize: 9,
                                            fontWeight:
                                            FontWeight.w600)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            _infoRow(Icons.badge_outlined,
                                'CNIC: $cnic'),
                            _infoRow(
                                Icons.phone_outlined, 'Phone: $phone'),
                            if (extra.isNotEmpty)
                              _infoRow(Icons.location_on_outlined,
                                  extra),
                            _infoRow(Icons.calendar_today_outlined,
                                'Joined: $createdAt'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Action Buttons ──
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                        top: BorderSide(
                            color: Colors.white
                                .withValues(alpha: 0.08))),
                  ),
                  child: Row(
                    children: [
                      // Verify / Unverify
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _toggleVerify(
                              table, user['id'], isVerified),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: isVerified
                                  ? Colors.orange
                                  .withValues(alpha: 0.12)
                                  : Colors.green
                                  .withValues(alpha: 0.12),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isVerified
                                      ? Icons.cancel_outlined
                                      : Icons.verified_outlined,
                                  color: isVerified
                                      ? Colors.orangeAccent
                                      : Colors.greenAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isVerified
                                      ? 'Unverify'
                                      : 'Verify',
                                  style: GoogleFonts.poppins(
                                      color: isVerified
                                          ? Colors.orangeAccent
                                          : Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Divider
                      Container(
                          width: 1,
                          height: 44,
                          color:
                          Colors.white.withValues(alpha: 0.08)),

                      // Delete
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _deleteUser(table, user['id'], name),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color:
                              Colors.red.withValues(alpha: 0.10),
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text('Delete',
                                    style: GoogleFonts.poppins(
                                        color: Colors.redAccent,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w600)),
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
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(text,
                style: GoogleFonts.poppins(
                    color: Colors.white60, fontSize: 11)),
          ),
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

  int totalBuyers = 0;
  int totalFarmers = 0;
  int totalShopkeepers = 0;
  int totalProducts = 0;
  int totalOrders = 0;
  int pendingOrders = 0;
  int doneOrders = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => isLoading = true);
    try {
      final b = await supabase.from('buyers').select('id');
      final f = await supabase.from('farmers').select('id');
      final s = await supabase.from('shopkeepers').select('id');
      final p = await supabase.from('products').select('id');
      final o = await supabase.from('orders').select('id, status');

      final orders = List<Map<String, dynamic>>.from(o);

      setState(() {
        totalBuyers = (b as List).length;
        totalFarmers = (f as List).length;
        totalShopkeepers = (s as List).length;
        totalProducts = (p as List).length;
        totalOrders = orders.length;
        pendingOrders =
            orders.where((x) => x['status'] == 'pending').length;
        doneOrders =
            orders.where((x) => x['status'] == 'done').length;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
            child:
            Image.asset('assets/images/W_bg.webp', fit: BoxFit.cover)),
        SizedBox.expand(
            child: Container(
                color: Colors.black.withValues(alpha: 0.72))),
        SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color:
                            Colors.redAccent.withValues(alpha: 0.5)),
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
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        TextSpan(
                            text: 'Statistics',
                            style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
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
                    child: CircularProgressIndicator(
                        color: Colors.redAccent))
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  child: Column(
                    children: [
                      // ── Users Section ──
                      _sectionTitle('👥 Users'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _statCard('Buyers', totalBuyers,
                              Icons.shopping_basket_outlined,
                              Colors.blueAccent),
                          const SizedBox(width: 10),
                          _statCard('Farmers', totalFarmers,
                              Icons.agriculture_outlined,
                              Colors.greenAccent),
                          const SizedBox(width: 10),
                          _statCard('Shopkeepers',
                              totalShopkeepers,
                              Icons.store_outlined,
                              Colors.orangeAccent),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Total Users ──
                      _bigStatCard(
                        icon: Icons.groups,
                        label: 'Total Registered Users',
                        value: totalBuyers +
                            totalFarmers +
                            totalShopkeepers,
                        color: Colors.purpleAccent,
                      ),

                      const SizedBox(height: 20),

                      // ── Products & Orders ──
                      _sectionTitle('📦 Products & Orders'),
                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _statCard(
                              'Products',
                              totalProducts,
                              Icons.inventory_2_outlined,
                              Colors.tealAccent),
                          const SizedBox(width: 10),
                          _statCard(
                              'Total Orders',
                              totalOrders,
                              Icons.receipt_long_outlined,
                              Colors.yellowAccent),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          _statCard(
                              'Pending',
                              pendingOrders,
                              Icons.hourglass_empty,
                              Colors.orange),
                          const SizedBox(width: 10),
                          _statCard(
                              'Completed',
                              doneOrders,
                              Icons.check_circle_outline,
                              Colors.greenAccent),
                        ],
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
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title,
          style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _statCard(
      String label, int count, IconData icon, Color color) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border:
              Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 8),
                Text('$count',
                    style: GoogleFonts.poppins(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return ClipRRect(
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          color: Colors.white60, fontSize: 12)),
                  Text('$value',
                      style: GoogleFonts.poppins(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}