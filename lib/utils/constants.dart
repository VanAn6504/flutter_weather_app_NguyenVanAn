import 'package:flutter/material.dart';

// SharedPreferences Keys
class StorageKeys {
  StorageKeys._();

  static const String cachedWeather = 'cached_weather';
  static const String cachedForecast = 'cached_forecast';
  static const String cacheTimestamp = 'cache_timestamp';
  static const String cachedCity = 'cached_city';
  static const String favoriteCities = 'favorite_cities';
  static const String searchHistory = 'search_history';
  static const String tempUnit = 'temp_unit'; // 'celsius' | 'fahrenheit'
  static const String windUnit = 'wind_unit'; // 'kmh' | 'mph'
  static const String timeFormat = 'time_format'; // '12h' | '24h'
  static const String lastLocation = 'last_location';
}

// Weather Theme Colors
class WeatherColors {
  WeatherColors._();

  // Trời nắng
  static const Color sunnyPrimary = Color(0xFFFDB813);
  static const Color sunnyBackground = Color(0xFF87CEEB);
  static const Color sunnyGradientEnd = Color(0xFFFF8C00);

  // Mưa
  static const Color rainyPrimary = Color(0xFF4A5568);
  static const Color rainyBackground = Color(0xFF718096);
  static const Color rainyGradientEnd = Color(0xFF2D3748);

  // Nhiều mây
  static const Color cloudyPrimary = Color(0xFFA0AEC0);
  static const Color cloudyBackground = Color(0xFFCBD5E0);
  static const Color cloudyGradientEnd = Color(0xFF718096);

  // Ban đêm
  static const Color nightPrimary = Color(0xFF2D3748);
  static const Color nightBackground = Color(0xFF1A202C);
  static const Color nightGradientEnd = Color(0xFF0D1117);

  // Tuyết
  static const Color snowPrimary = Color(0xFFE2E8F0);
  static const Color snowBackground = Color(0xFFEBF8FF);

  // Dông bão
  static const Color stormPrimary = Color(0xFF2D3748);
  static const Color stormBackground = Color(0xFF1A202C);
}

// App Design Constants
class AppDesign {
  AppDesign._();

  // Border radius
  static const double cardBorderRadius = 20.0;
  static const double buttonBorderRadius = 12.0;
  static const double chipBorderRadius = 25.0;

  // Elevation
  static const double cardElevation = 4.0;

  // Padding
  static const double screenPadding = 20.0;
  static const double cardPadding = 16.0;
  static const double itemSpacing = 12.0;

  // Font sizes
  static const double tempFontSize = 72.0;
  static const double cityFontSize = 28.0;
  static const double conditionFontSize = 18.0;
  static const double detailFontSize = 14.0;
  static const double labelFontSize = 12.0;
}

// App Theme
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF667EEA),
          secondary: Color(0xFF764BA2),
          surface: Color(0xFF1E2A3A),
          error: Color(0xFFFF6B6B),
        ),
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: AppDesign.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.cardBorderRadius),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDesign.buttonBorderRadius),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIconColor: Colors.white70,
          suffixIconColor: Colors.white70,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
          displayMedium:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          headlineMedium:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          labelMedium: TextStyle(color: Colors.white60),
        ),
      );
}
