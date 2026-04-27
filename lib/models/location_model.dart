class LocationModel {
  final String city;
  final String country;
  final double lat;
  final double lon;
  String get displayName => '$city, $country';

  const LocationModel({
    required this.city,
    required this.country,
    required this.lat,
    required this.lon,
  });

  // JSON Serialization
  factory LocationModel.fromWeatherJson(Map<String, dynamic> json) {
    return LocationModel(
      city: json['name'] as String? ?? 'Unknown',
      country:
          (json['sys'] as Map<String, dynamic>?)?['country'] as String? ?? '',
      lat: (json['coord'] as Map<String, dynamic>?)?['lat']?.toDouble() ?? 0.0,
      lon: (json['coord'] as Map<String, dynamic>?)?['lon']?.toDouble() ?? 0.0,
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      city: json['city'] as String? ?? 'Unknown',
      country: json['country'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lon'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'lat': lat,
      'lon': lon,
    };
  }

  // Utilities
  LocationModel copyWith({
    String? city,
    String? country,
    double? lat,
    double? lon,
  }) {
    return LocationModel(
      city: city ?? this.city,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationModel &&
        other.city == city &&
        other.country == country;
  }

  @override
  int get hashCode => city.hashCode ^ country.hashCode;

  @override
  String toString() => 'LocationModel(city: $city, country: $country, '
      'lat: $lat, lon: $lon)';
}
