import 'package:flutter/material.dart';
import 'package:royal_shetkari/widgets/shimmer_skeleton.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/animated_button.dart';
import '../localization/app_localizations.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import 'market_screen.dart';
import 'book_call_screen.dart';
import 'timetable_screen.dart';
import 'organic_tips_screen.dart';
import 'notification_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../models/post_model.dart';
import 'post_detail_screen.dart';
import 'package:intl/intl.dart';
import '../models/shop_model.dart';
import 'shop_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CommunityScreen(),
    const MarketScreen(),
    const ProfileScreen(),
  ];

  Future<bool> _onWillPop() async {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return false;
    } else {
      final bool quit = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.exit_to_app, color: Color(0xFF1B5E20)),
                  const SizedBox(width: 12),
                  Text(
                    context.translate('exit_title'),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              content: Text(
                context.translate('exit_msg'),
                style: const TextStyle(
                    fontSize: 13, height: 1.4, color: Colors.black87),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: Text(context.translate('no').toUpperCase(),
                      style: const TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(c, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.translate('yes').toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ) ??
          false;
      return quit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: [
          DashboardScreen(
              onTabChange: (i) => setState(() => _currentIndex = i)),
          CommunityScreen(
              onBackToHome: () => setState(() => _currentIndex = 0)),
          MarketScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
          ProfileScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
        ][_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home), label: context.translate('home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                label: context.translate('community')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.store),
                label: context.translate('market')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: context.translate('profile')),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const DashboardScreen({super.key, this.onTabChange});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _weather = 'Loading...';
  int _temperature = 0;
  String _condition = 'Loading...';
  int _weatherCode = 0;
  double _humidity = 0.0;
  double _windSpeed = 0.0;
  bool _isGoodForSpray = false;
  String _sprayRecommendationEn = '';
  String _sprayRecommendationMr = '';
  List<Map<String, dynamic>> _dailyTasks = [];
  List<Map<String, dynamic>> _diseaseHistory = [];
  bool _isLoadingData = false;
  final ApiService _api = ApiService();

  // Dynamic Dashboard and Slider variables
  List<PostModel> _recentAnimalPosts = [];
  List<Map<String, dynamic>> _shops = [];
  Map<String, dynamic>? _featuredShop;
  int _activeShopIndex = 0;
  PageController? _shopPageController;
  Timer? _shopSliderTimer;

  List<Map<String, dynamic>> _orderedShops = [];
  PageController? _featuredPageController;
  Timer? _featuredSliderTimer;
  int _activeFeaturedIndex = 0;

  // Analytics logging variables
  DateTime? _cardActiveStartTime;
  String? _currentActiveType;
  String? _currentActiveId;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _logImpressionsSession();
    _shopPageController?.dispose();
    _shopSliderTimer?.cancel();
    _featuredPageController?.dispose();
    _featuredSliderTimer?.cancel();
    super.dispose();
  }

  void _logImpressionsSession() {
    if (_cardActiveStartTime == null ||
        _currentActiveType == null ||
        _currentActiveId == null) return;
    final now = DateTime.now();
    final duration = now.difference(_cardActiveStartTime!).inSeconds;
    if (duration > 0) {
      _api.trackImpression(
        activeType: _currentActiveType!,
        activeId: _currentActiveId!,
        startTime: _cardActiveStartTime!,
        endTime: now,
        durationSeconds: duration,
      );
    }
  }

  void _startImpressionsSession(String type, String id) {
    _logImpressionsSession();
    _cardActiveStartTime = DateTime.now();
    _currentActiveType = type;
    _currentActiveId = id;
  }

  void _updateActiveDashboardCardSession() {
    if (!mounted) return;
    if (_recentAnimalPosts.isNotEmpty) {
      _startImpressionsSession(
          'animal_post', _recentAnimalPosts.first.id.toString());
    } else if (_shops.isNotEmpty) {
      final activeShop = _shops[_activeShopIndex];
      _startImpressionsSession('shop', activeShop['id'].toString());
      _setupShopSliderAutoScroll();
    } else {
      _startImpressionsSession('organic_ad', 'organic_ad_banner_1');
    }
  }

  void _setupShopSliderAutoScroll() {
    _shopSliderTimer?.cancel();
    if (_shops.length <= 1) return;

    _shopPageController ??= PageController(initialPage: _activeShopIndex);
    _shopSliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_shops.isEmpty) return;

      int nextIndex = (_activeShopIndex + 1) % _shops.length;
      setState(() {
        _activeShopIndex = nextIndex;
      });

      _shopPageController?.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );

      final activeShop = _shops[nextIndex];
      _startImpressionsSession('shop', activeShop['id'].toString());
    });
  }

  Future<Position?> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final dio = Dio();
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code';
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final current = response.data['current'];
        if (current != null) {
          _temperature = (current['temperature_2m'] as num).round();
          _humidity = (current['relative_humidity_2m'] as num).toDouble();
          _windSpeed = (current['wind_speed_10m'] as num).toDouble();
          _weatherCode = (current['weather_code'] as num).toInt();
          _condition = _getWeatherConditionText(_weatherCode);
          _weather = '${_getWeatherEmoji(_weatherCode)} $_condition';
          _calculateSpraySuitability(_weatherCode);
        }
      }
    } catch (e) {
      debugPrint('Error fetching live weather: $e');
      _temperature = 32;
      _humidity = 45;
      _windSpeed = 12.0;
      _weatherCode = 3;
      _condition = 'Sunny (Default)';
      _weather = '🌤️ Sunny (Default)';
      _calculateSpraySuitability(3);
    }
  }

  void _calculateSpraySuitability(int weatherCode) {
    List<String> reasonsEn = [];
    List<String> reasonsMr = [];

    if (_temperature > 30) {
      reasonsEn
          .add("Temp is too high (>30°C). Spray may evaporate or burn crop.");
      reasonsMr.add(
          "तापमान खूप जास्त आहे (>३०°C). औषध हवेत उडून जाऊ शकते किंवा पिकाचे नुकसान होऊ शकते.");
    } else if (_temperature < 15) {
      reasonsEn.add(
          "Temp is too low (<15°C). Crop won't absorb chemical effectively.");
      reasonsMr.add(
          "तापमान खूप कमी आहे (<१५°C). पीक औषध योग्य रीतीने शोषून घेणार नाही.");
    }

    if (_windSpeed > 15) {
      reasonsEn.add("Wind is too strong (>15 km/h). High risk of spray drift.");
      reasonsMr.add(
          "वारा खूप वेगाने वाहत आहे (>१५ किमी/तास). औषध उडून जाण्याचा मोठा धोका आहे.");
    } else if (_windSpeed < 3) {
      reasonsEn.add(
          "Wind is too calm (<3 km/h). Risk of temperature inversion drift.");
      reasonsMr.add(
          "वारा अत्यंत मंद आहे (<३ किमी/तास). हवेत औषध एकाच जागी तरंगत राहण्याचा धोका आहे.");
    }

    if (_humidity < 40) {
      reasonsEn
          .add("Humidity is too low (<40%). Droplets dry out too quickly.");
      reasonsMr.add("हवेतील आर्द्रता कमी आहे (<४०%). औषधाचे थेंब लगेच सुकतील.");
    }

    if (weatherCode >= 50) {
      reasonsEn.add("Rain or precipitation detected. Spray will wash off.");
      reasonsMr.add("पाऊस पडत आहे. औषध वाहून जाईल.");
    }

    if (reasonsEn.isEmpty) {
      _isGoodForSpray = true;
      _sprayRecommendationEn =
          "Optimal conditions! Safe and highly effective to spray now.";
      _sprayRecommendationMr =
          "हवामान अनुकूल आहे! फवारणीसाठी ही उत्तम वेळ आहे.";
    } else {
      _isGoodForSpray = false;
      _sprayRecommendationEn = reasonsEn.join("\n");
      _sprayRecommendationMr = reasonsMr.join("\n");
    }
  }

  String _getWeatherConditionText(int code) {
    if (code == 0) return 'Clear Sky';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code == 45 || code == 48) return 'Foggy';
    if (code >= 51 && code <= 55) return 'Drizzle';
    if (code >= 61 && code <= 65) return 'Rainy';
    if (code >= 71 && code <= 77) return 'Snowy';
    if (code >= 80 && code <= 82) return 'Rain Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Cloudy';
  }

  String _getWeatherEmoji(int code) {
    if (code == 0) return '☀️';
    if (code >= 1 && code <= 3) return '🌤️';
    if (code == 45 || code == 48) return '🌫️';
    if (code >= 51 && code <= 55) return '🌦️';
    if (code >= 61 && code <= 65) return '🌧️';
    if (code >= 71 && code <= 77) return '❄️';
    if (code >= 80 && code <= 82) return '🌧️';
    if (code >= 95 && code <= 99) return '⛈️';
    return '☁️';
  }

  IconData _getWeatherIconData(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy_outlined;
    if (code == 45 || code == 48) return Icons.dehaze;
    if (code >= 51 && code <= 55) return Icons.umbrella_outlined;
    if (code >= 61 && code <= 65) return Icons.beach_access;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.cloudy_snowing;
    if (code >= 95 && code <= 99) return Icons.thunderstorm;
    return Icons.cloud;
  }

  Future<void> _fetchData() async {
    setState(() => _isLoadingData = true);
    try {
      double lat = 18.5204;
      double lon = 73.8567;

      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final user = auth.user;

        Position? position = await _determinePosition();
        if (position != null) {
          lat = position.latitude;
          lon = position.longitude;
        } else if (user != null) {
          if (user['latitude'] != null && user['longitude'] != null) {
            lat = double.tryParse(user['latitude'].toString()) ?? 18.5204;
            lon = double.tryParse(user['longitude'].toString()) ?? 73.8567;
          }
        }
      } catch (locErr) {
        debugPrint('Location determination error: $locErr');
      }

      await _fetchWeather(lat, lon);

      _dailyTasks = await _api.getDailyTasks();
      _diseaseHistory = await _api.getDiseaseHistory();

      // Fetch dynamic dashboard content
      try {
        final now = DateTime.now();
        final postsData = await _api.getPosts(category: 'animals');
        final parsed =
            postsData.map((json) => PostModel.fromJson(json)).toList();
        _recentAnimalPosts = parsed.where((post) {
          return now.difference(post.createdAt).inHours < 24;
        }).toList();
      } catch (postErr) {
        debugPrint('Error fetching animal posts: $postErr');
        _recentAnimalPosts = [];
      }

      try {
        _shops = await _api.getNearbyShops(lat, lon);
      } catch (shopErr) {
        debugPrint('Error fetching dynamic shops: $shopErr');
        _shops = [];
      }

      try {
        _featuredShop = await _api.getFeaturedShop();
      } catch (fErr) {
        debugPrint('Error fetching featured shop: $fErr');
        _featuredShop = null;
      }

      _orderedShops = [];
      if (_shops.isNotEmpty) {
        final List<Map<String, dynamic>> sorted = List<Map<String, dynamic>>.from(_shops);
        final featuredId = _featuredShop != null ? _featuredShop!['id'] : null;
        final nowTime = DateTime.now();

        sorted.sort((a, b) {
          if (a['id'] == featuredId) return -1;
          if (b['id'] == featuredId) return 1;

          final aIsNew = a['is_new_arrival'] == true ||
              (a['created_at'] != null && nowTime.difference(DateTime.parse(a['created_at'].toString())).inHours < 24);
          final bIsNew = b['is_new_arrival'] == true ||
              (b['created_at'] != null && nowTime.difference(DateTime.parse(b['created_at'].toString())).inHours < 24);
          
          if (aIsNew && !bIsNew) return -1;
          if (!aIsNew && bIsNew) return 1;

          return 0;
        });
        _orderedShops = sorted;
      }

      _featuredPageController?.dispose();
      _featuredPageController = PageController(initialPage: 0);
      _activeFeaturedIndex = 0;
      
      _featuredSliderTimer?.cancel();
      if (_orderedShops.length > 1) {
        _featuredSliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
          if (!mounted) return;
          if (_featuredPageController != null && _featuredPageController!.hasClients) {
            int nextPage = _activeFeaturedIndex + 1;
            if (nextPage >= _orderedShops.length) {
              nextPage = 0;
            }
            _featuredPageController!.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOutCubic,
            );
          }
        });
      }

      _updateActiveDashboardCardSession();
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _scanDisease() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${context.translate('scan_crop_disease')}...')));
      try {
        final result = await _api.scanCropDisease(pickedFile.path);
        _showDiseaseResult(result);
        _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDiseaseResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('scan_crop_disease'),
            style: const TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${context.translate('topic')}: ${result['disease_name'] ?? result['diseaseName']}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            Text('${context.translate('chemical')}:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(result['chemical_solution'] ??
                result['chemicalSolution'] ??
                'N/A'),
            const SizedBox(height: 8),
            Text('${context.translate('organic')}:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(result['organic_solution'] ??
                result['organicSolution'] ??
                'N/A'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.translate('ok'))),
        ],
      ),
    );
  }

  Future<void> _deleteHistory(int id) async {
    try {
      await _api.deleteDiseaseHistory(id);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 38,
          fit: BoxFit.contain,
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const NotificationScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutQuart;
                    var tween = Tween(begin: begin, end: end)
                        .chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoadingData
            ? ShimmerSkeleton()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            child: Text(
                              user?['full_name']?[0] ?? 'F',
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${context.translate('welcome_only')}, ${user?['full_name'] ?? 'Farmer'}!',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                const SizedBox(height: 4),
                                Text(
                                    user?['village'] ??
                                        context.translate('your_village'),
                                    style:
                                        const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Row of Menu items: Time table, Organic Fertilizer, Fertilizer Calculator
                    Row(
                      children: [
                        Expanded(
                          child: _buildTopMenuButton(
                            icon: Icons.calendar_month,
                            label: context.translate('timetable'),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => const TimetableScreen()),
                              );
                              if (result == true) _fetchData();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTopMenuButton(
                            icon: Icons.spa,
                            label: context.translate('organic_fertilizer'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (c) => const OrganicTipsScreen()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTopMenuButton(
                            icon: Icons.calculate,
                            label: context.translate('fertilizer_calculator'),
                            onTap: _showFertilizerCalculator,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Community Card (Cow cartoon and vegetable/crop photos)
                    GestureDetector(
                      onTap: () => widget.onTabChange?.call(1),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  context.translate('community'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                Icon(Icons.arrow_forward,
                                    color: Colors.black87),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      'https://img.freepik.com/free-vector/cute-cow-cartoon-vector-illustration_138676-2009.jpg',
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        height: 80,
                                        color: Colors.amber.shade100,
                                        child: const Icon(Icons.pets,
                                            color: Colors.amber),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      'https://images.unsplash.com/photo-1566385278603-605b637d3ab4?w=500',
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        height: 80,
                                        color: Colors.green.shade100,
                                        child: const Icon(Icons.grass,
                                            color: Colors.green),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      'https://images.unsplash.com/photo-1595855759920-86582396756a?w=500',
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(
                                        height: 80,
                                        color: Colors.red.shade100,
                                        child: const Icon(Icons.eco,
                                            color: Colors.red),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Weather Card (light blue with sun peeking cloud in middle)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: _getWeatherGradient(_weatherCode),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location & Date
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    user?['village'] ?? 'Pune',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                DateFormat('EEEE, d MMM')
                                    .format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Temp & Condition & Weather Art
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$_temperature',
                                          style: const TextStyle(
                                            fontSize: 58,
                                            fontWeight: FontWeight.w300,
                                            color: Colors.white,
                                            height: 1.0,
                                          ),
                                        ),
                                        const Text(
                                          '°C',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _condition,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${context.translate('feels_like')} ${_temperature - 1}°C • ${_temperature - 2}°C / ${_temperature + 3}°C',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Weather Icon/Illustration
                              _buildWeatherIllustration(_weatherCode),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Divider(
                              color: Colors.white.withOpacity(0.24), height: 1),
                          const SizedBox(height: 16),
                          // Row of details (Humidity, Wind Speed, Spray Suitability)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildWeatherDetailItem(
                                icon: Icons.water_drop_outlined,
                                label: context.translate('humidity'),
                                value: '${_humidity.round()}%',
                                bgColor: Colors.white.withOpacity(0.15),
                                textColor: Colors.white,
                                subTextColor: Colors.white.withOpacity(0.85),
                              ),
                              _buildWeatherDetailItem(
                                icon: Icons.air,
                                label: context.translate('wind_speed'),
                                value: '${_windSpeed.toStringAsFixed(1)} km/h',
                                bgColor: Colors.white.withOpacity(0.15),
                                textColor: Colors.white,
                                subTextColor: Colors.white.withOpacity(0.85),
                              ),
                              _buildWeatherDetailItem(
                                icon: _isGoodForSpray
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_outlined,
                                label: context.translate('spraying'),
                                value: _isGoodForSpray
                                    ? context.translate('favourable')
                                    : context.translate('unfavourable'),
                                bgColor: _isGoodForSpray
                                    ? Colors.greenAccent.withOpacity(0.2)
                                    : Colors.redAccent.withOpacity(0.2),
                                textColor: Colors.white,
                                subTextColor: Colors.white.withOpacity(0.85),
                                isHighlight: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Book Call with Expert
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const BookCallScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                child:
                                    Icon(Icons.call, color: Color(0xFF2E7D32))),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.translate('book_call_expert'),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text(
                                      context
                                          .translate('get_professional_help'),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Disease Prediction Model (Scan Crop Disease)
                    GestureDetector(
                      onTap: _scanDisease,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blue.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5))
                          ],
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                                radius: 25,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.document_scanner,
                                    color: Color(0xFF0083B0))),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(context.translate('scan_crop_disease'),
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                  Text(
                                      context.translate('upload_get_solutions'),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.camera_alt, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildFeaturedShopMarquee(),
                    if (_dailyTasks.isNotEmpty) ...[
                      Text(context.translate('tasks_today'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange.shade200),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.orange.shade50),
                        child: Column(
                          children: _dailyTasks.map((taskGroup) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${taskGroup['cropName']} (Day ${taskGroup['dayOffset']})',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange)),
                                ...List.from(taskGroup['tasks'])
                                    .map((t) => ListTile(
                                          leading: const Icon(
                                              Icons.check_circle_outline,
                                              color: Colors.orange),
                                          title: Text(t['task_description']),
                                          subtitle: Text(
                                              '${context.translate('organic')}: ${t['organic_product']}'),
                                          contentPadding: EdgeInsets.zero,
                                        )),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_diseaseHistory.isNotEmpty) ...[
                      Text(context.translate('scanned_crops'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _diseaseHistory.length,
                          itemBuilder: (context, index) {
                            final item = _diseaseHistory[index];
                            return GestureDetector(
                              onTap: () => _showDiseaseResult(item),
                              onLongPress: () {
                                showDialog(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                          title:
                                              Text(context.translate('delete')),
                                          content: Text(context.translate(
                                              'delete_scan_history')),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(c),
                                                child: Text(context
                                                    .translate('cancel'))),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(c);
                                                  _deleteHistory(item['id']);
                                                },
                                                child: Text(
                                                    context.translate('delete'),
                                                    style: const TextStyle(
                                                        color: Colors.red))),
                                          ],
                                        ));
                              },
                              child: Container(
                                width: 120,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: Colors.grey.shade300)),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(12)),
                                        child: CachedNetworkImage(
                                          imageUrl: _api
                                              .getImageUrl(item['image_url']),
                                          fit: BoxFit.cover,
                                          errorWidget: (c, u, e) => const Icon(
                                              Icons.image_not_supported),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      color: Colors.white,
                                      child: Text(item['disease_name'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildDynamicRecentSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildDynamicRecentSection() {
    if (_recentAnimalPosts.isNotEmpty) {
      final post = _recentAnimalPosts.first;

      final timeDifference = DateTime.now().difference(post.createdAt);
      final String timeAgo = timeDifference.inHours > 0
          ? '${timeDifference.inHours} ${context.translate('hours_ago')}'
          : '${timeDifference.inMinutes} ${context.translate('mins_ago')}';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.translate('recent_animal_post'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.pets, size: 12, color: Colors.amber.shade800),
                    const SizedBox(width: 4),
                    Text(context.translate('latest_24h'),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              _logImpressionsSession();
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => PostDetailScreen(post: post)),
              );
              _startImpressionsSession('animal_post', post.id.toString());
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade100, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey.shade100,
                      child: post.imageUrl != null && post.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: post.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.pets, color: Colors.grey))
                          : const Icon(Icons.pets,
                              size: 40, color: Colors.grey),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  post.animalType?.toUpperCase() ?? 'ANIMAL',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900),
                                ),
                                Text(timeAgo,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            if (post.price != null)
                              Text(
                                '₹${post.price.toString()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.green),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    } else if (_shops.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.translate('nearby_shops'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.stars, size: 12, color: Colors.green.shade800),
                    const SizedBox(width: 4),
                    Text(context.translate('active_now'),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _shopPageController ??=
                  PageController(initialPage: _activeShopIndex),
              onPageChanged: (index) {
                _shopPageController = PageController(initialPage: index);
                setState(() {
                  _activeShopIndex = index;
                });
                final activeShop = _shops[index];
                _startImpressionsSession('shop', activeShop['id'].toString());
              },
              itemCount: _shops.length,
              itemBuilder: (context, index) {
                final shop = _shops[index];
                return GestureDetector(
                  onTap: () {
                    _logImpressionsSession();
                    widget.onTabChange?.call(2);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Colors.green.shade800, Colors.teal.shade900],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront,
                                color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop['name'] ?? 'Fertilizer Shop',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          shop['location_name'] ??
                                              'Nearby location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${context.translate('market')} #${index + 1} / ${_shops.length}',
                              style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                Text(context.translate('view_on_map'),
                                    style: const TextStyle(
                                        color: Colors.amber,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward,
                                    color: Colors.amber, size: 14),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_shops.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _activeShopIndex == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _activeShopIndex == index
                      ? Colors.green.shade800
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.translate('organic_banners'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.percent,
                        size: 12, color: Colors.orange.shade800),
                    const SizedBox(width: 4),
                    Text(context.translate('off_10'),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              _logImpressionsSession();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const BookCallScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.orange.shade800,
                  Colors.deepOrange.shade900
                ], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          context.translate('recommended_by_royal'),
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900),
                        ),
                      ),
                      const Icon(Icons.verified, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.translate('soil_amrit'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.translate('soil_amrit_desc'),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.phone_in_talk,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            context.translate('free_expert_consultation'),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: Colors.amberAccent,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          context.translate('book_call'),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  LinearGradient _getWeatherGradient(int code) {
    if (code == 0) {
      // Clear sky
      return const LinearGradient(
        colors: [Color(0xFF1E88E5), Color(0xFF4FC3F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (code >= 1 && code <= 3) {
      // Partly Cloudy
      return const LinearGradient(
        colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (code >= 51 && code <= 65 || code >= 80 && code <= 82) {
      // Rainy
      return const LinearGradient(
        colors: [Color(0xFF263238), Color(0xFF4F5B66)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (code >= 95 && code <= 99) {
      // Thunderstorm
      return const LinearGradient(
        colors: [Color(0xFF1A237E), Color(0xFF283593)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Cloudy/Fog/Other
      return const LinearGradient(
        colors: [Color(0xFF546E7A), Color(0xFF78909C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  Widget _buildWeatherIllustration(int code) {
    if (code == 0) {
      // Sunny
      return Container(
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
          color: Colors.yellow,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent,
              blurRadius: 25,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.wb_sunny, size: 48, color: Colors.orange),
      );
    } else if (code >= 1 && code <= 3) {
      // Partly Cloudy (Sun peeking behind cloud)
      return SizedBox(
        width: 90,
        height: 80,
        child: Stack(
          children: [
            Positioned(
              top: 5,
              right: 15,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent,
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 5,
              left: 5,
              child: Icon(
                Icons.cloud,
                size: 65,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ],
        ),
      );
    } else if (code >= 51 && code <= 65 || code >= 80 && code <= 82) {
      // Rainy
      return SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 5,
              child: Icon(
                Icons.cloud,
                size: 60,
                color: Colors.white,
              ),
            ),
            Positioned(
              bottom: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.opacity, size: 16, color: Colors.blueAccent),
                  SizedBox(width: 4),
                  Icon(Icons.opacity, size: 16, color: Colors.blueAccent),
                  SizedBox(width: 4),
                  Icon(Icons.opacity, size: 16, color: Colors.blueAccent),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (code >= 95 && code <= 99) {
      // Thunderstorm
      return SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 5,
              child: Icon(
                Icons.thunderstorm,
                size: 60,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    } else {
      // General Cloudy / Foggy
      return SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.cloud,
              size: 65,
              color: Colors.white.withOpacity(0.85),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildWeatherDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
    required Color subTextColor,
    bool isHighlight = false,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: textColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: subTextColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isHighlight
                    ? (value == 'Favourable'
                        ? Colors.greenAccent.shade400
                        : Colors.redAccent.shade100)
                    : textColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showFertilizerCalculator() {
    double guntha = 1.0;
    final controller = TextEditingController(text: '1.0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final double dapRequired = guntha * 1.25;
            final double bagsRequired = dapRequired / 50.0;
            final double nitrogen = dapRequired * 0.18;
            final double phosphorus = dapRequired * 0.46;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.calculate,
                              color: Colors.green.shade800, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.translate('fertilizer_calculator'),
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                              Text(
                                context.translate('dap_required'),
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Text(
                      context.translate('farm_size_guntha'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              hintText: context.translate('enter_guntha'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15)),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              prefixIcon: const Icon(Icons.grid_on,
                                  color: Colors.green),
                              suffixText: context.translate('guntha'),
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                guntha = double.tryParse(val) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Slider(
                      value: guntha.clamp(0.0, 100.0),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      activeColor: Colors.green.shade700,
                      inactiveColor: Colors.green.shade100,
                      label:
                          '${guntha.toStringAsFixed(1)} ${context.translate('guntha')}',
                      onChanged: (val) {
                        setModalState(() {
                          guntha = val;
                          controller.text = guntha.toStringAsFixed(1);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // DAP Requirement Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade800,
                            Colors.green.shade500
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                context.translate('dap_required').toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1),
                              ),
                              Icon(Icons.shopping_bag,
                                  color: Colors.white.withOpacity(0.8)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${dapRequired.toStringAsFixed(2)} kg',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '~ ${bagsRequired.toStringAsFixed(2)} ${context.translate('bags_unit')}',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '${context.translate('nutrient_breakdown')}:',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    _buildNutrientRow(context.translate('nitrogen_label'),
                        nitrogen, 0.18, Colors.blue),
                    const SizedBox(height: 12),
                    _buildNutrientRow(context.translate('phosphorus_label'),
                        phosphorus, 0.46, Colors.orange),
                    const SizedBox(height: 24),
                    // Tips
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber.shade800, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              context.translate('fertilizer_tip'),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNutrientRow(
      String label, double value, double pct, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${value.toStringAsFixed(2)} kg',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: pct,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildFeaturedShopMarquee() {
    if (_orderedShops.isEmpty) {
      const gradient = LinearGradient(
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrganicTipsScreen(),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                ),
                child: const Text(
                  "सेंद्रिय",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "🌱 सेंद्रिय शेती प्रोत्साहन (Organic Farming): ",
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const SizedBox(
                      height: 20,
                      child: MarqueeText(
                        text: "सेंद्रिय शेती संवर्धनासाठी सेंद्रिय खतांचा वापर करा व ५% सवलत मिळवा! रासायनिक खते टाळा, माती वाचवा! ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        speed: 60.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 145,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _featuredPageController ??= PageController(initialPage: 0),
              onPageChanged: (index) {
                setState(() {
                  _activeFeaturedIndex = index;
                });
              },
              itemCount: _orderedShops.length,
              itemBuilder: (context, index) {
                final shop = _orderedShops[index];
                final shopId = shop['id'];
                final featuredShopId = _featuredShop != null ? _featuredShop!['shop_id'] : null;
                final isTodayFeatured = shopId == featuredShopId;
                
                final isNewArrival = shop['is_new_arrival'] == true ||
                    (shop['created_at'] != null &&
                        DateTime.now().difference(DateTime.parse(shop['created_at'].toString())).inHours < 24);

                final cardGradient = isTodayFeatured
                    ? const LinearGradient(
                        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : (isNewArrival
                        ? const LinearGradient(
                            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF0D324D), Color(0xFF7F5A83)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ));

                String badgeText = "सक्रिय दुकाने";
                Color badgeColor = Colors.teal.shade700;
                if (isTodayFeatured) {
                  badgeText = "वैशिष्ट्यीकृत 🔥";
                  badgeColor = const Color(0xFFD84315);
                } else if (isNewArrival) {
                  badgeText = "नवीन दुकान ⭐";
                  badgeColor = const Color(0xFF0288D1);
                }

                final double discount = shop['discount_percentage'] != null
                    ? double.parse(shop['discount_percentage'].toString())
                    : 5.0;
                final int coins = shop['redeem_coin_cost'] != null
                    ? int.parse(shop['redeem_coin_cost'].toString())
                    : 50;

                return GestureDetector(
                  onTap: () {
                    final model = ShopModel.fromJson(shop);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShopDetailsScreen(shop: model),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: cardGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.12),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.amber.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: shop['profile_photo'] != null && shop['profile_photo'].toString().isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: shop['profile_photo'],
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey.shade800,
                                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.amber),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey.shade900,
                                      child: const Icon(Icons.store, color: Colors.amber, size: 30),
                                    ),
                                  )
                                : Container(
                                    color: Colors.teal.shade900,
                                    child: const Icon(Icons.store, color: Colors.amber, size: 30),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      shop['city'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.amber.shade200,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                shop['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.discount_outlined, color: Colors.orange.shade300, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$discount% सवलत (Discount)",
                                    style: const TextStyle(
                                      color: Colors.white80,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Icon(Icons.monetization_on, color: Colors.amber.shade400, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$coins नाणी (Coins)",
                                    style: const TextStyle(
                                      color: Colors.white80,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_orderedShops.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_orderedShops.length, (idx) {
                final isSelected = _activeFeaturedIndex == idx;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSelected ? 12 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.amberAccent : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );

  Widget _buildTopMenuButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.blue.shade50, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: Icon(icon, color: Colors.blueGrey.shade800, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double speed;

  const MarqueeText({
    Key? key,
    required this.text,
    required this.style,
    this.speed = 50.0,
  }) : super(key: key);

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScrolling();
    });
  }

  void _startScrolling() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.position.pixels;
        if (maxScroll <= 0) return;
        if (currentScroll >= maxScroll) {
          _scrollController.jumpTo(0.0);
        } else {
          _scrollController.jumpTo(currentScroll + (widget.speed * 0.05));
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          Text(widget.text, style: widget.style),
          SizedBox(width: MediaQuery.of(context).size.width * 0.5),
          Text(widget.text, style: widget.style),
          SizedBox(width: MediaQuery.of(context).size.width * 0.5),
        ],
      ),
    );
  }
}
