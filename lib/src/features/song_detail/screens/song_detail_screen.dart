import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/core/theme/colors.dart';
import 'package:fan_chant/src/core/theme/app_dimensions.dart';
import 'package:fan_chant/src/core/theme/text_styles.dart';
import 'package:fan_chant/src/core/widgets/safe_image.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_detail/providers/song_detail_provider.dart';
import 'package:fan_chant/src/features/song_recognition/providers/song_provider.dart';
import 'package:fan_chant/src/features/song_recognition/services/lyrics_service.dart';
import 'package:fan_chant/src/features/song_detail/screens/fullscreen_lyrics_screen.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

/// 파싱된 가사 정보를 담는 클래스
class ParsedLyric {
  final List<LyricComponent> components; // 순서가 유지된 컴포넌트들

  ParsedLyric({
    required this.components,
  });
}

/// 가사 컴포넌트 (텍스트 또는 팬 응원)
abstract class LyricComponent {}

/// 일반 텍스트 컴포넌트
class TextComponent extends LyricComponent {
  final String text;

  TextComponent(this.text);
}

/// 팬 응원 컴포넌트
class FanChantComponent extends LyricComponent {
  final String text;
  final LyricType type;

  FanChantComponent({
    required this.text,
    required this.type,
  });
}

/// 팬 응원 파트 정보를 담는 클래스 (기존 호환성용)
class FanChantPart {
  final String text;
  final LyricType type;

  FanChantPart({
    required this.text,
    required this.type,
  });
}

/// 노래 상세 정보 화면
class SongDetailScreen extends ConsumerStatefulWidget {
  /// 노래 정보
  final Song song;

  /// 생성자
  const SongDetailScreen({
    required this.song,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  // 가사 스크롤 컨트롤러
  final ScrollController _lyricsScrollController = ScrollController();

  // 자동 스크롤 상태 관리
  bool _isUserScrolling = false;
  int _lastAutoScrollIndex = -1;

  // 가사 아이템들의 GlobalKey 리스트 (정확한 위치 계산용)
  final List<GlobalKey> _lyricItemKeys = [];

  @override
  void initState() {
    super.initState();
    // 현재 노래 설정
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 가사 정보 로드
      Song songToUse = widget.song;

      // appleMusicId가 있는 경우 JSON에서 가사 정보 로드 시도
      if (widget.song.appleMusicId != null) {
        final songWithLyrics = await LyricsService.instance
            .loadSongByAppleMusicId(widget.song.appleMusicId!);
        if (songWithLyrics != null) {
          // 찜 상태는 유지
          songWithLyrics.isFavorite = widget.song.isFavorite;
          songToUse = songWithLyrics;
        }
      }

      // 현재 노래 설정
      ref.read(currentSongProvider.notifier).setCurrentSong(songToUse);

      // 가사에 맞게 재생 시간 설정 (마지막 가사의 종료 시간으로 설정)
      if (songToUse.lyrics != null && songToUse.lyrics!.isNotEmpty) {
        final lastLyric = songToUse.lyrics!.last;
        final totalDuration =
            Duration(seconds: lastLyric.endTime + 2); // 마지막 가사 이후 2초 추가
        ref.read(playbackStateProvider.notifier).setDuration(totalDuration);
      }

      // 재생 상태를 정지 상태로 초기화
      ref.read(playbackStateProvider.notifier).pause();
    });
  }

  @override
  void dispose() {
    // 스크롤 컨트롤러 해제
    _lyricsScrollController.dispose();
    super.dispose();
  }

  /// 자동 스크롤 토글
  void _toggleAutoScroll() {
    setState(() {
      _isUserScrolling = false;
    });

    // 재생 상태에 따라 현재 가사 위치로 이동
    final playbackState = ref.read(playbackStateProvider);
    if (playbackState.isPlaying) {
      final currentSong = ref.read(currentSongProvider);
      final lyrics = currentSong?.lyrics ?? widget.song.lyrics;
      final currentLyricIndex = ref.read(lyricsHighlightProvider);

      if (lyrics != null &&
          currentLyricIndex >= 0 &&
          currentLyricIndex < lyrics.length) {
        _scrollToLyric(currentLyricIndex, lyrics.length);
      }
    }
  }

  /// 개선된 스크롤 함수 - 실제 아이템 위치 기반
  void _scrollToLyric(int index, int totalLyrics) {
    if (!_lyricsScrollController.hasClients) return;

    // GlobalKey 리스트 크기가 부족한 경우 확장
    while (_lyricItemKeys.length <= index) {
      _lyricItemKeys.add(GlobalKey());
    }

    // 가사 영역의 실제 높이
    const lyricsAreaHeight = 380.0;

    // 약간의 지연을 두고 실행해서 렌더링 완료 후 정확한 위치 계산
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_lyricsScrollController.hasClients) return;

      // 현재 아이템의 GlobalKey로 위치 계산 시도
      final currentKey = _lyricItemKeys[index];
      final RenderBox? renderBox =
          currentKey.currentContext?.findRenderObject() as RenderBox?;

      double targetOffset;

      if (renderBox != null) {
        try {
          // 스크롤 뷰포트의 RenderBox 가져오기
          final scrollRenderBox = _lyricsScrollController
              .position.context.storageContext
              .findRenderObject() as RenderBox?;

          if (scrollRenderBox != null) {
            // 아이템의 글로벌 위치
            final itemGlobalPosition = renderBox.localToGlobal(Offset.zero);
            // 스크롤 뷰포트의 글로벌 위치
            final scrollGlobalPosition =
                scrollRenderBox.localToGlobal(Offset.zero);

            // 아이템의 상대적 위치 계산
            final itemRelativeY =
                itemGlobalPosition.dy - scrollGlobalPosition.dy;
            final itemHeight = renderBox.size.height;

            // 현재 스크롤 오프셋을 고려한 아이템의 실제 위치
            final itemActualPosition =
                _lyricsScrollController.offset + itemRelativeY;

            // 아이템 중앙을 화면 중앙에 위치시키기 위한 오프셋
            targetOffset =
                itemActualPosition + (itemHeight / 2) - (lyricsAreaHeight / 2);
          } else {
            // 스크롤 컨테이너를 찾지 못한 경우 추정값 사용
            targetOffset = _calculateEstimatedOffset(index);
          }
        } catch (e) {
          // 에러 발생 시 추정값 사용
          targetOffset = _calculateEstimatedOffset(index);
        }
      } else {
        // 렌더링이 안된 경우 추정값 사용
        targetOffset = _calculateEstimatedOffset(index);
      }

      // 스크롤 범위 제한
      final maxScrollExtent = _lyricsScrollController.position.maxScrollExtent;
      final minScrollExtent = _lyricsScrollController.position.minScrollExtent;

      // 시작점과 끝점에서는 특별 처리
      double finalOffset;

      if (index <= 1) {
        // 처음 1-2개 아이템은 상단에 고정
        finalOffset = minScrollExtent;
      } else if (index >= totalLyrics - 2) {
        // 마지막 1-2개 아이템은 하단에 고정
        finalOffset = maxScrollExtent;
      } else {
        // 중간 아이템들은 화면 중앙에 위치
        finalOffset =
            math.max(minScrollExtent, math.min(targetOffset, maxScrollExtent));
      }

      _lyricsScrollController.animateTo(
        finalOffset,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    });

    _lastAutoScrollIndex = index;
  }

  /// 추정값으로 오프셋 계산
  double _calculateEstimatedOffset(int index) {
    const estimatedItemHeight = 70.0;
    const estimatedSpacing = 24.0;
    const lyricsAreaHeight = 380.0;

    final estimatedPosition = index * (estimatedItemHeight + estimatedSpacing);
    return estimatedPosition - (lyricsAreaHeight / 2);
  }

  /// 가이드 링크 열기
  Future<void> _openGuideLink() async {
    final currentSong = ref.read(currentSongProvider);
    final song = currentSong ?? widget.song;

    if (song.guideLink != null && song.guideLink!.isNotEmpty) {
      try {
        final uri = Uri.parse(song.guideLink!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // 링크를 열 수 없는 경우 스낵바 표시
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('링크를 열 수 없습니다.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        // 오류 발생 시 스낵바 표시
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('링크 형식이 올바르지 않습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// 사용자 스크롤 감지
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      // 사용자가 스크롤을 시작한 경우
      if (notification.dragDetails != null) {
        setState(() {
          _isUserScrolling = true;
        });

        // 재생 중이면 일시정지
        final playbackState = ref.read(playbackStateProvider);
        if (playbackState.isPlaying) {
          ref.read(playbackStateProvider.notifier).pause();
        }
      }
    }
    return true;
  }

  /// 가사 텍스트에서 팬 응원 파트를 순서대로 파싱하는 함수
  ParsedLyric _parseLyricText(String text) {
    final RegExp fanChantRegex = RegExp(r'\[(fan|both):([^\]]+)\]');
    final List<LyricComponent> components = [];

    int lastEnd = 0;
    final matches = fanChantRegex.allMatches(text);

    for (final match in matches) {
      // 마크업 이전의 텍스트가 있으면 추가
      if (match.start > lastEnd) {
        final beforeText = text.substring(lastEnd, match.start).trim();
        if (beforeText.isNotEmpty) {
          components.add(TextComponent(beforeText));
        }
      }

      // 마크업 컴포넌트 추가
      final typeString = match.group(1)!;
      final chantText = match.group(2)!;
      final LyricType type =
          typeString == 'fan' ? LyricType.fan : LyricType.both;
      components.add(FanChantComponent(text: chantText, type: type));

      lastEnd = match.end;
    }

    // 마지막 텍스트가 있으면 추가
    if (lastEnd < text.length) {
      final afterText = text.substring(lastEnd).trim();
      if (afterText.isNotEmpty) {
        components.add(TextComponent(afterText));
      }
    }

    // 컴포넌트가 없으면 전체 텍스트를 하나의 컴포넌트로
    if (components.isEmpty) {
      components.add(TextComponent(text));
    }

    return ParsedLyric(components: components);
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackStateProvider);
    final currentLyricIndex = ref.watch(lyricsHighlightProvider);
    final currentSong = ref.watch(currentSongProvider);

    // 현재 노래의 찜 상태를 가져옴
    final isFavorite = currentSong?.isFavorite ?? widget.song.isFavorite;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션 바
            _buildAppBar(context),

            // 메인 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 노래 정보
                      _buildSongInfo(),

                      // 가사 및 응원법
                      _buildLyricsAndChant(currentLyricIndex),

                      // // 추가 정보
                      // _buildAdditionalInfo(),
                    ],
                  ),
                ),
              ),
            ),

            // 재생 컨트롤
            _buildPlaybackControls(playbackState),
          ],
        ),
      ),
    );
  }

  /// 상단 앱바 위젯
  Widget _buildAppBar(BuildContext context) {
    // 현재 노래 가져오기
    final currentSong = ref.watch(currentSongProvider);
    final songRecognition = ref.watch(songRecognitionProvider.notifier);

    // 찜 상태 가져오기 (현재 노래가 null이면 widget.song 사용)
    final song = currentSong ?? widget.song;
    final isFavorite = song.isFavorite;

    return Container(
      height: AppDimensions.appBarHeight,
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.paddingSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // 뒤로가기 버튼
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(FlutterRemix.arrow_left_s_line),
          ),

          // 제목
          Expanded(
            child: Text(
              widget.song.title,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 액션 버튼들
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 좋아요 버튼
              IconButton(
                onPressed: () async {
                  // 찜 상태 토글
                  await songRecognition.toggleFavorite(song);

                  // 현재 노래 상태 업데이트
                  if (currentSong != null) {
                    final updatedSong = Song(
                      id: currentSong.id,
                      title: currentSong.title,
                      artist: currentSong.artist,
                      album: currentSong.album,
                      albumCoverUrl: currentSong.albumCoverUrl,
                      releaseDate: currentSong.releaseDate,
                      genre: currentSong.genre,
                      hasFanChant: currentSong.hasFanChant,
                      lyrics: currentSong.lyrics,
                      isFavorite: !isFavorite, // 상태 반전
                      recognizedAt: currentSong.recognizedAt,
                    );
                    ref
                        .read(currentSongProvider.notifier)
                        .setCurrentSong(updatedSong);
                  }

                  // 찜 목록 프로바이더 갱신
                  ref.invalidate(favoriteSongsProvider);
                },
                icon: Icon(
                  isFavorite
                      ? FlutterRemix.heart_fill
                      : FlutterRemix.heart_line,
                  color: isFavorite ? Colors.red : AppColors.textLight,
                ),
                tooltip: '찜하기',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 노래 정보 위젯
  Widget _buildSongInfo() {
    return Row(
      children: [
        // 앨범 커버
        SafeImage(
          imageUrl: widget.song.albumCoverUrl,
          width: 80,
          height: 80,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          placeholderIcon: FlutterRemix.music_2_line,
          placeholderColor: AppColors.primary.withOpacity(0.7),
        ),

        const SizedBox(width: AppDimensions.padding),

        // 노래 정보
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.song.title,
                style: AppTextStyles.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.song.artist,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textMedium,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _openGuideLink,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.borderRadiusFull),
                  ),
                  child: Text(
                    '응원법 가이드',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 가사 및 응원법 위젯
  Widget _buildLyricsAndChant(int currentLyricIndex) {
    // 현재 노래 정보 가져오기
    final currentSong = ref.watch(currentSongProvider);
    // 현재 노래 또는 원래 노래의 가사 정보 사용
    final lyrics = currentSong?.lyrics ?? widget.song.lyrics;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.margin),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            AppColors.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        child: Column(
          children: [
            // 상단 제목 및 아티스트 정보
            Container(
              padding: const EdgeInsets.all(AppDimensions.padding),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // 작은 앨범 커버
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SafeImage(
                      imageUrl: widget.song.albumCoverUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 노래 및 아티스트 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.song.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.song.artist,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 전체화면 버튼
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FullScreenLyricsScreen(song: widget.song),
                        ),
                      );
                    },
                    icon: const Icon(
                      FlutterRemix.fullscreen_line,
                      color: AppColors.textLight,
                    ),
                    tooltip: '전체화면',
                  ),
                ],
              ),
            ),

            // 가사 내용
            if (lyrics != null && lyrics.isNotEmpty)
              SizedBox(
                height: 380, // 고정 높이 설정
                child: Stack(
                  children: [
                    // 배경 앨범 아트 (흐릿하게)
                    Positioned.fill(
                      child: SafeImage(
                        imageUrl: widget.song.albumCoverUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // 배경 오버레이
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    // 가사 리스트
                    Positioned.fill(
                      child: _buildAppleMusicStyleLyrics(
                          lyrics, currentLyricIndex),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 200,
                alignment: Alignment.center,
                child: Text(
                  '가사 정보가 없습니다',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 애플 뮤직 스타일 가사 위젯
  Widget _buildAppleMusicStyleLyrics(
      List<LyricLine> lyrics, int currentLyricIndex) {
    final playbackState = ref.watch(playbackStateProvider);

    // 재생 중이고 사용자가 스크롤하지 않을 때만 자동 스크롤 실행
    if (playbackState.isPlaying &&
        !_isUserScrolling &&
        currentLyricIndex >= 0 &&
        currentLyricIndex < lyrics.length &&
        currentLyricIndex != _lastAutoScrollIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToLyric(currentLyricIndex, lyrics.length);
      });
    }

    // 가사 리스트 생성
    final lyricWidgets = <Widget>[];

    for (int i = 0; i < lyrics.length; i++) {
      final lyric = lyrics[i];
      final isActive = i == currentLyricIndex;

      // artist 타입인 경우 텍스트 파싱하여 인라인 표시
      if (lyric.type == LyricType.artist) {
        final parsedLyric = _parseLyricText(lyric.text);
        lyricWidgets.add(
            _buildInlineLyricItem(lyric, i, parsedLyric, isActive: isActive));
      } else {
        // fan, both 타입은 기존 방식대로
        lyricWidgets.add(_buildSimpleLyricItem(lyric, i, isActive: isActive));
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ShaderMask(
        shaderCallback: (Rect rect) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.white,
              Colors.white,
              Colors.transparent
            ],
            stops: [0.0, 0.1, 0.9, 1.0],
          ).createShader(rect);
        },
        blendMode: BlendMode.dstIn,
        child: ListView(
          controller: _lyricsScrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
          children: lyricWidgets,
        ),
      ),
    );
  }

  /// 인라인 마크업 가사 아이템 (artist 타입용)
  Widget _buildInlineLyricItem(
    LyricLine originalLyric,
    int index,
    ParsedLyric parsedLyric, {
    bool isActive = false,
  }) {
    // GlobalKey 리스트 크기 확장
    while (_lyricItemKeys.length <= index) {
      _lyricItemKeys.add(GlobalKey());
    }

    return GestureDetector(
      onTap: () {
        ref.read(lyricsHighlightProvider.notifier).jumpToLyric(index);
        setState(() {
          _isUserScrolling = false;
        });
        final playbackState = ref.read(playbackStateProvider);
        if (!playbackState.isPlaying) {
          ref.read(playbackStateProvider.notifier).play();
        }
      },
      child: Container(
        key: _lyricItemKeys[index],
        margin: const EdgeInsets.symmetric(
          vertical: 10.0, // 고정 마진
          horizontal: 0.0,
        ),
        constraints: const BoxConstraints(
          minHeight: 60.0, // 최소 높이 고정
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 12.0,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.2) // 활성화 시 더 밝게
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              _buildRichTextWithInlineChants(parsedLyric, isActive: isActive),
        ),
      ),
    );
  }

  /// 인라인 팬 응원이 포함된 리치 텍스트 생성 (순서 유지)
  Widget _buildRichTextWithInlineChants(
    ParsedLyric parsedLyric, {
    bool isActive = false,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      children: parsedLyric.components.map((component) {
        if (component is TextComponent) {
          // 일반 텍스트 컴포넌트
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              component.text,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 18, // 고정 크기
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                height: 1.3, // 줄간격 고정
              ),
              textAlign: TextAlign.center,
            ),
          );
        } else if (component is FanChantComponent) {
          // 팬 응원 컴포넌트 - 단순 텍스트 색상만 변경
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              component.text,
              style: TextStyle(
                color: component.type == LyricType.fan
                    ? AppColors.secondary // 팬 응원은 secondary 색상
                    : AppColors.primary, // both는 primary 색상
                fontSize: 18, // 고정 크기
                fontWeight: FontWeight.w700, // 응원 부분은 항상 굵게
                height: 1.3, // 줄간격 고정
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return const SizedBox.shrink(); // fallback
      }).toList(),
    );
  }

  /// 단순 가사 아이템 (fan, both 타입용)
  Widget _buildSimpleLyricItem(
    LyricLine lyric,
    int index, {
    bool isActive = false,
  }) {
    final isBothChant = lyric.type == LyricType.both;
    final isFanChant = lyric.type == LyricType.fan;

    // GlobalKey 리스트 크기 확장
    while (_lyricItemKeys.length <= index) {
      _lyricItemKeys.add(GlobalKey());
    }

    return GestureDetector(
      onTap: () {
        ref.read(lyricsHighlightProvider.notifier).jumpToLyric(index);
        setState(() {
          _isUserScrolling = false;
        });
        final playbackState = ref.read(playbackStateProvider);
        if (!playbackState.isPlaying) {
          ref.read(playbackStateProvider.notifier).play();
        }
      },
      child: Container(
        key: _lyricItemKeys[index],
        margin: const EdgeInsets.symmetric(
          vertical: 10.0, // 고정 마진
          horizontal: 0.0,
        ),
        constraints: const BoxConstraints(
          minHeight: 60.0, // 최소 높이 고정
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 16.0,
          ),
          decoration: BoxDecoration(
            color: isBothChant
                ? AppColors.primary.withOpacity(isActive ? 0.25 : 0.08)
                : isFanChant
                    ? AppColors.secondary.withOpacity(isActive ? 0.3 : 0.1)
                    : Colors.white.withOpacity(isActive ? 0.2 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isBothChant
                  ? AppColors.primary.withOpacity(isActive ? 0.6 : 0.2)
                  : isFanChant
                      ? AppColors.secondary.withOpacity(isActive ? 0.8 : 0.3)
                      : Colors.white.withOpacity(isActive ? 0.5 : 0.1),
              width: isActive ? 2 : 1, // 테두리로 활성화 표시
            ),
          ),
          child: Row(
            children: [
              if (isBothChant || isFanChant)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isBothChant ? Icons.people : Icons.mic_external_on,
                      size: 18,
                      color: Colors.white.withOpacity(isActive ? 0.9 : 0.6),
                    ),
                    if (isBothChant) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.mic,
                        size: 16,
                        color: Colors.white.withOpacity(isActive ? 0.9 : 0.6),
                      ),
                    ],
                    const SizedBox(width: 12),
                  ],
                ),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: isBothChant
                      ? TextStyle(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.7),
                          fontSize: 18, // 고정 크기
                          fontWeight: FontWeight.w800,
                          height: 1.3, // 줄간격 고정
                        )
                      : isFanChant
                          ? TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15, // 고정 크기
                              letterSpacing: 0.3,
                              height: 1.3, // 줄간격 고정
                            )
                          : TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.7),
                              fontSize: 18, // 고정 크기
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                              height: 1.3, // 줄간격 고정
                            ),
                  textAlign: TextAlign.center,
                  child: Text(
                    lyric.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 추가 정보 위젯
  Widget _buildAdditionalInfo() {
    return Column(
      children: [
        // 노래 정보
        _buildInfoSection(
          '노래 정보',
          [
            InfoItem('발매일', widget.song.releaseDate),
            InfoItem('앨범', widget.song.album),
            InfoItem('장르', widget.song.genre),
          ],
        ),

        const SizedBox(height: AppDimensions.margin),

        // 응원법 팁
        _buildInfoSection(
          '응원법 팁',
          [
            InfoItem('', '응원봉을 사용할 때는 가수 파트에서 리듬에 맞춰 흔들어주세요'),
            InfoItem('', '팬 응원 파트에서는 목소리를 크게 내어 함께 호응해주세요'),
            InfoItem('', '콘서트에서는 주변 팬들과 호흡을 맞추는 것이 중요합니다'),
          ],
          isBulletList: true,
        ),
      ],
    );
  }

  /// 정보 섹션 위젯
  Widget _buildInfoSection(
    String title,
    List<InfoItem> items, {
    bool isBulletList = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 12),
          ...items.map((item) => _buildInfoItem(item, isBulletList)),
        ],
      ),
    );
  }

  /// 정보 아이템 위젯
  Widget _buildInfoItem(InfoItem item, bool isBulletList) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: isBulletList
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: AppTextStyles.bodyMedium),
                Expanded(
                  child: Text(
                    item.value,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                ),
              ],
            )
          : RichText(
              text: TextSpan(
                style: AppTextStyles.bodyMedium,
                children: [
                  if (item.label.isNotEmpty)
                    TextSpan(
                      text: '${item.label}: ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  TextSpan(
                    text: item.value,
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
    );
  }

  /// 재생 컨트롤 위젯
  Widget _buildPlaybackControls(PlaybackStateModel playbackState) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // 진행 상태 표시줄
          Row(
            children: [
              Text(
                playbackState.currentPositionText,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: AppColors.primary,
                      overlayColor: AppColors.primary.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: playbackState.progressPercent,
                      onChanged: (value) {
                        final position = Duration(
                          milliseconds: (value *
                                  playbackState.totalDuration.inMilliseconds)
                              .toInt(),
                        );
                        ref
                            .read(playbackStateProvider.notifier)
                            .seekTo(position);
                      },
                    ),
                  ),
                ),
              ),
              Text(
                playbackState.totalDurationText,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 재생 컨트롤
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      ref
                          .read(playbackStateProvider.notifier)
                          .togglePlayPause();

                      // 재생 시작 시 자동 스크롤도 재시작
                      if (!playbackState.isPlaying) {
                        _toggleAutoScroll();
                      }
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40FF4081),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        playbackState.isPlaying
                            ? FlutterRemix.pause_fill
                            : FlutterRemix.play_fill,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 전체화면 모드의 인라인 가사 아이템
  Widget _buildFullScreenInlineLyricItem(
    LyricLine originalLyric,
    int index,
    ParsedLyric parsedLyric, {
    bool isActive = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isActive ? 20.0 : 16.0, // 마진 차이 줄임
        horizontal: 0.0,
      ),
      constraints: const BoxConstraints(
        minHeight: 80.0, // 전체화면용 최소 높이
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 20.0,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildFullScreenRichTextWithInlineChants(parsedLyric,
            isActive: isActive),
      ),
    );
  }

  /// 전체화면용 인라인 팬 응원이 포함된 리치 텍스트
  Widget _buildFullScreenRichTextWithInlineChants(
    ParsedLyric parsedLyric, {
    bool isActive = false,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      children: parsedLyric.components.map((component) {
        if (component is TextComponent) {
          // 일반 텍스트 컴포넌트
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              component.text,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 26, // 고정 크기 (전체화면용)
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                height: 1.4, // 줄간격 고정
              ),
              textAlign: TextAlign.center,
            ),
          );
        } else if (component is FanChantComponent) {
          // 팬 응원 컴포넌트 - 단순 텍스트 색상만 변경
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              component.text,
              style: TextStyle(
                color: component.type == LyricType.fan
                    ? AppColors.secondary // 팬 응원은 secondary 색상
                    : AppColors.primary, // both는 primary 색상
                fontSize: 26, // 고정 크기 (전체화면용)
                fontWeight: FontWeight.w700, // 응원 부분은 항상 굵게
                height: 1.4, // 줄간격 고정
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        return const SizedBox.shrink(); // fallback
      }).toList(),
    );
  }

  /// 전체화면 모드의 단순 가사 아이템
  Widget _buildFullScreenSimpleLyricItem(
    LyricLine lyric,
    int index, {
    bool isActive = false,
  }) {
    final isBothChant = lyric.type == LyricType.both;
    final isFanChant = lyric.type == LyricType.fan;

    return Container(
      margin: EdgeInsets.symmetric(
        vertical: isActive ? 20.0 : 16.0, // 마진 차이 줄임
        horizontal: 0.0,
      ),
      constraints: const BoxConstraints(
        minHeight: 80.0, // 전체화면용 최소 높이
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          vertical: 20.0,
          horizontal: 24.0,
        ),
        decoration: BoxDecoration(
          color: isBothChant
              ? AppColors.primary.withOpacity(isActive ? 0.25 : 0.1)
              : isFanChant
                  ? AppColors.secondary.withOpacity(isActive ? 0.3 : 0.12)
                  : Colors.white.withOpacity(isActive ? 0.2 : 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isBothChant
                ? AppColors.primary.withOpacity(isActive ? 0.5 : 0.25)
                : isFanChant
                    ? AppColors.secondary.withOpacity(isActive ? 0.7 : 0.35)
                    : Colors.white.withOpacity(isActive ? 0.4 : 0.15),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            if (isBothChant || isFanChant)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBothChant ? Icons.people : Icons.mic_external_on,
                    size: 24,
                    color: Colors.white.withOpacity(isActive ? 0.95 : 0.7),
                  ),
                  if (isBothChant) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.mic,
                      size: 20,
                      color: Colors.white.withOpacity(isActive ? 0.95 : 0.7),
                    ),
                  ],
                  const SizedBox(width: 16),
                ],
              ),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: isBothChant
                    ? TextStyle(
                        color: Colors.white.withOpacity(isActive ? 0.98 : 0.75),
                        fontSize: isActive ? 28 : 24, // 크기 차이 줄임 (기존: 30/26)
                        fontWeight: FontWeight.w800,
                        height: 1.4, // 줄간격 고정
                      )
                    : isFanChant
                        ? TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: 0.5,
                            height: 1.4, // 줄간격 고정
                          )
                        : TextStyle(
                            color:
                                Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                            fontSize: isActive ? 28 : 24, // 크기 차이 줄임
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            height: 1.4, // 줄간격 고정
                          ),
                textAlign: TextAlign.center,
                child: Text(
                  lyric.text,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 정보 아이템 클래스
class InfoItem {
  /// 라벨
  final String label;

  /// 값
  final String value;

  /// 생성자
  InfoItem(this.label, this.value);
}
