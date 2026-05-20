import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/shop_model.dart';
import '../services/api_service.dart';
import '../widgets/royal_app_bar.dart';

class AdminShopDetailClicksScreen extends StatefulWidget {
  final ShopModel shop;
  const AdminShopDetailClicksScreen({super.key, required this.shop});

  @override
  State<AdminShopDetailClicksScreen> createState() => _AdminShopDetailClicksScreenState();
}

class _AdminShopDetailClicksScreenState extends State<AdminShopDetailClicksScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _clicks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClicks();
  }

  Future<void> _loadClicks() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _api.getShopClicksAdmin(widget.shop.id);
      setState(() {
        _clicks = raw;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    int callCount = _clicks.where((c) => c['click_type'] == 'call').length;
    int waCount = _clicks.where((c) => c['click_type'] == 'whatsapp').length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: RoyalAppBar(
        title: '${widget.shop.name} - Engagement',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : RefreshIndicator(
              onRefresh: _loadClicks,
              color: const Color(0xFF1B5E20),
              child: Column(
                children: [
                  _buildQuickStats(callCount, waCount),
                  Expanded(
                    child: _clicks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _clicks.length,
                            itemBuilder: (context, index) {
                              final click = _clicks[index];
                              final String clickType = click['click_type'] ?? 'unknown';
                              final String farmerName = click['farmer_name'] ?? 'अनामित शेतकरी / Guest User';
                              final String mobile = click['farmer_mobile'] ?? 'N/A';
                              final String dateString = click['created_at'] ?? DateTime.now().toIso8601String();
                              
                              DateTime? parsedDate;
                              try {
                                parsedDate = DateTime.parse(dateString);
                              } catch (_) {}

                              final formattedTime = parsedDate != null 
                                  ? DateFormat('dd MMM yyyy, hh:mm a').format(parsedDate)
                                  : dateString;

                              return Card(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 2,
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: clickType == 'call' ? Colors.green.shade50 : Colors.teal.shade50,
                                    child: Icon(
                                      clickType == 'call' ? Icons.phone : Icons.chat,
                                      color: clickType == 'call' ? Colors.green : Colors.teal,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    farmerName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text('मोबाईल / Mobile: $mobile', style: const TextStyle(fontSize: 12)),
                                      const SizedBox(height: 2),
                                      Text('दिनांक / Time: $formattedTime', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: clickType == 'call' ? Colors.green.shade100 : Colors.teal.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      clickType == 'call' ? 'CALL' : 'WHATSAPP',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: clickType == 'call' ? Colors.green.shade800 : Colors.teal.shade800,
                                      ),
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
    );
  }

  Widget _buildQuickStats(int calls, int whatsapp) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1B5E20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatTile('एकूण कॉल / Calls', '$calls', Icons.phone_callback, Colors.greenAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatTile('व्हॉट्सॲप / Chat', '$whatsapp', Icons.chat_bubble_outline, Colors.tealAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: 400,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.query_stats, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'अद्याप या दुकानाला शेतकऱ्यांनी प्रतिसाद दिला नाही.\nNo engagement recorded for this shop yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
