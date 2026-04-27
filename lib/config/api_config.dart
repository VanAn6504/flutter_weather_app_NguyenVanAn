import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  ApiConfig._();

  // API Credentials
  static String get apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  static String get baseUrl =>
      dotenv.env['OPENWEATHER_BASE_URL'] ??
      'https://api.openweathermap.org/data/2.5';

  // API Endpoints
  static String get currentWeatherEndpoint => '$baseUrl/weather';

  static String get forecastEndpoint => '$baseUrl/forecast';

  // URL Builders
  static String currentWeatherByCity(String city) {
    return '$currentWeatherEndpoint?q=$city&appid=$apiKey&units=metric&lang=vi';
  }

  static String currentWeatherByCoords(double lat, double lon) {
    return '$currentWeatherEndpoint?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=vi';
  }

  static String forecastByCity(String city) {
    return '$forecastEndpoint?q=$city&appid=$apiKey&units=metric&cnt=40&lang=vi';
  }

  static String forecastByCoords(double lat, double lon) {
    return '$forecastEndpoint?lat=$lat&lon=$lon&appid=$apiKey&units=metric&cnt=40&lang=vi';
  }

  static String weatherIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  // App Constants
  static const int cacheDurationMinutes = 30;

  static const int maxFavoriteCities = 5;

  static const int requestTimeoutSeconds = 15;
}
