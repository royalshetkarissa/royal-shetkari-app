import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../models/shop_model.dart';
import '../widgets/royal_app_bar.dart';
import 'admin_shop_detail_clicks_screen.dart';

class AdminShopManagementScreen extends StatefulWidget {
  const AdminShopManagementScreen({super.key});

  @override
  State<AdminShopManagementScreen> createState() => _AdminShopManagementScreenState();
}

class _AdminShopManagementScreenState extends State<AdminShopManagementScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _servicesController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _cityController = TextEditingController();
  
  File? _profilePhoto;
  List<File> _shopImages = [];
  bool _isLoading = false;
  Position? _currentPosition;
  
  // The 7 Core Categories
  final Map<String, Map<String, String>> _categories = {
    'fertilizers': {'mr': 'खते व बियाणे', 'en': 'Fertilizers & Seeds'},
    'crop': {'mr': 'धान्य व पीक बाजार', 'en': 'Crop Market'},
    'equipment_repair': {'mr': 'शेती अवजारे दुरुस्ती', 'en': 'Equipment Repairing'},
    'hardware': {'mr': 'कृषी हार्डवेअर', 'en': 'Hardware Shop'},
    'organic_farming': {'mr': 'सेंद्रिय शेती साहित्य', 'en': 'Organic Farming'},
    'animal_doctor': {'mr': 'पशुवैद्यकीय डॉक्टर', 'en': 'Animal Doctor / Vet'},
    'produce_buyer': {'mr': 'शेतमाल खरेदीदार', 'en': 'Agricultural Produce Buyer'},
  };

  final Map<String, bool> _selectedCategories = {
    'fertilizers': false,
    'crop': false,
    'equipment_repair': false,
    'hardware': false,
    'organic_farming': false,
    'animal_doctor': false,
    'produce_buyer': false,
  };

  List<ShopModel> _shops = [];
  bool _acceptedTerms = false;
  List<Map<String, dynamic>> _claims = [];
  bool _claimsLoading = false;
  final _claimsSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchShops();
    _fetchClaims();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _whatsappController.dispose();
    _servicesController.dispose();
    _pincodeController.dispose();
    _cityController.dispose();
    _claimsSearchController.dispose();
    super.dispose();
  }

  Future<void> _fetchShops() async {
    try {
      final raw = await _api.getAdminShops();
      setState(() => _shops = raw.map((j) => ShopModel.fromJson(j)).toList());
    } catch (_) {}
  }

  Future<void> _pickProfilePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _profilePhoto = File(picked.path);
      });
    }
  }

  Future<void> _pickShopImages() async {
    final picker = ImagePicker();
    final pickedList = await picker.pickMultiImage(imageQuality: 70);
    if (pickedList != null) {
      if (pickedList.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can select maximum 10 photos'), backgroundColor: Colors.red));
        return;
      }
      setState(() {
        _shopImages = pickedList.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable GPS Location services')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
    setState(() => _currentPosition = pos);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS Coordinates Captured successfully!'), backgroundColor: Colors.green));
  }

  Future<void> _submitShop() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('नोंदणी करण्यासाठी कृपया नियम व अटी मान्य करा / Please accept terms to submit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_profilePhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a shop profile photo'), backgroundColor: Colors.red));
      return;
    }

    final selectedCats = _selectedCategories.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedCats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one shop category'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      FormData formData = FormData.fromMap({
        'name': _nameController.text.trim(),
        'owner_name': _ownerNameController.text.trim(),
        'address': _addressController.text.trim(),
        'contact_mobile': _mobileController.text.trim(),
        'whatsapp_number': _whatsappController.text.isNotEmpty ? _whatsappController.text.trim() : _mobileController.text.trim(),
        'services': _servicesController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'city': _cityController.text.trim(),
        'latitude': 19.0760,
        'longitude': 72.8777,
        'categories': selectedCats.join(','),
        'profilePhoto': await MultipartFile.fromFile(_profilePhoto!.path),
      });

      for (int i = 0; i < _shopImages.length; i++) {
        formData.files.add(MapEntry(
          'shopImages',
          await MultipartFile.fromFile(_shopImages[i].path),
        ));
      }

      await _api.addShopApi(formData);
      _clearForm();
      _fetchShops();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop Registered Successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add shop, please verify details.'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _ownerNameController.clear();
    _addressController.clear();
    _mobileController.clear();
    _whatsappController.clear();
    _servicesController.clear();
    _pincodeController.clear();
    _cityController.clear();
    setState(() {
      _profilePhoto = null;
      _shopImages = [];
      _currentPosition = null;
      _selectedCategories.updateAll((key, value) => false);
      _acceptedTerms = false;
    });
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (c) {
        final List<String> legalPoints = List.generate(100, (index) {
          final int pointNum = index + 1;
          return "कलम $pointNum (Section $pointNum): "
              "रॉयल शेतकरी बाजार नियंत्रण नियमावली अंतर्गत कलम $pointNum च्या अधीन राहून, हा अर्ज केवळ शेतकऱ्यांच्या सोयीसाठी आणि माहिती प्रदान करण्याच्या उद्देशाने (Information Purposes Only) तयार करण्यात आला आहे. "
              "This legal framework serves strictly under compliance of Section $pointNum. The application does not handle physical commercial transactions or guarantee seed quality. "
              "Furthermore, the registered merchant hereby grants absolute location navigation permission to allow real-time coordinate mapping via high-accuracy device geolocator APIs, "
              "and gallery storage media permission to allow compression, transmission, and rendering of catalog product images. "
              "The merchant and user agree that all listings, crop repair templates, organic fertilizer guides, vermiwash tutorials, and homemade humic carbon carbon solutions "
              "are provided strictly for advisory reference and educational use. Farmers must exercise due diligence before physical application in physical fields. "
              "The platform retains absolute right to soft-delete or deactivate profiles violating Section $pointNum terms. "
              "By checking the legal consent box, the user declares 100% agreement with standard electronic agricultural compliance directives. "
              "[Verification ID: RSC-LAW-POINT-$pointNum-COMPLIANCE-VERIFIED-SECURE]. "
              "This document constitutes a 100% legal, binding, and transparent user agreement designed to promote clean district agro-trade, preventing fraud and optimizing logistics.";
        });

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.gavel, color: Color(0xFF1B5E20)),
              SizedBox(width: 12),
              Text(
                'नियम आणि कायदेशीर अटी / Terms',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: ListView.builder(
              itemCount: legalPoints.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    legalPoints[index],
                    style: const TextStyle(fontSize: 11, height: 1.5, color: Colors.black87),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('बंद करा / CANCEL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() => _acceptedTerms = true);
                Navigator.pop(c);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('नियम आणि अटी यशस्वीरीत्या स्वीकारल्या! ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'सर्व नियम मान्य करा / ACCEPT ALL',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: RoyalAppBar(
          title: 'शेतकरी मार्केट व्यवस्थापन / Admin Shops',
          bottom: const TabBar(
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'नवीन नोंदणी / ADD SHOP'),
              Tab(text: 'व्यवस्थापन / MANAGE'),
              Tab(text: 'नाणी क्लेम लॉग / COIN CLAIMS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddShopTab(),
            _buildManageShopsTab(),
            _buildCoinClaimsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddShopTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickProfilePhoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: Colors.green.shade50,
                      backgroundImage: _profilePhoto != null ? FileImage(_profilePhoto!) : null,
                      child: _profilePhoto == null 
                          ? const Icon(Icons.add_a_photo, size: 36, color: Color(0xFF1B5E20)) 
                          : null,
                    ),
                    if (_profilePhoto != null)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFF1B5E20),
                          child: const Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel('दुकानदाराचे नाव / Owner Name *'),
            TextFormField(
              controller: _ownerNameController,
              validator: (v) => v == null || v.isEmpty ? 'कृपया मालकाचे नाव प्रविष्ट करा' : null,
              decoration: _buildInputDecoration('उदा. ज्ञानेश्वर पाटील / Dnyaneshwar Patil'),
            ),
            const SizedBox(height: 16),
            _buildLabel('दुकानाचे नाव / Shop Name *'),
            TextFormField(
              controller: _nameController,
              validator: (v) => v == null || v.isEmpty ? 'कृपया दुकानाचे नाव प्रविष्ट करा' : null,
              decoration: _buildInputDecoration('उदा. रॉयल शेती सेवा केंद्र / Royal Agro Services'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('शहर / City Name *'),
                      TextFormField(
                        controller: _cityController,
                        validator: (v) => v == null || v.isEmpty ? 'शहर आवश्यक' : null,
                        decoration: _buildInputDecoration('उदा. बारामती'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('पिनकोड / Pincode *'),
                      TextFormField(
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        validator: (v) => v == null || v.length != 6 ? '६ अंकी पिनकोड आवश्यक' : null,
                        decoration: _buildInputDecoration('उदा. 411001'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('पत्ता / Full Address *'),
            TextFormField(
              controller: _addressController,
              validator: (v) => v == null || v.isEmpty ? 'पत्ता प्रविष्ट करा' : null,
              maxLines: 2,
              decoration: _buildInputDecoration('दुकानाचा संपूर्ण पत्ता प्रविष्ट करा'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('मोबाईल नंबर / Mobile *'),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.length < 10 ? '१० अंकी मोबाईल नंबर आवश्यक' : null,
                        decoration: _buildInputDecoration('उदा. 9876543210'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('व्हॉट्सॲप नंबर / WhatsApp'),
                      TextFormField(
                        controller: _whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: _buildInputDecoration('उदा. 9876543210'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel('सेवांचा तपशील / Services Provided *'),
            TextFormField(
              controller: _servicesController,
              validator: (v) => v == null || v.isEmpty ? 'कृपया सेवांचा तपशील टाका' : null,
              maxLines: 3,
              decoration: _buildInputDecoration('उदा. सर्व प्रकारचे खते, औषधे, अवजारे व हार्डवेअर साहित्य वाजवी दरात उपलब्ध.'),
            ),
            const SizedBox(height: 24),
            _buildLabel('वर्ग / Shop Categories *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: _categories.keys.map((catKey) {
                  final details = _categories[catKey]!;
                  return CheckboxListTile(
                    title: Text(details['mr']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: Text(details['en']!, style: const TextStyle(fontSize: 11)),
                    value: _selectedCategories[catKey],
                    activeColor: const Color(0xFF1B5E20),
                    onChanged: (v) => setState(() => _selectedCategories[catKey] = v!),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _pickShopImages,
                icon: const Icon(Icons.photo_library, color: Color(0xFF1B5E20)),
                label: Text(
                  'गॅलरी फोटो (${_shopImages.length}/10)',
                  style: const TextStyle(color: Color(0xFF1B5E20), fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              key: const Key('row_terms_and_conditions'),
              children: [
                Checkbox(
                  key: const Key('checkbox_terms_accept'),
                  value: _acceptedTerms,
                  activeColor: const Color(0xFF1B5E20),
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsAndConditions,
                    child: const Text.rich(
                      TextSpan(
                        text: 'मी सर्व ',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                        children: [
                          TextSpan(
                            text: 'नियम आणि कायदेशीर अटी (Terms & Conditions)',
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' स्वीकारतो. * (गॅलरी व लोकेशन परवानगीसह)'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitShop,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 54),
                backgroundColor: const Color(0xFF1B5E20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('दुकानाची नोंदणी करा / ADD SHOP TO SYSTEM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildManageShopsTab() {
    // Exclude deleted shops from visual list, keep others
    final activeShops = _shops.where((s) => s.status.toLowerCase() != 'deleted').toList();

    if (activeShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('सध्या नोंदणीकृत दुकाने नाहीत \nNo registered shops found.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchShops,
      color: const Color(0xFF1B5E20),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeShops.length,
        itemBuilder: (context, index) {
          final shop = activeShops[index];
          final bool isActive = shop.status == 'active';

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green.shade50,
                backgroundImage: shop.profilePhoto != null ? NetworkImage(_api.getImageUrl(shop.profilePhoto)) : null,
                child: shop.profilePhoto == null ? const Icon(Icons.store, color: Color(0xFF1B5E20)) : null,
              ),
              title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('शहर/तालुका: ${shop.city ?? 'Maharashtra'}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isActive ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isActive ? Colors.green.shade800 : Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📊 Analytics Button
                  IconButton(
                    icon: const Icon(Icons.bar_chart, color: Colors.blueAccent),
                    tooltip: 'Engagement logs',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => AdminShopDetailClicksScreen(shop: shop),
                        ),
                      );
                    },
                  ),
                  if (!isActive)
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.green),
                      tooltip: 'Activate shop',
                      onPressed: () => _activateShop(shop.id),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Soft delete shop',
                    onPressed: () => _deleteShop(shop.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _activateShop(int id) async {
    await _api.activateShop(id);
    _fetchShops();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop is now Active!'), backgroundColor: Colors.green));
  }

  Future<void> _deleteShop(int id) async {
    await _api.deleteShopAdmin(id);
    _fetchShops();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop soft-deleted from live views.'), backgroundColor: Colors.red));
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12.5),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Future<void> _fetchClaims() async {
    setState(() => _claimsLoading = true);
    try {
      final claims = await _api.getAdminCoinClaims();
      setState(() {
        _claims = claims;
        _claimsLoading = false;
      });
    } catch (_) {
      setState(() => _claimsLoading = false);
    }
  }

  Widget _buildCoinClaimsTab() {
    if (_claimsLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)));
    }

    final query = _claimsSearchController.text.trim().toLowerCase();
    final filteredClaims = _claims.where((claim) {
      final shopName = (claim['shop_name'] ?? '').toString().toLowerCase();
      final userName = (claim['user_name'] ?? '').toString().toLowerCase();
      final userMobile = (claim['user_mobile'] ?? '').toString();
      final code = (claim['claim_code'] ?? '').toString().toLowerCase();

      return shopName.contains(query) ||
          userName.contains(query) ||
          userMobile.contains(query) ||
          code.contains(query);
    }).toList();

    return RefreshIndicator(
      onRefresh: _fetchClaims,
      color: const Color(0xFF1B5E20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _claimsSearchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'शोध दुकान, शेतकरी किंवा कोड / Search...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1B5E20)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                isDense: true,
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text('एकूण क्लेम्स / Total Claims', style: TextStyle(fontSize: 11, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('${filteredClaims.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text('एकूण नाणी / Total Coins', style: TextStyle(fontSize: 11, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredClaims.fold<int>(0, (sum, item) => sum + (int.tryParse(item['coins_redeemed']?.toString() ?? '50') ?? 50))}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredClaims.isEmpty
                ? const Center(child: Text('कोणतेही रेकॉर्ड सापडले नाही / No claims found.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredClaims.length,
                    itemBuilder: (context, index) {
                      final claim = filteredClaims[index];
                      final dateStr = claim['created_at'] != null 
                          ? DateTime.parse(claim['created_at'].toString()).toLocal().toString().substring(0, 16)
                          : 'N/A';

                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      claim['shop_name'] ?? 'Shop',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${claim['discount_percentage'] ?? '5'}% OFF',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.person, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${claim['user_name'] ?? 'Farmer'} (${claim['user_mobile'] ?? ''})',
                                    style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.vpn_key, size: 16, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      SelectableText(
                                        claim['claim_code'] ?? 'CODE',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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
        ],
      ),
    );
  }
}
