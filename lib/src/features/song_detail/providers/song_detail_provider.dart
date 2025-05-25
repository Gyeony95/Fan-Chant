import 'dart:async';
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
  Timer? _timer;

  @override
  PlaybackStateModel build() {
    // dispose 시 타이머 취소 및 재생 상태 초기화
    ref.onDispose(() {
      if (_timer != null) {
        _timer!.cancel();
        _timer = null;
      }
      // 마지막 상태가 재생 중이었다면 재생 중지 상태로 설정
      // (이는 새로운 리스너에게 알리지 않고 내부적으로만 상태를 변경)
      if (state.isPlaying) {
        state = state.copyWith(isPlaying: false);
      }
    });

    return const PlaybackStateModel();
  }

  /// 재생/일시정지 토글
  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// 재생 시작
  void play() {
    // 이미 재생 중이면 리턴
    if (state.isPlaying) return;

    state = state.copyWith(isPlaying: true);

    // 재생 중일 때 1초마다 현재 위치 업데이트
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      // 재생 중이 아니면 타이머 취소
      if (!state.isPlaying) {
        _timer?.cancel();
        return;
      }

      // 현재 위치 업데이트
      final newPosition =
          state.currentPosition + const Duration(milliseconds: 200);

      // 총 재생 시간을 초과하면 처음으로 돌아감
      if (newPosition >= state.totalDuration) {
        state =
            state.copyWith(currentPosition: Duration.zero, isPlaying: false);
        _timer?.cancel();
      } else {
        state = state.copyWith(currentPosition: newPosition);
      }
    });
  }

  /// 일시정지
  void pause() {
    _timer?.cancel();
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

  /// 현재 위치를 초 단위로 반환
  int get currentSeconds {
    return currentPosition.inSeconds;
  }
}

/// 가사의 현재 강조 표시 위치를 관리하는 프로바이더
@riverpod
class LyricsHighlight extends _$LyricsHighlight {
  @override
  int build() {
    // 현재 재생 시간 모니터링
    final playbackState = ref.watch(playbackStateProvider);
    final currentSong = ref.watch(currentSongProvider);

    // 현재 재생 시간
    final currentSeconds = playbackState.currentSeconds;

    // 현재 노래가 없으면 0 반환
    if (currentSong == null || currentSong.lyrics == null) {
      return -1;
    }

    // 현재 시간에 해당하는 가사 찾기
    for (int i = 0; i < currentSong.lyrics!.length; i++) {
      final lyric = currentSong.lyrics![i];
      if (lyric.startTime <= currentSeconds && currentSeconds < lyric.endTime) {
        return i;
      }
    }

    // 해당하는 가사가 없으면 -1 반환
    return -1;
  }

  /// 특정 가사 인덱스로 이동
  void jumpToLyric(int index) {
    final currentSong = ref.read(currentSongProvider);
    if (currentSong?.lyrics != null &&
        index >= 0 &&
        index < currentSong!.lyrics!.length) {
      final startTime = currentSong.lyrics![index].startTime;
      // 해당 가사의 시작 시간으로 플레이어 이동
      ref
          .read(playbackStateProvider.notifier)
          .seekTo(Duration(seconds: startTime));
    }
  }
}
