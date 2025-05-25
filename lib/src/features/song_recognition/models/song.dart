/// 노래 정보를 담는 모델 클래스
class Song {
  /// 노래 ID
  final String id;

  /// 노래 제목
  final String title;

  /// 아티스트 이름
  final String artist;

  /// 앨범 이름
  final String album;

  /// 앨범 커버 이미지 URL
  final String albumCoverUrl;

  /// 발매일
  final String releaseDate;

  /// 장르
  final String genre;

  /// 응원법 정보가 있는지 여부
  final bool hasFanChant;

  /// 가사 및 응원법 리스트
  final List<LyricLine>? lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumCoverUrl,
    required this.releaseDate,
    this.genre = 'K-POP',
    this.hasFanChant = false,
    this.lyrics,
  });

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
          LyricLine(text: '세상의 모서리에 홀로 서 있어도', type: LyricType.artist, time: 0),
          LyricLine(text: '(아이유! 아이유!)', type: LyricType.fan, time: 4),
          LyricLine(text: '외롭기만 한 바보는 아니야', type: LyricType.artist, time: 8),
          LyricLine(text: '(박수 박수 박수)', type: LyricType.fan, time: 12),
          LyricLine(text: '네가 있는 그 곳이 어디든', type: LyricType.artist, time: 16),
          LyricLine(text: '(응원봉 흔들기)', type: LyricType.fan, time: 20),
          LyricLine(text: '그냥 설 수 있다면', type: LyricType.artist, time: 24),
          LyricLine(text: '(유애나! 유애나!)', type: LyricType.fan, time: 28),
          LyricLine(
              text: 'You\'re my celebrity',
              type: LyricType.artist,
              time: 32,
              isHighlighted: true),
          LyricLine(
              text: '(Celebrity! Celebrity!)',
              type: LyricType.fan,
              time: 36,
              isHighlighted: true),
          LyricLine(text: '잊지마 넌 흐린 어둠 사이', type: LyricType.artist, time: 40),
          LyricLine(text: '(손하트 만들기)', type: LyricType.fan, time: 44),
          LyricLine(text: '빛나는 별 하나라는 걸', type: LyricType.artist, time: 48),
          LyricLine(text: '(응원봉 위로 들기)', type: LyricType.fan, time: 52),
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
          LyricLine(text: '1, 2, 3, 4', type: LyricType.artist, time: 0),
          LyricLine(text: '너 없인 시간이 달려가질 않아', type: LyricType.artist, time: 4),
          LyricLine(text: '(박수 박수 박수)', type: LyricType.fan, time: 8),
          LyricLine(text: '하루가 몇 년이 된 것만 같아', type: LyricType.artist, time: 12),
          LyricLine(text: '(뉴진스! 뉴진스!)', type: LyricType.fan, time: 16),
          LyricLine(
              text: '얼마나 기다려야 내 맘이 전해질까', type: LyricType.artist, time: 20),
          LyricLine(text: '(손하트 만들기)', type: LyricType.fan, time: 24),
          LyricLine(
              text: 'Baby, you\'re my Hype Boy',
              type: LyricType.artist,
              time: 28,
              isHighlighted: true),
          LyricLine(
              text: '(Hype Boy! Hype Boy!)',
              type: LyricType.fan,
              time: 32,
              isHighlighted: true),
          LyricLine(text: '내 기분을 다 가져가', type: LyricType.artist, time: 36),
          LyricLine(text: '(응원봉 흔들기)', type: LyricType.fan, time: 40),
          LyricLine(text: '분명 네가 있으면', type: LyricType.artist, time: 44),
          LyricLine(text: '(하이! 하이!)', type: LyricType.fan, time: 48),
          LyricLine(text: '하루가 즐거워져', type: LyricType.artist, time: 52),
          LyricLine(text: '(응원봉 좌우로 흔들기)', type: LyricType.fan, time: 56),
          LyricLine(text: '모든 게 다 신기해', type: LyricType.artist, time: 60),
          LyricLine(text: '(뉴진스 사랑해요!)', type: LyricType.fan, time: 64),
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
              time: 0),
          LyricLine(text: '(BTS! BTS!)', type: LyricType.fan, time: 4),
          LyricLine(
              text: 'So watch me bring the fire and set the night alight',
              type: LyricType.artist,
              time: 8),
          LyricLine(text: '(아미! 아미!)', type: LyricType.fan, time: 12),
          LyricLine(
              text: 'Shoes on, get up in the morn\'',
              type: LyricType.artist,
              time: 16),
          LyricLine(text: '(박수 박수 박수)', type: LyricType.fan, time: 20),
          LyricLine(
              text: 'Cup of milk, let\'s rock and roll',
              type: LyricType.artist,
              time: 24),
          LyricLine(text: '(응원봉 흔들기)', type: LyricType.fan, time: 28),
          LyricLine(
              text: 'King Kong, kick the drum',
              type: LyricType.artist,
              time: 32),
          LyricLine(text: '(방탄! 방탄!)', type: LyricType.fan, time: 36),
          LyricLine(
              text: 'Rolling on like a Rolling Stone',
              type: LyricType.artist,
              time: 40),
          LyricLine(text: '(아미 사랑해요!)', type: LyricType.fan, time: 44),
          LyricLine(
              text: 'Sing song when I\'m walking home',
              type: LyricType.artist,
              time: 48),
          LyricLine(text: '(응원봉 좌우로 흔들기)', type: LyricType.fan, time: 52),
          LyricLine(
              text: 'Jump up to the top, LeBron',
              type: LyricType.artist,
              time: 56,
              isHighlighted: true),
          LyricLine(
              text: '(Dynamite! Dynamite!)',
              type: LyricType.fan,
              time: 60,
              isHighlighted: true),
        ],
      ),
    ];
  }
}

/// 가사 유형 열거형
enum LyricType {
  /// 가수가 부르는 파트
  artist,

  /// 팬이 부르는 파트
  fan,
}

/// 가사 한 줄을 표현하는 클래스
class LyricLine {
  /// 가사 텍스트
  final String text;

  /// 가사 유형 (가수/팬)
  final LyricType type;

  /// 타임라인 (초 단위)
  final int time;

  /// 강조 표시 여부
  final bool isHighlighted;

  LyricLine({
    required this.text,
    required this.type,
    required this.time,
    this.isHighlighted = false,
  });
}
