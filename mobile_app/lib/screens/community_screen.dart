import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_shetkari/widgets/shimmer_skeleton.dart';
import '../core/providers/post_provider.dart';
import '../core/providers/auth_provider.dart';
import '../models/post_model.dart';
import '../widgets/swipeable_image_slider.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_localizations.dart';

class CommunityScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const CommunityScreen({super.key, this.onBackToHome});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ApiService _api = ApiService();
  final Set<int> _likedPosts = {};
  final Set<int> _savedPostsSet = {};
  final Map<int, int> _localLikesCount = {};

  String _selectedCategory = 'all';
  String? _animalType;
  double? _minPrice;
  double? _maxPrice;
  double? _radiusKm;
  String _searchQuery = '';
  String _sortBy = 'latest';
  String _dateFilter = 'all';
  bool _hasImagesOnly = false;
  late TextEditingController _searchController;

  final List<String> _categories = ['all', 'animals', 'farming', 'equipment', 'land'];
  final List<String> _animalTypes = ['Cow', 'Buffalo', 'Goat', 'Sheep', 'Other'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  Future<void> _loadPosts() async {
    final postProvider = Provider.of<PostProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    double? userLat;
    double? userLng;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
        userLat = pos.latitude;
        userLng = pos.longitude;
      }
    } catch (_) {}

    if (userLat == null && authProvider.user != null) {
      final u = authProvider.user!;
      if (u['latitude'] != null && u['longitude'] != null) {
        userLat = double.tryParse(u['latitude'].toString());
        userLng = double.tryParse(u['longitude'].toString());
      }
    }

    await postProvider.fetchPosts(
      category: _selectedCategory,
      animalType: _selectedCategory == 'animals' ? _animalType : null,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      userLat: userLat,
      userLng: userLng,
      radiusKm: _radiusKm,
      search: _searchQuery,
      sortBy: _sortBy,
      dateFilter: _dateFilter,
      hasImages: _hasImagesOnly,
    );

    if (authProvider.isAuthenticated) {
      try {
        final saved = await _api.getSavedPosts();
        setState(() {
          _savedPostsSet.clear();
          for (var p in saved) {
            if (p['id'] != null) {
              _savedPostsSet.add(p['id']);
            }
          }
        });
      } catch (e) {
        debugPrint('Error loading saved posts: $e');
      }
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Advanced Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search Keywords',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        onChanged: (v) => _searchQuery = v.trim(),
                      ),
                      const SizedBox(height: 16),
                      const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _sortBy,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'latest', child: Text('Latest Uploads')),
                          DropdownMenuItem(value: 'likes', child: Text('Most Liked')),
                          DropdownMenuItem(value: 'views', child: Text('Most Viewed')),
                          DropdownMenuItem(value: 'price_asc', child: Text('Price: Low to High')),
                          DropdownMenuItem(value: 'price_desc', child: Text('Price: High to Low')),
                        ],
                        onChanged: (v) => setModalState(() => _sortBy = v ?? 'latest'),
                      ),
                      const SizedBox(height: 16),
                      const Text('Upload Date Filter', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _dateFilter,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Time')),
                          DropdownMenuItem(value: 'today', child: Text('Today')),
                          DropdownMenuItem(value: 'week', child: Text('This Week')),
                          DropdownMenuItem(value: 'month', child: Text('This Month')),
                        ],
                        onChanged: (v) => setModalState(() => _dateFilter = v ?? 'all'),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Only show posts with photos'),
                        value: _hasImagesOnly,
                        activeColor: const Color(0xFF2E7D32),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setModalState(() => _hasImagesOnly = v),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedCategory == 'animals') ...[
                        const Text('Animal Type', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _animalType,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                          hint: const Text('Any'),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String>(value: null, child: Text('Any')),
                            ..._animalTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                          ],
                          onChanged: (v) => setModalState(() => _animalType = v),
                        ),
                        const SizedBox(height: 16),
                      ],
                      const Text('Price Range (₹)', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Min',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                isDense: true,
                              ),
                              controller: TextEditingController(text: _minPrice?.toString() ?? ''),
                              onChanged: (v) => _minPrice = double.tryParse(v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Max',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                isDense: true,
                              ),
                              controller: TextEditingController(text: _maxPrice?.toString() ?? ''),
                              onChanged: (v) => _maxPrice = double.tryParse(v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Max Distance (km)', style: TextStyle(fontWeight: FontWeight.bold)),
                      Slider(
                        value: _radiusKm ?? 50.0,
                        min: 5.0,
                        max: 500.0,
                        divisions: 100,
                        activeColor: const Color(0xFF2E7D32),
                        label: '${_radiusKm?.round() ?? 50} km',
                        onChanged: (v) => setModalState(() => _radiusKm = v),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _animalType = null;
                                  _minPrice = null;
                                  _maxPrice = null;
                                  _radiusKm = null;
                                  _searchQuery = '';
                                  _searchController.clear();
                                  _sortBy = 'latest';
                                  _dateFilter = 'all';
                                  _hasImagesOnly = false;
                                });
                                Navigator.pop(context);
                                _loadPosts();
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Clear Filters', style: TextStyle(color: Colors.black)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _loadPosts();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2E7D32),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = Provider.of<PostProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.translate('community_title'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            } else if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        color: const Color(0xFF2E7D32),
        child: Column(
          children: [
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  String categoryLabel = category.toUpperCase();
                  if (category == 'all') categoryLabel = context.translate('all_category');
                  if (category == 'animals') categoryLabel = context.translate('animals_category');
                  if (category == 'farming') categoryLabel = context.translate('farming_category');
                  if (category == 'equipment') categoryLabel = context.translate('equipment_category');
                  if (category == 'land') categoryLabel = context.translate('land_category');
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedCategory = category);
                        _loadPosts();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[300]!),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          categoryLabel,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: postProvider.isLoading
                  ? Center(child: ShimmerSkeleton())
                  : postProvider.posts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: postProvider.posts.length,
                          itemBuilder: (context, index) {
                            final post = postProvider.posts[index];
                            return _buildInstagramPost(post, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(PostModel post) async {
    final postId = post.id;
    final isCurrentlyLiked = _likedPosts.contains(postId);
    
    setState(() {
      if (isCurrentlyLiked) {
        _likedPosts.remove(postId);
        _localLikesCount[postId] = (_localLikesCount[postId] ?? post.likesCount) - 1;
      } else {
        _likedPosts.add(postId);
        _localLikesCount[postId] = (_localLikesCount[postId] ?? post.likesCount) + 1;
      }
    });

    try {
      await _api.likePost(postId);
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isCurrentlyLiked) {
            _likedPosts.add(postId);
            _localLikesCount[postId] = (_localLikesCount[postId] ?? post.likesCount) + 1;
          } else {
            _likedPosts.remove(postId);
            _localLikesCount[postId] = (_localLikesCount[postId] ?? post.likesCount) - 1;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('failed_add_comment'))),
        );
      }
    }
  }

  Future<void> _launchCall(PostModel post) async {
    try {
      await _api.trackCallClick(post.id);
    } catch (_) {}
    final Uri url = Uri(scheme: 'tel', path: post.contactMobile);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('could_not_launch_dialer'))),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(PostModel post) async {
    try {
      await _api.trackWpClick(post.id);
    } catch (_) {}
    final Uri url = Uri.parse(
        "https://wa.me/91${post.contactMobile}?text=Hi, I saw your post '${post.title}' on Royal Shetkari.");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('could_not_launch_whatsapp'))),
        );
      }
    }
  }

  void _showPostOptions(PostModel post) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final bool isOwnPost = currentUser != null &&
        (post.userId == currentUser['id'] || post.contactMobile == currentUser['mobile']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              if (isOwnPost) ...[
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Post', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePost(post);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.share_outlined, color: Color(0xFF2E7D32)),
                  title: const Text('Share Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _sharePost(post);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined, color: Colors.orange),
                  title: const Text('Report Post', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    _reportPost(post);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _confirmDeletePost(PostModel post) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(dialogContext);
                final postProvider = Provider.of<PostProvider>(context, listen: false);
                final success = await postProvider.deletePost(post.id);
                if (success) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Post deleted successfully')),
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Failed to delete post')),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _sharePost(PostModel post) {
    final Uri whatsappUrl = Uri.parse(
        "https://wa.me/?text=Check out this post: '${post.title}' on Royal Shetkari app! Price: ₹${post.price}. Contact: ${post.contactMobile}");
    launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
  }

  void _reportPost(PostModel post) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Report Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Spam or Duplicate'),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(post, 'Spam');
                },
              ),
              ListTile(
                title: const Text('Fraud or Scam'),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(post, 'Fraud');
                },
              ),
              ListTile(
                title: const Text('Inappropriate Content'),
                onTap: () {
                  Navigator.pop(context);
                  _submitReport(post, 'Inappropriate');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitReport(PostModel post, String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Thank you! Post reported for: $reason')),
    );
  }

  Widget _buildLikeButton(PostModel post) {
    final isLiked = _likedPosts.contains(post.id);
    final likesCount = _localLikesCount[post.id] ?? post.likesCount;

    return Row(
      children: [
        IconButton(
          icon: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.black87,
          ),
          onPressed: () => _toggleLike(post),
        ),
        Text(
          '$likesCount',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Future<void> _toggleSave(PostModel post) async {
    final postId = post.id;
    final isCurrentlySaved = _savedPostsSet.contains(postId);

    setState(() {
      if (isCurrentlySaved) {
        _savedPostsSet.remove(postId);
      } else {
        _savedPostsSet.add(postId);
      }
    });

    try {
      await _api.savePost(postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCurrentlySaved 
                ? 'Post removed from saved list' 
                : 'Post saved successfully!'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isCurrentlySaved) {
            _savedPostsSet.add(postId);
          } else {
            _savedPostsSet.remove(postId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('failed_add_comment'))),
        );
      }
    }
  }

  Widget _buildSaveButton(PostModel post) {
    final isSaved = _savedPostsSet.contains(post.id);

    return IconButton(
      icon: Icon(
        isSaved ? Icons.bookmark : Icons.bookmark_border,
        color: isSaved ? const Color(0xFF2E7D32) : Colors.black87,
      ),
      onPressed: () => _toggleSave(post),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No posts in this category', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildInstagramPost(PostModel post, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF2E7D32),
                    child: Text(
                      (post.farmerName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.farmerName ?? 'Farmer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Row(
                          children: [
                            Text(post.location, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                            if (post.distance != null && post.distance! > 0) ...[
                              Text(' • ', style: TextStyle(color: Colors.grey[400])),
                              Text('${post.distance!.toStringAsFixed(1)} km away', style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onPressed: () => _showPostOptions(post),
                  ),
                ],
              ),
            ),
            SwipeableImageSlider(
              imageUrls: post.images.isNotEmpty ? post.images : (post.imageUrl != null ? <String>[post.imageUrl!] : <String>[]),
              heroTagPrefix: 'post-image-${post.id}',
              onTapImage: (index) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => PostDetailScreen(post: post),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  _buildLikeButton(post),
                  IconButton(
                    icon: const Icon(Icons.mode_comment_outlined), 
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => PostDetailScreen(post: post)))
                  ),
                  const Spacer(),
                  _buildSaveButton(post),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (post.price > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '₹${post.price}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 16),
                      ),
                    ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(text: '${post.farmerName ?? 'Farmer'} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: post.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[800], fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'View all comments',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo(post.createdAt),
                    style: TextStyle(color: Colors.grey[400], fontSize: 10),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _launchCall(post),
                          icon: const Icon(Icons.call, size: 16, color: Color(0xFF2E7D32)),
                          label: Text(
                            context.translate('call'),
                            style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2E7D32)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchWhatsApp(post),
                          icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                          label: Text(
                            context.translate('whatsapp'),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getTimeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays >= 365) {
      final years = (duration.inDays / 365).floor();
      return '$years ${years == 1 ? "YEAR" : "YEARS"} AGO';
    } else if (duration.inDays >= 30) {
      final months = (duration.inDays / 30).floor();
      return '$months ${months == 1 ? "MONTH" : "MONTHS"} AGO';
    } else if (duration.inDays >= 7) {
      final weeks = (duration.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? "WEEK" : "WEEKS"} AGO';
    } else if (duration.inDays >= 1) {
      return '${duration.inDays} ${duration.inDays == 1 ? "DAY" : "DAYS"} AGO';
    } else if (duration.inHours >= 1) {
      return '${duration.inHours} ${duration.inHours == 1 ? "HOUR" : "HOURS"} AGO';
    } else if (duration.inMinutes >= 1) {
      return '${duration.inMinutes} ${duration.inMinutes == 1 ? "MINUTE" : "MINUTES"} AGO';
    } else {
      return 'JUST NOW';
    }
  }
}
