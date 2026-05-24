import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/skeleton_loader.dart';

class AdminAccessManagementScreen extends StatefulWidget {
  const AdminAccessManagementScreen({super.key});

  @override
  State<AdminAccessManagementScreen> createState() => _AdminAccessManagementScreenState();
}

class _AdminAccessManagementScreenState extends State<AdminAccessManagementScreen> with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<dynamic> _users = [];
  List<dynamic> _filteredUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _listController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fetchUsers();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _api.getAdminUsers();
      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
      _listController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query;
      _filteredUsers = _users.where((user) {
        final name = user['full_name'].toString().toLowerCase();
        final mobile = user['mobile'].toString();
        return name.contains(query.toLowerCase()) || mobile.contains(query);
      }).toList();
    });
    _listController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroAppBar(),
          _buildSearchSection(),
          _isLoading 
            ? _buildSkeletonList()
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUserAccessCard(_filteredUsers[index], index),
                    childCount: _filteredUsers.length,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildHeroAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: const Color(0xFF111827),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Access Control', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
        background: Stack(
          children: [
            Positioned(right: -40, bottom: -40, child: Icon(Icons.shield, size: 200, color: Colors.white.withOpacity(0.03))),
            Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
          child: TextField(
            onChanged: _filterUsers,
            decoration: const InputDecoration(
              hintText: 'Search by user name or ID...',
              prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserAccessCard(Map<String, dynamic> user, int index) {
    bool isSuper = user['mobile'] == '8605889356' || user['is_admin'] == true || user['role'] == 'admin';
    return FadeTransition(
      opacity: _listController,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(backgroundColor: const Color(0xFF1F2937), radius: 25, child: Text(user['full_name'][0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          title: Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user['mobile'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              if (isSuper) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade200, width: 0.8),
                  ),
                  child: Text(
                    'Super User',
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                  ),
                ),
              ],
            ],
          ),
          trailing: _buildRoleChip(user['role'] ?? 'user'),
          onTap: () => _showAdvancedAccessPanel(user),
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role) {
    Color color = role == 'admin' ? Colors.redAccent : (role == 'expert' ? Colors.green : Colors.blueAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  void _showAdvancedAccessPanel(Map<String, dynamic> user) {
    String role = user['role'] ?? 'user';
    bool isAdmin = user['is_admin'] == true;
    
    Map<String, dynamic> perms = {
      'can_view_bookings': false,
      'can_manage_posts': false,
      'can_view_analytics': false,
    };
    if (user['permissions'] != null && user['permissions'] is Map) {
      user['permissions'].forEach((k, v) {
        perms[k.toString()] = v == true;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setPanelState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('System Access Control', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('Managing profile for ${user['full_name']}', style: TextStyle(color: Colors.grey[500])),
              const SizedBox(height: 32),
              
              _buildToggle('Super Admin Status', 'Full override access', isAdmin, Colors.red, (v) => setPanelState(() => isAdmin = v)),
              const SizedBox(height: 24),
              
              const Text('SYSTEM ROLE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
              const SizedBox(height: 12),
              _buildRoleSelector(role, (r) => setPanelState(() => role = r)),
              const SizedBox(height: 32),
              
              const Text('ACTIVE MODULES', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey, letterSpacing: 1)),
              _buildModuleToggle('Booking Control', perms['can_view_bookings'] ?? false, (v) => setPanelState(() => perms['can_view_bookings'] = v)),
              _buildModuleToggle('Inventory & Posts', perms['can_manage_posts'] ?? false, (v) => setPanelState(() => perms['can_manage_posts'] = v)),
              _buildModuleToggle('Enterprise Analytics', perms['can_view_analytics'] ?? false, (v) => setPanelState(() => perms['can_view_analytics'] = v)),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF111827), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: () {
                    _showReviewAndApplyDialog(
                      user,
                      role,
                      isAdmin,
                      Map<String, bool>.from(perms),
                    );
                  },
                  child: const Text('APPLY SECURITY CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewAndApplyDialog(Map<String, dynamic> user, String newRole, bool newIsAdmin, Map<String, bool> newPerms) {
    List<Widget> changeWidgets = [];

    // Role check
    String oldRole = user['role'] ?? 'user';
    if (oldRole != newRole) {
      changeWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              const Icon(Icons.arrow_right_alt, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Change Role: ${oldRole.toUpperCase()} ➔ ${newRole.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Admin Status check
    bool oldIsAdmin = user['is_admin'] == true;
    if (oldIsAdmin != newIsAdmin) {
      changeWidgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Icon(
                newIsAdmin ? Icons.add_circle : Icons.remove_circle,
                color: newIsAdmin ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  newIsAdmin ? 'Grant Super Admin Status' : 'Revoke Super Admin Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: newIsAdmin ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Permissions check
    Map<String, dynamic> oldPerms = {};
    if (user['permissions'] != null && user['permissions'] is Map) {
      user['permissions'].forEach((k, v) {
        oldPerms[k.toString()] = v == true;
      });
    }
    
    List<String> permKeys = ['can_view_bookings', 'can_manage_posts', 'can_view_analytics'];
    Map<String, String> readableKeys = {
      'can_view_bookings': 'Booking Control',
      'can_manage_posts': 'Inventory & Posts',
      'can_view_analytics': 'Enterprise Analytics',
    };

    for (var key in permKeys) {
      bool oldVal = oldPerms[key] == true;
      bool newVal = newPerms[key] == true;
      if (oldVal != newVal) {
        String name = readableKeys[key] ?? key;
        changeWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  newVal ? Icons.check_circle : Icons.cancel,
                  color: newVal ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    newVal ? 'Enable $name Access' : 'Disable $name Access',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: newVal ? Colors.green[800] : Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    if (changeWidgets.isEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('No Changes Detected'),
          content: const Text('No modifications were made to the permissions or role.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield, color: Colors.blue),
            SizedBox(width: 12),
            Text('Review Security Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are modifying system access for ${user['full_name']}. Please review the following updates:',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: changeWidgets,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Are you sure you want to apply these changes?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(c); // close confirmation dialog
              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingCtx) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              );

              try {
                await _api.updateUserAccess(
                  targetUserId: user['id'],
                  role: newRole,
                  permissions: newPerms,
                  isAdmin: newIsAdmin,
                );
                
                // Close loading dialog
                if (mounted) Navigator.pop(context);
                // Close bottom sheet panel
                if (mounted) Navigator.pop(context);
                
                // Fetch updated user list
                _fetchUsers();

                // Refresh the current session user details in case they modified their own permissions
                if (mounted) {
                  await Provider.of<AuthProvider>(context, listen: false).refreshUser();
                }

                // Show Success Dialog
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (successCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: const [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 12),
                          Text('Success / यशस्वी', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      content: const Text(
                        'Security access updated successfully in PostgreSQL database and logged in moderation history!',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                      actions: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.pop(successCtx),
                          child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }
              } catch (e) {
                // Close loading dialog
                if (mounted) Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('CONFIRM & APPLY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(String title, String sub, bool val, Color color, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: val ? color.withOpacity(0.05) : Colors.grey[50], borderRadius: BorderRadius.circular(20), border: Border.all(color: val ? color.withOpacity(0.2) : Colors.transparent)),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey[500]))])),
          Switch.adaptive(value: val, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(String current, Function(String) onSelect) {
    return Wrap(
      spacing: 8,
      children: ['user', 'moderator', 'expert', 'admin'].map((r) => InkWell(
        onTap: () => onSelect(r),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: current == r ? const Color(0xFF111827) : Colors.grey[100], borderRadius: BorderRadius.circular(12)),
          child: Text(r.toUpperCase(), style: TextStyle(color: current == r ? Colors.white : Colors.black87, fontSize: 10, fontWeight: FontWeight.w900)),
        ),
      )).toList(),
    );
  }

  Widget _buildModuleToggle(String title, bool val, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      value: val,
      onChanged: (v) => onChanged(v ?? false),
      activeColor: const Color(0xFF111827),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  Widget _buildSkeletonList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(delegate: SliverChildBuilderDelegate((c, i) => Padding(padding: const EdgeInsets.only(bottom: 12), child: SkeletonLoader(width: double.infinity, height: 80, borderRadius: 24)), childCount: 6)),
    );
  }
}
