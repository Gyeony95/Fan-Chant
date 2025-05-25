import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/config/routes.dart';
import 'package:fan_chant/src/core/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Google Fonts 초기화
  await GoogleFonts.pendingFonts([
    GoogleFonts.notoSans(),
    GoogleFonts.pacifico(),
  ]);

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
