import 'package:flutter/material.dart';
import 'package:royal_shetkari/widgets/shimmer_skeleton.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AdminHospitalManagementScreen extends StatefulWidget {
  const AdminHospitalManagementScreen({super.key});

  @override
  State<AdminHospitalManagementScreen> createState() => _AdminHospitalManagementScreenState();
}

class _AdminHospitalManagementScreenState extends State<AdminHospitalManagementScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactController = TextEditingController();
  final _serviceController = TextEditingController();

  List<dynamic> _hospitals = [];
  List<dynamic> _claims = [];
  bool _isLoadingHospitals = true;
  bool _isLoadingClaims = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHospitals();
    _fetchClaims();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    _serviceController.dispose();
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

  Future<void> _fetchClaims() async {
    setState(() => _isLoadingClaims = true);
    try {
      final data = await _api.getAdminRedemptions();
      setState(() {
        _claims = data;
        _isLoadingClaims = false;
      });
    } catch (e) {
      setState(() => _isLoadingClaims = false);
    }
  }

  Future<void> _addHospital() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAdding = true);
    try {
      await _api.addHospital(
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        contactNumber: _contactController.text.trim(),
        service: _serviceController.text.trim(),
      );
      
      _nameController.clear();
      _locationController.clear();
      _contactController.clear();
      _serviceController.clear();
      
      _fetchHospitals();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hospital added successfully!', style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteHospital(int id, String name) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Hospital?'),
        content: Text('Are you sure you want to delete $name? This will remove it from the public list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteHospital(id);
      _fetchHospitals();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hospital deleted successfully.'), backgroundColor: Colors.blueGrey),
        );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'रुग्णालय व क्लेम / Hospital Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(text: 'रुग्णालये / Hospitals'),
            Tab(text: 'क्लेम्स / Redemptions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHospitalsTab(),
          _buildClaimsTab(),
        ],
      ),
    );
  }

  Widget _buildHospitalsTab() {
    return CustomScrollView(
      slivers: [
        // Add Hospital Form Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'नवीन रुग्णालय जोडा / Add New Hospital',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'रुग्णालयाचे नाव / Hospital Name',
                        prefixIcon: Icon(Icons.local_hospital, color: Colors.red),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter hospital name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _locationController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'पत्ता / Location',
                        prefixIcon: Icon(Icons.location_on, color: Colors.blue),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter location address' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'संपर्क क्रमांक / Contact Number',
                        prefixIcon: Icon(Icons.phone, color: Colors.green),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter phone number' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _serviceController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'सुविधा / Services offered (e.g. ICU, IPD)',
                        prefixIcon: Icon(Icons.medical_services, color: Colors.blueGrey),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Please enter service details' : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isAdding ? null : _addHospital,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isAdding
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('रुग्णालय जोडा / SAVE HOSPITAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Active Hospitals Section Heading
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              'सक्रिय रुग्णालये / ACTIVE HOSPITALS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.2, color: Colors.grey),
            ),
          ),
        ),
        // Active Hospitals List
        _isLoadingHospitals
            ? ShimmerSkeleton()
            : _hospitals.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No active hospitals registered.', style: TextStyle(color: Colors.grey))),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final h = _hospitals[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                                child: const Icon(Icons.local_hospital, color: Colors.red, size: 22),
                              ),
                              title: Text(h['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text('${h['location']} • Contact: ${h['contact_number']}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deleteHospital(h['id'], h['name']),
                              ),
                            ),
                          );
                        },
                        childCount: _hospitals.length,
                      ),
                    ),
                  ),
      ],
    );
  }

  Widget _buildClaimsTab() {
    if (_isLoadingClaims) {
      return Center(child: ShimmerSkeleton());
    }

    if (_claims.isEmpty) {
      return const Center(child: Text('No coin redemption claims recorded yet.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)));
    }

    return RefreshIndicator(
      onRefresh: _fetchClaims,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _claims.length,
        itemBuilder: (context, i) {
          final claim = _claims[i];
          final date = DateTime.parse(claim['created_at']);
          final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      claim['user_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: const [
                          Icon(Icons.stars, color: Colors.amber, size: 12),
                          SizedBox(width: 4),
                          Text('५० नाणी / 50 Coins', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Mobile: ${claim['user_mobile']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const Divider(height: 20),
                Row(
                  children: [
                    const Icon(Icons.local_hospital_outlined, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Hospital: ${claim['hospital_name']}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        claim['hospital_location'],
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
