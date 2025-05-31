import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:flutter_shazam_kit/flutter_shazam_kit.dart';
import 'package:fan_chant/src/features/song_recognition/services/lyrics_service.dart';

/// ShazamKit을 사용하여 노래를 인식하는 서비스
class ShazamService {
  /// 싱글톤 인스턴스
  static final ShazamService instance = ShazamService._internal();

  /// Flutter ShazamKit 인스턴스
  final FlutterShazamKit _shazamKit = FlutterShazamKit();

  /// 가사 서비스
  final LyricsService _lyricsService = LyricsService.instance;

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
    _shazamKit.onMatchResultDiscovered((result) async {
      // 메인 스레드에서 결과 처리
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (result is Matched) {
          // 매치된 경우
          final mediaItems = result.mediaItems;
          if (mediaItems.isNotEmpty) {
            final mediaItem = mediaItems.first;

            // Apple Music ID 가져오기
            final appleMusicId =
                _getAppleMusicIdFromUrl(mediaItem.appleMusicUrl);

            // 가사 정보가 있는지 확인
            Song? songWithLyrics;
            if (appleMusicId != null) {
              // 가사 정보 로드 시도
              songWithLyrics =
                  await _lyricsService.loadSongByAppleMusicId(appleMusicId);
            }

            // 가사 정보가 있으면 해당 정보 사용, 없으면 기본 정보 사용
            if (songWithLyrics != null) {
              _matchResult = songWithLyrics;
            } else {
              // 기본 정보로 Song 객체 생성
              final song = Song(
                id: mediaItem.shazamId ?? '',
                title: mediaItem.title,
                artist: mediaItem.artist,
                album: mediaItem.subtitle ?? '알 수 없는 앨범',
                albumCoverUrl: mediaItem.artworkUrl,
                releaseDate: '',
                hasFanChant: false, // 가사 정보가 없으므로 false
                appleMusicId: appleMusicId, // Apple Music ID 저장
              );

              // 노래 정보 반환
              _matchResult = song;
            }
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

  /// Apple Music URL에서 ID 추출
  String? _getAppleMusicIdFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    try {
      // URL 형식: https://music.apple.com/kr/album/celebrity/1560113132?i=1560113348
      // 또는: https://music.apple.com/album/celebrity/1560113132?i=1560113348
      // i= 다음의 숫자가 appleMusicId

      final uri = Uri.parse(url);
      final iParam = uri.queryParameters['i'];

      if (iParam != null && iParam.isNotEmpty) {
        return iParam;
      }

      // 다른 형식일 경우 URL의 마지막 경로 부분 추출
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        final lastSegment = pathSegments.last;
        if (lastSegment.isNotEmpty && int.tryParse(lastSegment) != null) {
          return lastSegment;
        }
      }

      return null;
    } catch (e) {
      print('Apple Music ID 추출 오류: $e');
      return null;
    }
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

      // 인식 완료 컴플리터 - 노래가 인식되면 완료
      final completer = Completer<Song?>();

      // 매치 결과 리스너 설정 (새로운 리스너)
      resultListener(result) async {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (result is Matched) {
            final mediaItems = result.mediaItems;
            if (mediaItems.isNotEmpty) {
              final mediaItem = mediaItems.first;
              debugPrint('artworkUrl : ${mediaItem.artworkUrl}');
              debugPrint('title : ${mediaItem.title}');
              // Apple Music ID 가져오기
              final appleMusicId =
                  _getAppleMusicIdFromUrl(mediaItem.appleMusicUrl);

              // 가사 정보가 있는지 확인
              Song? songWithLyrics;
              if (appleMusicId != null) {
                // 가사 정보 로드 시도
                songWithLyrics =
                    await _lyricsService.loadSongByAppleMusicId(appleMusicId);
              }

              // 가사 정보가 있으면 해당 정보 사용, 없으면 기본 정보 사용
              if (songWithLyrics != null) {
                _matchResult = songWithLyrics;
              } else {
                // 기본 정보로 Song 객체 생성
                final song = Song(
                  id: mediaItem.shazamId ?? '',
                  title: mediaItem.title,
                  artist: mediaItem.artist,
                  album: mediaItem.subtitle ?? '알 수 없는 앨범',
                  albumCoverUrl: mediaItem.artworkUrl,
                  releaseDate: '',
                  hasFanChant: false, // 가사 정보가 없으므로 false
                  appleMusicId: appleMusicId, // Apple Music ID 저장
                );
                // 노래 정보 설정
                _matchResult = song;
              }

              // 인식이 완료되었으므로 즉시 종료 처리
              if (!completer.isCompleted) {
                completer.complete(_matchResult);
              }
            }
          } else if (result is NoMatch && !completer.isCompleted) {
            // 15초가 지난 후 매치가 없으면 자동으로 null 반환됨 (처리하지 않음)
          }
        });
      }

      // 임시 리스너 등록
      _shazamKit.onMatchResultDiscovered(resultListener);

      // 진행 상황 업데이트 설정
      double progress = 0.0;
      const maxDuration = 15.0; // 최대 15초 인식

      // 진행 상황 타이머
      if (_timerSubscription != null) {
        await _timerSubscription!.cancel();
        _timerSubscription = null;
      }

      _timerStream =
          Stream.periodic(const Duration(seconds: 1), (i) => i).take(15);
      _timerSubscription = _timerStream!.listen((i) {
        progress = (i + 1) / maxDuration;
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

      // 타임아웃 설정 (15초)
      Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          completer.complete(_matchResult);
        }
      });

      // 결과 기다리기 (최대 15초 또는 인식 완료까지)
      final result = await completer.future;

      // 타이머 취소
      if (_timerSubscription != null) {
        await _timerSubscription!.cancel();
        _timerSubscription = null;
      }

      // 감지 종료
      await _shazamKit.endDetectionWithMicrophone();

      // 원래 리스너 복구
      _setupShazamKit();

      // 결과 반환
      return result;
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
