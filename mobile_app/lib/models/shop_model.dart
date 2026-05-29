class ShopModel {
  final int id;
  final String name;
  final String? profilePhoto;
  final String address;
  final String contactMobile;
  final String? whatsappNumber;
  final List<String> categories;
  final List<String> images;
  final double latitude;
  final double longitude;
  final String status;
  final double? distance;
  final String? ownerName;
  final String? services;
  final String? pincode;
  final String? city;

  ShopModel({
    required this.id,
    required this.name,
    this.profilePhoto,
    required this.address,
    required this.contactMobile,
    this.whatsappNumber,
    required this.categories,
    required this.images,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.distance,
    this.ownerName,
    this.services,
    this.pincode,
    this.city,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'],
      name: json['name'],
      profilePhoto: json['profile_photo'],
      address: json['address'],
      contactMobile: json['contact_mobile'],
      whatsappNumber: json['whatsapp_number'],
      categories: List<String>.from(json['categories'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      status: json['status'],
      distance: json['distance'] != null ? double.parse(json['distance'].toString()) : null,
      ownerName: json['owner_name'],
      services: json['services'],
      pincode: json['pincode'],
      city: json['city'],
    );
  }

  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1) return '${(distance! * 1000).toInt()} m away';
    return '${distance!.toStringAsFixed(1)} km away';
  }
}
