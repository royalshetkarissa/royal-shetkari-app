import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:royal_shetkari/widgets/shimmer_skeleton.dart';
import '../services/api_service.dart';
import '../models/shop_model.dart';
import '../widgets/royal_app_bar.dart';
import 'shop_details_screen.dart';
import 'organic_tips_screen.dart';
import '../localization/app_localizations.dart';

class MarketScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  const MarketScreen({super.key, this.onBackToHome});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<ShopModel> _shops = [];
  bool _isLoading = true;
  TabController? _tabController;
  final TextEditingController _cityFilterController = TextEditingController();
  final TextEditingController _pincodeFilterController = TextEditingController();

  final List<Map<String, String>> _tabs = [
    {'key': 'fertilizers', 'labelMr': 'खते व औषधे', 'labelEn': 'Fertilizers'},
    {'key': 'crop', 'labelMr': 'पीक बाजार', 'labelEn': 'Crop Market'},
    {'key': 'equipment_repair', 'labelMr': 'अवजारे दुरुस्ती', 'labelEn': 'Equipment'},
    {'key': 'hardware', 'labelMr': 'हार्डवेअर', 'labelEn': 'Hardware'},
    {'key': 'organic_farming', 'labelMr': 'सेंद्रिय शेती', 'labelEn': 'Organic'},
    {'key': 'animal_doctor', 'labelMr': 'पशुवैद्यकीय डॉक्टर', 'labelEn': 'Animal Doctor'},
    {'key': 'produce_buyer', 'labelMr': 'शेतमाल खरेदीदार', 'labelEn': 'Produce Buyers'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadShops();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _cityFilterController.dispose();
    _pincodeFilterController.dispose();
    super.dispose();
  }

  Future<void> _loadShops() async {
    setState(() => _isLoading = true);
    try {
      double lat = 19.0760; // Default fallback to Maharashtra
      double lng = 72.8777;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {
        // Location failed, use fallback coordinates
      }

      final raw = await _api.getNearbyShops(lat, lng);
      setState(() {
        _shops = raw.map((j) => ShopModel.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<ShopModel> _getShopsForCategory(String categoryKey) {
    // Filter active shops for the specific category
    final categoryShops = _shops.where((s) {
      final statusLower = s.status.toLowerCase();
      if (statusLower == 'deleted' || statusLower == 'inactive') return false;

      // Handle category key matches (flexible mapping)
      return s.categories.any((cat) {
        final catLower = cat.toLowerCase();
        return catLower.contains(categoryKey.toLowerCase()) || 
               categoryKey.toLowerCase().contains(catLower);
      });
    }).toList();

    // Apply city and pincode filters
    final filtered = categoryShops.where((s) {
      final cityText = _cityFilterController.text.trim().toLowerCase();
      final pincodeText = _pincodeFilterController.text.trim();

      if (cityText.isNotEmpty) {
        final shopCity = (s.city ?? '').toLowerCase();
        if (!shopCity.contains(cityText)) return false;
      }

      if (pincodeText.isNotEmpty) {
        final shopPincode = s.pincode ?? '';
        if (!shopPincode.contains(pincodeText)) return false;
      }

      return true;
    }).toList();

    // 🔄 Apply the daily 4-shop cycling schedule
    if (filtered.length <= 4) {
      return filtered;
    }

    final now = DateTime.now();
    final daysSinceEpoch = now.difference(DateTime(2026, 1, 1)).inDays;
    int startIndex = (daysSinceEpoch * 4) % filtered.length;

    List<ShopModel> cyclicList = [];
    for (int i = 0; i < 4; i++) {
      int index = (startIndex + i) % filtered.length;
      cyclicList.add(filtered[index]);
    }
    return cyclicList;
  }

  Widget _buildFilterRow() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cityFilterController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: context.translate('city_taluka'),
                prefixIcon: const Icon(Icons.location_city, size: 18, color: Color(0xFF1B5E20)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _pincodeFilterController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Pincode',
                prefixIcon: const Icon(Icons.pin_drop, size: 18, color: Color(0xFF1B5E20)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.exit_to_app, color: Color(0xFF1B5E20)),
            const SizedBox(width: 12),
            Text(context.translate('quit_title'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          context.translate('quit_msg'),
          style: const TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.translate('no').toUpperCase(), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(context.translate('yes').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();
    return WillPopScope(
      onWillPop: () async {
        if (canPop) {
          return await _onWillPop();
        }
        if (widget.onBackToHome != null) {
          widget.onBackToHome!();
        }
        return false;
      },
      child: Scaffold(
        appBar: RoyalAppBar(
          title: context.translate('market'),
          onBackPressed: () async {
            if (canPop) {
              if (await _onWillPop()) {
                if (mounted) Navigator.of(context).pop();
              }
            } else if (widget.onBackToHome != null) {
              widget.onBackToHome!();
            }
          },
          actions: [
            IconButton(
              key: const Key('btn_refresh_market'),
              onPressed: _loadShops,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh shops',
            ),
          ],
          bottom: TabBar(
            key: const Key('tab_bar_market'),
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3.5,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: _tabs.map((tab) {
              final key = tab['key'] == 'crop' ? 'crop_market' : tab['key']!;
              return Tab(
                key: Key('tab_item_${tab['key']}'),
                child: Text(
                  context.translate(key),
                  style: const TextStyle(fontSize: 12),
                ),
              );
            }).toList(),
          ),
        ),
      body: _isLoading
          ? Center(child: ShimmerSkeleton())
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                final categoryShops = _getShopsForCategory(tab['key']!);
                final isOrganic = tab['key'] == 'organic_farming';

                return RefreshIndicator(
                  onRefresh: _loadShops,
                  color: const Color(0xFF1B5E20),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildFilterRow(),
                      const SizedBox(height: 16),
                      if (isOrganic) ...[
                        _buildOrganicTipsHeader(),
                        const SizedBox(height: 16),
                      ],
                      if (categoryShops.isEmpty)
                        Container(
                          height: 300,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.storefront, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'या विभागात सध्या दुकाने उपलब्ध नाहीत.\nNo shops available in this category.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      else
                        ...categoryShops.map((shop) => _buildShopCard(shop, tab['key']!)),
                    ],
                  ),
                );
              }).toList(),
            ),
      ),
    );
  }

  Widget _buildOrganicTipsHeader() {
    return Container(
      key: const Key('card_organic_tips_guide'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const OrganicTipsScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.menu_book, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'सेंद्रिय शेती टिप्स व पद्धती ( Vermiwash / जीवामृत )',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'कृती आणि सविस्तर माहितीसाठी येथे क्लिक करा \nClick here for step-by-step preparation guides.',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShopCard(ShopModel shop, String categoryKey) {
    return Container(
      key: Key('shop_card_${shop.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ShopDetailsScreen(shop: shop, categoryKey: categoryKey),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      _api.getImageUrl(shop.profilePhoto),
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 160,
                          color: Colors.green.shade50,
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: const Color(0xFF1B5E20),
                          ),
                        );
                      },
                      errorBuilder: (c, e, s) => Container(
                        height: 160,
                        color: Colors.green.shade50,
                        child: const Icon(Icons.store, size: 60, color: Color(0xFF1B5E20)),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          shop.formattedDistance.isNotEmpty ? shop.formattedDistance : 'Proximity active',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E20),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'आजचे दुकान / Featured',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              shop.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          if (shop.city != null)
                            Text(
                              shop.city!,
                              style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              shop.address,
                              style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (shop.services != null && shop.services!.isNotEmpty) ...[
                        Text(
                          'सेवा / Services: ${shop.services}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.star, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text('Verified Shetkari Partner', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF1B5E20)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
