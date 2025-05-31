import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/core/theme/colors.dart';
import 'package:fan_chant/src/core/theme/text_styles.dart';
import 'package:fan_chant/src/core/widgets/safe_image.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_detail/providers/song_detail_provider.dart';
import 'package:fan_chant/src/features/song_recognition/providers/song_provider.dart';
import 'package:flutter_remix/flutter_remix.dart';
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

/// 전체화면 가사 화면
class FullScreenLyricsScreen extends ConsumerStatefulWidget {
  /// 노래 정보
  final Song song;

  /// 생성자
  const FullScreenLyricsScreen({
    required this.song,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<FullScreenLyricsScreen> createState() =>
      _FullScreenLyricsScreenState();
}

class _FullScreenLyricsScreenState
    extends ConsumerState<FullScreenLyricsScreen> {
  // 가사 스크롤 컨트롤러
  final ScrollController _lyricsScrollController = ScrollController();

  // 자동 스크롤 상태 관리
  bool _isUserScrolling = false;
  int _lastAutoScrollIndex = -1;

  // 가사 아이템들의 GlobalKey 리스트 (정확한 위치 계산용)
  final List<GlobalKey> _lyricItemKeys = [];

  // UI 표시 상태
  bool _showUI = true;

  @override
  void initState() {
    super.initState();

    // 상태 바와 네비게이션 바 숨기기
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 3초 후 UI 숨기기
    _hideUIAfterDelay();
  }

  @override
  void dispose() {
    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _lyricsScrollController.dispose();
    super.dispose();
  }

  /// UI 자동 숨기기
  void _hideUIAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showUI = false;
        });
      }
    });
  }

  /// UI 토글
  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });

    if (_showUI) {
      _hideUIAfterDelay();
    }
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

  /// 개선된 스크롤 함수
  void _scrollToLyric(int index, int totalLyrics) {
    if (!_lyricsScrollController.hasClients) return;

    // GlobalKey 리스트 크기가 부족한 경우 확장
    while (_lyricItemKeys.length <= index) {
      _lyricItemKeys.add(GlobalKey());
    }

    // 화면 높이 가져오기
    final screenHeight = MediaQuery.of(context).size.height;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_lyricsScrollController.hasClients) return;

      final currentKey = _lyricItemKeys[index];
      final RenderBox? renderBox =
          currentKey.currentContext?.findRenderObject() as RenderBox?;

      double targetOffset;

      if (renderBox != null) {
        try {
          final scrollRenderBox = _lyricsScrollController
              .position.context.storageContext
              .findRenderObject() as RenderBox?;

          if (scrollRenderBox != null) {
            final itemGlobalPosition = renderBox.localToGlobal(Offset.zero);
            final scrollGlobalPosition =
                scrollRenderBox.localToGlobal(Offset.zero);

            final itemRelativeY =
                itemGlobalPosition.dy - scrollGlobalPosition.dy;
            final itemHeight = renderBox.size.height;

            final itemActualPosition =
                _lyricsScrollController.offset + itemRelativeY;

            // 화면 중앙에 위치시키기
            targetOffset =
                itemActualPosition + (itemHeight / 2) - (screenHeight / 2);
          } else {
            targetOffset = _calculateEstimatedOffset(index, screenHeight);
          }
        } catch (e) {
          targetOffset = _calculateEstimatedOffset(index, screenHeight);
        }
      } else {
        targetOffset = _calculateEstimatedOffset(index, screenHeight);
      }

      final maxScrollExtent = _lyricsScrollController.position.maxScrollExtent;
      final minScrollExtent = _lyricsScrollController.position.minScrollExtent;

      double finalOffset;

      if (index <= 1) {
        finalOffset = minScrollExtent;
      } else if (index >= totalLyrics - 2) {
        finalOffset = maxScrollExtent;
      } else {
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
  double _calculateEstimatedOffset(int index, double screenHeight) {
    const estimatedItemHeight = 80.0;
    const estimatedSpacing = 30.0;

    final estimatedPosition = index * (estimatedItemHeight + estimatedSpacing);
    return estimatedPosition - (screenHeight / 2);
  }

  /// 사용자 스크롤 감지
  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        setState(() {
          _isUserScrolling = true;
        });

        final playbackState = ref.read(playbackStateProvider);
        if (playbackState.isPlaying) {
          ref.read(playbackStateProvider.notifier).pause();
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackStateProvider);
    final currentLyricIndex = ref.watch(lyricsHighlightProvider);
    final currentSong = ref.watch(currentSongProvider);
    final lyrics = currentSong?.lyrics ?? widget.song.lyrics;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          children: [
            // 배경 앨범 아트
            Positioned.fill(
              child: SafeImage(
                imageUrl: widget.song.albumCoverUrl,
                fit: BoxFit.cover,
              ),
            ),

            // 배경 오버레이
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),

            // 가사 내용
            if (lyrics != null && lyrics.isNotEmpty)
              Positioned.fill(
                child: _buildFullScreenLyrics(lyrics, currentLyricIndex),
              ),

            // 상단 UI (제목, 뒤로가기)
            if (_showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopUI(),
              ),

            // 하단 UI (재생 컨트롤)
            if (_showUI)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomUI(playbackState),
              ),
          ],
        ),
      ),
    );
  }

  /// 상단 UI
  Widget _buildTopUI() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // 뒤로가기 버튼
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              FlutterRemix.arrow_left_s_line,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          // 노래 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.song.artist,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 UI (재생 컨트롤)
  Widget _buildBottomUI(PlaybackStateModel playbackState) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 진행 상태 표시줄
          Row(
            children: [
              Text(
                playbackState.currentPositionText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white.withOpacity(0.3),
                      thumbColor: Colors.white,
                      overlayColor: Colors.white.withOpacity(0.2),
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 재생 버튼
          GestureDetector(
            onTap: () {
              ref.read(playbackStateProvider.notifier).togglePlayPause();

              if (!playbackState.isPlaying) {
                setState(() {
                  _isUserScrolling = false;
                });
              }
            },
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                playbackState.isPlaying
                    ? FlutterRemix.pause_fill
                    : FlutterRemix.play_fill,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 전체화면 가사 표시
  Widget _buildFullScreenLyrics(List<LyricLine> lyrics, int currentLyricIndex) {
    final playbackState = ref.watch(playbackStateProvider);

    // 자동 스크롤 처리
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
        lyricWidgets.add(_buildFullScreenLyricItem(lyric, i, parsedLyric,
            isActive: isActive));
      } else {
        // fan, both 타입은 기존 방식대로
        lyricWidgets
            .add(_buildFullScreenSimpleLyricItem(lyric, i, isActive: isActive));
      }
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListView(
        controller: _lyricsScrollController,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.of(context).size.height * 0.3,
          horizontal: 40,
        ),
        children: lyricWidgets,
      ),
    );
  }

  /// 전체화면용 인라인 마크업 가사 아이템
  Widget _buildFullScreenLyricItem(
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
          vertical: 16.0, // 고정 마진
          horizontal: 0.0,
        ),
        constraints: const BoxConstraints(
          minHeight: 80.0, // 최소 높이 고정
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 20.0,
          ),
          decoration: BoxDecoration(
            color:
                isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: _buildFullScreenRichText(parsedLyric, isActive: isActive),
        ),
      ),
    );
  }

  /// 전체화면용 리치 텍스트 (순서 유지)
  Widget _buildFullScreenRichText(
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
                color: isActive ? Colors.white : Colors.white.withOpacity(0.6),
                fontSize: 26, // 고정 크기 (전체화면용)
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                height: 1.4, // 줄간격 고정
              ),
              textAlign: TextAlign.center,
            ),
          );
        } else if (component is FanChantComponent) {
          // 팬 응원 컴포넌트
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: component.type == LyricType.fan
                  ? AppColors.secondary.withOpacity(isActive ? 0.9 : 0.8)
                  : AppColors.primary.withOpacity(isActive ? 0.9 : 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: component.type == LyricType.fan
                    ? AppColors.secondary
                    : AppColors.primary,
                width: isActive ? 2 : 1.5, // 테두리로 활성화 표시
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  component.type == LyricType.fan
                      ? Icons.mic_external_on
                      : Icons.people,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  component.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16, // 고정 크기
                    height: 1.2,
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink(); // fallback
      }).toList(),
    );
  }

  /// 전체화면용 단순 가사 아이템
  Widget _buildFullScreenSimpleLyricItem(
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
          vertical: 16.0, // 고정 마진
          horizontal: 0.0,
        ),
        constraints: const BoxConstraints(
          minHeight: 80.0, // 최소 높이 고정
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            vertical: 20.0,
            horizontal: 20.0,
          ),
          decoration: BoxDecoration(
            color: isBothChant
                ? AppColors.primary.withOpacity(isActive ? 0.35 : 0.15)
                : isFanChant
                    ? AppColors.secondary.withOpacity(isActive ? 0.35 : 0.15)
                    : Colors.white.withOpacity(isActive ? 0.15 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isBothChant
                  ? AppColors.primary.withOpacity(isActive ? 0.7 : 0.3)
                  : isFanChant
                      ? AppColors.secondary.withOpacity(isActive ? 0.7 : 0.3)
                      : Colors.white.withOpacity(isActive ? 0.4 : 0.1),
              width: isActive ? 2 : 1.5, // 테두리로 활성화 표시
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
                      color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                    ),
                    if (isBothChant) ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.mic,
                        size: 20,
                        color: Colors.white.withOpacity(isActive ? 1.0 : 0.7),
                      ),
                    ],
                    const SizedBox(width: 16),
                  ],
                ),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color:
                        isActive ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: isFanChant ? 20 : 24, // 고정 크기 (타입별 차이)
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
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
      ),
    );
  }
}
