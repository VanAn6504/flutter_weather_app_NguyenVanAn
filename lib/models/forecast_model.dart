import 'hourly_weather_model.dart';
import 'location_model.dart';

class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double maxPrecipitationProbability;
  final HourlyWeatherModel representativeHour;
  final List<HourlyWeatherModel> hourlyData;

  // Tính toán
  double get tempMaxF => tempMax * 9 / 5 + 32;
  double get tempMinF => tempMin * 9 / 5 + 32;
  int get precipitationPercent => (maxPrecipitationProbability * 100).round();

  int get avgHumidity {
    if (hourlyData.isEmpty) return 0;
    final total = hourlyData.fold(0, (sum, h) => sum + h.humidity);
    return total ~/ hourlyData.length;
  }

  double get maxWindSpeed {
    if (hourlyData.isEmpty) return 0;
    return hourlyData.map((h) => h.wind.speed).reduce((a, b) => a > b ? a : b);
  }

  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.maxPrecipitationProbability,
    required this.representativeHour,
    required this.hourlyData,
  });

  @override
  String toString() =>
      'DailyForecast(${date.toLocal().toString().split(' ')[0]}, '
      'max: ${tempMax.toStringAsFixed(1)}°C, min: ${tempMin.toStringAsFixed(1)}°C)';
}

class ForecastModel {
  // Thông tin thành phố
  final LocationModel location;
  final int count;
  // Dữ liệu thô theo giờ
  final List<HourlyWeatherModel> hourlyForecasts;
  // Dữ liệu tính toán
  List<DailyForecast> get dailyForecasts => _groupByDay();

  List<HourlyWeatherModel> get next24Hours {
    final now = DateTime.now().toUtc();
    final cutoff = now.add(const Duration(hours: 24));
    return hourlyForecasts
        .where((h) => h.dateTime.isAfter(now) && h.dateTime.isBefore(cutoff))
        .toList();
  }

  const ForecastModel({
    required this.location,
    required this.count,
    required this.hourlyForecasts,
  });

  // JSON Serialization
  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    final cityJson = json['city'] as Map<String, dynamic>? ?? {};
    final coord = cityJson['coord'] as Map<String, dynamic>? ?? {};
    final listJson = json['list'] as List<dynamic>? ?? [];

    final location = LocationModel(
      city: cityJson['name'] as String? ?? 'Unknown',
      country: cityJson['country'] as String? ?? '',
      lat: (coord['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (coord['lon'] as num?)?.toDouble() ?? 0.0,
    );

    final hourlyList = listJson
        .map(
            (item) => HourlyWeatherModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return ForecastModel(
      location: location,
      count: json['cnt'] as int? ?? hourlyList.length,
      hourlyForecasts: hourlyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cnt': count,
      'city': {
        'name': location.city,
        'country': location.country,
        'coord': {'lat': location.lat, 'lon': location.lon},
      },
      'list': hourlyForecasts.map((h) => h.toJson()).toList(),
    };
  }

  // Private Helpers
  List<DailyForecast> _groupByDay() {
    if (hourlyForecasts.isEmpty) return [];

    // Nhóm theo ngày (yyyy-MM-dd theo local time)
    final Map<String, List<HourlyWeatherModel>> groups = {};

    for (final hourly in hourlyForecasts) {
      // Chuyển sang local date string làm key
      final localDt = hourly.dateTime.toLocal();
      final key = '${localDt.year}-${localDt.month.toString().padLeft(2, '0')}-'
          '${localDt.day.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(hourly);
    }

    // Chuyển map thành danh sách DailyForecast, bỏ qua ngày hiện tại
    final result = <DailyForecast>[];
    final today = DateTime.now().toLocal();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';

    for (final entry in groups.entries) {
      // Bỏ qua ngày hôm nay (đã có CurrentWeather)
      if (entry.key == todayKey) continue;
      if (entry.value.isEmpty) continue;

      final hours = entry.value;
      final tempValues = hours.map((h) => h.temperature).toList();

      // Chọn giờ đại diện: ưu tiên 12:00 hoặc mốc giữa ngày
      HourlyWeatherModel representative = hours[hours.length ~/ 2];
      for (final h in hours) {
        if (h.dateTime.toLocal().hour == 12) {
          representative = h;
          break;
        }
      }

      final dateStr = entry.key.split('-');
      result.add(DailyForecast(
        date: DateTime(
          int.parse(dateStr[0]),
          int.parse(dateStr[1]),
          int.parse(dateStr[2]),
        ),
        tempMax: tempValues.reduce((a, b) => a > b ? a : b),
        tempMin: tempValues.reduce((a, b) => a < b ? a : b),
        maxPrecipitationProbability: hours
            .map((h) => h.precipitationProbability)
            .reduce((a, b) => a > b ? a : b),
        representativeHour: representative,
        hourlyData: hours,
      ));
    }

    // Sắp xếp theo ngày tăng dần
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  String toString() => 'ForecastModel(city: ${location.city}, '
      '${hourlyForecasts.length} hourly points, '
      '${dailyForecasts.length} days)';
}
