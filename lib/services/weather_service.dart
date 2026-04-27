import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';

// Custom Exceptions
sealed class WeatherException implements Exception {
  final String message;
  const WeatherException(this.message);

  @override
  String toString() => message;
}

final class InvalidApiKeyException extends WeatherException {
  const InvalidApiKeyException()
      : super('API Key không hợp lệ. Vui lòng kiểm tra file .env');
}

final class CityNotFoundException extends WeatherException {
  final String city;
  const CityNotFoundException(this.city)
      : super('Không tìm thấy thành phố "$city"');
}

final class RateLimitException extends WeatherException {
  const RateLimitException()
      : super('Quá nhiều request. Vui lòng thử lại sau vài phút.');
}

final class NetworkException extends WeatherException {
  const NetworkException([super.message = 'Không có kết nối internet']);
}

final class ServerException extends WeatherException {
  final int statusCode;
  const ServerException(this.statusCode)
      : super('Lỗi server ($statusCode). Vui lòng thử lại sau.');
}

final class UnknownWeatherException extends WeatherException {
  const UnknownWeatherException(super.message);
}

// WeatherService
class WeatherService {
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  // Current Weather
  Future<WeatherModel> fetchWeatherByCity(String city) async {
    final url = ApiConfig.currentWeatherByCity(city);
    final data = await _get(url);
    return WeatherModel.fromJson(data);
  }

  Future<WeatherModel> fetchWeatherByCoords(double lat, double lon) async {
    final url = ApiConfig.currentWeatherByCoords(lat, lon);
    final data = await _get(url);
    return WeatherModel.fromJson(data);
  }

  // Forecast
  Future<ForecastModel> fetchForecastByCity(String city) async {
    final url = ApiConfig.forecastByCity(city);
    final data = await _get(url);
    return ForecastModel.fromJson(data);
  }

  Future<ForecastModel> fetchForecastByCoords(double lat, double lon) async {
    final url = ApiConfig.forecastByCoords(lat, lon);
    final data = await _get(url);
    return ForecastModel.fromJson(data);
  }

  // Batch Fetch
  Future<({WeatherModel weather, ForecastModel forecast})>
      fetchWeatherAndForecastByCity(String city) async {
    final results = await Future.wait([
      fetchWeatherByCity(city),
      fetchForecastByCity(city),
    ]);
    return (
      weather: results[0] as WeatherModel,
      forecast: results[1] as ForecastModel,
    );
  }

  Future<({WeatherModel weather, ForecastModel forecast})>
      fetchWeatherAndForecastByCoords(double lat, double lon) async {
    final results = await Future.wait([
      fetchWeatherByCoords(lat, lon),
      fetchForecastByCoords(lat, lon),
    ]);
    return (
      weather: results[0] as WeatherModel,
      forecast: results[1] as ForecastModel,
    );
  }

  // API Key Validation
  Future<bool> validateApiKey() async {
    try {
      await fetchWeatherByCity('London');
      return true;
    } on InvalidApiKeyException {
      return false;
    } catch (_) {
      // Lỗi khác (network, server...) không có nghĩa key sai
      return true;
    }
  }

  // Private HTTP Core
  Future<Map<String, dynamic>> _get(String url, {int retryCount = 1}) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: ApiConfig.requestTimeoutSeconds));

      return _handleResponse(response, url);
    } on SocketException {
      throw const NetworkException(
          'Không thể kết nối đến server. Kiểm tra mạng.');
    } on HttpException {
      throw const NetworkException('Lỗi HTTP kết nối.');
    } on FormatException {
      throw const UnknownWeatherException('Dữ liệu API không đúng định dạng.');
    } on WeatherException {
      // Re-throw WeatherException trực tiếp
      rethrow;
    } catch (e) {
      // Retry 1 lần với lỗi không xác định
      if (retryCount > 0) {
        await Future.delayed(const Duration(seconds: 1));
        return _get(url, retryCount: retryCount - 1);
      }
      throw UnknownWeatherException('Lỗi không xác định: ${e.toString()}');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response, String url) {
    final statusCode = response.statusCode;

    if (statusCode == 200) {
      // Thành công - parse JSON
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        throw const UnknownWeatherException('Lỗi parse JSON từ API.');
      }
    }

    // Lỗi - parse message từ API nếu có
    String? apiMessage;
    try {
      final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
      apiMessage = errorBody['message'] as String?;
    } catch (_) {
      // Body không phải JSON
    }

    switch (statusCode) {
      case 401:
        throw const InvalidApiKeyException();

      case 404:
        // OpenWeatherMap trả "city not found" trong message
        final cityMatch = RegExp(r'q=([^&]+)').firstMatch(url);
        final cityName = cityMatch != null
            ? Uri.decodeComponent(cityMatch.group(1) ?? 'Unknown')
            : apiMessage ?? 'Unknown';
        throw CityNotFoundException(cityName);

      case 429:
        throw const RateLimitException();

      case >= 500:
        throw ServerException(statusCode);

      default:
        throw UnknownWeatherException(
          apiMessage ?? 'HTTP Error $statusCode',
        );
    }
  }

  // Cleanup
  void dispose() => _client.close();
}
