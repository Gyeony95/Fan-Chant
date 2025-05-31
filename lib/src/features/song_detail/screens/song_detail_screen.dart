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
import 'package:flutter_remix/flutter_remix.dart';
import 'dart:math' as math;

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

      // 재생 시작
      ref.read(playbackStateProvider.notifier).play();
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

  /// 지정된 가사로 스크롤
  void _scrollToLyric(int index, int totalLyrics) {
    if (!_lyricsScrollController.hasClients) return;

    final itemHeight = 70.0;
    final screenHeight = 380.0;
    final offset = (index * itemHeight) - (screenHeight / 2) + (itemHeight / 2);
    final maxScrollExtent = _lyricsScrollController.position.maxScrollExtent;
    final targetOffset = math.max(0.0, math.min(offset, maxScrollExtent));

    _lyricsScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );

    _lastAutoScrollIndex = index;
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

                      // 추가 정보
                      _buildAdditionalInfo(),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 뒤로가기 버튼
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(FlutterRemix.arrow_left_s_line),
          ),

          // 제목
          Text(
            widget.song.title,
            style: AppTextStyles.title,
          ),

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
              isFavorite ? FlutterRemix.heart_fill : FlutterRemix.heart_line,
              color: isFavorite ? Colors.red : AppColors.textLight,
            ),
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
              Container(
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
    // 팬 전용 파트는 스킵하고 가수/함께 부르는 파트만 포커싱
    if (playbackState.isPlaying &&
        !_isUserScrolling &&
        currentLyricIndex >= 0 &&
        currentLyricIndex < lyrics.length &&
        currentLyricIndex != _lastAutoScrollIndex) {
      // 현재 가사가 팬 전용 파트가 아닌 경우에만 스크롤
      final currentLyric = lyrics[currentLyricIndex];
      if (currentLyric.type != LyricType.fan) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToLyric(currentLyricIndex, lyrics.length);
        });
      }
    }

    // 가수/함께 부르는 파트만 표시하고, 각 파트 아래에 관련 팬 응원 표시
    final mainLyrics = <Widget>[];

    for (int i = 0; i < lyrics.length; i++) {
      final lyric = lyrics[i];

      // 팬 전용 파트는 개별적으로 표시하지 않음 (메인 파트와 함께 표시됨)
      if (lyric.type == LyricType.fan) {
        continue;
      }

      final isActive = i == currentLyricIndex;

      // 현재 가사 다음에 오는 팬 응원 파트들 찾기
      final List<LyricLine> fanChants = [];
      for (int j = i + 1; j < lyrics.length; j++) {
        if (lyrics[j].type == LyricType.fan) {
          fanChants.add(lyrics[j]);
        } else {
          break;
        }
      }

      mainLyrics.add(
          _buildMainLyricWithFanChant(lyric, i, fanChants, isActive: isActive));
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
          children: mainLyrics,
        ),
      ),
    );
  }

  /// 메인 가사와 팬 응원을 함께 표시하는 위젯
  Widget _buildMainLyricWithFanChant(
    LyricLine mainLyric,
    int index,
    List<LyricLine> fanChants, {
    bool isActive = false,
  }) {
    final isBothChant = mainLyric.type == LyricType.both;

    return GestureDetector(
      onTap: () {
        // 가사 터치 시 해당 시간으로 이동
        ref.read(lyricsHighlightProvider.notifier).jumpToLyric(index);

        // 사용자 스크롤 상태 해제 및 재생 시작
        setState(() {
          _isUserScrolling = false;
        });

        // 재생 시작
        final playbackState = ref.read(playbackStateProvider);
        if (!playbackState.isPlaying) {
          ref.read(playbackStateProvider.notifier).play();
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: isActive ? 16.0 : 12.0,
          horizontal: 0.0,
        ),
        child: Column(
          children: [
            // 메인 가사 (가수 또는 함께 부르는 파트)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                vertical: 12.0,
                horizontal: isBothChant ? 16.0 : 12.0,
              ),
              decoration: BoxDecoration(
                color: isBothChant
                    ? AppColors.primary.withOpacity(isActive ? 0.2 : 0.08)
                    : isActive
                        ? Colors.white.withOpacity(0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(isBothChant ? 16 : 12),
                border: isBothChant
                    ? Border.all(
                        color:
                            AppColors.primary.withOpacity(isActive ? 0.4 : 0.2),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  if (isBothChant)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 18,
                          color: Colors.white.withOpacity(isActive ? 0.9 : 0.6),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.mic,
                          size: 16,
                          color: Colors.white.withOpacity(isActive ? 0.9 : 0.6),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: isBothChant
                          ? AppTextStyles.appleMusicActiveLyric.copyWith(
                              color: Colors.white
                                  .withOpacity(isActive ? 0.95 : 0.7),
                              fontSize: isActive ? 22 : 18,
                              fontWeight: FontWeight.w800,
                            )
                          : isActive
                              ? AppTextStyles.appleMusicActiveLyric
                              : AppTextStyles.appleMusicInactiveLyric,
                      textAlign: TextAlign.center,
                      child: Text(
                        mainLyric.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 팬 응원 파트들 (서브 정보)
            if (fanChants.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...fanChants.map((fanChant) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.6),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.mic_external_on,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            fanChant.text,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
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
