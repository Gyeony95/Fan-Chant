// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allSongsHash() => r'c8bf3ed81400346f231e71e373a7b28f18c0529d';

/// 모든 노래 목록을 제공하는 프로바이더
///
/// Copied from [allSongs].
@ProviderFor(allSongs)
final allSongsProvider = AutoDisposeProvider<List<Song>>.internal(
  allSongs,
  name: r'allSongsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allSongsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllSongsRef = AutoDisposeProviderRef<List<Song>>;
String _$favoriteSongsHash() => r'1687f7246a4f0b1f619b96ff514c644dd9ca3d9c';

/// 찜한 노래 목록을 제공하는 프로바이더
///
/// Copied from [favoriteSongs].
@ProviderFor(favoriteSongs)
final favoriteSongsProvider = AutoDisposeProvider<List<Song>>.internal(
  favoriteSongs,
  name: r'favoriteSongsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$favoriteSongsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FavoriteSongsRef = AutoDisposeProviderRef<List<Song>>;
String _$songRecognitionHash() => r'25972ee9b5bf5459be8d71773d0595b77b54e0a9';

/// 노래 인식 상태를 관리하는 프로바이더
///
/// Copied from [SongRecognition].
@ProviderFor(SongRecognition)
final songRecognitionProvider =
    AutoDisposeNotifierProvider<SongRecognition, SongRecognitionState>.internal(
  SongRecognition.new,
  name: r'songRecognitionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$songRecognitionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SongRecognition = AutoDisposeNotifier<SongRecognitionState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
