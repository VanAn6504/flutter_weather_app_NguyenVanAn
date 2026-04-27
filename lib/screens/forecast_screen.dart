import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../models/forecast_model.dart';
import '../models/hourly_weather_model.dart';
import '../utils/weather_icons.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WeatherProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A2A4A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dự báo thời tiết',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (wp.weather != null)
              Text(
                wp.weather!.cityName,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF667EEA),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Theo giờ'),
            Tab(text: '5 ngày'),
          ],
        ),
        elevation: 0,
      ),
      body: wp.forecast == null
          ? const Center(
              child: Text(
                'Không có dữ liệu dự báo',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _HourlyTab(wp: wp),
                _DailyTab(wp: wp),
              ],
            ),
    );
  }
}

// Tab Theo Giờ
class _HourlyTab extends StatelessWidget {
  final WeatherProvider wp;
  const _HourlyTab({required this.wp});

  @override
  Widget build(BuildContext context) {
    final hourly = wp.forecast!.hourlyForecasts;

    return ListView.builder(
      padding: const EdgeInsets.all(AppDesign.screenPadding),
      itemCount: hourly.length,
      itemBuilder: (_, i) => _HourlyDetailTile(data: hourly[i], wp: wp),
    );
  }
}

class _HourlyDetailTile extends StatelessWidget {
  final HourlyWeatherModel data;
  final WeatherProvider wp;

  const _HourlyDetailTile({required this.data, required this.wp});

  @override
  Widget build(BuildContext context) {
    final localDt = data.dateTime.toLocal();
    final timeStr =
        DateFormatter.formatTime(localDt, is24Hour: wp.is24HourFormat);
    final emoji = WeatherIconHelper.getWeatherEmoji(
      data.mainCondition.id,
      isDay: data.isDay,
    );
    final temp =
        wp.isCelsius ? data.temperature : data.temperature * 9 / 5 + 32;
    final wind = wp.isKmh ? data.wind.speedKmh : data.wind.speedMph;

    // Group header: khi bắt đầu ngày mới
    final isNewDay = _isFirstHourOfDay(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNewDay) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              DateFormatter.getDayName(localDt),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              // Thời gian
              SizedBox(
                width: 50,
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Icon
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              // Chi tiết
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.mainCondition.description.isNotEmpty
                          ? _cap(data.mainCondition.description)
                          : WeatherIconHelper.getConditionNameVi(
                              data.mainCondition.id),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.water_drop_outlined,
                            size: 11,
                            color:
                                Colors.lightBlueAccent.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text(
                          '${data.humidity}%',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.air_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.4)),
                        const SizedBox(width: 3),
                        Text(
                          '${wind.round()} ${wp.windUnitLabel}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        if (data.precipitationPercent >= 20) ...[
                          const SizedBox(width: 10),
                          Text(
                            '💧 ${data.precipitationPercent}%',
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Nhiệt độ
              Text(
                '${temp.round()}${wp.tempUnitLabel}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isFirstHourOfDay(HourlyWeatherModel data) {
    // Nếu giờ địa phương < 3 → đầu ngày mới
    return data.dateTime.toLocal().hour < 3;
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// Tab 5 Ngày

class _DailyTab extends StatelessWidget {
  final WeatherProvider wp;
  const _DailyTab({required this.wp});

  @override
  Widget build(BuildContext context) {
    final days = wp.forecast!.dailyForecasts;

    if (days.isEmpty) {
      return const Center(
        child: Text(
          'Không có dữ liệu dự báo',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppDesign.screenPadding),
      itemCount: days.length,
      itemBuilder: (_, i) => _DailyDetailCard(day: days[i], wp: wp),
    );
  }
}

class _DailyDetailCard extends StatelessWidget {
  final DailyForecast day;
  final WeatherProvider wp;

  const _DailyDetailCard({required this.day, required this.wp});

  @override
  Widget build(BuildContext context) {
    final condition = day.representativeHour.mainCondition;
    final isDay = day.representativeHour.isDay;
    final emoji = WeatherIconHelper.getWeatherEmoji(condition.id, isDay: isDay);
    final dayName = DateFormatter.getDayName(day.date);
    final fullDate = DateFormatter.formatShortDate(day.date);

    final tempMin = wp.isCelsius ? day.tempMin : day.tempMin * 9 / 5 + 32;
    final tempMax = wp.isCelsius ? day.tempMax : day.tempMax * 9 / 5 + 32;
    final maxWind =
        wp.isKmh ? day.maxWindSpeed * 3.6 : day.maxWindSpeed * 2.237;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Header: Ngày + icon + nhiệt độ
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    fullDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tempMax.round()}°',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${tempMin.round()}°',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Mô tả
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              condition.description.isNotEmpty
                  ? _cap(condition.description)
                  : WeatherIconHelper.getConditionNameVi(condition.id),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Metric(
                icon: Icons.water_drop_outlined,
                label: 'Độ ẩm',
                value: '${day.avgHumidity}%',
              ),
              _Metric(
                icon: Icons.air_rounded,
                label: 'Gió max',
                value: '${maxWind.round()} ${wp.windUnitLabel}',
              ),
              _Metric(
                icon: Icons.umbrella_rounded,
                label: 'Mưa',
                value: '${day.precipitationPercent}%',
                valueColor: day.precipitationPercent >= 50
                    ? Colors.lightBlueAccent
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
