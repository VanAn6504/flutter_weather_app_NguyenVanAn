import 'weather_model.dart' show WeatherCondition, WindData;

class HourlyWeatherModel {
  // Thời gian
  final DateTime dateTime;
  final String dateTimeText;

  // Nhiệt độ
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;

  // Điều kiện
  final List<WeatherCondition> conditions;

  WeatherCondition get mainCondition => conditions.isNotEmpty
      ? conditions.first
      : const WeatherCondition(
          id: 800, main: 'Clear', description: 'Trời quang', icon: '01d');

  // Khí tượng
  final int pressure;
  final int humidity;
  final int cloudiness;
  final double precipitationProbability;
  final double? rain3h;
  final double? snow3h;
  final WindData wind;
  final int? visibility;

  // Tính toán
  double get temperatureF => temperature * 9 / 5 + 32;
  int get precipitationPercent => (precipitationProbability * 100).round();
  bool get hasPrecipitation => rain3h != null && rain3h! > 0;
  bool get hasSnow => snow3h != null && snow3h! > 0;

  bool get isDay {
    final hour = dateTime.hour;
    return hour >= 6 && hour < 18;
  }

  const HourlyWeatherModel({
    required this.dateTime,
    required this.dateTimeText,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.conditions,
    required this.pressure,
    required this.humidity,
    required this.cloudiness,
    required this.precipitationProbability,
    this.rain3h,
    this.snow3h,
    required this.wind,
    this.visibility,
  });

  // JSON Serialization
  factory HourlyWeatherModel.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    final weatherList = json['weather'] as List<dynamic>? ?? [];
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final rain = json['rain'] as Map<String, dynamic>?;
    final snow = json['snow'] as Map<String, dynamic>?;

    return HourlyWeatherModel(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as int?) ?? 0) * 1000,
        isUtc: true,
      ),
      dateTimeText: json['dt_txt'] as String? ?? '',
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
      precipitationProbability: (json['pop'] as num?)?.toDouble() ?? 0.0,
      rain3h: (rain?['3h'] as num?)?.toDouble(),
      snow3h: (snow?['3h'] as num?)?.toDouble(),
      wind: WindData.fromJson(wind),
      visibility: json['visibility'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
        'dt_txt': dateTimeText,
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
        'wind': wind.toJson(),
        'visibility': visibility,
        'pop': precipitationProbability,
        if (rain3h != null) 'rain': {'3h': rain3h},
        if (snow3h != null) 'snow': {'3h': snow3h},
      };

  @override
  String toString() =>
      'HourlyWeatherModel($dateTimeText, ${temperature.toStringAsFixed(1)}°C)';
}
