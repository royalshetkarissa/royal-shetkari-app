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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.agriculture, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(context.translate('no_active_schedules'), style: const TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _navigateToSelection(),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: Text(context.translate('start_new_journey'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _journeys.length,
                      itemBuilder: (context, index) {
                        final j = _journeys[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Dismissible(
                              key: Key(j.id.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                color: Colors.red.shade400,
                                child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
                              ),
                              confirmDismiss: (dir) => _confirmDelete(j),
                              onDismissed: (dir) => _performDelete(index, j.id),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(_getIconData(j.iconName), color: const Color(0xFF2E7D32), size: 28),
                                ),
                                title: Text(j.cropMarathi, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(j.cropName, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 12, color: Colors.blueGrey.shade300),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${context.translate('planted')}: ${DateFormat('dd MMM yyyy').format(j.plantingDate)}',
                                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                      onPressed: () async {
                                        if (await _confirmDelete(j) == true) {
                                          _performDelete(index, j.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CropTimelineScreen(journey: j)),
                                ).then((_) => _fetchJourneys()),
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
