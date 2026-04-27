class WeatherCondition {
  final int id;
  final String main;
  final String description;
  final String icon;
  const WeatherCondition({
    required this.id,
    required this.main,
    required this.description,
    required this.icon,
  });

  factory WeatherCondition.fromJson(Map<String, dynamic> json) {
    return WeatherCondition(
      id: json['id'] as int? ?? 800,
      main: json['main'] as String? ?? '',
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '01d',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'main': main,
        'description': description,
        'icon': icon,
      };
}

class WindData {
  final double speed;

  final int? degree;

  final double? gust;

  const WindData({
    required this.speed,
    this.degree,
    this.gust,
  });

  String get directionName {
    if (degree == null) return 'N/A';
    final d = degree!;
    if (d < 22.5 || d >= 337.5) return 'Bắc';
    if (d < 67.5) return 'Đông Bắc';
    if (d < 112.5) return 'Đông';
    if (d < 157.5) return 'Đông Nam';
    if (d < 202.5) return 'Nam';
    if (d < 247.5) return 'Tây Nam';
    if (d < 292.5) return 'Tây';
    return 'Tây Bắc';
  }

  double get speedKmh => speed * 3.6;

  double get speedMph => speed * 2.237;

  factory WindData.fromJson(Map<String, dynamic> json) {
    return WindData(
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      degree: json['deg'] as int?,
      gust: (json['gust'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'speed': speed,
        'deg': degree,
        'gust': gust,
      };
}

class WeatherModel {
  // Vị trí
  final String cityName;
  final String country;
  final double lat;
  final double lon;

  // Nhiệt độ (°C nếu units=metric)
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;

  // Điều kiện thời tiết
  final List<WeatherCondition> conditions;

  WeatherCondition get mainCondition => conditions.isNotEmpty
      ? conditions.first
      : const WeatherCondition(
          id: 800, main: 'Clear', description: 'Trời quang', icon: '01d');

  // Chi tiết khí tượng
  final int pressure;
  final int humidity;
  final int cloudiness;
  final int? visibility;

  // Gió
  final WindData wind;

  // Thời gian
  final DateTime lastUpdated;
  final DateTime? sunrise;
  final DateTime? sunset;
  final int timezoneOffset;

  // Tính toán
  bool get isDay {
    final now = DateTime.now().toUtc();
    final localNow = now.add(Duration(seconds: timezoneOffset));
    final localHour = localNow.hour;
    return localHour >= 6 && localHour < 18;
  }

  double get temperatureF => temperature * 9 / 5 + 32;

  double get feelsLikeF => feelsLike * 9 / 5 + 32;

  const WeatherModel({
    required this.cityName,
    required this.country,
    required this.lat,
    required this.lon,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.conditions,
    required this.pressure,
    required this.humidity,
    required this.cloudiness,
    this.visibility,
    required this.wind,
    required this.lastUpdated,
    this.sunrise,
    this.sunset,
    required this.timezoneOffset,
  });

  // JSON Serialization
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final coord = json['coord'] as Map<String, dynamic>? ?? {};
    final sys = json['sys'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final wind = json['wind'] as Map<String, dynamic>? ?? {};

    return WeatherModel(
      cityName: json['name'] as String? ?? 'Unknown',
      country: sys['country'] as String? ?? '',
      lat: (coord['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (coord['lon'] as num?)?.toDouble() ?? 0.0,
      temperature: (main['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0.0,
      tempMin: (main['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (main['temp_max'] as num?)?.toDouble() ?? 0.0,
      conditions: weatherList
          .map((w) => WeatherCondition.fromJson(w as Map<String, dynamic>))
          .toList(),
      pressure: main['pressure'] as int? ?? 1013,
      humidity: main['humidity'] as int? ?? 0,
      cloudiness: clouds['all'] as int? ?? 0,
      visibility: json['visibility'] as int?,
      wind: WindData.fromJson(wind),
      // dt là Unix timestamp tính bằng giây
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as int?) ?? 0) * 1000,
        isUtc: true,
      ),
      sunrise: sys['sunrise'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (sys['sunrise'] as int) * 1000,
              isUtc: true,
            )
          : null,
      sunset: sys['sunset'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (sys['sunset'] as int) * 1000,
              isUtc: true,
            )
          : null,
      timezoneOffset: json['timezone'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'coord': {'lat': lat, 'lon': lon},
      'sys': {
        'country': country,
        if (sunrise != null) 'sunrise': sunrise!.millisecondsSinceEpoch ~/ 1000,
        if (sunset != null) 'sunset': sunset!.millisecondsSinceEpoch ~/ 1000,
      },
      'main': {
        'temp': temperature,
        'feels_like': feelsLike,
        'temp_min': tempMin,
        'temp_max': tempMax,
        'pressure': pressure,
        'humidity': humidity,
      },
      'weather': conditions.map((c) => c.toJson()).toList(),
      'clouds': {'all': cloudiness},
      'visibility': visibility,
      'wind': wind.toJson(),
      'dt': lastUpdated.millisecondsSinceEpoch ~/ 1000,
      'timezone': timezoneOffset,
    };
  }

  WeatherModel copyWith({
    String? cityName,
    String? country,
    double? lat,
    double? lon,
    double? temperature,
    double? feelsLike,
    double? tempMin,
    double? tempMax,
    List<WeatherCondition>? conditions,
    int? pressure,
    int? humidity,
    int? cloudiness,
    int? visibility,
    WindData? wind,
    DateTime? lastUpdated,
    DateTime? sunrise,
    DateTime? sunset,
    int? timezoneOffset,
  }) {
    return WeatherModel(
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      tempMin: tempMin ?? this.tempMin,
      tempMax: tempMax ?? this.tempMax,
      conditions: conditions ?? this.conditions,
      pressure: pressure ?? this.pressure,
      humidity: humidity ?? this.humidity,
      cloudiness: cloudiness ?? this.cloudiness,
      visibility: visibility ?? this.visibility,
      wind: wind ?? this.wind,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      sunrise: sunrise ?? this.sunrise,
      sunset: sunset ?? this.sunset,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
    );
  }

  @override
  String toString() =>
      'WeatherModel(city: $cityName, temp: ${temperature.toStringAsFixed(1)}°C)';
}
