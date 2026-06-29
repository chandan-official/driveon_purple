class UserModel {
  final String id;
  final String fullname;
  final String email;
  final String? phone;
  final String role;

  UserModel({
    required this.id,
    required this.fullname,
    required this.email,
    this.phone,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'USER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'role': role,
    };
  }
}
