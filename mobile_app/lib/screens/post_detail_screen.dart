import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/post_provider.dart';
import '../core/providers/auth_provider.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/swipeable_image_slider.dart';
import 'full_screen_gallery_screen.dart';
import '../localization/app_localizations.dart';

class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final comments = await _api.getComments(widget.post.id);
      setState(() => _comments = comments);
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;
    try {
      await _api.addComment(widget.post.id, _commentController.text.trim());
      _commentController.clear();
      _fetchComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('failed_add_comment'))));
    }
  }

  Future<void> _launchCall() async {
    try {
      await _api.trackCallClick(widget.post.id);
    } catch (_) {}
    final Uri url = Uri(scheme: 'tel', path: widget.post.contactMobile);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.translate('could_not_launch_dialer'))));
    }
  }

  Future<void> _launchWhatsApp() async {
    try {
      await _api.trackWpClick(widget.post.id);
    } catch (_) {}
    final Uri url = Uri.parse(
        "https://wa.me/91${widget.post.contactMobile}?text=Hi, I saw your post '${widget.post.title}' on Royal Shetkari.");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.translate('could_not_launch_whatsapp'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: SwipeableImageSlider(
                imageUrls: widget.post.images.isNotEmpty
                    ? widget.post.images
                    : (widget.post.imageUrl != null
                        ? <String>[widget.post.imageUrl!]
                        : <String>[]),
                heroTagPrefix: 'post-image-${widget.post.id}',
                onTapImage: (index) {
                  final List<String> urls = widget.post.images.isNotEmpty
                      ? widget.post.images
                      : (widget.post.imageUrl != null
                          ? <String>[widget.post.imageUrl!]
                          : <String>[]);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenGalleryScreen(
                        imageUrls: urls,
                        initialIndex: index,
                        heroTagPrefix: 'post-image-${widget.post.id}',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF2E7D32),
                        child: Text((widget.post.farmerName ?? 'U')[0],
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.post.farmerName ?? 'Farmer',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              Text(widget.post.location,
                                  style: TextStyle(
                                      color: Colors.grey[600], fontSize: 12)),
                              if (widget.post.distance != null &&
                                  widget.post.distance! > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                    '(${widget.post.distance!.toStringAsFixed(1)} km ${context.translate('away')})',
                                    style: const TextStyle(
                                        color: Color(0xFF2E7D32),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchCall,
                          icon: const Icon(Icons.call, size: 18),
                          label: Text(context.translate('call')),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _launchWhatsApp,
                          icon: const Icon(Icons.chat, size: 18),
                          label: Text(context.translate('whatsapp')),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.post.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (widget.post.price > 0)
                    Text('₹${widget.post.price}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100))),
                  const SizedBox(height: 16),
                  if (widget.post.category == 'animals' &&
                      widget.post.animalType != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.translate('animal_details'),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  '${context.translate('type')}: ${context.translate(widget.post.animalType?.toLowerCase() ?? '')}'),
                              if (widget.post.lactation != null)
                                Text(
                                    '${context.translate('lactation')}: ${context.translate(widget.post.lactation!.toLowerCase())}'),
                              if (widget.post.milkPerDay != null)
                                Text(
                                    '${context.translate('milk')}: ${widget.post.milkPerDay} L/day'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(context.translate('description'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(widget.post.description,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey[800], height: 1.5)),
                  const Divider(height: 40),
                  Text(context.translate('comments'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  _isLoadingComments
                      ? const Center(child: CircularProgressIndicator())
                      : _comments.isEmpty
                          ? Text(context.translate('no_comments_yet'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _comments.length,
                              itemBuilder: (context, index) {
                                final comment = _comments[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.grey[300],
                                      child: Text(
                                          (comment['full_name'] as String)[0])),
                                  title: Text(comment['full_name'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  subtitle: Text(comment['content']),
                                );
                              },
                            ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ]),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                    hintText: context.translate('add_comment_hint'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
                onPressed: _addComment,
                icon: const Icon(Icons.send, color: Color(0xFF2E7D32))),
          ],
        ),
      ),
    );
  }
}
