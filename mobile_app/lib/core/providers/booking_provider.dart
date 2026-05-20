import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  int _bookingCount = 0;
  List<String> _bookedSlots = [];

  bool get isLoading => _isLoading;
  int get bookingCount => _bookingCount;
  List<String> get bookedSlots => _bookedSlots;

  Future<void> bookCall({
    required String date,
    required String time,
    required String helpType,
    required String mobile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.bookCall(
        date: date,
        time: time,
        helpType: helpType,
        mobile: mobile,
      );
      await fetchBookingCount();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBookingCount() async {
    try {
      _bookingCount = await _apiService.getBookingCount();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching booking count: $e');
    }
  }

  Future<void> fetchBookedSlots(String date) async {
    _isLoading = true;
    notifyListeners();
    try {
      _bookedSlots = await _apiService.getBookedSlots(date);
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
