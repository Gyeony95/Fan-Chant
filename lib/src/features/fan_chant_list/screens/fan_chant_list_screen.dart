import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/core/theme/colors.dart';
import 'package:fan_chant/src/core/theme/app_dimensions.dart';
import 'package:fan_chant/src/core/theme/text_styles.dart';
import 'package:fan_chant/src/core/widgets/safe_image.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_recognition/services/lyrics_service.dart';
import 'package:fan_chant/src/features/song_detail/screens/song_detail_screen.dart';
import 'package:flutter_remix/flutter_remix.dart';

/// 모든 응원법을 불러오는 프로바이더
final fanChantSongsProvider = FutureProvider<List<Song>>((ref) async {
  return await LyricsService.instance.loadAllSongs();
});

/// 응원법 리스트 화면
class FanChantListScreen extends ConsumerWidget {
  /// 생성자
  const FanChantListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fanChantSongsAsync = ref.watch(fanChantSongsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 타이틀
            _buildHeader(),

            // 응원법 리스트
            Expanded(
              child: fanChantSongsAsync.when(
                loading: () => _buildLoadingWidget(),
                error: (error, stack) => _buildErrorWidget(error),
                data: (songs) => _buildSongsList(context, songs),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 헤더 위젯
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            FlutterRemix.music_2_line,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '응원법 가이드',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '모든 응원법을 확인해보세요',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 로딩 위젯
  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
      ),
    );
  }

  /// 에러 위젯
  Widget _buildErrorWidget(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FlutterRemix.error_warning_line,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '응원법을 불러올 수 없습니다',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 노래 리스트 위젯
  Widget _buildSongsList(BuildContext context, List<Song> songs) {
    if (songs.isEmpty) {
      return _buildEmptyWidget();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.padding),
      itemCount: songs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongCard(context, song);
      },
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FlutterRemix.music_2_line,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '응원법이 없습니다',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textMedium,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '응원법 가이드가 있는 노래를 추가해주세요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 노래 카드 위젯
  Widget _buildSongCard(BuildContext context, Song song) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SongDetailScreen(song: song),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 앨범 커버
            SafeImage(
              imageUrl: song.albumCoverUrl,
              width: 60,
              height: 60,
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
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
                    song.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textMedium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(
                              AppDimensions.borderRadiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FlutterRemix.mic_line,
                              size: 12,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '응원법 가이드',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (song.genre.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.borderRadiusFull),
                          ),
                          child: Text(
                            song.genre,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textMedium,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 화살표 아이콘
            Icon(
              FlutterRemix.arrow_right_s_line,
              color: AppColors.textLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
