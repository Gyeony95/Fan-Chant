import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/config/routes.dart';
import 'package:fan_chant/src/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fan_chant/src/config/shazam_config.dart';
import 'package:fan_chant/src/features/song_recognition/services/shazam_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_recognition/services/song_storage_service.dart';
import 'package:fan_chant/src/features/home/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Fonts 초기화
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoSans(),
    GoogleFonts.pacifico(),
  ]);

  // Hive 초기화
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  // Hive 어댑터 등록
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(LyricLineAdapter());
  Hive.registerAdapter(LyricTypeAdapter());

  // 저장소 서비스 초기화
  await SongStorageService().init();

  // ShazamKit 초기화 (iOS에서만 동작)
  if (ShazamService.instance.isSupported) {
    ShazamService.instance.setDeveloperToken(ShazamConfig.developerToken);
  }

  // 앱 라이프사이클 옵저버 등록
  final observer = AppLifecycleObserver();
  WidgetsBinding.instance.addObserver(observer);

  runApp(
    const ProviderScope(
      child: FanChantApp(),
    ),
  );
}

/// 앱의 루트 위젯
class FanChantApp extends StatelessWidget {
  /// 생성자
  const FanChantApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FanChant',
      theme: AppTheme.lightTheme,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// 앱 종료 시 자원 정리
class AppLifecycleObserver extends WidgetsBindingObserver {
  bool _disposed = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached && !_disposed) {
      // 앱 종료 시 ShazamService 자원 정리
      _disposed = true;
      // 메인 스레드에서 dispose 호출
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShazamService.instance.dispose();
        // Hive 닫기
        Hive.close();
      });
    }
  }
}
