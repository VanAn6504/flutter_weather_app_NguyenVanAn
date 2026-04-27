import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../models/hourly_weather_model.dart';
import '../utils/weather_icons.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';

class HourlyForecastList extends StatelessWidget {
  const HourlyForecastList({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final forecast = wp.forecast;
    if (forecast == null) return const SizedBox.shrink();

    final hourlyList = forecast.next24Hours;
    if (hourlyList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề
        Row(
          children: [
            const Icon(Icons.schedule_rounded, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              'DỰ BÁO 24 GIỜ',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Danh sách ngang
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: hourlyList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) =>
                _HourlyItem(data: hourlyList[index], wp: wp),
          ),
        ),
      ],
    );
  }
}

class _HourlyItem extends StatelessWidget {
  final HourlyWeatherModel data;
  final WeatherProvider wp;

  const _HourlyItem({required this.data, required this.wp});

  @override
  Widget build(BuildContext context) {
    final isDay = data.isDay;
    final emoji = WeatherIconHelper.getWeatherEmoji(
      data.mainCondition.id,
      isDay: isDay,
    );
    final localDt = data.dateTime.toLocal();
    final timeStr =
        DateFormatter.formatTime(localDt, is24Hour: wp.is24HourFormat);
    final temp =
        wp.isCelsius ? data.temperature : data.temperature * 9 / 5 + 32;

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius - 4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Thời gian
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          // Icon
          Text(emoji, style: const TextStyle(fontSize: 24)),
          // Nhiệt độ
          Text(
            '${temp.round()}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Xác suất mưa (nếu > 20%)
          if (data.precipitationPercent >= 20)
            Text(
              '💧${data.precipitationPercent}%',
              style: TextStyle(
                color: Colors.lightBlueAccent.withValues(alpha: 0.85),
                fontSize: 10,
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }
}
