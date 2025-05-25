import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/config/routes.dart';
import 'package:fan_chant/src/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fan_chant/src/config/shazam_config.dart';
import 'package:fan_chant/src/features/song_recognition/services/shazam_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Fonts 초기화
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoSans(),
    GoogleFonts.pacifico(),
  ]);

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
      initialRoute: AppRoutes.recognition,
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
      });
    }
  }
}
