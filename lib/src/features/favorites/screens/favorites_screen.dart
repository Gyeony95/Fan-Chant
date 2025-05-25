import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/config/routes.dart';
import 'package:fan_chant/src/core/theme/colors.dart';
import 'package:fan_chant/src/core/theme/app_dimensions.dart';
import 'package:fan_chant/src/core/theme/text_styles.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_recognition/providers/song_provider.dart';
import 'package:flutter_remix/flutter_remix.dart';

/// 찜한 노래 목록 화면
class FavoritesScreen extends ConsumerStatefulWidget {
  /// 생성자
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin 사용 시 필수
    // 찜한 노래 목록 가져오기
    final favoriteSongs = ref.watch(favoriteSongsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션 바
            _buildAppBar(context),

            // 메인 콘텐츠
            Expanded(
              child: favoriteSongs.isEmpty
                  ? _buildEmptyState()
                  : _buildFavoritesList(context, ref, favoriteSongs),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 앱바 위젯
  Widget _buildAppBar(BuildContext context) {
    return Container(
      height: AppDimensions.appBarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.padding),
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
      child: Center(
        child: Text(
          '찜한 노래',
          style: AppTextStyles.title,
        ),
      ),
    );
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FlutterRemix.heart_line,
            size: 80,
            color: AppColors.textLight,
          ),
          const SizedBox(height: 16),
          Text(
            '찜한 노래가 없습니다',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textMedium,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '마음에 드는 노래를 찾아 하트를 눌러보세요',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  /// 찜한 노래 목록 위젯
  Widget _buildFavoritesList(
      BuildContext context, WidgetRef ref, List<Song> songs) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppDimensions.padding),
      itemCount: songs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongItem(context, ref, song);
      },
    );
  }

  /// 노래 아이템 위젯
  Widget _buildSongItem(BuildContext context, WidgetRef ref, Song song) {
    final songRecognition = ref.watch(songRecognitionProvider.notifier);

    return InkWell(
      onTap: () => _onSongSelected(context, ref, song),
      borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingSmall),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.borderRadius),
        ),
        child: Row(
          children: [
            // 앨범 커버
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(AppDimensions.borderRadiusSmall),
              child: Image.network(
                song.albumCoverUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),

            // 노래 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSmall,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 찜 아이콘
            IconButton(
              onPressed: () async {
                await songRecognition.toggleFavorite(song);
              },
              icon: Icon(
                FlutterRemix.heart_fill,
                color: Colors.red,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            const SizedBox(width: 8),

            // 화살표 아이콘
            Icon(
              FlutterRemix.arrow_right_s_line,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  /// 노래 선택 메서드
  Future<void> _onSongSelected(
      BuildContext context, WidgetRef ref, Song song) async {
    final notifier = ref.read(songRecognitionProvider.notifier);
    notifier.selectSong(song);
    await notifier.addToRecentSongs(song);
    await AppRoutes.navigateToSongDetail(context, song);
  }
}
