import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/post_model.dart';

class PostProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<PostModel> _posts = [];
  List<PostModel> _userPosts = [];
  bool _isLoading = false;
  String? _error;

  List<PostModel> get posts => _posts;
  List<PostModel> get userPosts => _userPosts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPosts({
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
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final rawPosts = await _api.getPosts(
        category: category,
        animalType: animalType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        userLat: userLat,
        userLng: userLng,
        radiusKm: radiusKm,
        search: search,
        sortBy: sortBy,
        dateFilter: dateFilter,
        hasImages: hasImages,
      );
      _posts = rawPosts.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      _error = 'Failed to load posts';
      _posts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final rawPosts = await _api.getUserPosts();
      _userPosts = rawPosts.map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      _error = 'Failed to load user posts';
      _userPosts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String category,
    required String title,
    required String description,
    required double? price,
    required String location,
    required String contactMobile,
    List<String>? imagePaths,
    List<dynamic>? imageFiles, // Added for mobile/desktop support
    List<dynamic>? imageBytesList, // Added for web support
    bool isWeb = false,
    double? latitude,
    double? longitude,
    String? animalType,
    String? lactation,
    double? milkPerDay,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // In a real production app, you'd handle image upload logic here
      // converting File or Bytes to MultipartFile via ApiService
      await _api.createPost(
        category: category,
        title: title,
        description: description,
        price: price,
        location: location,
        contactNumber: contactMobile,
        imagePaths: imagePaths ?? imageFiles?.map((f) => f.path).toList().cast<String>(),
        imageBytesList: imageBytesList?.cast<Uint8List>(),
        isWeb: isWeb,
        latitude: latitude,
        longitude: longitude,
        animalType: animalType,
        lactation: lactation,
        milkPerDay: milkPerDay,
      );
      await fetchPosts();
      return true;
    } catch (e) {
      _error = 'Failed to create post';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadB2Image(String imagePath, String caption) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.uploadB2Image(imagePath: imagePath, caption: caption);
      await fetchPosts();
      return true;
    } catch (e) {
      _error = 'Failed to upload B2 image';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost(int postId) async {
    try {
      await _api.deletePost(postId);
      await fetchUserPosts();
      await fetchPosts();
      return true;
    } catch (e) {
      _error = 'Failed to delete post';
      return false;
    }
  }

  Future<bool> updatePost({
    required int id,
    required String category,
    required String title,
    required String description,
    required double? price,
    required String location,
    required String contactMobile,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _api.updatePost(
        id: id,
        category: category,
        title: title,
        description: description,
        price: price,
        location: location,
        contactMobile: contactMobile,
      );
      await fetchUserPosts();
      await fetchPosts();
      return true;
    } catch (e) {
      _error = 'Failed to update post';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}