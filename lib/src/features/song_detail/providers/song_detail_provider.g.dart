// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentSongHash() => r'd74ea6d597f866c6957c7e2a56a762c59753106b';

/// 현재 선택된 노래를 관리하는 프로바이더
///
/// Copied from [CurrentSong].
@ProviderFor(CurrentSong)
final currentSongProvider =
    AutoDisposeNotifierProvider<CurrentSong, Song?>.internal(
  CurrentSong.new,
  name: r'currentSongProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentSongHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentSong = AutoDisposeNotifier<Song?>;
String _$playbackStateHash() => r'8ead24299261035270ec680d07beeecf0f907b2e';

/// 현재 재생 상태를 관리하는 프로바이더
///
/// Copied from [PlaybackState].
@ProviderFor(PlaybackState)
final playbackStateProvider =
    AutoDisposeNotifierProvider<PlaybackState, PlaybackStateModel>.internal(
  PlaybackState.new,
  name: r'playbackStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playbackStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlaybackState = AutoDisposeNotifier<PlaybackStateModel>;
String _$lyricsHighlightHash() => r'cb72891dc7b7b8a5ef6b38305acab958ef9d6a5b';

/// 가사의 현재 강조 표시 위치를 관리하는 프로바이더
///
/// Copied from [LyricsHighlight].
@ProviderFor(LyricsHighlight)
final lyricsHighlightProvider =
    AutoDisposeNotifierProvider<LyricsHighlight, int>.internal(
  LyricsHighlight.new,
  name: r'lyricsHighlightProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$lyricsHighlightHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LyricsHighlight = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
