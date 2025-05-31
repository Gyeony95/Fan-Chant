import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';

/// 가사 정보를 관리하는 서비스 클래스
class LyricsService {
  /// 싱글톤 인스턴스
  static final LyricsService instance = LyricsService._internal();

  /// 내부 생성자
  LyricsService._internal();

  /// 캐시: appleMusicId -> Song 매핑
  final Map<String, Song> _lyricsCache = {};

  /// appleMusicId로 노래 정보 로드
  Future<Song?> loadSongByAppleMusicId(String appleMusicId) async {
    // 캐시에 있는지 확인
    if (_lyricsCache.containsKey(appleMusicId)) {
      return _lyricsCache[appleMusicId];
    }

    try {
      // JSON 파일 로드
      final jsonString =
          await rootBundle.loadString('assets/lyrics/$appleMusicId.json');
      final jsonData = json.decode(jsonString);

      // 가사 정보 파싱
      final List<dynamic> lyricsJson = jsonData['lyrics'] ?? [];
      final List<LyricLine> lyrics = lyricsJson.map((lyric) {
        return LyricLine(
          text: lyric['text'],
          type: lyric['type'] == 'artist' ? LyricType.artist : LyricType.fan,
          startTime: lyric['startTime'],
          endTime: lyric['endTime'],
          isHighlighted: lyric['isHighlighted'] ?? false,
        );
      }).toList();

      // Song 객체 생성
      final song = Song(
        id: jsonData['appleMusicId'],
        title: jsonData['title'],
        artist: jsonData['artist'],
        album: jsonData['album'],
        albumCoverUrl: jsonData['albumCoverUrl'],
        releaseDate: jsonData['releaseDate'],
        genre: jsonData['genre'],
        hasFanChant: jsonData['hasFanChant'] ?? false,
        lyrics: lyrics,
      );

      // 캐시에 저장
      _lyricsCache[appleMusicId] = song;

      return song;
    } catch (e) {
      print('가사 로드 오류: $e');
      return null;
    }
  }

  /// 모든 가사 파일 리스트 반환 (향후 확장을 위한 메서드)
  Future<List<String>> getAllAvailableLyricsIds() async {
    try {
      // 이 방법은 Flutter에서 asset 디렉토리 목록을 가져오는 직접적인 방법이 없어 제한적임
      // 실제 앱에서는 Firebase 등의 백엔드 서비스를 사용하거나 미리 정의된 리스트를 사용하는 것이 좋음
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final lyricsFiles = manifestMap.keys
          .where((key) =>
              key.startsWith('assets/lyrics/') && key.endsWith('.json'))
          .map((key) => key.split('/').last.replaceAll('.json', ''))
          .toList();

      return lyricsFiles;
    } catch (e) {
      print('가사 목록 로드 오류: $e');
      return [];
    }
  }

  /// 모든 응원법 가이드 노래 로드
  Future<List<Song>> loadAllSongs() async {
    try {
      // 사용 가능한 모든 가사 ID 가져오기
      final lyricsIds = await getAllAvailableLyricsIds();
      final List<Song> songs = [];

      // 각 ID에 대해 노래 정보 로드
      for (final id in lyricsIds) {
        final song = await loadSongByAppleMusicId(id);
        if (song != null && song.hasFanChant) {
          songs.add(song);
        }
      }

      // 제목순으로 정렬
      songs.sort((a, b) => a.title.compareTo(b.title));

      return songs;
    } catch (e) {
      print('모든 노래 로드 오류: $e');
      return [];
    }
  }

  /// 캐시 초기화
  void clearCache() {
    _lyricsCache.clear();
  }
}
