import 'location_model.dart';
import 'user_model.dart';
import 'ride_model.dart';

class BookingModel {
  final String id;
  // This can be a String or a full RideModel depending on if it's populated.
  // We'll use dynamic or parse it to a Ride object if available.
  final RideModel? ride;
  final UserModel? passenger;
  final int seatsBooked;
  final String paymentMode;
  final String paymentStatus;
  final String status;
  final String? pickupAddress;
  final String? dropAddress;
  final LocationModel? pickupLocation;
  final LocationModel? dropLocation;
  final double? estimatedDistanceKm;
  final double? estimatedDurationMin;
  final FareBreakdown? fareBreakdown;
  final double totalAmount;
  final double? refundedAmount;

  BookingModel({
    required this.id,
    this.ride,
    this.passenger,
    required this.seatsBooked,
    required this.paymentMode,
    required this.paymentStatus,
    required this.status,
    this.pickupAddress,
    this.dropAddress,
    this.pickupLocation,
    this.dropLocation,
    this.estimatedDistanceKm,
    this.estimatedDurationMin,
    this.fareBreakdown,
    required this.totalAmount,
    this.refundedAmount,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    RideModel? parsedRide;
    if (json['rideId'] is Map<String, dynamic>) {
      parsedRide = RideModel.fromJson(json['rideId']);
    }

    UserModel? parsedPassenger;
    if (json['passengerId'] is Map<String, dynamic>) {
      parsedPassenger = UserModel.fromJson(json['passengerId']);
    }

    return BookingModel(
      id: json['_id'] ?? '',
      ride: parsedRide,
      passenger: parsedPassenger,
      seatsBooked: json['seatsBooked'] ?? 1,
      paymentMode: json['paymentMode'] ?? 'ONLINE',
      paymentStatus: json['paymentStatus'] ?? 'UNPAID',
      status: json['status'] ?? 'DRAFT',
      pickupAddress: json['pickupAddress'],
      dropAddress: json['dropAddress'],
      pickupLocation: json['pickupLocation'] != null
          ? LocationModel.fromJson(json['pickupLocation'])
          : null,
      dropLocation: json['dropLocation'] != null
          ? LocationModel.fromJson(json['dropLocation'])
          : null,
      estimatedDistanceKm: (json['estimatedDistanceKm'] ?? 0.0).toDouble(),
      estimatedDurationMin: (json['estimatedDurationMin'] ?? 0.0).toDouble(),
      fareBreakdown: json['fareBreakdown'] != null
          ? FareBreakdown.fromJson(json['fareBreakdown'])
          : null,
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      refundedAmount: json['refundedAmount'] != null ? (json['refundedAmount']).toDouble() : null,
    );
  }
}
