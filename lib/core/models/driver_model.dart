import 'user_model.dart';

class VehicleModel {
  final String vehicleType;
  final String vehicleName;
  final String vehicleNumber;
  final String color;
  final int seatCapacity;

  VehicleModel({
    required this.vehicleType,
    required this.vehicleName,
    required this.vehicleNumber,
    required this.color,
    required this.seatCapacity,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      vehicleType: json['vehicleType']?.toString() ?? '',
      vehicleName: json['vehicleName']?.toString() ?? '',
      vehicleNumber: json['vehicleNumber']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      seatCapacity: json['seatCapacity'] is num ? (json['seatCapacity'] as num).toInt() : int.tryParse(json['seatCapacity']?.toString() ?? '4') ?? 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleType': vehicleType,
      'vehicleName': vehicleName,
      'vehicleNumber': vehicleNumber,
      'color': color,
      'seatCapacity': seatCapacity,
    };
  }
}

class DriverModel extends UserModel {
  final bool isVerified;
  final String? profileImage;
  final String licenseNo;
  final String rcNo;
  final VehicleModel? vehicle;
  final double rating;
  final int totalTrips;
  final double totalEarnings;

  DriverModel({
    required super.id,
    required super.fullname,
    required super.email,
    super.phone,
    required super.role,
    this.isVerified = false,
    this.profileImage,
    required this.licenseNo,
    required this.rcNo,
    this.vehicle,
    this.rating = 0.0,
    this.totalTrips = 0,
    this.totalEarnings = 0.0,
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    final userPart = UserModel.fromJson(json);
    return DriverModel(
      id: userPart.id,
      fullname: userPart.fullname,
      email: userPart.email,
      phone: userPart.phone,
      role: userPart.role,
      isVerified: json['isVerified'] == true,
      profileImage: json['profileImage']?.toString(),
      licenseNo: json['licenseNo']?.toString() ?? '',
      rcNo: json['rcNo']?.toString() ?? '',
      vehicle: json['vehicle'] is Map ? VehicleModel.fromJson((json['vehicle'] as Map).cast<String, dynamic>()) : null,
      rating: json['rating'] is num ? (json['rating'] as num).toDouble() : double.tryParse(json['rating']?.toString() ?? '0') ?? 0,
      totalTrips: json['totalTrips'] is num ? (json['totalTrips'] as num).toInt() : int.tryParse(json['totalTrips']?.toString() ?? '0') ?? 0,
      totalEarnings: json['totalEarnings'] is num ? (json['totalEarnings'] as num).toDouble() : double.tryParse(json['totalEarnings']?.toString() ?? '0') ?? 0,
    );
  }
}
