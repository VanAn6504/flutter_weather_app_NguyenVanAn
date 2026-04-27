import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/weather_provider.dart';
import '../providers/location_provider.dart';
import '../utils/constants.dart';
import '../utils/date_formatter.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A2A4A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        title: const Text(
          'Cài đặt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
        ),
        elevation: 0,
      ),
      body: Consumer<WeatherProvider>(
        builder: (context, wp, _) => ListView(
          padding: const EdgeInsets.all(AppDesign.screenPadding),
          children: [
            // Đơn vị đo
            const _SectionTitle(title: '📐 Đơn vị đo'),
            const SizedBox(height: 12),
            _SegmentedSetting(
              label: 'Nhiệt độ',
              icon: Icons.thermostat_rounded,
              options: const ['°C', '°F'],
              selectedIndex: wp.isCelsius ? 0 : 1,
              onChanged: (i) =>
                  wp.setTemperatureUnit(i == 0 ? 'celsius' : 'fahrenheit'),
            ),
            const SizedBox(height: 12),
            _SegmentedSetting(
              label: 'Tốc độ gió',
              icon: Icons.air_rounded,
              options: const ['km/h', 'mph'],
              selectedIndex: wp.isKmh ? 0 : 1,
              onChanged: (i) => wp.setWindUnit(i == 0 ? 'kmh' : 'mph'),
            ),
            const SizedBox(height: 12),
            _SegmentedSetting(
              label: 'Định dạng giờ',
              icon: Icons.schedule_rounded,
              options: const ['24 giờ', '12 giờ'],
              selectedIndex: wp.is24HourFormat ? 0 : 1,
              onChanged: (i) => wp.setTimeFormat(i == 0 ? '24h' : '12h'),
            ),
            const SizedBox(height: 28),

            // Vị trí
            const _SectionTitle(title: '📍 Vị trí'),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.my_location_rounded,
              label: 'Dùng vị trí hiện tại',
              subtitle: 'Cập nhật thời tiết theo GPS',
              onTap: () async {
                final lp = context.read<LocationProvider>();
                await lp.fetchCurrentLocation();
                if (lp.hasLocation) {
                  await wp.fetchByLocation(lp.selectedLocation!);
                }
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 28),

            // Cache
            const _SectionTitle(title: '💾 Dữ liệu & Cache'),
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.cached_rounded,
              label: 'Cache thời tiết',
              value: wp.isCacheValid
                  ? 'Còn hiệu lực'
                  : wp.lastCacheTime != null
                      ? 'Hết hạn'
                      : 'Chưa có',
              valueColor: wp.isCacheValid ? Colors.greenAccent : Colors.orange,
            ),
            if (wp.lastCacheTime != null) ...[
              const SizedBox(height: 8),
              _InfoTile(
                icon: Icons.update_rounded,
                label: 'Cập nhật lần cuối',
                value: DateFormatter.getTimeAgo(wp.lastCacheTime!),
              ),
            ],
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.delete_outline_rounded,
              label: 'Xóa cache',
              subtitle: 'Buộc tải lại dữ liệu từ server',
              iconColor: Colors.redAccent,
              onTap: () async {
                await wp.clearCache();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    _buildSnackBar('Đã xóa cache thành công'),
                  );
                }
              },
            ),
            const SizedBox(height: 28),

            // Thông tin
            const _SectionTitle(title: 'ℹ️ Thông tin'),
            const SizedBox(height: 12),
            const _InfoTile(
              icon: Icons.info_outline_rounded,
              label: 'Phiên bản',
              value: '1.0.0',
            ),
            const SizedBox(height: 8),
            const _InfoTile(
              icon: Icons.cloud_rounded,
              label: 'Nguồn dữ liệu',
              value: 'OpenWeatherMap',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  SnackBar _buildSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF2D3748),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

// Helper Widgets

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SegmentedSetting extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedSetting({
    required this.label,
    required this.icon,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          // Segmented control
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: options.asMap().entries.map((entry) {
                final isSelected = entry.key == selectedIndex;
                return GestureDetector(
                  onTap: () => onChanged(entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    height: 34,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF667EEA)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white54,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
