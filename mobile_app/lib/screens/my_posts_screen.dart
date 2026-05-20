import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/post_provider.dart';
import '../models/post_model.dart';
import 'edit_post_screen.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchUserPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Post History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2E7D32)),
            onPressed: () => postProvider.fetchUserPosts(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => postProvider.fetchUserPosts(),
        color: const Color(0xFF2E7D32),
        child: postProvider.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
            : postProvider.error != null
                ? _buildErrorState(postProvider.error!)
                : postProvider.userPosts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: postProvider.userPosts.length,
                        itemBuilder: (context, index) {
                          final post = postProvider.userPosts[index];
                          return _buildPostItem(post);
                        },
                      ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error', style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Provider.of<PostProvider>(context, listen: false).fetchUserPosts(),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey[200]),
              const SizedBox(height: 16),
              const Text('No post history found', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Pull down to refresh', style: TextStyle(color: Colors.grey, fontSize: 12)),
              if (postProvider.error != null) ...[
                const SizedBox(height: 16),
                Text('Last Error: ${postProvider.error}', style: const TextStyle(color: Colors.red, fontSize: 10)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostItem(PostModel post) {
    bool isDeleted = post.status == 'deleted';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDeleted ? Colors.red[50]?.withOpacity(0.5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDeleted ? Colors.red[200]! : Colors.grey[200]!,
          width: isDeleted ? 1.5 : 1,
        ),
        boxShadow: [
          if (!isDeleted)
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (post.images != null && post.images!.isNotEmpty)
                      ? Image.network(post.images!.first, width: 60, height: 60, fit: BoxFit.cover)
                      : Container(width: 60, height: 60, color: Colors.grey[100], child: const Icon(Icons.image, size: 30)),
                ),
                if (isDeleted)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 40),
                    ),
                  ),
              ],
            ),
            title: Text(
              post.title ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: isDeleted ? TextDecoration.lineThrough : null,
                color: isDeleted ? Colors.grey[600] : Colors.black,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDeleted ? Colors.grey[200] : const Color(0xFF2E7D32).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        post.category?.toUpperCase() ?? '',
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: isDeleted ? Colors.grey[600] : const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '₹${post.price ?? '0'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDeleted ? Colors.grey : Colors.black87,
                      ),
                    ),
                    if (post.oldPrice != null && post.oldPrice != post.price) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${post.oldPrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAnalyticsItem(Icons.visibility_outlined, 'Views', post.viewsCount.toString()),
                    _buildAnalyticsItem(Icons.chat_outlined, 'WhatsApp', post.wpClicks.toString()),
                    _buildAnalyticsItem(Icons.call_outlined, 'Calls', post.callClicks.toString()),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      isDeleted ? Icons.history_rounded : (post.status == 'inactive' ? Icons.pause_circle_outline : Icons.check_circle_outline),
                      size: 14,
                      color: isDeleted ? Colors.red[400] : (post.status == 'inactive' ? Colors.orange[600] : Colors.green[600]),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isDeleted ? 'Deleted from Public Feed' : (post.status == 'inactive' ? 'Inactive (Hidden)' : 'Active on Public Feed'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDeleted ? Colors.red[700] : (post.status == 'inactive' ? Colors.orange[700] : Colors.green[700]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Uploaded: ${_formatDate(post.createdAt)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    if (isDeleted && post.deletedAt != null)
                      Text(
                        'Deleted: ${_formatDate(post.deletedAt!)}',
                        style: TextStyle(fontSize: 10, color: Colors.red[600], fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!isDeleted)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => EditPostScreen(post: post))
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('EDIT'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _confirmDelete(post.id!),
                    icon: const Icon(Icons.delete_forever_outlined, size: 18),
                    label: const Text('DELETE'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
                  ),
                ],
              ),
            ),
          if (isDeleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red[100]?.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: const Text(
                'ACTIVITY: Post hidden from public but archived for developer review.',
                style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmDelete(int postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This post will be removed from the public feed but kept in your history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final postProvider = Provider.of<PostProvider>(context, listen: false);
              final success = await postProvider.deletePost(postId);
              if (success) {
                postProvider.fetchUserPosts();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deleted successfully')));
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
