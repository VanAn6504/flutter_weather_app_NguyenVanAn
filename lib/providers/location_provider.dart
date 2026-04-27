import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/location_model.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

enum LocationStatus {
  idle,
  loading,
  success,
  error,
  permissionDeniedForever,
}

// LocationProvider
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final StorageService _storageService;

  LocationProvider({
    LocationService? locationService,
    StorageService? storageService,
  })  : _locationService = locationService ?? LocationService(),
        _storageService = storageService ?? StorageService();

  // Private State
  LocationStatus _status = LocationStatus.idle;
  LocationModel? _currentLocation; // Vị trí GPS thực tế
  LocationModel? _selectedLocation; // Vị trí đang xem (GPS hoặc search)
  String? _errorMessage;
  bool _isUsingGps = true; // true = đang xem vị trí GPS
  bool _initialized = false;

  // Public Getters
  LocationStatus get status => _status;
  LocationModel? get currentLocation => _currentLocation;
  LocationModel? get selectedLocation => _selectedLocation ?? _currentLocation;
  String? get errorMessage => _errorMessage;
  bool get isUsingGps => _isUsingGps;
  bool get isLoading => _status == LocationStatus.loading;
  bool get hasLocation => selectedLocation != null;
  bool get hasError => _status == LocationStatus.error;
  bool get isPermissionDeniedForever =>
      _status == LocationStatus.permissionDeniedForever;

  LocationModel? get displayLocation => selectedLocation;

  // Initialization
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _storageService.initialize();

    // Khôi phục vị trí cuối từ cache (để hiển thị ngay khi mở app)
    final cached = _storageService.getLastLocation();
    if (cached != null) {
      _currentLocation = cached;
      _selectedLocation = cached;
      _status = LocationStatus.success;
      notifyListeners();
    }
  }

  // GPS Location
  Future<void> fetchCurrentLocation() async {
    if (_status == LocationStatus.loading) return; // Tránh gọi trùng

    _setLoading();

    try {
      final location = await _locationService.getCurrentLocation();
      _currentLocation = location;
      _selectedLocation = location;
      _isUsingGps = true;
      _status = LocationStatus.success;
      _errorMessage = null;

      // Lưu vào cache để dùng offline sau
      await _storageService.saveLastLocation(location);
    } on LocationException catch (e) {
      _handleLocationError(e);
    } catch (e) {
      _status = LocationStatus.error;
      _errorMessage = 'Lỗi không xác định: ${e.toString()}';
    } finally {
      notifyListeners();
    }
  }

  // Manual Location Selection
  void selectLocation(LocationModel location) {
    _selectedLocation = location;
    _isUsingGps = false;
    _status = LocationStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> returnToGpsLocation() async {
    if (_currentLocation != null) {
      _selectedLocation = _currentLocation;
      _isUsingGps = true;
      notifyListeners();
    } else {
      // Chưa có GPS location → lấy mới
      await fetchCurrentLocation();
    }
  }

  // Permission
  Future<bool> checkHasPermission() async {
    return await _locationService.hasPermission();
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // Favorites & History
  List<LocationModel> get favoriteCities => _storageService.getFavoriteCities();

  Future<bool> addCurrentToFavorites() async {
    final loc = selectedLocation;
    if (loc == null) return false;
    return await _storageService.addFavoriteCity(loc);
  }

  Future<bool> addToFavorites(LocationModel location) async {
    return await _storageService.addFavoriteCity(location);
  }

  Future<void> removeFromFavorites(LocationModel location) async {
    await _storageService.removeFavoriteCity(location);
    notifyListeners();
  }

  bool isFavorite(LocationModel location) {
    return _storageService.isFavoriteCity(location);
  }

  // Private Helpers
  void _setLoading() {
    _status = LocationStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _handleLocationError(LocationException e) {
    _errorMessage = e.message;
    switch (e.type) {
      case LocationErrorType.permissionDeniedForever:
        _status = LocationStatus.permissionDeniedForever;
      case LocationErrorType.serviceDisabled:
        _status = LocationStatus.error;
        _errorMessage = 'GPS đang bị tắt. Vui lòng bật GPS và thử lại.';
      case LocationErrorType.permissionDenied:
        _status = LocationStatus.error;
        _errorMessage = 'Quyền vị trí bị từ chối. Nhấn thử lại để cấp quyền.';
      case LocationErrorType.timeout:
        _status = LocationStatus.error;
        _errorMessage = 'Timeout khi lấy vị trí. Hãy thử lại.';
      case LocationErrorType.unknown:
        _status = LocationStatus.error;
    }
  }
}
