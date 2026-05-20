import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'admin_post_audit_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userSummary;
  const AdminUserDetailScreen({super.key, required this.userSummary});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  Map<String, dynamic>? _activityData;
  List<dynamic> _commentHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final activity = await _api.getAdminUserActivity(widget.userSummary['id']);
      final comments = await _api.getAdminUserComments(widget.userSummary['id']);
      setState(() {
        _activityData = activity;
        _commentHistory = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showPostHistory(int postId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (c) => AdminPostAuditScreen(postId: postId, postTitle: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(widget.userSummary['full_name'], style: const TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.black, foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [Tab(text: 'POSTS'), Tab(text: 'COMMENTS'), Tab(text: 'BOOKINGS')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : TabBarView(
              controller: _tabController,
              children: [_buildPostsTab(), _buildCommentsTab(), _buildBookingsTab()],
            ),
    );
  }

  Widget _buildPostsTab() {
    final posts = _activityData?['posts'] as List? ?? [];
    if (posts.isEmpty) return const Center(child: Text('No posts found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final p = posts[i];
        bool isDeleted = p['status'] == 'deleted';
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            onTap: () => _showPostHistory(p['id'], p['title']),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_api.getImageUrl(p['image_url']), width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
            ),
            title: Text(p['title'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('₹${p['price']} • ${isDeleted ? "DELETED" : "ACTIVE"}'),
            trailing: const Icon(Icons.info_outline, size: 20),
          ),
        );
      },
    );
  }

  Widget _buildCommentsTab() {
    if (_commentHistory.isEmpty) return const Center(child: Text('No comments found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _commentHistory.length,
      itemBuilder: (context, i) {
        final c = _commentHistory[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(_api.getImageUrl(c['post_photo']), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image)),
            ),
            title: Text(c['content'], style: const TextStyle(fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('On Post: ${c['post_title']}', style: const TextStyle(fontSize: 10, color: Colors.blue), maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(c['created_at'].toString().substring(5, 10), style: const TextStyle(fontSize: 10)),
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab() {
    final bookings = _activityData?['bookings'] as List? ?? [];
    if (bookings.isEmpty) return const Center(child: Text('No bookings found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, i) {
        final b = bookings[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.call, color: Colors.green),
            title: Text(b['help_type'] ?? 'Call'),
            subtitle: Text('${b['booking_date'].toString().substring(0, 10)} at ${b['booking_time']}'),
          ),
        );
      },
    );
  }
}
