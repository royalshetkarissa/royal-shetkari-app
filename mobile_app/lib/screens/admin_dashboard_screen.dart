import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';
import 'admin_user_detail_screen.dart';
import 'admin_access_management_screen.dart';
import 'admin_shop_management_screen.dart';
import 'admin_shop_analytics_screen.dart';
import 'admin_hospital_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  List<dynamic> _modLogs = [];
  List<dynamic> _topCommenters = [];
  bool _isLoading = true;
  String _activeFilter = 'ALL';
  
  late TabController _tabController;
  late AnimationController _appearController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _appearController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _appearController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Sync current logged in user details to pick up active permissions instantly
      await Provider.of<AuthProvider>(context, listen: false).refreshUser();

      final usersData = await _api.getAdminUsers();
      final logsData = await _api.getAdminModerationLogs();
      final commentersData = await _api.getAdminTopCommenters();
      setState(() {
        _users = usersData;
        _modLogs = logsData;
        _topCommenters = commentersData;
        _isLoading = false;
      });
      _appearController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(int id) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete User?'),
        content: const Text('This will permanently remove the user and all their data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('DELETE', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _api.adminDeleteUser(id);
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    bool isSuperUser = auth.user?['mobile'] == '8605889356';
    
    // Dynamic permissions checking
    Map<String, dynamic> permissions = auth.user?['permissions'] ?? {};
    bool hasBookingAccess = isSuperUser || permissions['can_view_bookings'] == true;
    bool hasPostAccess = isSuperUser || permissions['can_manage_posts'] == true;
    bool hasAnalyticsAccess = isSuperUser || permissions['can_view_analytics'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildElegantAppBar(isSuperUser),
          _buildTopCommentersSection(),
          _buildStatsSection(hasBookingAccess, hasPostAccess, hasAnalyticsAccess),
          _buildTabsHeader(),
          _buildContentSection(isSuperUser),
        ],
      ),
    );
  }

  Widget _buildElegantAppBar(bool isSuperUser) {
    return SliverAppBar(
      expandedHeight: 120, pinned: true, backgroundColor: const Color(0xFF0F172A), elevation: 0,
      flexibleSpace: FlexibleSpaceBar(title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 20)), centerTitle: false),
      actions: [
        if (isSuperUser) IconButton(icon: const Icon(Icons.security, color: Colors.amberAccent), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminAccessManagementScreen()))),
        IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _fetchData),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTopCommentersSection() {
    if (_isLoading || _topCommenters.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 10), child: Text('LEADERSHIP: TOP COMMENTERS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.grey))),
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _topCommenters.length,
              itemBuilder: (context, i) {
                final c = _topCommenters[i];
                return Container(
                  width: 160, margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.05))),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 15, backgroundColor: const Color(0xFF6366F1), child: Text(c['full_name'][0], style: const TextStyle(color: Colors.white, fontSize: 10))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['full_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${c['comment_count']} Comments', style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool hasBookingAccess, bool hasPostAccess, bool hasAnalyticsAccess) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard('Users', _users.length.toString(), Icons.group, const Color(0xFF6366F1)),
                const SizedBox(width: 12),
                _buildStatCard('Engagement', _modLogs.length.toString(), Icons.history, const Color(0xFF10B981)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSuperUserControls(),
            const SizedBox(height: 16),
            _buildShopManagementControls(hasPostAccess, hasAnalyticsAccess),
            const SizedBox(height: 16),
            _buildHospitalManagementControls(hasBookingAccess),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperUserControls() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user?['mobile'] != '8605889356') return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminAccessManagementScreen())),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.security, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SYSTEM SECURITY & ACCESS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                  Text('Manage administrative roles & permissions', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildShopManagementControls(bool hasPostAccess, bool hasAnalyticsAccess) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: hasPostAccess
                ? () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminShopManagementScreen()))
                : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied: Requires "Inventory & Posts" permission.'))),
            child: Opacity(
              opacity: hasPostAccess ? 1.0 : 0.4,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.store, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SHOP INFRASTRUCTURE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                        Text('Add fertilizer shops & manage inventory', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(hasPostAccess ? Icons.arrow_forward_ios : Icons.lock, color: Colors.white60, size: 14),
                ],
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider(color: Colors.white12)),
          InkWell(
            onTap: hasAnalyticsAccess
                ? () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminShopAnalyticsScreen()))
                : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied: Requires "Enterprise Analytics" permission.'))),
            child: Opacity(
              opacity: hasAnalyticsAccess ? 1.0 : 0.4,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MARKET ANALYTICS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                        Text('Track farmer clicks & engagement', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(hasAnalyticsAccess ? Icons.arrow_forward_ios : Icons.lock, color: Colors.white60, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalManagementControls(bool hasBookingAccess) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF880E4F), Color(0xFFD81B60)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: hasBookingAccess
            ? () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AdminHospitalManagementScreen()))
            : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access Denied: Requires "Booking Control" permission.'))),
        child: Opacity(
          opacity: hasBookingAccess ? 1.0 : 0.4,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.local_hospital, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HOSPITALS & CLAIMS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                    Text('Add active hospitals & view user redemptions', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ],
                ),
              ),
              Icon(hasBookingAccess ? Icons.arrow_forward_ios : Icons.lock, color: Colors.white60, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 20)]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 12), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)), Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildTabsHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: Colors.black, unselectedLabelColor: Colors.grey, indicatorColor: Colors.black,
          tabs: const [Tab(text: 'USERS'), Tab(text: 'MODERATION'), Tab(text: 'AUDIT')],
        ),
      ),
    );
  }

  Widget _buildContentSection(bool isSuperUser) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _isLoading ? _buildSkeleton() : _buildUserList(isSuperUser),
          _isLoading ? _buildSkeleton() : _buildModLogs(),
          _isLoading ? _buildSkeleton() : _buildAuditView(),
        ],
      ),
    );
  }

  Widget _buildUserList(bool isSuperUser) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _users.length,
      itemBuilder: (context, i) {
        final u = _users[i];
        bool isSuper = u['mobile'] == '8605889356' || u['is_admin'] == true || u['role'] == 'admin';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: Colors.black, child: Text(u['full_name'][0].toUpperCase(), style: const TextStyle(color: Colors.white))),
            title: Row(
              children: [
                Expanded(child: Text(u['full_name'], style: const TextStyle(fontWeight: FontWeight.bold))),
                if (isSuper) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SUPER USER',
                      style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 8),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Text(u['mobile']),
            trailing: isSuperUser ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteUser(u['id'])) : const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AdminUserDetailScreen(userSummary: u))),
          ),
        );
      },
    );
  }

  Widget _buildModLogs() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _modLogs.length,
      itemBuilder: (context, i) {
        final log = _modLogs[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.delete_forever, color: Colors.red, size: 20)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log['admin_name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Text(log['action_type'], style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text(log['created_at'].toString().substring(5, 16), style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditView() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.verified_user, size: 60, color: Colors.grey), const SizedBox(height: 16), const Text('Complete System Audit History', style: TextStyle(fontWeight: FontWeight.bold)), Text('Visible to authorized administrators', style: TextStyle(color: Colors.grey[400]))]));
  }

  Widget _buildSkeleton() => ListView.builder(padding: const EdgeInsets.all(20), itemCount: 5, itemBuilder: (c, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: SkeletonLoader(width: double.infinity, height: 80, borderRadius: 20)));
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: const Color(0xFFF4F7FE), child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
