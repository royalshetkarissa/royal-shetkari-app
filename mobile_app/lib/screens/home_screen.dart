import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/auth_provider.dart';
import '../widgets/animated_button.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/api_service.dart';
import 'profile_screen.dart';
import 'community_screen.dart';
import 'market_screen.dart';
import 'book_call_screen.dart';
import 'timetable_screen.dart';
import 'notification_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'dart:async';
import '../models/post_model.dart';
import 'post_detail_screen.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.exit_to_app, color: Color(0xFF1B5E20)),
              SizedBox(width: 12),
              Text(
                'बाहेर पडा / Exit?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: const Text(
            'तुम्हाला रॉयल शेतकरी ॲप बंद करायचे आहे का?\nDo you want to exit the application?',
            style: TextStyle(fontSize: 13, height: 1.4, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('नाही / NO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('होय / YES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ) ?? false;
      return quit;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: [
          DashboardScreen(onTabChange: (i) => setState(() => _currentIndex = i)),
          const CommunityScreen(),
          const MarketScreen(),
          ProfileScreen(onBackToHome: () => setState(() => _currentIndex = 0)),
        ][_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF2E7D32),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Community'),
            BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
  int _activeShopIndex = 0;
  PageController? _shopPageController;
  Timer? _shopSliderTimer;

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
    super.dispose();
  }

  void _logImpressionsSession() {
    if (_cardActiveStartTime == null || _currentActiveType == null || _currentActiveId == null) return;
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
      _startImpressionsSession('animal_post', _recentAnimalPosts.first.id.toString());
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
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code';
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
      reasonsEn.add("Temp is too high (>30°C). Spray may evaporate or burn crop.");
      reasonsMr.add("तापमान खूप जास्त आहे (>३०°C). औषध हवेत उडून जाऊ शकते किंवा पिकाचे नुकसान होऊ शकते.");
    } else if (_temperature < 15) {
      reasonsEn.add("Temp is too low (<15°C). Crop won't absorb chemical effectively.");
      reasonsMr.add("तापमान खूप कमी आहे (<१५°C). पीक औषध योग्य रीतीने शोषून घेणार नाही.");
    }

    if (_windSpeed > 15) {
      reasonsEn.add("Wind is too strong (>15 km/h). High risk of spray drift.");
      reasonsMr.add("वारा खूप वेगाने वाहत आहे (>१५ किमी/तास). औषध उडून जाण्याचा मोठा धोका आहे.");
    } else if (_windSpeed < 3) {
      reasonsEn.add("Wind is too calm (<3 km/h). Risk of temperature inversion drift.");
      reasonsMr.add("वारा अत्यंत मंद आहे (<३ किमी/तास). हवेत औषध एकाच जागी तरंगत राहण्याचा धोका आहे.");
    }

    if (_humidity < 40) {
      reasonsEn.add("Humidity is too low (<40%). Droplets dry out too quickly.");
      reasonsMr.add("हवेतील आर्द्रता कमी आहे (<४०%). औषधाचे थेंब लगेच सुकतील.");
    }

    if (weatherCode >= 50) {
      reasonsEn.add("Rain or precipitation detected. Spray will wash off.");
      reasonsMr.add("पाऊस पडत आहे. औषध वाहून जाईल.");
    }

    if (reasonsEn.isEmpty) {
      _isGoodForSpray = true;
      _sprayRecommendationEn = "Optimal conditions! Safe and highly effective to spray now.";
      _sprayRecommendationMr = "हवामान अनुकूल आहे! फवारणीसाठी ही उत्तम वेळ आहे.";
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
        final parsed = postsData.map((json) => PostModel.fromJson(json)).toList();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scanning image...')));
      try {
        final result = await _api.scanCropDisease(pickedFile.path);
        _showDiseaseResult(result);
        _fetchData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDiseaseResult(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Result', style: TextStyle(color: Colors.green)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disease: ${result['disease_name'] ?? result['diseaseName']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            const Text('Chemical Solution:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result['chemical_solution'] ?? result['chemicalSolution'] ?? 'N/A'),
            const SizedBox(height: 8),
            const Text('Organic Solution:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(result['organic_solution'] ?? result['organicSolution'] ?? 'N/A'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _deleteHistory(int id) async {
    try {
      await _api.deleteDiseaseHistory(id);
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Royal Shetkari'),
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const NotificationScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeOutQuart;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoadingData ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                       user?['full_name']?[0] ?? 'F',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${user?['full_name'] ?? 'Farmer'}!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(user?['village'] ?? 'Your Village', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade900,
                      Colors.blue.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Today\'s Weather / आजचे हवामान',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${_getWeatherEmoji(_weatherCode)} $_temperature°C',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _condition,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _getWeatherIconData(_weatherCode),
                            size: 64,
                            color: Colors.yellow.shade400,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildWeatherMetric('Wind / वारा', '${_windSpeed.toStringAsFixed(1)} km/h', Icons.air),
                          _buildWeatherMetric('Humidity / आर्द्रता', '${_humidity.toStringAsFixed(0)}%', Icons.water_drop),
                          _buildWeatherMetric('Rain / पाऊस', _weatherCode >= 50 ? 'Yes' : 'No', Icons.cloudy_snowing),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _isGoodForSpray
                            ? Colors.green.shade900.withOpacity(0.85)
                            : Colors.red.shade900.withOpacity(0.85),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isGoodForSpray ? Icons.check_circle : Icons.warning,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _isGoodForSpray
                                      ? 'फवारणीसाठी योग्य / Good for Spraying'
                                      : 'फवारणीसाठी अयोग्य / Not Recommended for Spraying',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _sprayRecommendationMr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sprayRecommendationEn,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BookCallScreen())),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.call, color: Color(0xFF2E7D32))),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Book Call with Expert', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Get professional help for your farm', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _scanDisease,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00B4DB), Color(0xFF0083B0)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(radius: 25, backgroundColor: Colors.white, child: Icon(Icons.document_scanner, color: Color(0xFF0083B0))),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Scan Crop Disease', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text('Upload image & get instant solutions', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.camera_alt, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_dailyTasks.isNotEmpty) ...[
                const Text('Tasks for Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(12), color: Colors.orange.shade50),
                  child: Column(
                    children: _dailyTasks.map((taskGroup) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${taskGroup['cropName']} (Day ${taskGroup['dayOffset']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ...List.from(taskGroup['tasks']).map((t) => ListTile(
                            leading: const Icon(Icons.check_circle_outline, color: Colors.orange),
                            title: Text(t['task_description']),
                            subtitle: Text('Organic: ${t['organic_product']}'),
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
                const Text('Your Scanned Crops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                              title: const Text('Delete?'),
                              content: const Text('Remove this scan from history?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
                                TextButton(onPressed: () { Navigator.pop(c); _deleteHistory(item['id']); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            )
                          );
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: CachedNetworkImage(
                                    imageUrl: _api.getImageUrl(item['image_url']),
                                    fit: BoxFit.cover,
                                    errorWidget: (c, u, e) => const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.white,
                                child: Text(item['disease_name'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
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
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildQuickActionCard(icon: Icons.post_add, title: 'New Post', color: const Color(0xFF42A5F5), onTap: () => Navigator.pushNamed(context, '/create-post'))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickActionCard(icon: Icons.storefront, title: 'Shops', color: Colors.deepOrange, onTap: () => widget.onTabChange?.call(2))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickActionCard(icon: Icons.calendar_month, title: 'Timetables', color: Colors.purple, onTap: () async {
                    final result = await Navigator.push(context, MaterialPageRoute(builder: (c) => const TimetableScreen()));
                    if (result == true) _fetchData();
                  })),
                ],
              ),
              const SizedBox(height: 20),
              _buildDynamicRecentSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicRecentSection() {
    if (_recentAnimalPosts.isNotEmpty) {
      final post = _recentAnimalPosts.first;
      
      final timeDifference = DateTime.now().difference(post.createdAt);
      final String timeAgo = timeDifference.inHours > 0 
          ? '${timeDifference.inHours} hrs ago' 
          : '${timeDifference.inMinutes} mins ago';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Animal Post / नवीन पशू', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.pets, size: 12, color: Colors.amber.shade800),
                    const SizedBox(width: 4),
                    Text('24H LATEST', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
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
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
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
                          ? CachedNetworkImage(imageUrl: post.imageUrl!, fit: BoxFit.cover, errorWidget: (c, u, e) => const Icon(Icons.pets, color: Colors.grey))
                          : const Icon(Icons.pets, size: 40, color: Colors.grey),
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
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                ),
                                Text(timeAgo, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              post.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                            ),
                            const SizedBox(height: 6),
                            if (post.price != null)
                              Text(
                                '₹${post.price.toString()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
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
              const Text('Nearby Fertilizer Shops / खत दुकाने', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.stars, size: 12, color: Colors.green.shade800),
                    const SizedBox(width: 4),
                    Text('ACTIVE NOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _shopPageController ??= PageController(initialPage: _activeShopIndex),
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
                      gradient: LinearGradient(colors: [Colors.green.shade800, Colors.teal.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.storefront, color: Colors.white, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop['name'] ?? 'Fertilizer Shop',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          shop['location_name'] ?? 'Nearby location',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                              'Shop #${index + 1} of ${_shops.length}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: const [
                                Text('VIEW ON MAP', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: Colors.amber, size: 14),
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
                  color: _activeShopIndex == index ? Colors.green.shade800 : Colors.grey.shade300,
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
              const Text('Royal Organic Banners / रॉयल सेंद्रिय खते', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: Row(
                  children: [
                    Icon(Icons.percent, size: 12, color: Colors.orange.shade800),
                    const SizedBox(width: 4),
                    Text('10% OFF NOW', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
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
                gradient: LinearGradient(colors: [Colors.orange.shade800, Colors.deepOrange.shade900], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          'RECOMMENDED BY ROYAL SHETKARI',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                        ),
                      ),
                      const Icon(Icons.verified, color: Colors.white, size: 24),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Soil Amrit (सॉईल अमृत) - Super Booster',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contains pristine Humic acid & Seaweed extract. Boosts cotton, wheat, and sugarcane yield by 45% naturally! Free shipping pan-Maharashtra.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.phone_in_talk, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'FREE EXPERT CONSULTATION',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.amberAccent, borderRadius: BorderRadius.circular(12)),
                        child: const Text(
                          'BOOK CALL',
                          style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildWeatherMetric(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
