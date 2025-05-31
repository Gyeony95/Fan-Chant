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
    // 현재 가사 인덱스가 변경되면 스크롤 위치 업데이트
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentLyricIndex >= 0 && currentLyricIndex < lyrics.length) {
        final itemHeight = 70.0; // 각 가사 항목의 대략적인 높이
        final screenHeight = 380.0; // 가사 컨테이너의 높이
        final offset = (currentLyricIndex * itemHeight) -
            (screenHeight / 2) +
            (itemHeight / 2);

        if (_lyricsScrollController.hasClients) {
          _lyricsScrollController.animateTo(
            math.max(0, offset),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      }
    });

    return ShaderMask(
      shaderCallback: (Rect rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent
          ],
          stops: const [0.0, 0.1, 0.9, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: ListView.builder(
        controller: _lyricsScrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
        itemCount: lyrics.length,
        itemBuilder: (context, index) {
          final lyric = lyrics[index];
          final isActive = index == currentLyricIndex;

          return _buildAppleMusicLyricItem(lyric, index, isActive: isActive);
        },
      ),
    );
  }

  /// 애플 뮤직 스타일 가사 아이템
  Widget _buildAppleMusicLyricItem(LyricLine lyric, int index,
      {bool isActive = false}) {
    // 팬 응원법인 경우 특별한 스타일 적용
    final isFanChant = lyric.type == LyricType.fan;

    return GestureDetector(
      onTap: () {
        // 가사 터치 시 해당 시간으로 이동
        ref.read(lyricsHighlightProvider.notifier).jumpToLyric(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          vertical: isActive ? 12.0 : 8.0,
          horizontal: isActive
              ? 0.0
              : isFanChant
                  ? 20.0
                  : 10.0,
        ),
        padding: EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: isFanChant ? 14.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: isFanChant
              ? AppColors.secondary.withOpacity(isActive ? 0.3 : 0.1)
              : isActive
                  ? Colors.white.withOpacity(0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(isFanChant ? 24 : 12),
          border: isFanChant
              ? Border.all(
                  color: AppColors.secondary.withOpacity(isActive ? 0.6 : 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            if (isFanChant)
              Icon(
                Icons.mic_external_on,
                size: 16,
                color: Colors.white.withOpacity(isActive ? 0.9 : 0.5),
              ),
            if (isFanChant) const SizedBox(width: 8),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: isFanChant
                    ? AppTextStyles.appleMusicFanChant.copyWith(
                        color: Colors.white.withOpacity(isActive ? 0.9 : 0.6),
                        fontSize: isActive ? 16 : 14,
                      )
                    : isActive
                        ? AppTextStyles.appleMusicActiveLyric
                        : AppTextStyles.appleMusicInactiveLyric,
                textAlign: isFanChant ? TextAlign.left : TextAlign.center,
                child: Text(
                  lyric.text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
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
