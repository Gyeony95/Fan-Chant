import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'song.g.dart';

/// 노래 정보를 담는 모델 클래스
@HiveType(typeId: 0)
class Song {
  /// 노래 ID
  @HiveField(0)
  final String id;

  /// 노래 제목
  @HiveField(1)
  final String title;

  /// 아티스트 이름
  @HiveField(2)
  final String artist;

  /// 앨범 이름
  @HiveField(3)
  final String album;

  /// 앨범 커버 이미지 URL
  @HiveField(4)
  final String albumCoverUrl;

  /// 발매일
  @HiveField(5)
  final String releaseDate;

  /// 장르
  @HiveField(6)
  final String genre;

  /// 응원법 정보가 있는지 여부
  @HiveField(7)
  final bool hasFanChant;

  /// 가사 및 응원법 리스트
  @HiveField(8)
  final List<LyricLine>? lyrics;

  /// 찜 여부
  @HiveField(9)
  bool isFavorite;

  /// 인식된 시간 (정렬을 위해 사용)
  @HiveField(10)
  final DateTime recognizedAt;

  /// Apple Music ID
  @HiveField(11)
  final String? appleMusicId;

  Song({
    String? id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumCoverUrl,
    required this.releaseDate,
    this.genre = 'K-POP',
    this.hasFanChant = false,
    this.lyrics,
    this.isFavorite = false,
    DateTime? recognizedAt,
    this.appleMusicId,
  })  : this.id = id ?? const Uuid().v4(),
        this.recognizedAt = recognizedAt ?? DateTime.now();

  /// 찜 상태 토글 메서드
  void toggleFavorite() {
    isFavorite = !isFavorite;
  }
}

/// 가사 유형 열거형
@HiveType(typeId: 1)
enum LyricType {
  /// 가수가 부르는 파트
  @HiveField(0)
  artist,

  /// 팬이 부르는 파트
  @HiveField(1)
  fan,

  /// 가수와 팬이 함께 부르는 파트
  @HiveField(2)
  both,
}

/// 가사 한 줄을 표현하는 클래스
@HiveType(typeId: 2)
class LyricLine {
  /// 가사 텍스트
  @HiveField(0)
  final String text;

  /// 가사 유형 (가수/팬)
  @HiveField(1)
  final LyricType type;

  /// 시작 시간 (초 단위)
  @HiveField(2)
  final int startTime;

  /// 종료 시간 (초 단위)
  @HiveField(3)
  final int endTime;

  /// 강조 표시 여부
  @HiveField(4)
  final bool isHighlighted;

  LyricLine({
    required this.text,
    required this.type,
    required this.startTime,
    this.endTime = 0, // 기본값은 0으로 설정
    this.isHighlighted = false,
  });

  /// 현재 재생 시간에 이 가사가 해당하는지 확인
  bool isActive(int currentTime) {
    return currentTime >= startTime && currentTime < endTime;
  }
}
