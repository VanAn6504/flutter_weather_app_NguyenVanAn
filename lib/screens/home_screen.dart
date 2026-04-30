import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../utils/weather_icons.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/hourly_forecast_list.dart';
import '../widgets/daily_forecast_card.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/error_widget.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'forecast_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final lp = context.watch<LocationProvider>();

    // Xác định gradient nền từ điều kiện thời tiết
    final gradient = _buildGradient(wp);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // AppBar
              _buildAppBar(context, wp, lp),
              // Body
              Expanded(
                child: _buildBody(context, wp, lp),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AppBar
  Widget _buildAppBar(
    BuildContext context,
    WeatherProvider wp,
    LocationProvider lp,
  ) {
    final location = lp.displayLocation ?? lp.selectedLocation;
    final cityName = wp.weather?.cityName ?? location?.city ?? '—';
    final country = wp.weather?.country ?? location?.country ?? '';
    final now = DateTime.now();
    final dateStr = DateFormatter.formatFullDate(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDesign.screenPadding,
        8,
        AppDesign.screenPadding,
        0,
      ),
      child: Row(
        children: [
          // Vị trí + ngày
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        country.isNotEmpty ? '$cityName, $country' : cityName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (lp.isLoading) ...[
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Nút Yêu thích
          if (location != null)
            _AppBarIconButton(
              icon: lp.isFavorite(location)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              iconColor: lp.isFavorite(location) ? Colors.pinkAccent : Colors.white,
              tooltip: 'Yêu thích',
              onTap: () {
                if (lp.isFavorite(location)) {
                  lp.removeFromFavorites(location);
                } else {
                  lp.addToFavorites(location);
                }
              },
            ),
          if (location != null) const SizedBox(width: 8),
          // Nút Search
          _AppBarIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Tìm kiếm',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          const SizedBox(width: 8),
          // Nút Settings
          _AppBarIconButton(
            icon: Icons.tune_rounded,
            tooltip: 'Cài đặt',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  // Body
  Widget _buildBody(
    BuildContext context,
    WeatherProvider wp,
    LocationProvider lp,
  ) {
    // Loading ban đầu
    if (wp.isLoading && !wp.hasData) {
      return const HomeScreenSkeleton();
    }

    // Lỗi GPS không có cache
    if (lp.hasError && !wp.hasData) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LocationErrorWidget(
            message: lp.errorMessage ?? 'Không thể xác định vị trí.',
            showSettingsButton: lp.isPermissionDeniedForever,
            onRetry: () => lp.fetchCurrentLocation(),
            onOpenSettings: () => lp.openAppSettings(),
          ),
          // Nút tìm kiếm thành phố thủ công
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(children: [
                  Expanded(
                      child:
                          Divider(color: Colors.white.withValues(alpha: 0.15))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'hoặc',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 13),
                    ),
                  ),
                  Expanded(
                      child:
                          Divider(color: Colors.white.withValues(alpha: 0.15))),
                ]),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    icon: const Icon(Icons.search_rounded, size: 18),
                    label: const Text('Tìm kiếm thành phố'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Lỗi API không có cache
    if (wp.hasError && !wp.hasData) {
      return WeatherErrorWidget(
        message: wp.errorMessage ?? 'Không thể tải dữ liệu.',
        exception: wp.lastException,
        onRetry: () => wp.refresh(),
      );
    }

    // Có data (online hoặc cache)
    return RefreshIndicator(
      onRefresh: () => wp.refresh(),
      color: Colors.white,
      backgroundColor: Colors.white.withValues(alpha: 0.2),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppDesign.screenPadding,
          16,
          AppDesign.screenPadding,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget thời tiết chính
            const CurrentWeatherCard(),
            const SizedBox(height: 32),
            // Dự báo theo giờ
            const HourlyForecastList(),
            const SizedBox(height: 28),
            // Dự báo 5 ngày
            const DailyForecastCard(),
            const SizedBox(height: 16),
            // Nút xem chi tiết dự báo
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ForecastScreen()),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppDesign.cardBorderRadius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Xem dự báo chi tiết',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white70, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Sunrise / Sunset
            if (wp.weather?.sunrise != null) _buildSunriseSunset(wp),
            // Nếu đang refresh: hiện inline loading
            if (wp.isRefreshing) ...[
              const SizedBox(height: 16),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white54,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80), // bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildSunriseSunset(WeatherProvider wp) {
    final weather = wp.weather!;
    final is24h = wp.is24HourFormat;
    final sunrise = weather.sunrise?.toLocal();
    final sunset = weather.sunset?.toLocal();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SunTime(
              label: 'Bình minh',
              emoji: '🌅',
              time: sunrise != null
                  ? DateFormatter.formatTime(sunrise, is24Hour: is24h)
                  : '--:--',
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            _SunTime(
              label: 'Hoàng hôn',
              emoji: '🌇',
              time: sunset != null
                  ? DateFormatter.formatTime(sunset, is24Hour: is24h)
                  : '--:--',
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _buildGradient(WeatherProvider wp) {
    final weather = wp.weather;
    if (weather == null) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A2A4A), Color(0xFF0D1117)],
      );
    }
    return WeatherIconHelper.getWeatherGradient(
      weather.mainCondition.id,
      isDay: weather.isDay,
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color iconColor;

  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}

class _SunTime extends StatelessWidget {
  final String label;
  final String emoji;
  final String time;

  const _SunTime({
    required this.label,
    required this.emoji,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
