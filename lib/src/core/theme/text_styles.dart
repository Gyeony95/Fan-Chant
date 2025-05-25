import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fan_chant/src/core/theme/colors.dart';

/// 앱에서 사용되는 텍스트 스타일을 정의합니다.
class AppTextStyles {
  AppTextStyles._();

  /// 로고 텍스트 스타일
  static final TextStyle logo = GoogleFonts.pacifico(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.primary,
    letterSpacing: 0.5,
  );

  /// 제목 텍스트 스타일
  static final TextStyle title = GoogleFonts.notoSans(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    height: 1.3,
  );

  /// 서브타이틀 텍스트 스타일
  static final TextStyle subtitle = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    height: 1.3,
  );

  /// 본문 텍스트 스타일
  static final TextStyle body = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black,
    height: 1.5,
  );

  /// 작은 본문 텍스트 스타일
  static final TextStyle bodySmallCustom = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.black87,
    height: 1.5,
  );

  /// 라벨 텍스트 스타일
  static final TextStyle label = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.black,
    letterSpacing: 0.5,
    height: 1.2,
  );

  /// 아티스트 가사 텍스트 스타일
  static final TextStyle artistLyrics = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    height: 1.5,
  );

  /// 팬 가사 텍스트 스타일
  static final TextStyle fanLyrics = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
    height: 1.5,
  );

  /// 강조 가사 텍스트 스타일
  static final TextStyle highlightedLyrics = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.5,
  );

  /// 버튼 텍스트 스타일
  static final TextStyle button = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.2,
  );

  // Material 3 Text Styles
  static final TextStyle displayLarge = GoogleFonts.notoSans(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static final TextStyle displayMedium = GoogleFonts.notoSans(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static final TextStyle displaySmall = GoogleFonts.notoSans(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  static final TextStyle headlineLarge = GoogleFonts.notoSans(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  static final TextStyle headlineMedium = GoogleFonts.notoSans(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );

  static final TextStyle headlineSmall = GoogleFonts.notoSans(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  static final TextStyle titleLarge = GoogleFonts.notoSans(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );

  static final TextStyle titleMedium = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static final TextStyle titleSmall = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static final TextStyle bodyLarge = GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static final TextStyle bodyMedium = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static final TextStyle bodySmall = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  static final TextStyle labelLarge = GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static final TextStyle labelMedium = GoogleFonts.notoSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static final TextStyle labelSmall = GoogleFonts.notoSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );
}
