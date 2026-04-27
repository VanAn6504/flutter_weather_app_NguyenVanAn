import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/location_model.dart';
import '../utils/constants.dart';

class StorageService {
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Lifecycle

  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
          'StorageService chưa được khởi tạo. Hãy gọi initialize() trước.');
    }
  }

  // Weather Cache
  Future<void> cacheWeather(WeatherModel weather) async {
    _ensureInitialized();
    final json = jsonEncode(weather.toJson());
    await Future.wait([
      _prefs.setString(StorageKeys.cachedWeather, json),
      _prefs.setString(StorageKeys.cachedCity, weather.cityName),
      // Lưu timestamp để kiểm tra cache còn hợp lệ không
      _prefs.setInt(
        StorageKeys.cacheTimestamp,
        DateTime.now().millisecondsSinceEpoch,
      ),
    ]);
  }

  Future<WeatherModel?> getCachedWeather({bool ignoreExpiry = false}) async {
    _ensureInitialized();

    final jsonStr = _prefs.getString(StorageKeys.cachedWeather);
    if (jsonStr == null) return null;

    // Kiểm tra cache có còn hợp lệ không
    if (!ignoreExpiry && !isCacheValid()) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WeatherModel.fromJson(json);
    } catch (_) {
      // JSON lỗi → xóa cache cũ
      await clearWeatherCache();
      return null;
    }
  }

  // Forecast Cache
  Future<void> cacheForecast(ForecastModel forecast) async {
    _ensureInitialized();
    final json = jsonEncode(forecast.toJson());
    await _prefs.setString(StorageKeys.cachedForecast, json);
  }

  Future<ForecastModel?> getCachedForecast({bool ignoreExpiry = false}) async {
    _ensureInitialized();

    final jsonStr = _prefs.getString(StorageKeys.cachedForecast);
    if (jsonStr == null) return null;

    if (!ignoreExpiry && !isCacheValid()) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ForecastModel.fromJson(json);
    } catch (_) {
      await clearForecastCache();
      return null;
    }
  }

  // Cache Validation
  bool isCacheValid() {
    _ensureInitialized();
    final timestamp = _prefs.getInt(StorageKeys.cacheTimestamp);
    if (timestamp == null) return false;

    final cached = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final diff = DateTime.now().difference(cached);
    return diff.inMinutes < ApiConfig.cacheDurationMinutes;
  }

  DateTime? getLastCacheTime() {
    _ensureInitialized();
    final ts = _prefs.getInt(StorageKeys.cacheTimestamp);
    if (ts == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> clearWeatherCache() async {
    _ensureInitialized();
    await Future.wait([
      _prefs.remove(StorageKeys.cachedWeather),
      _prefs.remove(StorageKeys.cacheTimestamp),
    ]);
  }

  Future<void> clearForecastCache() async {
    _ensureInitialized();
    await _prefs.remove(StorageKeys.cachedForecast);
  }

  Future<void> clearAllCache() async {
    await Future.wait([
      clearWeatherCache(),
      clearForecastCache(),
    ]);
  }

  // Favorite Cities
  List<LocationModel> getFavoriteCities() {
    _ensureInitialized();
    final jsonStr = _prefs.getString(StorageKeys.favoriteCities);
    if (jsonStr == null) return [];

    try {
      final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
      return list
          .map((item) => LocationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavoriteCities(List<LocationModel> cities) async {
    _ensureInitialized();
    final json = jsonEncode(cities.map((c) => c.toJson()).toList());
    await _prefs.setString(StorageKeys.favoriteCities, json);
  }

  Future<bool> addFavoriteCity(LocationModel city) async {
    final favorites = getFavoriteCities();

    // Kiểm tra đã có chưa
    if (favorites.any((f) => f == city)) return true;

    // Kiểm tra giới hạn
    if (favorites.length >= ApiConfig.maxFavoriteCities) return false;

    favorites.add(city);
    await saveFavoriteCities(favorites);
    return true;
  }

  Future<void> removeFavoriteCity(LocationModel city) async {
    final favorites = getFavoriteCities();
    favorites.removeWhere((f) => f == city);
    await saveFavoriteCities(favorites);
  }

  bool isFavoriteCity(LocationModel city) {
    return getFavoriteCities().any((f) => f == city);
  }

  // Search History
  List<String> getSearchHistory() {
    _ensureInitialized();
    return _prefs.getStringList(StorageKeys.searchHistory) ?? [];
  }

  Future<void> addSearchHistory(String query) async {
    _ensureInitialized();
    final history = getSearchHistory();

    // Xóa nếu đã tồn tại (để đưa lên đầu)
    history.remove(query);
    history.insert(0, query);

    // Giới hạn 10 mục
    final limited = history.take(10).toList();
    await _prefs.setStringList(StorageKeys.searchHistory, limited);
  }

  Future<void> clearSearchHistory() async {
    _ensureInitialized();
    await _prefs.remove(StorageKeys.searchHistory);
  }

  // User Settings
  String getTemperatureUnit() {
    _ensureInitialized();
    return _prefs.getString(StorageKeys.tempUnit) ?? 'celsius';
  }

  Future<void> setTemperatureUnit(String unit) async {
    _ensureInitialized();
    await _prefs.setString(StorageKeys.tempUnit, unit);
  }

  bool get isCelsius => getTemperatureUnit() == 'celsius';

  String getWindUnit() {
    _ensureInitialized();
    return _prefs.getString(StorageKeys.windUnit) ?? 'kmh';
  }

  Future<void> setWindUnit(String unit) async {
    _ensureInitialized();
    await _prefs.setString(StorageKeys.windUnit, unit);
  }

  bool get isKmh => getWindUnit() == 'kmh';

  String getTimeFormat() {
    _ensureInitialized();
    return _prefs.getString(StorageKeys.timeFormat) ?? '24h';
  }

  Future<void> setTimeFormat(String format) async {
    _ensureInitialized();
    await _prefs.setString(StorageKeys.timeFormat, format);
  }

  bool get is24HourFormat => getTimeFormat() == '24h';

  // Last Location
  Future<void> saveLastLocation(LocationModel location) async {
    _ensureInitialized();
    final json = jsonEncode(location.toJson());
    await _prefs.setString(StorageKeys.lastLocation, json);
  }

  LocationModel? getLastLocation() {
    _ensureInitialized();
    final jsonStr = _prefs.getString(StorageKeys.lastLocation);
    if (jsonStr == null) return null;
    try {
      return LocationModel.fromJson(
          jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // Full Reset
  Future<void> clearAll() async {
    _ensureInitialized();
    await _prefs.clear();
  }
}
