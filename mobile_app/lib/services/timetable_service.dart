import 'package:dio/dio.dart';
import '../models/crop_model.dart';
import 'dio_client.dart';

class TimetableService {
  final Dio _dio = DioClient().dio;

  Future<List<Crop>> getCrops() async {
    try {
      final response = await _dio.get('/timetable/crops');
      if (response.data['success']) {
        return (response.data['crops'] as List)
            .map((c) => Crop.fromJson(c))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> startJourney(int cropId, DateTime plantingDate) async {
    try {
      final response = await _dio.post('/timetable/start-journey', data: {
        'cropId': cropId,
        'plantingDate': plantingDate.toIso8601String().split('T')[0],
      });
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }

  Future<List<CropJourney>> getMyJourneys() async {
    try {
      final response = await _dio.get('/timetable/my-journeys');
      if (response.data['success']) {
        return (response.data['journeys'] as List)
            .map((j) => CropJourney.fromJson(j))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> completeTask(int taskId) async {
    try {
      final response = await _dio.patch('/timetable/tasks/$taskId/complete');
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteJourney(int journeyId) async {
    try {
      final response = await _dio.delete('/timetable/journey/$journeyId');
      return response.data['success'];
    } catch (e) {
      return false;
    }
  }

  Future<List<CropDisease>> getCropDiseases(int cropId) async {
    try {
      final response = await _dio.get('/timetable/crops/$cropId/diseases');
      if (response.data['success']) {
        return (response.data['diseases'] as List)
            .map((d) => CropDisease.fromJson(d))
            .toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
