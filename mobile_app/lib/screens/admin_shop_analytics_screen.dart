import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class AdminShopAnalyticsScreen extends StatefulWidget {
  const AdminShopAnalyticsScreen({super.key});

  @override
  State<AdminShopAnalyticsScreen> createState() => _AdminShopAnalyticsScreenState();
}

class _AdminShopAnalyticsScreenState extends State<AdminShopAnalyticsScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _stats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _api.getShopAnalytics();
      setState(() {
        _stats = raw;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Engagement Analytics'),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats.isEmpty
              ? const Center(child: Text('No clicks tracked yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _stats.length,
                  itemBuilder: (context, index) {
                    final stat = _stats[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _getIcon(stat['click_type']),
                        title: Text('${stat['farmer_name'] ?? 'Guest User'} clicked ${stat['shop_name']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Action: ${stat['click_type'].toUpperCase()} | Count: ${stat['click_count']}'),
                            Text('Mobile: ${stat['farmer_mobile'] ?? 'N/A'}'),
                            Text('Last Click: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(stat['last_click']))}'),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _getIcon(String type) {
    switch (type) {
      case 'call': return const Icon(Icons.phone, color: Colors.green);
      case 'whatsapp': return const Icon(Icons.chat, color: Colors.teal);
      case 'view': return const Icon(Icons.visibility, color: Colors.blue);
      default: return const Icon(Icons.touch_app);
    }
  }
}
