import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:royal_shetkari/widgets/shimmer_skeleton.dart';
import '../services/api_service.dart';

class AdminPostAuditScreen extends StatefulWidget {
  final int postId;
  final String postTitle;
  const AdminPostAuditScreen({super.key, required this.postId, required this.postTitle});

  @override
  State<AdminPostAuditScreen> createState() => _AdminPostAuditScreenState();
}

class _AdminPostAuditScreenState extends State<AdminPostAuditScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAuditData();
  }

  Future<void> _fetchAuditData() async {
    try {
      final data = await _api.getAdminPostHistory(widget.postId);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getTimeAgo(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (e) { return 'N/A'; }
  }

  @override
  Widget build(BuildContext context) {
    final post = _data?['post'] != null ? Map<String, dynamic>.from(_data!['post']) : <String, dynamic>{};
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(title: const Text('Post Audit Command', style: TextStyle(fontWeight: FontWeight.w900)), backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: _isLoading 
          ? Center(child: ShimmerSkeleton())
          : CustomScrollView(
              slivers: [
                _buildHeroHeader(post),
                _buildStatsGrid(post),
                _buildSectionHeader('AUDIT TRAIL & EDITS'),
                _buildTimelineList(),
                _buildSectionHeader('ENGAGEMENT ANALYTICS'),
                _buildEngagementSection('LIKED BY', _data?['likers'], Colors.red),
                _buildEngagementSection('SAVED BY', _data?['savers'], Colors.orange),
                _buildEngagementSection('RECENT VIEWERS', _data?['viewers'], Colors.blue),
                _buildCommentsSection(),
                const SliverToBoxAdapter(child: SizedBox(height: 60)),
              ],
            ),
    );
  }

  Widget _buildHeroHeader(Map<String, dynamic> post) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(_api.getImageUrl(post['image_url']), width: 80, height: 80, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image, size: 40))),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.postTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('By ${post['author_name'] ?? 'Unknown'}', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: post['status'] == 'deleted' ? Colors.red : Colors.green, borderRadius: BorderRadius.circular(10)), child: Text(post['status']?.toUpperCase() ?? 'ACTIVE', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> post) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildStatCard('VIEWS', post['views_count']?.toString() ?? '0', Icons.visibility, Colors.blue),
            const SizedBox(width: 10),
            _buildStatCard('LIKES', (post['total_likes'] ?? post['likes_count'] ?? 0).toString(), Icons.favorite, Colors.red),
            const SizedBox(width: 10),
            _buildStatCard('SAVES', post['total_saves']?.toString() ?? '0', Icons.bookmark, Colors.orange),
            const SizedBox(width: 10),
            _buildStatCard('EDITS', post['edit_count']?.toString() ?? '0', Icons.edit, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String val, IconData icon, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [Icon(icon, size: 16, color: col), const SizedBox(height: 8), Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(label, style: TextStyle(fontSize: 8, color: Colors.grey[400], fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(24, 32, 24, 16), child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey[400], letterSpacing: 1.5))));
  }

  Widget _buildTimelineList() {
    final logs = _data?['history'] as List? ?? [];
    if (logs.isEmpty) return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No edit history found', style: TextStyle(color: Colors.grey)))));
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) {
          final log = logs[i];
          final details = log['details'] is String ? jsonDecode(log['details']) : log['details'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                children: [
                  Icon(Icons.history, size: 16, color: Colors.purple[300]),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(log['action_type'].replaceAll('_', ' '), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                        if (log['action_type'] == 'POST_EDITED' && details['changes'] != null)
                          ...List.from(details['changes']).map((ch) => Text('• ${ch['field']}: ${ch['old']} → ${ch['new']}', style: const TextStyle(fontSize: 10, color: Colors.black54)))
                        else
                          Text('Action by ${log['actor_name']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(_getTimeAgo(log['created_at']), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                ],
              ),
            ),
          );
        },
        childCount: logs.length,
      ),
    );
  }

  Widget _buildEngagementSection(String title, dynamic items, Color col) {
    final list = items as List? ?? [];
    if (list.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: col, letterSpacing: 1)),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: list.map((l) => Chip(avatar: CircleAvatar(backgroundColor: col.withOpacity(0.1), child: Text((l['full_name'] ?? 'U')[0], style: TextStyle(fontSize: 10, color: col))), label: Text(l['full_name'] ?? 'User', style: const TextStyle(fontSize: 10)))).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final comments = _data?['comments'] as List? ?? [];
    if (comments.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (c, i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                CircleAvatar(child: Text((comments[i]['full_name'] ?? 'U')[0])),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(comments[i]['full_name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), Text(comments[i]['content'] ?? '', style: const TextStyle(fontSize: 12))])),
                Text(_getTimeAgo(comments[i]['created_at']), style: const TextStyle(fontSize: 9, color: Colors.grey)),
              ],
            ),
          ),
          childCount: comments.length,
        ),
      ),
    );
  }
}
