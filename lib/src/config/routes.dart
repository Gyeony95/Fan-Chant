import 'package:flutter/material.dart';
import 'package:fan_chant/src/features/song_detail/screens/song_detail_screen.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';

/// 앱 라우트 관리 클래스
class AppRoutes {
  AppRoutes._();

  /// 노래 상세 화면 경로
  static const String songDetail = '/song-detail';

  /// 노래 인식 실패 화면 경로
  static const String recognitionFailed = '/recognition-failed';

  /// 앱의 라우트 정의
  static Map<String, WidgetBuilder> get routes => {
        recognitionFailed: (context) => const Center(child: Text('인식 실패')),
      };

  /// 노래 상세 화면으로 이동
  static Future<void> navigateToSongDetail(
      BuildContext context, Song song) async {
    Navigator.pushNamed(
      context,
      songDetail,
      arguments: song,
    );
  }

  /// 인식 실패 화면으로 이동
  static Future<void> navigateToRecognitionFailed(BuildContext context) async {
    Navigator.pushNamed(context, recognitionFailed);
  }

  /// 이름 있는 라우트에 대한 라우트 생성자
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case songDetail:
        final song = settings.arguments as Song;
        return MaterialPageRoute(
          builder: (context) => SongDetailScreen(song: song),
          settings: settings,
        );
      default:
        return null;
    }
  }
}
