import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';

part 'song_provider.g.dart';

/// 노래 인식 상태를 관리하는 프로바이더
@riverpod
class SongRecognition extends _$SongRecognition {
  @override
  SongRecognitionState build() {
    return const SongRecognitionState();
  }

  /// 노래 인식 시작
  Future<void> startRecognition() async {
    state = state.copyWith(status: SongRecognitionStatus.recognizing);

    // 실제로는 오디오 인식 API를 호출하지만, 여기서는 지연만 시뮬레이션
    await Future.delayed(const Duration(seconds: 3));

    // 샘플 노래 목록에서 두 번째 노래 (Hype Boy)를 선택하여 인식 성공으로 처리
    final songs = Song.getSampleSongs();
    final recognizedSong = songs[1]; // Hype Boy

    state = state.copyWith(
      status: SongRecognitionStatus.success,
      recognizedSong: recognizedSong,
    );
  }

  /// 노래 인식 취소
  void cancelRecognition() {
    state = state.copyWith(status: SongRecognitionStatus.idle);
  }

  /// 특정 노래 선택
  void selectSong(Song song) {
    state = state.copyWith(
      status: SongRecognitionStatus.success,
      recognizedSong: song,
    );
  }

  /// 최근 인식한 노래 목록에 노래 추가
  void addToRecentSongs(Song song) {
    // 이미 목록에 있는지 확인
    final isAlreadyInList = state.recentSongs.any((s) => s.id == song.id);

    if (!isAlreadyInList) {
      // 최대 5개까지만 유지
      final updatedList = [song, ...state.recentSongs];
      if (updatedList.length > 5) {
        updatedList.removeLast();
      }

      state = state.copyWith(recentSongs: updatedList);
    }
  }

  /// 인식 상태 초기화
  void resetRecognition() {
    state = state.copyWith(
      status: SongRecognitionStatus.idle,
      recognizedSong: null,
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

  const SongRecognitionState({
    this.status = SongRecognitionStatus.idle,
    this.recognizedSong,
    this.recentSongs = const [],
  });

  /// 상태 복사 메서드
  SongRecognitionState copyWith({
    SongRecognitionStatus? status,
    Song? recognizedSong,
    List<Song>? recentSongs,
  }) {
    return SongRecognitionState(
      status: status ?? this.status,
      recognizedSong: recognizedSong ?? this.recognizedSong,
      recentSongs: recentSongs ?? this.recentSongs,
    );
  }
}

/// 모든 노래 목록을 제공하는 프로바이더
@riverpod
List<Song> allSongs(AllSongsRef ref) {
  return Song.getSampleSongs();
}
