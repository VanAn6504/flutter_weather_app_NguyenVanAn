import 'package:flutter/material.dart';
import 'constants.dart';

class WeatherIconHelper {
  WeatherIconHelper._();

  // Weather Condition Groups
  static bool isThunderstorm(int id) => id >= 200 && id < 300;

  static bool isDrizzle(int id) => id >= 300 && id < 400;

  static bool isRain(int id) => id >= 500 && id < 600;

  static bool isSnow(int id) => id >= 600 && id < 700;

  static bool isAtmosphere(int id) => id >= 700 && id < 800;

  static bool isClear(int id) => id == 800;

  static bool isCloudy(int id) => id >= 801 && id < 900;

  // Emoji Icons
  static String getWeatherEmoji(int weatherId, {bool isDay = true}) {
    if (isThunderstorm(weatherId)) return '⛈️';
    if (isDrizzle(weatherId)) return '🌦️';
    if (isRain(weatherId)) {
      if (weatherId == 511) return '🌨️'; // Freezing rain
      return '🌧️';
    }
    if (isSnow(weatherId)) return '❄️';
    if (isAtmosphere(weatherId)) {
      if (weatherId == 781) return '🌪️'; // Tornado
      return '🌫️';
    }
    if (isClear(weatherId)) return isDay ? '☀️' : '🌙';
    if (isCloudy(weatherId)) {
      if (weatherId == 801) return isDay ? '🌤️' : '☁️'; // Few clouds
      if (weatherId == 802) return '⛅'; // Scattered clouds
      return '☁️';
    }
    return '🌡️';
  }

  // Material Icons
  static IconData getWeatherIcon(int weatherId, {bool isDay = true}) {
    if (isThunderstorm(weatherId)) return Icons.thunderstorm;
    if (isDrizzle(weatherId) || isRain(weatherId)) return Icons.grain;
    if (isSnow(weatherId)) return Icons.ac_unit;
    if (isAtmosphere(weatherId)) return Icons.blur_on;
    if (isClear(weatherId)) {
      return isDay ? Icons.wb_sunny : Icons.nightlight_round;
    }
    if (isCloudy(weatherId)) return Icons.cloud;
    return Icons.device_thermostat;
  }

  // Colors & Gradients
  static LinearGradient getWeatherGradient(int weatherId, {bool isDay = true}) {
    if (!isDay) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [WeatherColors.nightBackground, WeatherColors.nightGradientEnd],
      );
    }

    if (isThunderstorm(weatherId)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [WeatherColors.stormBackground, WeatherColors.stormPrimary],
      );
    }

    if (isDrizzle(weatherId) || isRain(weatherId)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [WeatherColors.rainyBackground, WeatherColors.rainyGradientEnd],
      );
    }

    if (isSnow(weatherId)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [WeatherColors.snowBackground, WeatherColors.cloudyBackground],
      );
    }

    if (isAtmosphere(weatherId)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          WeatherColors.cloudyBackground,
          WeatherColors.cloudyGradientEnd
        ],
      );
    }

    if (isClear(weatherId)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [WeatherColors.sunnyBackground, WeatherColors.sunnyPrimary],
      );
    }

    if (isCloudy(weatherId)) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          WeatherColors.cloudyBackground,
          WeatherColors.cloudyGradientEnd
        ],
      );
    }

    // Default gradient
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    );
  }

  static Color getPrimaryColor(int weatherId, {bool isDay = true}) {
    if (!isDay) return WeatherColors.nightPrimary;
    if (isThunderstorm(weatherId)) return WeatherColors.stormPrimary;
    if (isDrizzle(weatherId) || isRain(weatherId))
      return WeatherColors.rainyPrimary;
    if (isSnow(weatherId)) return WeatherColors.snowPrimary;
    if (isAtmosphere(weatherId)) return WeatherColors.cloudyPrimary;
    if (isClear(weatherId)) return WeatherColors.sunnyPrimary;
    if (isCloudy(weatherId)) return WeatherColors.cloudyPrimary;
    return const Color(0xFF667EEA);
  }

  static String getConditionNameVi(int weatherId) {
    if (isThunderstorm(weatherId)) return 'Dông bão';
    if (isDrizzle(weatherId)) return 'Mưa phùn';
    if (isRain(weatherId)) return 'Mưa';
    if (isSnow(weatherId)) return 'Tuyết';
    if (weatherId == 701) return 'Sương mù nhẹ';
    if (weatherId == 711) return 'Khói';
    if (weatherId == 721) return 'Sương mù';
    if (weatherId == 731 || weatherId == 761) return 'Bụi';
    if (weatherId == 741) return 'Sương dày';
    if (weatherId == 751) return 'Cát bụi';
    if (weatherId == 762) return 'Tro núi lửa';
    if (weatherId == 771) return 'Gió giật mạnh';
    if (weatherId == 781) return 'Lốc xoáy';
    if (isClear(weatherId)) return 'Trời quang';
    if (weatherId == 801) return 'Ít mây';
    if (weatherId == 802) return 'Nhiều mây';
    if (weatherId == 803) return 'Trời nhiều mây';
    if (weatherId == 804) return 'Trời âm u';
    return 'Không xác định';
  }
}
