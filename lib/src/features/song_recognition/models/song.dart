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

  /// 샘플 데이터 생성 메서드
  static List<Song> getSampleSongs() {
    return [
      Song(
        id: '1',
        title: 'Celebrity',
        artist: '아이유 (IU)',
        album: 'IU 5th Album \'LILAC\'',
        albumCoverUrl:
            'https://readdy.ai/api/search-image?query=album%20cover%20of%20IU%20Celebrity%2C%20K-pop%20album%20art%2C%20professional%20photography%2C%20high%20quality&width=80&height=80&seq=1&orientation=squarish',
        releaseDate: '2023년 5월 15일',
        hasFanChant: true,
        lyrics: [
          LyricLine(
              text: '세상의 모서리에 홀로 서 있어도',
              type: LyricType.artist,
              startTime: 0,
              endTime: 4),
          LyricLine(
              text: '(아이유! 아이유!)',
              type: LyricType.fan,
              startTime: 4,
              endTime: 8),
          LyricLine(
              text: '외롭기만 한 바보는 아니야',
              type: LyricType.artist,
              startTime: 8,
              endTime: 12),
          LyricLine(
              text: '(박수 박수 박수)',
              type: LyricType.fan,
              startTime: 12,
              endTime: 16),
          LyricLine(
              text: '네가 있는 그 곳이 어디든',
              type: LyricType.artist,
              startTime: 16,
              endTime: 20),
          LyricLine(
              text: '(응원봉 흔들기)',
              type: LyricType.fan,
              startTime: 20,
              endTime: 24),
          LyricLine(
              text: '그냥 설 수 있다면',
              type: LyricType.artist,
              startTime: 24,
              endTime: 28),
          LyricLine(
              text: '(유애나! 유애나!)',
              type: LyricType.fan,
              startTime: 28,
              endTime: 32),
          LyricLine(
              text: 'You\'re my celebrity',
              type: LyricType.artist,
              startTime: 32,
              endTime: 36,
              isHighlighted: true),
          LyricLine(
              text: '(Celebrity! Celebrity!)',
              type: LyricType.fan,
              startTime: 36,
              endTime: 40,
              isHighlighted: true),
          LyricLine(
              text: '잊지마 넌 흐린 어둠 사이',
              type: LyricType.artist,
              startTime: 40,
              endTime: 44),
          LyricLine(
              text: '(손하트 만들기)',
              type: LyricType.fan,
              startTime: 44,
              endTime: 48),
          LyricLine(
              text: '빛나는 별 하나라는 걸',
              type: LyricType.artist,
              startTime: 48,
              endTime: 52),
          LyricLine(
              text: '(응원봉 위로 들기)',
              type: LyricType.fan,
              startTime: 52,
              endTime: 56),
        ],
      ),
      Song(
        id: '2',
        title: 'Hype Boy',
        artist: '뉴진스 (NewJeans)',
        album: 'NewJeans 1st EP',
        albumCoverUrl:
            'https://readdy.ai/api/search-image?query=album%20cover%20of%20NewJeans%20Hype%20Boy%2C%20K-pop%20album%20art%2C%20professional%20photography%2C%20high%20quality&width=80&height=80&seq=2&orientation=squarish',
        releaseDate: '2022년 8월 1일',
        hasFanChant: true,
        lyrics: [
          LyricLine(
              text: '1, 2, 3, 4',
              type: LyricType.artist,
              startTime: 0,
              endTime: 4),
          LyricLine(
              text: '너 없인 시간이 달려가질 않아',
              type: LyricType.artist,
              startTime: 4,
              endTime: 8),
          LyricLine(
              text: '(박수 박수 박수)',
              type: LyricType.fan,
              startTime: 8,
              endTime: 12),
          LyricLine(
              text: '하루가 몇 년이 된 것만 같아',
              type: LyricType.artist,
              startTime: 12,
              endTime: 16),
          LyricLine(
              text: '(뉴진스! 뉴진스!)',
              type: LyricType.fan,
              startTime: 16,
              endTime: 20),
          LyricLine(
              text: '얼마나 기다려야 내 맘이 전해질까',
              type: LyricType.artist,
              startTime: 20,
              endTime: 24),
          LyricLine(
              text: '(손하트 만들기)',
              type: LyricType.fan,
              startTime: 24,
              endTime: 28),
          LyricLine(
              text: 'Baby, you\'re my Hype Boy',
              type: LyricType.artist,
              startTime: 28,
              endTime: 32,
              isHighlighted: true),
          LyricLine(
              text: '(Hype Boy! Hype Boy!)',
              type: LyricType.fan,
              startTime: 32,
              endTime: 36,
              isHighlighted: true),
          LyricLine(
              text: '내 기분을 다 가져가',
              type: LyricType.artist,
              startTime: 36,
              endTime: 40),
          LyricLine(
              text: '(응원봉 흔들기)',
              type: LyricType.fan,
              startTime: 40,
              endTime: 44),
          LyricLine(
              text: '분명 네가 있으면',
              type: LyricType.artist,
              startTime: 44,
              endTime: 48),
          LyricLine(
              text: '(하이! 하이!)',
              type: LyricType.fan,
              startTime: 48,
              endTime: 52),
          LyricLine(
              text: '하루가 즐거워져',
              type: LyricType.artist,
              startTime: 52,
              endTime: 56),
          LyricLine(
              text: '(응원봉 좌우로 흔들기)',
              type: LyricType.fan,
              startTime: 56,
              endTime: 60),
          LyricLine(
              text: '모든 게 다 신기해',
              type: LyricType.artist,
              startTime: 60,
              endTime: 64),
          LyricLine(
              text: '(뉴진스 사랑해요!)',
              type: LyricType.fan,
              startTime: 64,
              endTime: 68),
        ],
      ),
      Song(
        id: '3',
        title: 'Dynamite',
        artist: '방탄소년단 (BTS)',
        album: 'Dynamite (DayTime Version)',
        albumCoverUrl:
            'https://readdy.ai/api/search-image?query=album%20cover%20of%20BTS%20Dynamite%2C%20K-pop%20album%20art%2C%20professional%20photography%2C%20high%20quality&width=80&height=80&seq=3&orientation=squarish',
        releaseDate: '2020년 8월 21일',
        hasFanChant: true,
        lyrics: [
          LyricLine(
              text: 'Cause I-I-I\'m in the stars tonight',
              type: LyricType.artist,
              startTime: 0,
              endTime: 4),
          LyricLine(
              text: '(BTS! BTS!)',
              type: LyricType.fan,
              startTime: 4,
              endTime: 8),
          LyricLine(
              text: 'So watch me bring the fire and set the night alight',
              type: LyricType.artist,
              startTime: 8,
              endTime: 12),
          LyricLine(
              text: '(아미! 아미!)',
              type: LyricType.fan,
              startTime: 12,
              endTime: 16),
          LyricLine(
              text: 'Shoes on, get up in the morn\'',
              type: LyricType.artist,
              startTime: 16,
              endTime: 20),
          LyricLine(
              text: '(박수 박수 박수)',
              type: LyricType.fan,
              startTime: 20,
              endTime: 24),
          LyricLine(
              text: 'Cup of milk, let\'s rock and roll',
              type: LyricType.artist,
              startTime: 24,
              endTime: 28),
          LyricLine(
              text: '(응원봉 흔들기)',
              type: LyricType.fan,
              startTime: 28,
              endTime: 32),
          LyricLine(
              text: 'King Kong, kick the drum',
              type: LyricType.artist,
              startTime: 32,
              endTime: 36),
          LyricLine(
              text: '(방탄! 방탄!)',
              type: LyricType.fan,
              startTime: 36,
              endTime: 40),
          LyricLine(
              text: 'Rolling on like a Rolling Stone',
              type: LyricType.artist,
              startTime: 40,
              endTime: 44),
          LyricLine(
              text: '(아미 사랑해요!)',
              type: LyricType.fan,
              startTime: 44,
              endTime: 48),
          LyricLine(
              text: 'Sing song when I\'m walking home',
              type: LyricType.artist,
              startTime: 48,
              endTime: 52),
          LyricLine(
              text: '(응원봉 좌우로 흔들기)',
              type: LyricType.fan,
              startTime: 52,
              endTime: 56),
          LyricLine(
              text: 'Jump up to the top, LeBron',
              type: LyricType.artist,
              startTime: 56,
              endTime: 60,
              isHighlighted: true),
          LyricLine(
              text: '(Dynamite! Dynamite!)',
              type: LyricType.fan,
              startTime: 60,
              endTime: 64,
              isHighlighted: true),
        ],
      ),
    ];
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
