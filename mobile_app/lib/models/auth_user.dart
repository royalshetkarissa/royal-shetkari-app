class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.village,
    required this.isVerified,
  });

  final int id;
  final String fullName;
  final String mobile;
  final String email;
  final String village;
  final bool isVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      mobile: json['mobile'] as String,
      email: json['email'] as String,
      village: json['village'] as String,
      isVerified: json['isVerified'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      'village': village,
      'isVerified': isVerified,
    };
  }
}
