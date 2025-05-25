import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_recognition/services/shazam_service.dart';
import 'package:fan_chant/src/features/song_recognition/services/song_storage_service.dart';
import 'package:fan_chant/src/features/song_recognition/services/lyrics_service.dart';

part 'song_provider.g.dart';

/// 노래 인식 상태를 관리하는 프로바이더
@riverpod
class SongRecognition extends _$SongRecognition {
  late SongStorageService _storageService;

  @override
  SongRecognitionState build() {
    // 서비스 초기화
    _storageService = SongStorageService();

    // 서비스 콜백 설정
    _setupShazamServiceCallbacks();

    // 최근 인식한 노래 목록 로드
    final recentSongs = _storageService.getRecentSongs();

    return SongRecognitionState(
      recentSongs: recentSongs,
    );
  }

  /// ShazamService 콜백 설정
  void _setupShazamServiceCallbacks() {
    final shazamService = ShazamService.instance;

    // 상태 메시지 업데이트
    shazamService.onStatusUpdate = (message) {
      state = state.copyWith(statusMessage: message);
    };

    // 진행 상황 업데이트
    shazamService.onProgressUpdate = (progress) {
      state = state.copyWith(recognitionProgress: progress);
    };

    // 녹음 시작
    shazamService.onRecordingStarted = () {
      state = state.copyWith(
        status: SongRecognitionStatus.recognizing,
        statusMessage: '노래를 인식하는 중...',
        recognitionProgress: 0.0,
      );
    };

    // 녹음 중지
    shazamService.onRecordingStopped = () {
      // 이미 성공 또는 실패 상태가 아니면 대기 상태로 변경
      if (state.status == SongRecognitionStatus.recognizing) {
        state = state.copyWith(
          status: SongRecognitionStatus.idle,
          statusMessage: null,
          recognitionProgress: 0.0,
        );
      }
    };
  }

  /// 노래 인식 시작
  Future<void> startRecognition() async {
    state = state.copyWith(
      status: SongRecognitionStatus.recognizing,
      statusMessage: '노래 듣는 중...',
      recognitionProgress: 0.0,
    );

    try {
      // iOS에서는 ShazamKit 사용
      if (Platform.isIOS) {
        final song = await ShazamService.instance.recognizeSong();

        if (song != null) {
          state = state.copyWith(
            status: SongRecognitionStatus.success,
            recognizedSong: song,
            statusMessage: '인식 성공!',
          );
        } else {
          state = state.copyWith(
            status: SongRecognitionStatus.failure,
            statusMessage: '인식 실패. 다시 시도해주세요.',
          );
        }
      }
      // iOS가 아닌 경우 테스트 데이터 사용 (시뮬레이션)
      else {
        // 프로그레스 시뮬레이션 (0.0 ~ 1.0)
        for (int i = 1; i <= 5; i++) {
          if (state.status != SongRecognitionStatus.recognizing) {
            // 사용자가 도중에 취소한 경우
            break;
          }

          // 진행 상태 업데이트
          state = state.copyWith(
            recognitionProgress: i / 5,
            statusMessage: i <= 2
                ? '음악을 들어보는 중...'
                : i <= 4
                    ? '인식 중...'
                    : '거의 완료되었습니다...',
          );

          // 잠시 대기
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // 테스트용 Celebrity 노래 정보 로드
        final recognizedSong =
            await LyricsService.instance.loadSongByAppleMusicId('1560113348');

        if (recognizedSong != null) {
          state = state.copyWith(
            status: SongRecognitionStatus.success,
            recognizedSong: recognizedSong,
            statusMessage: '인식 성공!',
            recognitionProgress: 1.0,
          );
        } else {
          state = state.copyWith(
            status: SongRecognitionStatus.failure,
            statusMessage: '인식 실패. 다시 시도해주세요.',
          );
        }
      }
    } catch (e) {
      print('노래 인식 오류: $e');
      state = state.copyWith(
        status: SongRecognitionStatus.failure,
        statusMessage: '인식 오류: $e',
      );
    }
  }

  /// 노래 인식 취소
  void cancelRecognition() {
    if (Platform.isIOS) {
      ShazamService.instance.stopRecognition();
    }

    state = state.copyWith(
      status: SongRecognitionStatus.idle,
      statusMessage: null,
      recognitionProgress: 0.0,
    );
  }

  /// 특정 노래 선택
  void selectSong(Song song) {
    state = state.copyWith(
      status: SongRecognitionStatus.success,
      recognizedSong: song,
    );
  }

  /// 최근 인식한 노래 목록에 노래 추가
  Future<void> addToRecentSongs(Song song) async {
    // 노래를 저장소에 추가
    await _storageService.addRecentSong(song);

    // 최근 인식한 노래 목록 갱신
    final updatedRecentSongs = _storageService.getRecentSongs();

    state = state.copyWith(recentSongs: updatedRecentSongs);
  }

  /// 최근 인식한 노래 목록 새로고침
  Future<void> refreshRecentSongs() async {
    // 최근 인식한 노래 목록 다시 로드
    final updatedRecentSongs = _storageService.getRecentSongs();

    state = state.copyWith(recentSongs: updatedRecentSongs);
  }

  /// 노래 찜하기 토글
  Future<void> toggleFavorite(Song song) async {
    await _storageService.toggleFavorite(song);

    // 최근 인식한 노래 목록 갱신 (찜 상태가 변경되었을 수 있음)
    final updatedRecentSongs = _storageService.getRecentSongs();

    state = state.copyWith(recentSongs: updatedRecentSongs);

    // 현재 인식된 노래라면 상태 업데이트
    if (state.recognizedSong?.id == song.id) {
      final updatedSong = updatedRecentSongs.firstWhere(
        (s) => s.id == song.id,
        orElse: () => song..toggleFavorite(), // 목록에 없으면 직접 토글
      );

      state = state.copyWith(recognizedSong: updatedSong);
    }

    // 찜 상태가 변경되었음을 알리기 위해 상태 변경 이벤트 발생
    ref.invalidateSelf();
  }

  /// 찜한 노래 목록 가져오기
  List<Song> getFavoriteSongs() {
    return _storageService.getFavoriteSongs();
  }

  /// 노래가 찜 목록에 있는지 확인
  bool isFavorite(String songId) {
    return _storageService.isFavorite(songId);
  }

  /// 최근 인식한 노래 목록 초기화
  Future<void> clearRecentSongs() async {
    await _storageService.clearRecentSongs();
    state = state.copyWith(recentSongs: []);
  }

  /// 인식 상태 초기화
  void resetRecognition() {
    state = state.copyWith(
      status: SongRecognitionStatus.idle,
      recognizedSong: null,
      statusMessage: null,
      recognitionProgress: 0.0,
    );
  }
}

/// 노래 인식 상태 열거형
enum SongRecognitionStatus {
  /// 대기 상태
  idle,

  /// 인식 중
  recognizing,

  /// 인식 성공
  success,

  /// 인식 실패
  failure,
}

/// 노래 인식 상태 클래스
class SongRecognitionState {
  /// 현재 인식 상태
  final SongRecognitionStatus status;

  /// 인식된 노래
  final Song? recognizedSong;

  /// 최근 인식한 노래 목록
  final List<Song> recentSongs;

  /// 인식 진행 상태 메시지
  final String? statusMessage;

  /// 인식 진행률 (0.0 ~ 1.0)
  final double recognitionProgress;

  const SongRecognitionState({
    this.status = SongRecognitionStatus.idle,
    this.recognizedSong,
    this.recentSongs = const [],
    this.statusMessage,
    this.recognitionProgress = 0.0,
  });

  /// 상태 복사 메서드
  SongRecognitionState copyWith({
    SongRecognitionStatus? status,
    Song? recognizedSong,
    List<Song>? recentSongs,
    String? statusMessage,
    double? recognitionProgress,
  }) {
    return SongRecognitionState(
      status: status ?? this.status,
      recognizedSong: recognizedSong ?? this.recognizedSong,
      recentSongs: recentSongs ?? this.recentSongs,
      statusMessage: statusMessage, // null 값도 허용
      recognitionProgress: recognitionProgress ?? this.recognitionProgress,
    );
  }
}

/// 모든 노래 목록을 제공하는 프로바이더
@riverpod
Future<List<Song>> allSongs(AllSongsRef ref) async {
  // 가사 서비스로부터 이용 가능한 모든 노래 ID 가져오기
  final lyricsIds = await LyricsService.instance.getAllAvailableLyricsIds();
  final songs = <Song>[];

  // 각 ID에 해당하는 노래 정보 로드
  for (final id in lyricsIds) {
    final song = await LyricsService.instance.loadSongByAppleMusicId(id);
    if (song != null) {
      songs.add(song);
    }
  }

  return songs;
}

/// 찜한 노래 목록을 제공하는 프로바이더
@riverpod
List<Song> favoriteSongs(Ref ref) {
  // songRecognitionProvider 상태가 변경될 때마다 다시 계산
  ref.watch(songRecognitionProvider);

  // notifier에서 직접 찜 목록 가져오기
  final songRecognition = ref.read(songRecognitionProvider.notifier);
  return songRecognition.getFavoriteSongs();
}
