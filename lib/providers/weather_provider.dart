import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/location_model.dart';
import '../services/weather_service.dart';
import '../services/storage_service.dart';
import '../services/connectivity_service.dart';

// State Enum

enum WeatherStatus {
  initial,
  loading,
  refreshing,
  loaded,
  cached,
  error,
}

// WeatherProvider
class WeatherProvider extends ChangeNotifier {
  final WeatherService _weatherService;
  final StorageService _storageService;
  final ConnectivityService _connectivityService;

  WeatherProvider({
    WeatherService? weatherService,
    StorageService? storageService,
    ConnectivityService? connectivityService,
  })  : _weatherService = weatherService ?? WeatherService(),
        _storageService = storageService ?? StorageService(),
        _connectivityService = connectivityService ?? ConnectivityService();

  // Private State
  WeatherStatus _status = WeatherStatus.initial;
  WeatherModel? _weather;
  ForecastModel? _forecast;
  String? _errorMessage;
  WeatherException? _lastException;
  LocationModel? _lastFetchedLocation;
  bool _initialized = false;
  StreamSubscription<NetworkStatus>? _networkSubscription;

  // Public Getters
  WeatherStatus get status => _status;
  WeatherModel? get weather => _weather;
  ForecastModel? get forecast => _forecast;
  String? get errorMessage => _errorMessage;
  WeatherException? get lastException => _lastException;
  LocationModel? get lastFetchedLocation => _lastFetchedLocation;

  bool get isLoading => _status == WeatherStatus.loading;
  bool get isRefreshing => _status == WeatherStatus.refreshing;
  bool get isLoaded =>
      _status == WeatherStatus.loaded || _status == WeatherStatus.cached;
  bool get hasData => _weather != null;
  bool get hasError => _status == WeatherStatus.error;
  bool get isOfflineData => _status == WeatherStatus.cached;
  bool get isOnline => _connectivityService.isOnlineSync;

  // Settings Getters
  bool get isCelsius => _storageService.isCelsius;
  bool get isKmh => _storageService.isKmh;
  bool get is24HourFormat => _storageService.is24HourFormat;
  String get temperatureUnit => _storageService.getTemperatureUnit();
  String get windUnit => _storageService.getWindUnit();

  // Computed Display Values
  double? get displayTemperature {
    if (_weather == null) return null;
    return isCelsius ? _weather!.temperature : _weather!.temperatureF;
  }

  double? get displayFeelsLike {
    if (_weather == null) return null;
    return isCelsius ? _weather!.feelsLike : _weather!.feelsLikeF;
  }

  double? get displayWindSpeed {
    if (_weather == null) return null;
    return isKmh ? _weather!.wind.speedKmh : _weather!.wind.speedMph;
  }

  String get tempUnitLabel => isCelsius ? '°C' : '°F';
  String get windUnitLabel => isKmh ? 'km/h' : 'mph';

  // Initialization
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Khởi tạo các services
    await Future.wait([
      _storageService.initialize(),
      _connectivityService.initialize(),
    ]);

    // Load cache ngay để hiển thị data cũ trong khi đợi API
    await _loadFromCache();

    // Lắng nghe thay đổi mạng → tự reload khi có mạng trở lại
    _networkSubscription = _connectivityService.statusStream.listen(
      _onNetworkStatusChanged,
    );
  }

  // Fetch Methods
  Future<void> fetchByCity(String city, {bool isRefresh = false}) async {
    await _fetch(
      isRefresh: isRefresh,
      fetchFn: () => _weatherService.fetchWeatherAndForecastByCity(city),
      location: LocationModel(city: city, country: '', lat: 0, lon: 0),
    );
  }

  Future<void> fetchByCoords(
    double lat,
    double lon, {
    bool isRefresh = false,
  }) async {
    await _fetch(
      isRefresh: isRefresh,
      fetchFn: () => _weatherService.fetchWeatherAndForecastByCoords(lat, lon),
      location: LocationModel(city: '', country: '', lat: lat, lon: lon),
    );
  }

  Future<void> fetchByLocation(
    LocationModel location, {
    bool isRefresh = false,
  }) async {
    if (location.lat != 0 || location.lon != 0) {
      await fetchByCoords(location.lat, location.lon, isRefresh: isRefresh);
    } else {
      await fetchByCity(location.city, isRefresh: isRefresh);
    }
  }

  Future<void> refresh() async {
    if (_lastFetchedLocation == null) return;
    await fetchByLocation(_lastFetchedLocation!, isRefresh: true);
  }

  // Settings
  Future<void> setTemperatureUnit(String unit) async {
    await _storageService.setTemperatureUnit(unit);
    notifyListeners();
  }

  Future<void> setWindUnit(String unit) async {
    await _storageService.setWindUnit(unit);
    notifyListeners();
  }

  Future<void> setTimeFormat(String format) async {
    await _storageService.setTimeFormat(format);
    notifyListeners();
  }

  Future<void> toggleTemperatureUnit() async {
    await setTemperatureUnit(isCelsius ? 'fahrenheit' : 'celsius');
  }

  Future<void> toggleWindUnit() async {
    await setWindUnit(isKmh ? 'mph' : 'kmh');
  }

  Future<void> toggleTimeFormat() async {
    await setTimeFormat(is24HourFormat ? '12h' : '24h');
  }

  // Search History
  List<String> getSearchHistory() => _storageService.getSearchHistory();

  Future<void> addSearchHistory(String query) async {
    await _storageService.addSearchHistory(query);
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    await _storageService.clearSearchHistory();
    notifyListeners();
  }

  // Cache
  bool get hasCachedData => _storageService.getLastCacheTime() != null;

  DateTime? get lastCacheTime => _storageService.getLastCacheTime();

  bool get isCacheValid => _storageService.isCacheValid();

  Future<void> clearCache() async {
    await _storageService.clearAllCache();
    notifyListeners();
  }

  // Private Core
  Future<void> _fetch({
    required bool isRefresh,
    required Future<({WeatherModel weather, ForecastModel forecast})> Function()
        fetchFn,
    required LocationModel location,
  }) async {
    // Tránh gọi fetch khi đang loading (nhưng vẫn cho refresh)
    if (_status == WeatherStatus.loading && !isRefresh) return;

    // Set trạng thái loading
    if (isRefresh && hasData) {
      _status = WeatherStatus.refreshing;
    } else {
      _status = WeatherStatus.loading;
    }
    _errorMessage = null;
    _lastException = null;
    notifyListeners();

    // Kiểm tra kết nối mạng
    final online = await _connectivityService.isConnected;

    if (!online) {
      // Offline → dùng cache
      await _loadFromCache();
      if (!hasData) {
        // Không có cache → hiện lỗi
        _setError('Không có kết nối internet và không có dữ liệu cache.');
      }
      return;
    }

    // Online → gọi API
    try {
      final result = await fetchFn();

      _weather = result.weather;
      _forecast = result.forecast;
      _lastFetchedLocation = LocationModel(
        city: result.weather.cityName,
        country: result.weather.country,
        lat: result.weather.lat,
        lon: result.weather.lon,
      );
      _status = WeatherStatus.loaded;
      _errorMessage = null;
      _lastException = null;

      // Cache kết quả mới
      await Future.wait([
        _storageService.cacheWeather(result.weather),
        _storageService.cacheForecast(result.forecast),
      ]);

      // Lưu search history nếu search theo tên thành phố
      if (location.city.isNotEmpty && location.lat == 0) {
        await _storageService.addSearchHistory(location.city);
      }
    } on CityNotFoundException catch (e) {
      _lastException = e;
      _setError(e.message);
    } on InvalidApiKeyException catch (e) {
      _lastException = e;
      _setError(e.message);
    } on RateLimitException catch (e) {
      _lastException = e;
      // Rate limit → fallback về cache nếu có
      if (!await _loadFromCache()) {
        _setError(e.message);
      }
    } on NetworkException catch (e) {
      _lastException = e;
      if (!await _loadFromCache()) {
        _setError(e.message);
      }
    } on ServerException catch (e) {
      _lastException = e;
      if (!await _loadFromCache()) {
        _setError(e.message);
      }
    } on WeatherException catch (e) {
      _lastException = e;
      if (!await _loadFromCache()) {
        _setError(e.message);
      }
    } catch (e) {
      if (!await _loadFromCache()) {
        _setError('Lỗi không xác định: ${e.toString()}');
      }
    } finally {
      notifyListeners();
    }
  }

  Future<bool> _loadFromCache({bool ignoreExpiry = false}) async {
    // Khi offline, luôn bỏ qua expiry để có data hiển thị
    final shouldIgnore = ignoreExpiry || !_connectivityService.isOnlineSync;

    final cachedWeather = await _storageService.getCachedWeather(
      ignoreExpiry: shouldIgnore,
    );
    final cachedForecast = await _storageService.getCachedForecast(
      ignoreExpiry: shouldIgnore,
    );

    if (cachedWeather != null) {
      _weather = cachedWeather;
      _forecast = cachedForecast;
      _lastFetchedLocation = LocationModel(
        city: cachedWeather.cityName,
        country: cachedWeather.country,
        lat: cachedWeather.lat,
        lon: cachedWeather.lon,
      );
      _status = WeatherStatus.cached;
      _errorMessage = null;
      notifyListeners();
      return true;
    }
    return false;
  }

  void _onNetworkStatusChanged(NetworkStatus networkStatus) {
    if (networkStatus == NetworkStatus.online) {
      // Vừa có mạng → tự động reload nếu đang xem cache
      if (_status == WeatherStatus.cached && _lastFetchedLocation != null) {
        fetchByLocation(_lastFetchedLocation!);
      }
    } else {
      // Mất mạng → thông báo UI (không xóa data hiện tại)
      if (_status == WeatherStatus.loaded) {
        notifyListeners(); // UI sẽ kiểm tra isOnline để hiển thị badge
      }
    }
  }

  void _setError(String message) {
    _status = WeatherStatus.error;
    _errorMessage = message;
  }

  // Cleanup
  @override
  void dispose() {
    _networkSubscription?.cancel();
    _connectivityService.dispose();
    _weatherService.dispose();
    super.dispose();
  }
}
