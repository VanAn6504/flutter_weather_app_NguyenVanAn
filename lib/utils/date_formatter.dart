import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  // Time Formatting
  static String formatTime(DateTime dateTime, {bool is24Hour = true}) {
    if (is24Hour) {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }

  static String formatTimeFromUnix(int unixTimestamp, {bool is24Hour = true}) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    return formatTime(dateTime, is24Hour: is24Hour);
  }

  // Date Formatting
  static String formatFullDate(DateTime dateTime) {
    final weekday = _getVietnameseWeekday(dateTime.weekday);
    final month = _getVietnameseMonth(dateTime.month);
    return '$weekday, ${dateTime.day} $month ${dateTime.year}';
  }

  static String formatShortDate(DateTime dateTime) {
    final weekday = _getShortVietnameseWeekday(dateTime.weekday);
    return '$weekday, ${dateTime.day}/${dateTime.month}';
  }

  static String formatDateTime(DateTime dateTime, {bool is24Hour = true}) {
    final date = DateFormat('dd/MM/yyyy').format(dateTime);
    final time = formatTime(dateTime, is24Hour: is24Hour);
    return '$date $time';
  }

  static String formatFullDateFromUnix(int unixTimestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    return formatFullDate(dateTime);
  }

  static String getDayName(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (target == today) return 'Hôm nay';
    if (target == today.add(const Duration(days: 1))) return 'Ngày mai';
    return _getShortVietnameseWeekday(dateTime.weekday);
  }

  static String getDayNameFromUnix(int unixTimestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    return getDayName(dateTime);
  }

  // Cache Time
  static String getTimeAgo(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inMinutes < 1) return 'Vừa cập nhật';
    if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
    if (difference.inHours < 24) return '${difference.inHours} giờ trước';
    return '${difference.inDays} ngày trước';
  }

  static bool isDaytime(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= 6 && hour < 18;
  }

  static bool isDaytimeFromUnix(int unixTimestamp) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    return isDaytime(dateTime);
  }

  // Private Helpers
  static String _getVietnameseWeekday(int weekday) {
    const weekdays = {
      1: 'Thứ Hai',
      2: 'Thứ Ba',
      3: 'Thứ Tư',
      4: 'Thứ Năm',
      5: 'Thứ Sáu',
      6: 'Thứ Bảy',
      7: 'Chủ Nhật',
    };
    return weekdays[weekday] ?? '';
  }

  static String _getShortVietnameseWeekday(int weekday) {
    const weekdays = {
      1: 'T2',
      2: 'T3',
      3: 'T4',
      4: 'T5',
      5: 'T6',
      6: 'T7',
      7: 'CN',
    };
    return weekdays[weekday] ?? '';
  }

  static String _getVietnameseMonth(int month) {
    const months = {
      1: 'Tháng 1',
      2: 'Tháng 2',
      3: 'Tháng 3',
      4: 'Tháng 4',
      5: 'Tháng 5',
      6: 'Tháng 6',
      7: 'Tháng 7',
      8: 'Tháng 8',
      9: 'Tháng 9',
      10: 'Tháng 10',
      11: 'Tháng 11',
      12: 'Tháng 12',
    };
    return months[month] ?? '';
  }
}
