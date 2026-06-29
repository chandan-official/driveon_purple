class LocationModel {
  final double lat;
  final double lng;

  LocationModel({required this.lat, required this.lng});

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class FareBreakdown {
  final double baseFare;
  final double distanceFare;
  final double timeFare;
  final double platformFee;
  final double subtotal;
  final double surge;
  final double total;

  FareBreakdown({
    required this.baseFare,
    required this.distanceFare,
    required this.timeFare,
    required this.platformFee,
    required this.subtotal,
    required this.surge,
    required this.total,
  });

  factory FareBreakdown.fromJson(Map<String, dynamic> json) {
    return FareBreakdown(
      baseFare: (json['baseFare'] ?? 0.0).toDouble(),
      distanceFare: (json['distanceFare'] ?? 0.0).toDouble(),
      timeFare: (json['timeFare'] ?? 0.0).toDouble(),
      platformFee: (json['platformFee'] ?? 0.0).toDouble(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      surge: (json['surge'] ?? 0.0).toDouble(),
      total: (json['total'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseFare': baseFare,
      'distanceFare': distanceFare,
      'timeFare': timeFare,
      'platformFee': platformFee,
      'subtotal': subtotal,
      'surge': surge,
      'total': total,
    };
  }
}
