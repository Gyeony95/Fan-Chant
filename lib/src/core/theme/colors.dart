import 'package:flutter/material.dart';

/// 앱에서 사용되는 색상 테마를 정의합니다.
class AppColors {
  AppColors._();

  /// 주 색상 - #FF4081
  static const Color primary = Color(0xFFFF4081);

  /// 보조 색상 - #7C4DFF
  static const Color secondary = Color(0xFF7C4DFF);

  /// 배경 색상 - White
  static const Color background = Colors.white;

  /// 표면 색상 - Light Grey
  static const Color surface = Color(0xFFF5F5F5);

  /// 오류 색상 - Red
  static const Color error = Color(0xFFD32F2F);

  /// 성공 색상 - Green
  static const Color success = Color(0xFF388E3C);

  /// 경고 색상 - Amber
  static const Color warning = Color(0xFFFFC107);

  /// 정보 색상 - Blue
  static const Color info = Color(0xFF2196F3);

  /// 비활성화 색상 - Grey
  static const Color disabled = Color(0xFFBDBDBD);

  /// 텍스트 색상 - Dark
  static const Color textDark = Color(0xFF212121);

  /// 텍스트 색상 - Medium
  static const Color textMedium = Color(0xFF757575);

  /// 텍스트 색상 - Light
  static const Color textLight = Color(0xFFBDBDBD);
}
