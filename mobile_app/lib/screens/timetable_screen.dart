import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/timetable_service.dart';
import 'package:intl/intl.dart';
import '../localization/app_localizations.dart';
import 'crop_selection_screen.dart';
import 'crop_timeline_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final TimetableService _service = TimetableService();
  bool _isLoading = true;
  List<CropJourney> _journeys = [];

  @override
  void initState() {
    super.initState();
    _fetchJourneys();
  }

  Future<void> _fetchJourneys() async {
    setState(() => _isLoading = true);
    try {
      _journeys = await _service.getMyJourneys();
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'grass': return Icons.grass;
      case 'apple': return Icons.apple;
      case 'eco': return Icons.eco;
      case 'bolt': return Icons.bolt;
      case 'spa': return Icons.spa;
      case 'favorite': return Icons.favorite;
      case 'brightness_high': return Icons.brightness_high;
      case 'bubble_chart': return Icons.bubble_chart;
      default: return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(context.translate('my_crop_schedules'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              onRefresh: _fetchJourneys,
              child: _journeys.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                              child: Icon(Icons.psychology_alt_outlined, size: 70, color: Colors.green.shade600),
                            ),
                            const SizedBox(height: 24),
                            Text(context.translate('no_active_schedules'), 
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Text(context.translate('start_new_journey', defaultValue: 'Start a new crop journey to get expert guidance'), 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () => _navigateToSelection(),
                                icon: const Icon(Icons.add, color: Colors.white),
                                label: Text(context.translate('start_new_journey'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                  elevation: 5,
                                  shadowColor: Colors.green.shade700,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _journeys.length,
                      itemBuilder: (context, index) {
                        final j = _journeys[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CropTimelineScreen(journey: j)),
                          ).then((_) => _fetchJourneys()),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Dismissible(
                                key: Key(j.id.toString()),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  color: Colors.red.shade500,
                                  child: const Icon(Icons.delete_sweep, color: Colors.white, size: 32),
                                ),
                                confirmDismiss: (dir) => _confirmDelete(j),
                                onDismissed: (dir) => _performDelete(index, j.id),
                                child: Stack(
                                  children: [
                                    // Decorative Background Icon
                                    Positioned(
                                      right: -20,
                                      bottom: -20,
                                      child: Icon(_getIconData(j.iconName), size: 120, color: Colors.white.withOpacity(0.1)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Icon(_getIconData(j.iconName), color: Colors.white, size: 24),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(j.cropMarathi, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                                                      Text(j.cropName, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                                                onPressed: () async {
                                                  if (await _confirmDelete(j) == true) {
                                                    _performDelete(index, j.id);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(context.translate('planted'), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.calendar_today, size: 14, color: Color(0xFF2E7D32)),
                                                        const SizedBox(width: 4),
                                                        Text(DateFormat('dd MMM yy').format(j.plantingDate), style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                Container(width: 1, height: 30, color: Colors.grey.shade200),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(context.translate('harvest_est'), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.eco, size: 14, color: Colors.amber),
                                                        const SizedBox(width: 4),
                                                        Text(DateFormat('dd MMM yy').format(j.plantingDate.add(Duration(days: j.harvestDaysMin ?? 60))), style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.bold)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
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
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToSelection(),
        backgroundColor: const Color(0xFF2E7D32),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(context.translate('new_crop'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _navigateToSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CropSelectionScreen()),
    ).then((_) => _fetchJourneys());
  }

  Future<bool?> _confirmDelete(CropJourney journey) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('delete_schedule_title')),
        content: Text(context.translate('delete_schedule_msg').replaceAll('{crop}', journey.cropMarathi)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(context.translate('cancel').toUpperCase())),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(context.translate('delete').toUpperCase(), style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _performDelete(int index, int journeyId) async {
    final success = await _service.deleteJourney(journeyId);
    if (success) {
      setState(() => _journeys.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.translate('journey_deleted'))));
      }
    }
  }
}
