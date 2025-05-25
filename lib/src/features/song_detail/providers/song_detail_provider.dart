import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';

part 'song_detail_provider.g.dart';

/// 현재 선택된 노래를 관리하는 프로바이더
@riverpod
class CurrentSong extends _$CurrentSong {
  @override
  Song? build() {
    return null;
  }

  /// 현재 노래 설정
  void setCurrentSong(Song song) {
    state = song;
  }
}

/// 현재 재생 상태를 관리하는 프로바이더
@riverpod
class PlaybackState extends _$PlaybackState {
  @override
  PlaybackStateModel build() {
    return const PlaybackStateModel();
  }

  /// 재생/일시정지 토글
  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  /// 재생 시작
  void play() {
    state = state.copyWith(isPlaying: true);
  }

  /// 일시정지
  void pause() {
    state = state.copyWith(isPlaying: false);
  }

  /// 현재 재생 위치 업데이트
  void updatePosition(Duration position) {
    state = state.copyWith(currentPosition: position);
  }

  /// 총 재생 시간 설정
  void setDuration(Duration duration) {
    state = state.copyWith(totalDuration: duration);
  }

  /// 특정 위치로 이동
  void seekTo(Duration position) {
    state = state.copyWith(currentPosition: position);
  }
}

/// 재생 상태 모델
class PlaybackStateModel {
  /// 재생 중 여부
  final bool isPlaying;

  /// 현재 재생 위치
  final Duration currentPosition;

  /// 총 재생 시간
  final Duration totalDuration;

  const PlaybackStateModel({
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = const Duration(minutes: 3, seconds: 42),
  });

  /// 상태 복사 메서드
  PlaybackStateModel copyWith({
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
  }) {
    return PlaybackStateModel(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
    );
  }

  /// 현재 위치의 퍼센트 계산
  double get progressPercent {
    if (totalDuration.inMilliseconds == 0) {
      return 0.0;
    }
    return currentPosition.inMilliseconds / totalDuration.inMilliseconds;
  }

  /// 현재 위치를 "MM:SS" 형식으로 반환
  String get currentPositionText {
    final minutes = currentPosition.inMinutes;
    final seconds = currentPosition.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// 총 재생 시간을 "MM:SS" 형식으로 반환
  String get totalDurationText {
    final minutes = totalDuration.inMinutes;
    final seconds = totalDuration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// 가사의 현재 강조 표시 위치를 관리하는 프로바이더
@riverpod
class LyricsHighlight extends _$LyricsHighlight {
  @override
  int build() {
    return 0; // 첫 번째 가사 인덱스
  }

  /// 현재 강조 표시할 가사 인덱스 설정
  void setHighlightIndex(int index) {
    state = index;
  }

  /// 다음 가사로 이동
  void nextLine(int maxIndex) {
    if (state < maxIndex) {
      state += 1;
    }
  }

  /// 이전 가사로 이동
  void previousLine() {
    if (state > 0) {
      state -= 1;
    }
  }
}
