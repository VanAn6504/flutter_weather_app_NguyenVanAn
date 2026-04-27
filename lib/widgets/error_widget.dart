import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class WeatherErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final WeatherException? exception;

  const WeatherErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.exception,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon lỗi
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getErrorIcon(),
                color: Colors.white.withValues(alpha: 0.7),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            // Tiêu đề lỗi
            Text(
              _getErrorTitle(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Chi tiết lỗi
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Thử lại'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    if (exception is NetworkException) return Icons.wifi_off_rounded;
    if (exception is CityNotFoundException) return Icons.location_off_rounded;
    if (exception is InvalidApiKeyException) return Icons.vpn_key_off_rounded;
    if (exception is RateLimitException) return Icons.timer_off_rounded;
    if (exception is ServerException) return Icons.cloud_off_rounded;
    return Icons.error_outline_rounded;
  }

  String _getErrorTitle() {
    if (exception is NetworkException) return 'Mất kết nối mạng';
    if (exception is CityNotFoundException) return 'Không tìm thấy thành phố';
    if (exception is InvalidApiKeyException) return 'Lỗi xác thực API';
    if (exception is RateLimitException) return 'Quá nhiều yêu cầu';
    if (exception is ServerException) return 'Lỗi máy chủ';
    return 'Đã xảy ra lỗi';
  }
}

class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  color: Colors.white60, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

class LocationErrorWidget extends StatelessWidget {
  final String message;
  final bool showSettingsButton;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;

  const LocationErrorWidget({
    super.key,
    required this.message,
    this.showSettingsButton = false,
    this.onRetry,
    this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                color: Colors.white70,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không thể xác định vị trí',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                        side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    ),
                  ),
                if (showSettingsButton && onOpenSettings != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onOpenSettings,
                    icon: const Icon(Icons.settings_rounded, size: 18),
                    label: const Text('Cài đặt'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF667EEA).withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
