import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/providers/auth_provider.dart';
import '../services/api_service.dart';
import 'dart:math' as math;

class CoinBenefitsScreen extends StatefulWidget {
  const CoinBenefitsScreen({super.key});

  @override
  State<CoinBenefitsScreen> createState() => _CoinBenefitsScreenState();
}

class _CoinBenefitsScreenState extends State<CoinBenefitsScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  List<dynamic> _hospitals = [];
  List<dynamic> _history = [];
  bool _isLoadingHospitals = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHospitals();
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHospitals() async {
    setState(() => _isLoadingHospitals = true);
    try {
      final data = await _api.getHospitals();
      setState(() {
        _hospitals = data;
        _isLoadingHospitals = false;
      });
    } catch (e) {
      setState(() => _isLoadingHospitals = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final data = await _api.getRedemptionHistory();
      setState(() {
        _history = data;
        _isLoadingHistory = false;
      });
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _makeCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open phone dialer')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone, String hospitalName) async {
    final String msg = "मी तपासणीसाठी रुग्णालयात येत आहे. तपासणीनंतर, भरतीची आवश्यकता असल्यास, मला नाणी रिडीम करायची आहेत.\n\nI am coming to the hospital for checking. After checking, if admission is needed, I want to redeem the coins against $hospitalName.";
    final String url = "https://wa.me/$phone?text=${Uri.encodeComponent(msg)}";
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _redeemCoins(int hospitalId, String hospitalName) async {
    final userCoins = Provider.of<AuthProvider>(context, listen: false).user?['coins'] ?? 0;
    if (userCoins < 50) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 8),
              Text('कमी नाणी / Low Coins'),
            ],
          ),
          content: const Text(
            'नाणी रिडीम करण्यासाठी तुमच्या खात्यात किमान ५० नाणी असणे आवश्यक आहे.\n\nYou need at least 50 coins in your account to redeem this offer.',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('ठीक आहे / OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    // Confirm dialog
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('नाणी रिडीम करायची? / Confirm Redeem?'),
        content: Text(
          'तुम्ही $hospitalName मध्ये १०% सूट मिळवण्यासाठी ५० नाणी रिडीम करू इच्छिता?\n\nDo you want to redeem 50 coins to get a 10% IPD discount at $hospitalName?',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('REDEEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _api.redeemHospitalCoins(hospitalId);
      if (res['success'] == true) {
        if (mounted) {
          // Sync new coins locally
          await Provider.of<AuthProvider>(context, listen: false).refreshUser();
          
          // Refresh views
          _fetchHistory();
          _fetchHospitals();

          // Show Animated Success Dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CreativeRedeemSuccessDialog(
              hospitalName: hospitalName,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final coins = user?['coins'] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'नाणी व आरोग्य लाभ / Coins & Benefits',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Coins and Health Benefit Overview Card
          _buildBenefitHeader(coins),
          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2E7D32),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF2E7D32),
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'रुग्णालय / Hospitals', icon: Icon(Icons.local_hospital_outlined)),
                Tab(text: 'इतिहास / History', icon: Icon(Icons.history_rounded)),
              ],
            ),
          ),
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHospitalsTab(coins),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitHeader(int coins) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          // Coin Counter Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amberAccent, size: 36),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$coins',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                    ),
                    const Text(
                      'एकूण उपलब्ध नाणी / Total Coins',
                      style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Health Benefit Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.favorite, color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'विशेष आरोग्य लाभ / Special Health Benefits',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                const Text(
                  'ज्या शेतकऱ्यांकडे ५० किंवा त्यापेक्षा जास्त नाणी उपलब्ध आहेत, त्यांना कुटुंबातील कोणत्याही व्यक्तीला भरती (Admit) केल्यानंतर रुग्णालयाच्या IPD बिलावर १०% विशेष सूट दिली जाईल.',
                  style: TextStyle(fontSize: 13, color: Colors.black87, height: 1.4, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Farmers who have 50 or more coins are eligible for a special 10% discount on IPD bills for any admitted family member in the designated hospitals.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalsTab(int userCoins) {
    if (_isLoadingHospitals) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (_hospitals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_hospital_rounded, color: Colors.grey.shade400, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'कोणतेही रुग्णालय उपलब्ध नाही',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  'सध्या कोणतीही रुग्णालय ऑफर उपलब्ध नाही.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  'No hospital offers available at the moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hospitals.length,
      itemBuilder: (context, i) {
        final h = _hospitals[i];
        final bool canRedeem = userCoins >= 50;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner with Hospital Name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50.withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_hospital, color: Colors.red, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        h['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFC62828)),
                      ),
                    ),
                  ],
                ),
              ),
              // Hospital Details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            h['location'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Services
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.medical_services, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'सुविधा / Services: ${h['service']}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Contact Info
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey.shade500),
                        const SizedBox(width: 8),
                        Text(
                          h['contact_number'],
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    // Call & WhatsApp & Redeem Row
                    Row(
                      children: [
                        // Phone Call Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _makeCall(h['contact_number']),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.blue.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.call, color: Colors.blue, size: 18),
                                SizedBox(width: 6),
                                Text('कॉल / Call', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // WhatsApp Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _openWhatsApp(h['contact_number'], h['name']),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.green.shade400),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.chat_bubble_outline, color: Colors.green, size: 18),
                                SizedBox(width: 6),
                                Text('WhatsApp', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Redeem Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => _redeemCoins(h['id'], h['name']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canRedeem ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: canRedeem ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars, color: canRedeem ? Colors.amberAccent : Colors.grey.shade500, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              canRedeem
                                  ? '५० नाणी रिडीम करा / Redeem 50 Coins'
                                  : 'रिडीमसाठी ५० नाणी आवश्यक / 50 Coins Required',
                              style: TextStyle(
                                color: canRedeem ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
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
      },
    );
  }

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, color: Colors.grey.shade400, size: 64),
            const SizedBox(height: 16),
            const Text(
              'कोणताही इतिहास नाही',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              'तुम्ही अद्याप कोणतीही नाणी रिडीम केलेली नाहीत.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, i) {
        final item = _history[i];
        final date = DateTime.parse(item['created_at']);
        final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              // Deduction symbol (-)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['hospital_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                '-${item['coins_redeemed']} नाणी',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Helper extension to make standard OutlinedButton act as container for custom child
extension OutlinedButtonExtension on OutlinedButton {
  Widget child(Widget build) {
    return InkWell(
      onTap: onPressed,
      child: build,
    );
  }
}

// ----------------------------------------------------
// 🏥 HOSPITAL PLUS (+) GROWING SUCCESS ANIMATION DIALOG
// ----------------------------------------------------
class CreativeRedeemSuccessDialog extends StatefulWidget {
  final String hospitalName;

  const CreativeRedeemSuccessDialog({
    super.key,
    required this.hospitalName,
  });

  @override
  State<CreativeRedeemSuccessDialog> createState() => _CreativeRedeemSuccessDialogState();
}

class _CreativeRedeemSuccessDialogState extends State<CreativeRedeemSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeInOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      elevation: 16,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Concentric Glowing Rings + Pulsing Hospital Plus Animation
            SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated concentric ripples
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(170, 170),
                        painter: SuccessRingRipplePainter(_controller.value),
                      );
                    },
                  ),
                  // Pulsing and Rotating Cross Circle
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Transform.rotate(
                            angle: _rotateAnimation.value * 2 * math.pi,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2E7D32).withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.add, // Plus Button Symbol
                                color: Colors.white,
                                size: 52,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Marathi success heading
            const Text(
              'रिडेम्पशन यशस्वी! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 4),
            // English success heading
            Text(
              'Redemption Successful! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            // Marathi success explanation
            Text(
              'तुमची ५० नाणी यशस्वीरित्या रिडीम करण्यात आली आहेत. ${widget.hospitalName} मध्ये दाखल करताना १०% IPD सवलतीचा लाभ घेण्यासाठी इतिहास दाखवा.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            // English success explanation
            Text(
              'Your 50 coins have been successfully redeemed. Please present the history record at ${widget.hospitalName} during admission to claim the 10% IPD discount.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close Success Popup
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
                child: const Text(
                  'उत्कृष्ट / Awesome',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Concentric gold/green rings that expand and fade out
class SuccessRingRipplePainter extends CustomPainter {
  final double progress;

  SuccessRingRipplePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Wave 1
    final paint1 = Paint()
      ..color = const Color(0xFFE8F5E9).withOpacity((1.0 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final r1 = 45 + progress * 35;
    canvas.drawCircle(center, r1, paint1);

    // Wave 2
    final paint2 = Paint()
      ..color = const Color(0xFFC8E6C9).withOpacity(((1.0 - progress) * 0.7).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r2 = 55 + progress * 45;
    canvas.drawCircle(center, r2, paint2);

    // Radiating golden sparkle circles
    if (progress > 0.4) {
      final sparkleProgress = (progress - 0.4) / 0.6;
      final sparklePaint = Paint()
        ..color = const Color(0xFFFFD54F).withOpacity((1.0 - sparkleProgress).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      
      final double sparkleRadius = 50 + sparkleProgress * 30;
      for (int i = 0; i < 8; i++) {
        final double angle = i * math.pi / 4;
        final sparklePos = Offset(
          center.dx + sparkleRadius * math.cos(angle),
          center.dy + sparkleRadius * math.sin(angle),
        );
        canvas.drawCircle(sparklePos, 4 * (1.0 - sparkleProgress), sparklePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SuccessRingRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
