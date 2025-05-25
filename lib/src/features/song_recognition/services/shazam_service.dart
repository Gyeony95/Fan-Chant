import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';

/// ShazamKit을 사용하여 노래를 인식하는 서비스
class ShazamService {
  /// 메서드 채널
  static const MethodChannel _channel = MethodChannel('com.fanchant.shazamkit');

  /// 싱글톤 인스턴스
  static final ShazamService instance = ShazamService._internal();

  /// 녹음 상태 콜백
  Function(String)? onStatusUpdate;

  /// 녹음 진행 상황 콜백 (0.0 ~ 1.0)
  Function(double)? onProgressUpdate;

  /// 녹음 시작 콜백
  Function()? onRecordingStarted;

  /// 녹음 중지 콜백
  Function()? onRecordingStopped;

  /// 비공개 생성자
  ShazamService._internal() {
    _setupMethodCallHandler();
  }

  /// 메서드 콜 핸들러 설정
  void _setupMethodCallHandler() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onRecordingStatus':
          final args = call.arguments as Map<dynamic, dynamic>;
          final message = args['message'] as String;
          onStatusUpdate?.call(message);
          break;
        case 'onRecordingProgress':
          final args = call.arguments as Map<dynamic, dynamic>;
          final progress = args['progress'] as double;
          onProgressUpdate?.call(progress);
          break;
        case 'onRecordingStarted':
          onRecordingStarted?.call();
          break;
        case 'onRecordingStopped':
          onRecordingStopped?.call();
          break;
      }
      return null;
    });
  }

  /// iOS에서만 ShazamKit을 사용 가능한지 확인
  bool get isSupported => Platform.isIOS;

  /// 노래 인식 시작
  Future<Song?> recognizeSong() async {
    // iOS 플랫폼에서만 실행
    if (!isSupported) {
      throw PlatformException(
        code: 'UNSUPPORTED_PLATFORM',
        message: 'ShazamKit은 iOS에서만 사용 가능합니다.',
      );
    }

    try {
      // 네이티브 코드 호출
      final result = await _channel
          .invokeMethod<Map<dynamic, dynamic>>('startRecognition');

      // 결과가 없으면 null 반환
      if (result == null) {
        return null;
      }

      // 결과를 Song 객체로 변환
      return Song(
        id: result['id'] as String? ?? '',
        title: result['title'] as String? ?? '알 수 없는 제목',
        artist: result['artist'] as String? ?? '알 수 없는 아티스트',
        album: result['album'] as String? ?? '알 수 없는 앨범',
        albumCoverUrl: result['albumCoverUrl'] as String? ?? '',
        releaseDate: result['releaseDate'] as String? ?? '',
        hasFanChant: result['hasFanChant'] as bool? ?? false,
      );
    } on PlatformException catch (e) {
      // 인식 실패 시 예외 처리
      print('노래 인식 실패: ${e.message}');
      return null;
    }
  }

  /// 노래 인식 중지
  Future<void> stopRecognition() async {
    if (!isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod('stopRecognition');
    } on PlatformException catch (e) {
      print('인식 중지 실패: ${e.message}');
    }
  }
}
