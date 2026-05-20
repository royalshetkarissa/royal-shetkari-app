import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/timetable_service.dart';
import 'package:intl/intl.dart';

class CropSelectionScreen extends StatefulWidget {
  const CropSelectionScreen({super.key});

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  final TimetableService _service = TimetableService();
  bool _isLoading = true;
  List<Crop> _crops = [];

  @override
  void initState() {
    super.initState();
    _fetchCrops();
  }

  Future<void> _fetchCrops() async {
    setState(() => _isLoading = true);
    try {
      _crops = await _service.getCrops();
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

  Future<void> _selectDateAndStart(Crop crop) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'Select Plantation Date for ${crop.marathiName}',
    );

    if (selectedDate != null) {
      bool success = await _service.startJourney(crop.id, selectedDate);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Successfully started journey for ${crop.marathiName}'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start journey. Please try again.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Choose Your Crop', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _crops.length,
              itemBuilder: (context, index) {
                final crop = _crops[index];
                return GestureDetector(
                  onTap: () => _selectDateAndStart(crop),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8E9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getIconData(crop.iconName), color: const Color(0xFF2E7D32), size: 40),
                        const SizedBox(height: 8),
                        Text(
                          crop.marathiName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          crop.name,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
