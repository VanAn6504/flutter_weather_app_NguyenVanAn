import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../models/location_model.dart';

class LocationException implements Exception {
  final String message;
  final LocationErrorType type;

  const LocationException(this.message, this.type);

  @override
  String toString() => 'LocationException($type): $message';
}

enum LocationErrorType {
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  timeout,
  unknown,
}

class LocationService {
  // Permission
  Future<void> requestPermission() async {
    // Kiểm tra dịch vụ GPS có bật không
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'Dịch vụ GPS đang bị tắt. Vui lòng bật GPS trong cài đặt.',
        LocationErrorType.serviceDisabled,
      );
    }

    // Kiểm tra quyền hiện tại
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Chưa có quyền → xin quyền
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Quyền truy cập vị trí bị từ chối.',
          LocationErrorType.permissionDenied,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Quyền vị trí bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền.',
        LocationErrorType.permissionDeniedForever,
      );
    }
  }

  Future<LocationPermission> checkPermissionStatus() async {
    return await Geolocator.checkPermission();
  }

  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Current Position
  Future<LocationModel> getCurrentLocation() async {
    // 1. Đảm bảo có quyền
    await requestPermission();

    // 2. Lấy tọa độ GPS
    late Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        'GPS bị tắt trong quá trình lấy vị trí.',
        LocationErrorType.serviceDisabled,
      );
    } catch (e) {
      if (e.toString().contains('timeout') ||
          e.toString().contains('TimeoutException')) {
        throw const LocationException(
          'Không thể lấy vị trí do timeout. Hãy thử lại.',
          LocationErrorType.timeout,
        );
      }
      throw LocationException(
        'Lỗi khi lấy vị trí: ${e.toString()}',
        LocationErrorType.unknown,
      );
    }

    // 3. Reverse geocode: tọa độ → tên thành phố
    return await _reverseGeocode(position.latitude, position.longitude);
  }

  Future<Position> getRawPosition() async {
    await requestPermission();
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
      timeLimit: const Duration(seconds: 15),
    );
  }

  // Geocoding
  Future<LocationModel> _reverseGeocode(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        lat,
        lon,
        localeIdentifier: 'vi_VN',
      );

      if (placemarks.isEmpty) {
        return LocationModel(
          city: 'Unknown',
          country: '',
          lat: lat,
          lon: lon,
        );
      }

      final place = placemarks.first;

      // Ưu tiên: locality (thành phố) > subAdministrativeArea > administrativeArea
      final city = place.locality?.isNotEmpty == true
          ? place.locality!
          : place.subAdministrativeArea?.isNotEmpty == true
              ? place.subAdministrativeArea!
              : place.administrativeArea ?? 'Unknown';

      return LocationModel(
        city: city,
        country: place.isoCountryCode ?? '',
        lat: lat,
        lon: lon,
      );
    } catch (_) {
      // Geocoding thất bại: trả về tọa độ thô
      return LocationModel(
        city: '${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}',
        country: '',
        lat: lat,
        lon: lon,
      );
    }
  }

  Future<LocationModel?> geocodeCity(String cityName) async {
    try {
      final locations = await locationFromAddress(cityName);
      if (locations.isEmpty) return null;

      final loc = locations.first;
      // Reverse lại để lấy tên chuẩn
      return await _reverseGeocode(loc.latitude, loc.longitude);
    } catch (_) {
      return null;
    }
  }

  // Distance
  double distanceBetween(LocationModel from, LocationModel to) {
    final meters = Geolocator.distanceBetween(
      from.lat,
      from.lon,
      to.lat,
      to.lon,
    );
    return meters / 1000; // Chuyển sang km
  }

  bool isSameLocation(
    LocationModel a,
    LocationModel b, {
    double thresholdKm = 5.0,
  }) {
    return distanceBetween(a, b) < thresholdKm;
  }
}
