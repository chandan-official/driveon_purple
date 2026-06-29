class RideRoute {
  final String startCity;
  final String endCity;
  final List<String> checkpoints;

  RideRoute({
    required this.startCity,
    required this.endCity,
    required this.checkpoints,
  });

  factory RideRoute.fromJson(Map<String, dynamic> json) {
    return RideRoute(
      startCity: json['startCity'] ?? '',
      endCity: json['endCity'] ?? '',
      checkpoints: List<String>.from(json['checkpoints'] ?? []),
    );
  }
}

class RidePricing {
  final double pricePerSeat;
  final double fullCarPrice;

  RidePricing({
    required this.pricePerSeat,
    required this.fullCarPrice,
  });

  factory RidePricing.fromJson(Map<String, dynamic> json) {
    return RidePricing(
      pricePerSeat: (json['pricePerSeat'] ?? 0.0).toDouble(),
      fullCarPrice: (json['fullCarPrice'] ?? 0.0).toDouble(),
    );
  }
}

class RideModel {
  final String id;
  // This might contain nested user info depending on populate depth
  final Map<String, dynamic>? driver;
  final RideRoute? route;
  final String travelDate;
  final String startTime;
  final RidePricing? pricing;
  final int totalSeats;
  final int availableSeats;
  final String status;

  RideModel({
    required this.id,
    this.driver,
    this.route,
    required this.travelDate,
    required this.startTime,
    this.pricing,
    required this.totalSeats,
    required this.availableSeats,
    required this.status,
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    return RideModel(
      id: json['_id'] ?? '',
      driver: json['driverId'] is Map<String, dynamic> ? json['driverId'] : null,
      route: json['route'] != null ? RideRoute.fromJson(json['route']) : null,
      travelDate: json['travelDate'] ?? '',
      startTime: json['startTime'] ?? '',
      pricing: json['pricing'] != null ? RidePricing.fromJson(json['pricing']) : null,
      totalSeats: json['totalSeats'] ?? 0,
      availableSeats: json['availableSeats'] ?? 0,
      status: json['status'] ?? 'OPEN',
    );
  }
}
