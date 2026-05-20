class PostModel {
  final int id;
  final int userId;
  final String category;
  final String title;
  final String description;
  final double price;
  final double? oldPrice;
  final String? status;
  final String location;
  final String contactMobile;
  final String? imageUrl;
  final List<String> images;
  final DateTime createdAt;
  final String? farmerName;
  final String? village;
  final int viewsCount;
  final int likesCount;
  final String? animalType;
  final String? lactation;
  final double? milkPerDay;
  final int wpClicks;
  final int callClicks;
  final double? distance;
  final DateTime? deletedAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.title,
    required this.description,
    required this.price,
    this.oldPrice,
    this.status,
    required this.location,
    required this.contactMobile,
    this.imageUrl,
    this.images = const [],
    required this.createdAt,
    this.farmerName,
    this.village,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.animalType,
    this.lactation,
    this.milkPerDay,
    this.wpClicks = 0,
    this.callClicks = 0,
    this.distance,
    this.deletedAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      title: json['title'],
      description: json['description'],
      price: _parsePrice(json['price']),
      oldPrice: _parsePrice(json['old_price']),
      status: json['status'],
      location: json['location'],
      contactMobile: json['contact_mobile'] ?? '',
      imageUrl: json['image_url'],
      images: _parseImages(json['images']),
      createdAt: DateTime.parse(json['created_at']),
      farmerName: json['farmer_name'],
      village: json['village'],
      viewsCount: json['views_count'] ?? 0,
      likesCount: json['likes_count'] ?? 0,
      animalType: json['animal_type'],
      lactation: json['lactation'],
      milkPerDay: _parsePrice(json['milk_per_day']),
      wpClicks: json['wp_clicks'] ?? 0,
      callClicks: json['call_clicks'] ?? 0,
      distance: _parsePrice(json['distance']),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price == null) return 0.0;
    if (price is double) return price;
    if (price is int) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }

  static List<String> _parseImages(dynamic images) {
    if (images == null) return [];
    if (images is List) return images.map((e) => e.toString()).toList();
    if (images is String) {
      try {
        return (images as String).split(',').where((e) => e.isNotEmpty).toList();
      } catch (_) {
        return [];
      }
    }
    return [];
  }
}
