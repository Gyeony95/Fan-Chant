// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'song_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$allSongsHash() => r'0e5492826109740f0e7ef85e646e1e29344299c0';

/// 모든 노래 목록을 제공하는 프로바이더
///
/// Copied from [allSongs].
@ProviderFor(allSongs)
final allSongsProvider = AutoDisposeFutureProvider<List<Song>>.internal(
  allSongs,
  name: r'allSongsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allSongsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllSongsRef = AutoDisposeFutureProviderRef<List<Song>>;
String _$favoriteSongsHash() => r'ac3fdb3394e17c4ec74d95c4d2db49f9f353c68c';

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
String _$songRecognitionHash() => r'ad2b0e1ae91765620b244c5f2feb41dcd68a37e6';

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
