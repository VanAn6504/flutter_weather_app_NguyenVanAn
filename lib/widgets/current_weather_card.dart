import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../utils/weather_icons.dart';
import '../utils/date_formatter.dart';
import 'weather_detail_item.dart';

class CurrentWeatherCard extends StatelessWidget {
  const CurrentWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final weather = wp.weather;
    if (weather == null) return const SizedBox.shrink();

    final condition = weather.mainCondition;
    final isDay = weather.isDay;
    final emoji = WeatherIconHelper.getWeatherEmoji(condition.id, isDay: isDay);
    final temp = wp.displayTemperature ?? weather.temperature;
    final feelsLike = wp.displayFeelsLike ?? weather.feelsLike;
    final lastUpdate = DateFormatter.getTimeAgo(weather.lastUpdated.toLocal());

    return Column(
      children: [
        // Emoji + Nhiệt độ
        Text(emoji, style: const TextStyle(fontSize: 80)),
        const SizedBox(height: 8),
        // Nhiệt độ lớn
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              temp.round().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 88,
                fontWeight: FontWeight.w200,
                height: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                wp.tempUnitLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Mô tả điều kiện
        Text(
          condition.description.isNotEmpty
              ? _capitalize(condition.description)
              : WeatherIconHelper.getConditionNameVi(condition.id),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        // Cảm giác như + cao/thấp
        Text(
          'Cảm giác ${feelsLike.round()}${wp.tempUnitLabel}  •  '
          'Cao ${(wp.isCelsius ? weather.tempMax : weather.tempMax * 9 / 5 + 32).round()}°  '
          'Thấp ${(wp.isCelsius ? weather.tempMin : weather.tempMin * 9 / 5 + 32).round()}°',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        // Offline badge + last update
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (wp.isOfflineData) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        color: Colors.orange, size: 12),
                    SizedBox(width: 4),
                    Text('Offline',
                        style: TextStyle(color: Colors.orange, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              'Cập nhật $lastUpdate',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Chi tiết (độ ẩm, gió, áp suất, tầm nhìn)
        WeatherDetailRow(
          items: [
            WeatherDetailItem(
              icon: Icons.water_drop_outlined,
              label: 'Độ ẩm',
              value: '${weather.humidity}%',
            ),
            WeatherDetailItem(
              icon: Icons.air_rounded,
              label: 'Gió',
              value:
                  '${(wp.displayWindSpeed ?? weather.wind.speedKmh).round()} ${wp.windUnitLabel}',
            ),
            WeatherDetailItem(
              icon: Icons.compress_rounded,
              label: 'Áp suất',
              value: '${weather.pressure} hPa',
            ),
            WeatherDetailItem(
              icon: Icons.visibility_outlined,
              label: 'Tầm nhìn',
              value: weather.visibility != null
                  ? '${(weather.visibility! / 1000).toStringAsFixed(1)} km'
                  : 'N/A',
            ),
          ],
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
