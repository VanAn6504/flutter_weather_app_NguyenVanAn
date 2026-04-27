import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../models/forecast_model.dart';
import '../utils/weather_icons.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';

class DailyForecastCard extends StatelessWidget {
  const DailyForecastCard({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();
    final forecast = wp.forecast;
    if (forecast == null) return const SizedBox.shrink();

    final days = forecast.dailyForecasts;
    if (days.isEmpty) return const SizedBox.shrink();

    // Tính nhiệt độ max/min toàn bộ để vẽ thanh tương đối
    final allMax = days.map((d) => d.tempMax).reduce((a, b) => a > b ? a : b);
    final allMin = days.map((d) => d.tempMin).reduce((a, b) => a < b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tiêu đề
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              'DỰ BÁO ${days.length} NGÀY',
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
        // Danh sách ngày
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: days.asMap().entries.map((entry) {
              final isLast = entry.key == days.length - 1;
              return _DailyRow(
                day: entry.value,
                wp: wp,
                globalMax: allMax,
                globalMin: allMin,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyForecast day;
  final WeatherProvider wp;
  final double globalMax;
  final double globalMin;
  final bool isLast;

  const _DailyRow({
    required this.day,
    required this.wp,
    required this.globalMax,
    required this.globalMin,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final condition = day.representativeHour.mainCondition;
    final isDay = day.representativeHour.isDay;
    final emoji = WeatherIconHelper.getWeatherEmoji(condition.id, isDay: isDay);
    final dayName = DateFormatter.getDayName(day.date);

    double tempMin = wp.isCelsius ? day.tempMin : day.tempMin * 9 / 5 + 32;
    double tempMax = wp.isCelsius ? day.tempMax : day.tempMax * 9 / 5 + 32;
    double gMin = wp.isCelsius ? globalMin : globalMin * 9 / 5 + 32;
    double gMax = wp.isCelsius ? globalMax : globalMax * 9 / 5 + 32;

    // Tính vị trí thanh gradient (relative to global range)
    final range = gMax - gMin;
    final barStart = range > 0 ? (tempMin - gMin) / range : 0.0;
    final barEnd = range > 0 ? (tempMax - gMin) / range : 1.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Ngày
              Expanded(
                flex: 3,
                child: Text(
                  dayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Icon + mưa — cố định nhỏ hơn
              SizedBox(
                width: 48,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 18)),
                    if (day.precipitationPercent >= 20) ...[
                      const SizedBox(width: 1),
                      Flexible(
                        child: Text(
                          '${day.precipitationPercent}%',
                          style: const TextStyle(
                            color: Colors.lightBlueAccent,
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Nhiệt độ min
              SizedBox(
                width: 32,
                child: Text(
                  '${tempMin.round()}°',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 6),
              // Thanh nhiệt độ — chiếm phần còn lại
              Expanded(
                flex: 4,
                child: _TempBar(start: barStart, end: barEnd),
              ),
              const SizedBox(width: 6),
              // Nhiệt độ max
              SizedBox(
                width: 32,
                child: Text(
                  '${tempMax.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            color: Colors.white.withValues(alpha: 0.08),
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}

class _TempBar extends StatelessWidget {
  final double start; // 0.0 - 1.0
  final double end; // 0.0 - 1.0

  const _TempBar({required this.start, required this.end});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final leftPad = totalWidth * start;
        final barWidth = totalWidth * (end - start);

        return Stack(
          children: [
            // Track (nền)
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Bar (giá trị)
            Positioned(
              left: leftPad,
              child: Container(
                width: barWidth.clamp(6.0, totalWidth),
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4FC3F7), Color(0xFFFF8A65)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
