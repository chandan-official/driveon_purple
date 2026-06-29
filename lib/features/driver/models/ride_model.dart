import 'package:flutter/material.dart';

class RideRoute {
  final String startCity;
  final String endCity;
  final List<String> checkpoints;

  const RideRoute({
    required this.startCity,
    required this.endCity,
    this.checkpoints = const [],
  });

  factory RideRoute.fromJson(Map<String, dynamic> json) {
    final start = (json['startCity'] ?? json['from'] ?? '').toString();
    final end = (json['endCity'] ?? json['to'] ?? '').toString();
    return RideRoute(
      startCity: start,
      endCity: end,
      checkpoints: (json['checkpoints'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class RidePricing {
  final double pricePerSeat;
  final double? fullCarPrice;

  const RidePricing({
    required this.pricePerSeat,
    this.fullCarPrice,
  });

  factory RidePricing.fromJson(Map<String, dynamic> json) {
    double toD(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
    final rawPerSeat = json['pricePerSeat'] ?? json['fare'];

    return RidePricing(
      pricePerSeat: rawPerSeat == null ? 0.0 : toD(rawPerSeat),
      fullCarPrice: (json['fullCarPrice'] as num?)?.toDouble(),
    );
  }
}

enum RideStatus { open, full, ongoing, cancelled, completed }

RideStatus rideStatusFromString(String s) {
  switch (s.trim().toUpperCase()) {
    case "AVAILABLE":
    case "OPEN":
      return RideStatus.open;
    case "FULL":
      return RideStatus.full;
    case "ONGOING":
      return RideStatus.ongoing;
    case "CANCELLED":
      return RideStatus.cancelled;
    case "COMPLETED":
      return RideStatus.completed;
    default:
      return RideStatus.open;
  }
}

class Ride {
  final String id;
  final dynamic driverId;
  final RideRoute route;
  final DateTime travelDate;
  final String startTime;
  final RidePricing pricing;
  final int totalSeats;
  final int availableSeats;
  final RideStatus status;

  const Ride({
    required this.id,
    required this.driverId,
    required this.route,
    required this.travelDate,
    required this.startTime,
    required this.pricing,
    required this.totalSeats,
    required this.availableSeats,
    required this.status,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    final travelDateRaw = (json['travelDate'] ?? json['departureTime'] ?? '').toString();
    final parsedDate = DateTime.tryParse(travelDateRaw) ?? DateTime.now();

    final pricingJson = (json['pricing'] is Map<String, dynamic>)
        ? (json['pricing'] as Map<String, dynamic>)
        : <String, dynamic>{'fare': json['fare']};

    final routeJson = (json['route'] is Map<String, dynamic>)
        ? (json['route'] as Map<String, dynamic>)
        : <String, dynamic>{
            'from': json['from'],
            'to': json['to'],
          };

    final totalSeats = (json['totalSeats'] ?? json['seats'] ?? 0);
    final bookedSeats = (json['bookedSeats'] ?? 0);
    final availableSeats = (json['availableSeats'] ??
        ((totalSeats is num && bookedSeats is num) ? totalSeats - bookedSeats : 0));

    return Ride(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      driverId: json['driverId'],
      route: RideRoute.fromJson(routeJson),
      travelDate: parsedDate,
      startTime: (json['startTime'] ?? json['departureTime'] ?? '').toString(),
      pricing: RidePricing.fromJson(pricingJson),
      totalSeats: totalSeats is num ? totalSeats.toInt() : 0,
      availableSeats: availableSeats is num ? availableSeats.toInt() : 0,
      status: rideStatusFromString((json['status'] ?? 'OPEN').toString()),
    );
  }
}
