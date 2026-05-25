import 'package:dio/dio.dart';
import './dio_client.dart';
import '../config/app_config.dart';

class ApiService {
  final Dio _dio = DioClient().instance;
  static const String serverUrl = AppConfig.serverUrl;

  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$serverUrl$path';
  }

  dynamic _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    }
    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
    );
  }

  // AUTH
  Future<Map<String, dynamic>> login({required String mobile, required String password}) async {
    final response = await _dio.post('/auth/login', data: {'mobile': mobile, 'password': password});
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> register({required String fullName, required String mobile, required String email, required String password, required String village, required String state, required String pincode, double? latitude, double? longitude, String? currentLocation}) async {
    final response = await _dio.post('/auth/register', data: {'fullName': fullName, 'mobile': mobile, 'email': email, 'password': password, 'village': village, 'state': state, 'pincode': pincode, 'latitude': latitude, 'longitude': longitude, 'currentLocation': currentLocation});
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> verifyOtp({required String mobile, required String otp, String? purpose}) async {
    final response = await _dio.post('/auth/verify-otp', data: {'mobile': mobile, 'otp': otp, 'purpose': purpose});
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> resendOtp({required String mobile}) async {
    final response = await _dio.post('/auth/resend-otp', data: {'mobile': mobile});
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> resetPassword({required String mobile, required String newPassword}) async {
    final response = await _dio.post('/auth/reset-password', data: {'mobile': mobile, 'newPassword': newPassword});
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  // PROFILE
  Future<Map<String, dynamic>> updateProfile({required String fullName, required String email, required String village, required String state, required String pincode}) async {
    final response = await _dio.put('/auth/user/profile', data: {'fullName': fullName, 'email': email, 'village': village, 'state': state, 'pincode': pincode});
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> updateProfilePhoto(String imagePath) async {
    FormData formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(imagePath),
    });
    final response = await _dio.post('/auth/user/profile/photo', data: formData);
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _dio.get('/auth/user/me');
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  // COMMUNITY & POSTS
  Future<List<Map<String, dynamic>>> getPosts({
    String category = 'all',
    String? animalType,
    double? minPrice,
    double? maxPrice,
    double? userLat,
    double? userLng,
    double? radiusKm,
    String? search,
    String? sortBy,
    String? dateFilter,
    bool? hasImages,
  }) async {
    final query = {'category': category};
    if (animalType != null) query['animal_type'] = animalType;
    if (minPrice != null) query['minPrice'] = minPrice.toString();
    if (maxPrice != null) query['maxPrice'] = maxPrice.toString();
    if (userLat != null && userLng != null) {
      query['userLat'] = userLat.toString();
      query['userLng'] = userLng.toString();
      query['radius_km'] = (radiusKm ?? 50.0).toString();
    }
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (sortBy != null) query['sortBy'] = sortBy;
    if (dateFilter != null) query['dateFilter'] = dateFilter;
    if (hasImages != null) query['hasImages'] = hasImages.toString();

    final response = await _dio.get('/posts', queryParameters: query);
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['posts']);
  }

  Future<Map<String, dynamic>> createPost({required String category, required String title, required String description, required double? price, required String location, required String contactNumber, List<String>? imagePaths, double? latitude, double? longitude, String? animalType, String? lactation, double? milkPerDay}) async {
    Map<String, dynamic> fields = {
      'category': category,
      'title': title,
      'description': description,
      'price': price?.toString() ?? '',
      'location': location,
      'contact_number': contactNumber,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (animalType != null) 'animal_type': animalType,
      if (lactation != null) 'lactation': lactation,
      if (milkPerDay != null) 'milk_per_day': milkPerDay,
    };
    
    if (imagePaths != null && imagePaths.isNotEmpty) {
      List<MultipartFile> files = [];
      for (var path in imagePaths) {
        files.add(await MultipartFile.fromFile(path));
      }
      fields['images'] = files;
    }

    FormData formData = FormData.fromMap(fields);
    final response = await _dio.post('/posts', data: formData);
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> getPostDetails(int id) async {
    final response = await _dio.get('/posts/$id');
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<void> likePost(int id) async {
    await _dio.post('/posts/$id/like');
  }

  Future<void> savePost(int id) async {
    await _dio.post('/posts/$id/save');
  }

  Future<List<Map<String, dynamic>>> getComments(int postId) async {
    final response = await _dio.get('/posts/$postId/comments');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['comments']);
  }

  Future<void> addComment(int postId, String content) async {
    await _dio.post('/posts/$postId/comments', data: {'content': content});
  }

  // BOOKINGS
  Future<void> bookCall({required String date, required String time, required String helpType, required String mobile}) async {
    await _dio.post('/bookings', data: {'booking_date': date, 'booking_time': time, 'help_type': helpType, 'mobile': mobile});
  }

  Future<int> getBookingCount() async {
    final response = await _dio.get('/bookings/count');
    final data = _handleResponse(response);
    return data['count'] ?? 0;
  }

  Future<List<String>> getBookedSlots(String date) async {
    final response = await _dio.get('/bookings/slots', queryParameters: {'date': date});
    final data = _handleResponse(response);
    return List<String>.from(data['slots']);
  }

  // USER STATS & SAVES
  Future<Map<String, dynamic>> getUserSocialStats() async {
    final response = await _dio.get('/auth/user/social-stats');
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<List<Map<String, dynamic>>> getSavedPosts() async {
    final response = await _dio.get('/auth/user/saved-posts');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['posts']);
  }

  Future<List<Map<String, dynamic>>> getUserPosts() async {
    final response = await _dio.get('/auth/user/posts');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['posts']);
  }

  Future<Map<String, dynamic>> deletePost(int id) async {
    final response = await _dio.delete('/posts/$id');
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<Map<String, dynamic>> updatePost({required int id, required String category, required String title, required String description, required double? price, required String location, required String contactMobile}) async {
    final response = await _dio.put('/posts/$id', data: {
      'category': category,
      'title': title,
      'description': description,
      'price': price,
      'location': location,
      'contact_mobile': contactMobile
    });
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  // ADMIN ENDPOINTS
  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final response = await _dio.get('/admin/users');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['users']);
  }

  Future<List<Map<String, dynamic>>> getAdminModerationLogs() async {
    final response = await _dio.get('/admin/logs/moderation');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['logs']);
  }

  Future<List<Map<String, dynamic>>> getAdminTopCommenters() async {
    final response = await _dio.get('/admin/stats/top-commenters');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['topCommenters']);
  }

  Future<void> adminDeleteUser(int id) async {
    await _dio.delete('/admin/users/$id');
  }

  Future<Map<String, dynamic>> getAdminUserActivity(int id) async {
    final response = await _dio.get('/admin/users/$id/activity');
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<List<Map<String, dynamic>>> getAdminUserComments(int id) async {
    final response = await _dio.get('/admin/users/$id/comments');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['comments']);
  }

  Future<void> updateUserAccess({required int targetUserId, required String role, required Map<String, bool> permissions, required bool isAdmin}) async {
    await _dio.post('/admin/update-access', data: {
      'targetUserId': targetUserId,
      'role': role,
      'permissions': permissions,
      'isAdmin': isAdmin
    });
  }

  Future<Map<String, dynamic>> getAdminPostHistory(int id) async {
    final response = await _dio.get('/admin/posts/$id/history');
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  // ADVANCED FEATURES
  Future<void> trackWpClick(int postId) async {
    await _dio.post('/posts/$postId/wp-click');
  }

  Future<void> trackCallClick(int postId) async {
    await _dio.post('/posts/$postId/call-click');
  }

  Future<Map<String, dynamic>> scanCropDisease(String imagePath) async {
    FormData formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(imagePath),
    });
    final response = await _dio.post('/disease/scan', data: formData);
    return Map<String, dynamic>.from(_handleResponse(response)['data']);
  }

  Future<List<Map<String, dynamic>>> getDiseaseHistory() async {
    final response = await _dio.get('/disease/history');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['history']);
  }

  Future<void> deleteDiseaseHistory(int id) async {
    await _dio.delete('/disease/history/$id');
  }


  Future<void> activateTimetable(int timetableId, String plantingDate) async {
    await _dio.post('/timetable/user-schedules', data: {'timetableId': timetableId, 'plantingDate': plantingDate});
  }

  Future<List<Map<String, dynamic>>> getDailyTasks() async {
    final response = await _dio.get('/timetable/daily-tasks');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['tasks']);
  }

  Future<List<Map<String, dynamic>>> getTimetableTemplates() async {
    final response = await _dio.get('/timetable/templates');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['templates']);
  }

  // FERTILIZER SHOPS & MARKET
  Future<List<Map<String, dynamic>>> getNearbyShops(double lat, double lng) async {
    final response = await _dio.get('/shops/nearby', queryParameters: {'lat': lat, 'lng': lng});
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['shops']);
  }

  Future<void> trackShopClick(int shopId, String type) async {
    await _dio.post('/shops/$shopId/click', data: {'type': type});
  }

  Future<List<Map<String, dynamic>>> getAdminShops() async {
    final response = await _dio.get('/shops/admin/list');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['shops']);
  }

  Future<void> addShopApi(FormData formData) async {
    await _dio.post('/shops/admin/add', data: formData);
  }

  Future<void> activateShop(int id) async {
    await _dio.post('/shops/admin/$id/activate');
  }

  Future<void> deleteShopAdmin(int id) async {
    await _dio.delete('/shops/admin/$id');
  }

  Future<List<Map<String, dynamic>>> getShopAnalytics() async {
    final response = await _dio.get('/shops/admin/analytics');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['stats']);
  }

  Future<List<Map<String, dynamic>>> getShopClicksAdmin(int shopId) async {
    final response = await _dio.get('/shops/admin/shop-clicks/$shopId');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['clicks']);
  }

  // 🏥 HOSPITAL COIN REDEMPTIONS & MANAGEMENT
  Future<List<Map<String, dynamic>>> getHospitals() async {
    final response = await _dio.get('/hospitals');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['hospitals']);
  }

  Future<void> addHospital({
    required String name,
    required String location,
    required String contactNumber,
    required String service,
  }) async {
    await _dio.post('/hospitals', data: {
      'name': name,
      'location': location,
      'contactNumber': contactNumber,
      'service': service,
    });
  }

  Future<void> deleteHospital(int id) async {
    await _dio.delete('/hospitals/$id');
  }

  Future<Map<String, dynamic>> redeemHospitalCoins(int hospitalId) async {
    final response = await _dio.post('/hospitals/$hospitalId/redeem');
    return Map<String, dynamic>.from(_handleResponse(response));
  }

  Future<List<Map<String, dynamic>>> getAdminRedemptions() async {
    final response = await _dio.get('/hospitals/redemptions');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['redemptions']);
  }

  Future<List<Map<String, dynamic>>> getRedemptionHistory() async {
    final response = await _dio.get('/hospitals/history');
    final data = _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['history']);
  }

  Future<void> trackImpression({
    required String activeType,
    required String activeId,
    required DateTime startTime,
    required DateTime endTime,
    required int durationSeconds,
  }) async {
    try {
      await _dio.post('/analytics/impressions', data: {
        'activeType': activeType,
        'activeId': activeId,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationSeconds': durationSeconds,
      });
    } catch (e) {
      print('Impression logging failed: $e');
    }
  }
}