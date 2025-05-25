import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:flutter_shazam_kit/flutter_shazam_kit.dart';

/// ShazamKit을 사용하여 노래를 인식하는 서비스
class ShazamService {
  /// 싱글톤 인스턴스
  static final ShazamService instance = ShazamService._internal();

  /// Flutter ShazamKit 인스턴스
  final FlutterShazamKit _shazamKit = FlutterShazamKit();

  /// 녹음 상태 콜백
  Function(String)? onStatusUpdate;

  /// 녹음 진행 상황 콜백 (0.0 ~ 1.0)
  Function(double)? onProgressUpdate;

  /// 녹음 시작 콜백
  Function()? onRecordingStarted;

  /// 녹음 중지 콜백
  Function()? onRecordingStopped;

  /// 개발자 토큰 (실제 앱에서는 서버에서 가져오거나 안전하게 저장해야 함)
  String? _developerToken;

  /// 매치 결과
  Song? _matchResult;

  /// 타이머
  Stream<int>? _timerStream;
  StreamSubscription<int>? _timerSubscription;

  /// 비공개 생성자
  ShazamService._internal() {
    _setupShazamKit();
  }

  /// ShazamKit 설정
  void _setupShazamKit() {
    // 매칭 결과 리스너 설정
    _shazamKit.onMatchResultDiscovered((result) {
      // 메인 스레드에서 결과 처리
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (result is Matched) {
          // 매치된 경우
          final mediaItems = result.mediaItems;
          if (mediaItems.isNotEmpty) {
            final mediaItem = mediaItems.first;
            final song = Song(
              id: mediaItem.shazamId ?? '',
              title: mediaItem.title,
              artist: mediaItem.artist,
              album: '알 수 없는 앨범',
              albumCoverUrl: mediaItem.artworkUrl,
              releaseDate: '',
              hasFanChant: true, // 임시 값
            );

            // 노래 정보 반환
            _matchResult = song;
          }
        } else if (result is NoMatch) {
          // 매치 없음
          _matchResult = null;
        }
      });
    });

    // 감지 상태 변경 리스너
    _shazamKit.onDetectStateChanged((state) {
      // 메인 스레드에서 상태 변경 처리
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (state == DetectState.detecting) {
          onRecordingStarted?.call();
        } else if (state == DetectState.none) {
          onRecordingStopped?.call();
        }

        // 상태 메시지 업데이트
        if (state == DetectState.detecting) {
          onStatusUpdate?.call('음악을 인식하는 중...');
        } else if (state == DetectState.none) {
          onStatusUpdate?.call('인식 완료');
        }
      });
    });

    // 오류 리스너
    _shazamKit.onError((error) {
      // 메인 스레드에서 오류 처리
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('ShazamKit 오류: ${error.message}');
        onStatusUpdate?.call('오류: ${error.message}');
      });
    });
  }

  /// 개발자 토큰 설정
  void setDeveloperToken(String token) {
    _developerToken = token;
    _shazamKit.configureShazamKitSession(developerToken: token);
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
      // 이전 결과 초기화
      _matchResult = null;

      // 진행 상황 업데이트 설정
      double progress = 0.0;
      const duration = 15.0; // 15초 인식

      // 진행 상황 타이머
      if (_timerSubscription != null) {
        await _timerSubscription!.cancel();
        _timerSubscription = null;
      }

      _timerStream =
          Stream.periodic(const Duration(seconds: 1), (i) => i).take(15);
      _timerSubscription = _timerStream!.listen((i) {
        progress = (i + 1) / duration;
        onProgressUpdate?.call(progress);

        // 상태 메시지 업데이트
        if (i == 2) {
          onStatusUpdate?.call('음악을 계속 들려주세요...');
        } else if (i == 5) {
          onStatusUpdate?.call('인식 중...');
        } else if (i == 9) {
          onStatusUpdate?.call('조금만 더 들려주세요...');
        }
      });

      // 마이크로 감지 시작
      await _shazamKit.startDetectionWithMicrophone();

      // 15초 후 결과 확인 및 감지 종료
      await Future.delayed(const Duration(seconds: 15));

      // 감지 종료
      await _shazamKit.endDetectionWithMicrophone();

      // 결과 반환
      return _matchResult;
    } on PlatformException catch (e) {
      // 인식 실패 시 예외 처리
      print('노래 인식 실패: ${e.message}');
      await stopRecognition();
      return null;
    }
  }

  /// 노래 인식 중지
  Future<void> stopRecognition() async {
    if (!isSupported) {
      return;
    }

    try {
      await _shazamKit.endDetectionWithMicrophone();
    } on PlatformException catch (e) {
      print('인식 중지 실패: ${e.message}');
    }
  }

  /// 서비스 종료
  void dispose() {
    if (_timerSubscription != null) {
      _timerSubscription!.cancel();
      _timerSubscription = null;
    }
    _shazamKit.endSession();
  }
}
