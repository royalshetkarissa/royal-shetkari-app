import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:royal_shetkari/widgets/shimmer_skeleton.dart';
import 'package:image_picker/image_picker.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/booking_provider.dart';
import '../services/api_service.dart';
import '../widgets/animated_button.dart';
import 'my_posts_screen.dart';
import 'admin_dashboard_screen.dart';
import 'post_detail_screen.dart';
import '../models/post_model.dart';
import 'coin_benefits_screen.dart';
import '../localization/app_localizations.dart';
import '../widgets/language_selector_widget.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const ProfileScreen({super.key, this.onBackToHome});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _villageController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  bool _isEditing = false;
  Map<String, dynamic> _socialStats = {'total_likes': 0, 'total_views': 0};
  List<PostModel> _savedPosts = [];
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?['full_name']);
    _emailController = TextEditingController(text: user?['email']);
    _villageController = TextEditingController(text: user?['village']);
    _stateController = TextEditingController(text: user?['state']);
    _pincodeController = TextEditingController(text: user?['pincode']);
    _fetchSocialData();
  }

  Future<void> _fetchSocialData() async {
    try {
      final stats = await _api.getUserSocialStats();
      final saved = await _api.getSavedPosts();
      setState(() {
        _socialStats = stats['stats'] ?? {'total_likes': 0, 'total_views': 0};
        _savedPosts =
            (saved as List).map((p) => PostModel.fromJson(p)).toList();
        _isStatsLoading = false;
      });
    } catch (e) {
      setState(() => _isStatsLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _villageController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.updateProfilePhoto(pickedFile.path);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final success = await auth.updateProfile(
          fullName: _nameController.text,
          email: _emailController.text,
          village: _villageController.text,
          state: _stateController.text,
          pincode: _pincodeController.text);
      if (success) setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
              child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                Color(0xFF1B5E20),
                Color(0xFF2E7D32),
                Color(0xFFF1F8E9)
              ],
                          stops: [
                0.0,
                0.4,
                1.0
              ])))),
          RefreshIndicator(
            onRefresh: _fetchSocialData,
            color: const Color(0xFF2E7D32),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildProfileHeader(user, auth),
                      const SizedBox(height: 24),
                      _isStatsLoading
                          ? _buildStatsSkeleton()
                          : _buildSocialStatsGrid(user),
                      const SizedBox(height: 32),
                      _buildModernCard([
                        _buildField(Icons.person_outline,
                            context.translate('full_name'), _nameController),
                        _buildField(Icons.alternate_email, 'Email Address',
                            _emailController),
                        _buildField(
                            Icons.location_on_outlined,
                            context.translate('location_label'),
                            _villageController),
                        _buildField(
                            Icons.map_outlined, 'State', _stateController),
                        _buildField(Icons.pin_drop_outlined, 'Pincode',
                            _pincodeController),
                      ]),
                      const SizedBox(height: 24),
                      if (_isEditing)
                        AnimatedButton(
                            text: 'SAVE CHANGES',
                            color: const Color(0xFF2E7D32),
                            onPressed: _saveProfile),
                      const SizedBox(height: 32),
                      _buildSavedPostsSection(),
                      const SizedBox(height: 32),
                      _buildActionList(user),
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/images/logo.png',
                              width: 140,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Version rsitv12026',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
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

  Widget _buildAppBar() {
    final bool canPop = Navigator.of(context).canPop();
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        key: const Key('btn_back_profile'),
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
        ),
        onPressed: () {
          if (canPop) {
            Navigator.of(context).pop();
          } else if (widget.onBackToHome != null) {
            widget.onBackToHome!();
          }
        },
      ),
      title: Text(context.translate('profile_title'),
          style: const TextStyle(
              fontWeight: FontWeight.w900, color: Colors.white)),
      actions: [
        IconButton(
          icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(_isEditing ? Icons.close : Icons.edit,
                  color: Colors.white, size: 20)),
          onPressed: () => setState(() => _isEditing = !_isEditing),
        ),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildProfileHeader(dynamic user, AuthProvider auth) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      child: auth.isLoading
                          ? const CircularProgressIndicator()
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: user?['profile_photo_url'] != null
                                  ? Image.network(
                                      ApiService().getImageUrl(
                                          user!['profile_photo_url']),
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover)
                                  : const Icon(Icons.person,
                                      size: 60, color: Colors.grey)))),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                          color: Color(0xFFFF9800), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(user?['full_name'] ?? 'User',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        Text(user?['mobile'] ?? '',
            style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSocialStatsGrid(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(Icons.favorite, context.translate('likes'),
              _socialStats['total_likes'].toString()),
          _buildStatItem(Icons.visibility, context.translate('views'),
              _socialStats['total_views'].toString()),
          _buildStatItem(Icons.bookmark, context.translate('saved'),
              _savedPosts.length.toString()),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (c) => const CoinBenefitsScreen())),
            child: _buildStatItem(Icons.monetization_on,
                context.translate('coins'), user?['coins']?.toString() ?? '0'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        Text(label,
            style:
                TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ],
    );
  }

  Widget _buildStatsSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
          4, (_) => ShimmerSkeleton(width: 70, height: 50, borderRadius: 12)),
    );
  }

  Widget _buildSavedPostsSection() {
    if (_savedPosts.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.translate('saved'),
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32))),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _savedPosts.length,
            itemBuilder: (context, i) {
              final post = _savedPosts[i];
              return InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (c) => PostDetailScreen(post: post))),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      image: post.images.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(
                                  _api.getImageUrl(post.images.first)),
                              fit: BoxFit.cover)
                          : null),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(8),
                  child: Text(post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          shadows: [
                            Shadow(blurRadius: 4, color: Colors.black)
                          ])),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModernCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildField(
      IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: _isEditing ? Colors.black87 : Colors.black54,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          filled: true,
          fillColor: _isEditing
              ? const Color(0xFF2E7D32).withOpacity(0.03)
              : Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildActionList(dynamic user) {
    bool isAdmin = user?['is_admin'] == true || user?['mobile'] == '8605889356';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionTile(
              Icons.history_rounded,
              context.translate('my_posts'),
              const Color(0xFF2E7D32),
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const MyPostsScreen())),
              showDivider: true),
          _buildActionTile(
              Icons.stars,
              context.translate('coins_health_benefits'),
              const Color(0xFF2E7D32),
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => const CoinBenefitsScreen())),
              showDivider: true),
          _buildActionTile(
            Icons.translate_rounded,
            context.translate('choose_language'),
            const Color(0xFF2E7D32),
            () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (c) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LanguageSelectorWidget(),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            context.translate('ok'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            showDivider: isAdmin,
          ),
          if (isAdmin)
            _buildActionTile(
                Icons.admin_panel_settings_rounded,
                'Owner Control Panel',
                Colors.black,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (c) => const AdminDashboardScreen())),
                isSpecial: true,
                showDivider: true),
          _buildActionTile(Icons.logout_rounded, context.translate('logout'),
              Colors.redAccent, _confirmLogout,
              showDivider: false),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final bool logoutConfirmed = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.logout_rounded, color: Colors.redAccent),
                SizedBox(width: 12),
                Text(
                  'लॉग आउट / Log Out?',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            content: const Text(
              'तुम्हाला रॉयल शेतकरी ॲपमधून लॉग आउट करायचे आहे का?\nDo you want to sign out from the application?',
              style:
                  TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('नाही / NO',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(c, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('होय / YES',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (logoutConfirmed && mounted) {
      Provider.of<AuthProvider>(context, listen: false).logout();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Widget _buildActionTile(
      IconData icon, String label, Color color, VoidCallback onTap,
      {bool isSpecial = false, bool showDivider = true}) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:
                  isSpecial ? color.withOpacity(0.15) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSpecial ? Colors.black87 : color,
              fontSize: 14,
            ),
          ),
          trailing:
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          onTap: onTap,
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.grey[100], height: 1),
          ),
      ],
    );
  }
}
