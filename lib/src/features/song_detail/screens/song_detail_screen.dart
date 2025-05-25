import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/core/theme/colors.dart';
import 'package:fan_chant/src/core/theme/app_dimensions.dart';
import 'package:fan_chant/src/core/theme/text_styles.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_detail/providers/song_detail_provider.dart';
import 'package:fan_chant/src/features/song_recognition/providers/song_provider.dart';
import 'package:flutter_remix/flutter_remix.dart';

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
  @override
  void initState() {
    super.initState();
    // 현재 노래 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentSongProvider.notifier).setCurrentSong(widget.song);
      // 재생 시작
      ref.read(playbackStateProvider.notifier).play();
    });
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
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          child: Image.network(
            widget.song.albumCoverUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
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
              ),
              const SizedBox(height: 4),
              Text(
                widget.song.artist,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textMedium,
                ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.margin),
      padding: const EdgeInsets.all(AppDimensions.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 및 범례
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '가사 및 응원법',
                style: AppTextStyles.subtitle,
              ),
              Row(
                children: [
                  _buildLegendItem(AppColors.primary, '가수'),
                  const SizedBox(width: 8),
                  _buildLegendItem(AppColors.secondary, '팬'),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.marginLarge),

          // 가사 목록
          if (widget.song.lyrics != null)
            ...List.generate(
              widget.song.lyrics!.length,
              (index) => _buildLyricItem(
                widget.song.lyrics![index],
                isHighlighted: index == currentLyricIndex,
              ),
            ),
        ],
      ),
    );
  }

  /// 범례 아이템 위젯
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall,
        ),
      ],
    );
  }

  /// 가사 아이템 위젯
  Widget _buildLyricItem(LyricLine lyric, {bool isHighlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
      ),
      decoration: isHighlighted || lyric.isHighlighted
          ? BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              border: Border(
                left: BorderSide(
                  color: AppColors.primary,
                  width: 3,
                ),
              ),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 가수 파트
          if (lyric.type == LyricType.artist)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: isHighlighted || lyric.isHighlighted ? 8 : 0,
                ),
                child: Text(
                  lyric.text,
                  style: isHighlighted || lyric.isHighlighted
                      ? AppTextStyles.highlightedLyrics
                      : AppTextStyles.artistLyrics,
                  textAlign: TextAlign.left,
                ),
              ),
            )
          else
            const Spacer(),

          // 팬 파트
          if (lyric.type == LyricType.fan)
            Expanded(
              child: Text(
                lyric.text,
                style: isHighlighted || lyric.isHighlighted
                    ? AppTextStyles.highlightedLyrics.copyWith(
                        color: AppColors.secondary,
                      )
                    : AppTextStyles.fanLyrics,
                textAlign: TextAlign.right,
              ),
            )
          else
            const Spacer(),
        ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  FlutterRemix.repeat_line,
                  color: AppColors.textMedium,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      FlutterRemix.skip_back_line,
                      size: 28,
                      color: AppColors.textDark,
                    ),
                  ),
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
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      FlutterRemix.skip_forward_line,
                      size: 28,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  FlutterRemix.volume_up_line,
                  color: AppColors.textMedium,
                ),
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
