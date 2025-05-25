import 'package:hive/hive.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';

/// Hive를 사용하여 노래 데이터를 저장하는 서비스
class SongStorageService {
  static const String _recentSongsBoxName = 'recent_songs';
  static const String _favoriteSongsBoxName = 'favorite_songs';

  late Box<Song> _recentSongsBox;
  late Box<Song> _favoriteSongsBox;

  /// 싱글턴 인스턴스
  static final SongStorageService _instance = SongStorageService._internal();

  /// 팩토리 생성자
  factory SongStorageService() => _instance;

  /// 내부 생성자
  SongStorageService._internal();

  /// 서비스 초기화
  Future<void> init() async {
    // 아직 박스가 열려있지 않으면 열기
    if (!Hive.isBoxOpen(_recentSongsBoxName)) {
      _recentSongsBox = await Hive.openBox<Song>(_recentSongsBoxName);
    } else {
      _recentSongsBox = Hive.box<Song>(_recentSongsBoxName);
    }

    if (!Hive.isBoxOpen(_favoriteSongsBoxName)) {
      _favoriteSongsBox = await Hive.openBox<Song>(_favoriteSongsBoxName);
    } else {
      _favoriteSongsBox = Hive.box<Song>(_favoriteSongsBoxName);
    }
  }

  /// 최근 인식한 노래 목록 가져오기 (최대 10개)
  List<Song> getRecentSongs() {
    final songs = _recentSongsBox.values.toList();

    // 최신순으로 정렬
    songs.sort((a, b) => b.recognizedAt.compareTo(a.recognizedAt));

    // 최대 10개까지만 반환
    return songs.take(10).toList();
  }

  /// 찜한 노래 목록 가져오기
  List<Song> getFavoriteSongs() {
    return _favoriteSongsBox.values.toList();
  }

  /// 노래가 찜 목록에 있는지 확인
  bool isFavorite(String songId) {
    return _favoriteSongsBox.containsKey(songId);
  }

  /// 최근 인식한 노래 추가
  Future<void> addRecentSong(Song song) async {
    // 이미 존재하는 노래라면 삭제 후 다시 추가 (최신 정보로 업데이트)
    if (_recentSongsBox.containsKey(song.id)) {
      await _recentSongsBox.delete(song.id);
    }

    // 최근 인식 시간 업데이트
    final updatedSong = Song(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      albumCoverUrl: song.albumCoverUrl,
      releaseDate: song.releaseDate,
      genre: song.genre,
      hasFanChant: song.hasFanChant,
      lyrics: song.lyrics,
      isFavorite: isFavorite(song.id),
      recognizedAt: DateTime.now(),
    );

    // 최근 인식한 노래에 추가
    await _recentSongsBox.put(song.id, updatedSong);

    // 최대 10개로 제한
    if (_recentSongsBox.length > 10) {
      final allSongs = getRecentSongs();
      final songsToRemove = allSongs.sublist(10);

      for (final songToRemove in songsToRemove) {
        await _recentSongsBox.delete(songToRemove.id);
      }
    }
  }

  /// 찜하기 토글
  Future<void> toggleFavorite(Song song) async {
    final isFav = isFavorite(song.id);

    if (isFav) {
      // 찜 목록에서 제거
      await _favoriteSongsBox.delete(song.id);

      // 최근 목록에 있다면 찜 상태 업데이트
      if (_recentSongsBox.containsKey(song.id)) {
        final recentSong = _recentSongsBox.get(song.id)!;
        final updatedSong = Song(
          id: recentSong.id,
          title: recentSong.title,
          artist: recentSong.artist,
          album: recentSong.album,
          albumCoverUrl: recentSong.albumCoverUrl,
          releaseDate: recentSong.releaseDate,
          genre: recentSong.genre,
          hasFanChant: recentSong.hasFanChant,
          lyrics: recentSong.lyrics,
          isFavorite: false,
          recognizedAt: recentSong.recognizedAt,
        );
        await _recentSongsBox.put(song.id, updatedSong);
      }
    } else {
      // 찜 목록에 추가
      final updatedSong = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        albumCoverUrl: song.albumCoverUrl,
        releaseDate: song.releaseDate,
        genre: song.genre,
        hasFanChant: song.hasFanChant,
        lyrics: song.lyrics,
        isFavorite: true,
        recognizedAt: song.recognizedAt,
      );
      await _favoriteSongsBox.put(song.id, updatedSong);

      // 최근 목록에 있다면 찜 상태 업데이트
      if (_recentSongsBox.containsKey(song.id)) {
        await _recentSongsBox.put(song.id, updatedSong);
      }
    }
  }

  /// 최근 인식한 노래 목록 초기화
  Future<void> clearRecentSongs() async {
    await _recentSongsBox.clear();
  }

  /// 찜 목록 초기화
  Future<void> clearFavoriteSongs() async {
    await _favoriteSongsBox.clear();
  }
}
