import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/weather_provider.dart';
import 'providers/location_provider.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi gọi các plugin
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Chỉ cho phép xoay dọc
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cấu hình thanh trạng thái trong suốt
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // LocationProvider: Quản lý vị trí GPS và quyền truy cập
        ChangeNotifierProvider(
          create: (_) => LocationProvider(),
        ),
        // WeatherProvider: Quản lý dữ liệu thời tiết, cache, trạng thái
        ChangeNotifierProvider(
          create: (_) => WeatherProvider(),
        ),
      ],
      child: MaterialApp(
        // App Metadata
        title: 'Weather App - Thời Tiết',
        debugShowCheckedModeBanner: false,

        // Theme
        theme: AppTheme.darkTheme,

        // Home Screen
        home: const _AppInitializer(),

        // Builder
        // Bọc thêm để xử lý text scaling
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // Giới hạn text scale factor để UI không bị vỡ
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
              ),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

class _AppInitializer extends StatefulWidget {
  const _AppInitializer();

  @override
  State<_AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<_AppInitializer> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Khởi tạo cả 2 providers (thứ tự: location trước, weather sau)
    final locationProvider = context.read<LocationProvider>();
    final weatherProvider = context.read<WeatherProvider>();

    await locationProvider.initialize();
    await weatherProvider.initialize();

    // Nếu đã có vị trí cached → fetch thời tiết ngay
    final lastLocation = locationProvider.selectedLocation;
    if (lastLocation != null) {
      await weatherProvider.fetchByLocation(lastLocation);
    } else {
      // Chưa có vị trí → thử lấy GPS (timeout 15 giây)
      await locationProvider.fetchCurrentLocation();
      final loc = locationProvider.selectedLocation;
      if (loc != null) {
        // GPS thành công
        await weatherProvider.fetchByLocation(loc);
      } else {
        // GPS thất bại (timeout / từ chối quyền / emulator không có GPS)
        // Fallback: fetch thời tiết thành phố mặc định để app vẫn hiển thị data
        await weatherProvider.fetchByCity('Ho Chi Minh City');
      }
    }

    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Màn hình splash đơn giản trong khi khởi tạo
      return const Scaffold(
        backgroundColor: Color(0xFF1A202C),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🌤️', style: TextStyle(fontSize: 64)),
              SizedBox(height: 24),
              Text(
                'Đang khởi tạo...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontFamily: 'Roboto',
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(
                color: Color(0xFF667EEA),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      );
    }

    return const HomeScreen();
  }
}
