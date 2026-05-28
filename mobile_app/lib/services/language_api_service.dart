import 'package:dio/dio.dart';
import './dio_client.dart';

class LanguageApiService {
  final Dio _dio = DioClient().instance;

  Future<bool> updateLanguagePreference(String langCode) async {
    try {
      final response = await _dio.put(
        '/language/preference',
        data: {'lang': langCode},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, String>> fetchTranslations(String langCode) async {
    try {
      final response = await _dio.get(
        '/language/translations',
        queryParameters: {'lang': langCode},
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['success'] == true) {
        final Map<String, dynamic> transData = response.data['translations'];
        return transData.map((key, value) => MapEntry(key, value.toString()));
      }
    } catch (e) {
      // Ignore and fallback
    }
    return {};
  }
}
