import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/config/routes.dart';
import 'package:fan_chant/src/core/theme/colors.dart';
import 'package:fan_chant/src/core/theme/app_dimensions.dart';
import 'package:fan_chant/src/core/theme/text_styles.dart';
import 'package:fan_chant/src/features/song_recognition/models/song.dart';
import 'package:fan_chant/src/features/song_recognition/providers/song_provider.dart';
import 'package:flutter_remix/flutter_remix.dart';

/// 노래 인식 화면
class SongRecognitionScreen extends ConsumerWidget {
  /// 생성자
  const SongRecognitionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recognitionState = ref.watch(songRecognitionProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션 바
            _buildAppBar(),

            // 메인 콘텐츠
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.padding,
                  AppDimensions.paddingSmall,
                  AppDimensions.padding,
                  AppDimensions.padding,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      '노래를 인식하여 응원법을 찾아보세요',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),

                    // 인식 버튼
                    Expanded(
                      child: Center(
                        child: _buildRecognitionButton(
                            context, ref, recognitionState),
                      ),
                    ),

                    // 인식 상태
                    if (recognitionState.status ==
                            SongRecognitionStatus.recognizing ||
                        recognitionState.status ==
                            SongRecognitionStatus.failure)
                      _buildRecognitionStatus(),

                    // 최근 인식한 노래
                    _buildRecentSongs(context, ref),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// 상단 앱바 위젯
  Widget _buildAppBar() {
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
          'FanChant',
          style: AppTextStyles.logo,
        ),
      ),
    );
  }

  /// 인식 버튼 위젯
  Widget _buildRecognitionButton(
    BuildContext context,
    WidgetRef ref,
    SongRecognitionState state,
  ) {
    // 인식 중인지 확인
    final isRecognizing = state.status == SongRecognitionStatus.recognizing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // 파동 효과 (인식 중일 때만 표시)
            if (isRecognizing) ...[
              _buildRippleEffect(300, 0.2),
              _buildRippleEffect(240, 0.3, delay: 0.5),
              _buildRippleEffect(180, 0.4, delay: 1.0),
            ],

            // 메인 버튼
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: () => isRecognizing
                    ? _cancelRecognition(ref)
                    : _startRecognition(ref, context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isRecognizing
                          ? FlutterRemix.stop_line
                          : FlutterRemix.mic_line,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isRecognizing) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _cancelRecognition(ref),
            child: Text(
              '취소',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 파동 효과 위젯
  Widget _buildRippleEffect(double size, double opacity, {double delay = 0.0}) {
    return _RippleEffectWidget(
      size: size,
      opacity: opacity,
      delay: delay,
      color: AppColors.primary,
    );
  }

  /// 인식 상태 위젯
  Widget _buildRecognitionStatus() {
    return Consumer(
      builder: (context, ref, child) {
        final recognitionState = ref.watch(songRecognitionProvider);
        final progress = recognitionState.recognitionProgress;
        final message = recognitionState.statusMessage ?? '노래 인식 중...';

        return Column(
          children: [
            const SizedBox(height: 20),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),

            // 진행 상황 표시기
            Stack(
              alignment: Alignment.center,
              children: [
                // 진행 상황 원형 표시
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4.0,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),

                // 사운드 웨이브 효과
                SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      12,
                      (index) => _buildSoundWaveLine(index),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            if (recognitionState.statusMessage?.contains('다시 시도') ?? false)
              Text(
                '음악 소리를 크게 하고 다시 시도해보세요',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textMedium,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        );
      },
    );
  }

  /// 사운드 웨이브 라인 위젯
  Widget _buildSoundWaveLine(int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: Duration(milliseconds: 800 + (index * 100) % 400),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Container(
            width: 4,
            height: 30 * value,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        },
      ),
    );
  }

  /// 최근 인식한 노래 목록 위젯
  Widget _buildRecentSongs(BuildContext context, WidgetRef ref) {
    final songs = Song.getSampleSongs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          '최근 인식한 노래',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: songs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final song = songs[index];
            return _buildSongItem(context, ref, song);
          },
        ),
      ],
    );
  }

  /// 노래 아이템 위젯
  Widget _buildSongItem(BuildContext context, WidgetRef ref, Song song) {
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
                    horizontal: AppDimensions.paddingSmall),
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

  /// 하단 탭바 위젯
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      height: AppDimensions.bottomTabBarHeight,
      child: Row(
        children: [
          _buildBottomNavItem(FlutterRemix.mic_line, '인식', isSelected: true),
          _buildBottomNavItem(FlutterRemix.history_line, '기록'),
          _buildBottomNavItem(FlutterRemix.user_line, '프로필'),
        ],
      ),
    );
  }

  /// 하단 탭바 아이템 위젯
  Widget _buildBottomNavItem(
    IconData icon,
    String label, {
    bool isSelected = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {},
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 노래 인식 시작 메서드
  Future<void> _startRecognition(WidgetRef ref, BuildContext context) async {
    final notifier = ref.read(songRecognitionProvider.notifier);
    await notifier.startRecognition();

    final state = ref.read(songRecognitionProvider);
    if (state.status == SongRecognitionStatus.success &&
        state.recognizedSong != null) {
      // 인식된 노래가 있으면 상세 화면으로 이동
      notifier.addToRecentSongs(state.recognizedSong!);
      await AppRoutes.navigateToSongDetail(context, state.recognizedSong!);
    } else if (state.status == SongRecognitionStatus.failure) {
      // 인식 실패 시 처리
      await AppRoutes.navigateToRecognitionFailed(context);
    }
  }

  /// 노래 인식 취소 메서드
  void _cancelRecognition(WidgetRef ref) {
    final notifier = ref.read(songRecognitionProvider.notifier);
    notifier.cancelRecognition();
  }

  /// 노래 선택 메서드
  Future<void> _onSongSelected(
      BuildContext context, WidgetRef ref, Song song) async {
    final notifier = ref.read(songRecognitionProvider.notifier);
    notifier.selectSong(song);
    notifier.addToRecentSongs(song);
    await AppRoutes.navigateToSongDetail(context, song);
  }
}

/// 파동 효과를 위한 Stateful 위젯
class _RippleEffectWidget extends StatefulWidget {
  final double size;
  final double opacity;
  final double delay;
  final Color color;

  const _RippleEffectWidget({
    required this.size,
    required this.opacity,
    required this.delay,
    required this.color,
  });

  @override
  State<_RippleEffectWidget> createState() => _RippleEffectWidgetState();
}

class _RippleEffectWidgetState extends State<_RippleEffectWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 생성
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // 애니메이션 정의
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // 지연 후 애니메이션 시작
    Future.delayed(Duration(milliseconds: (widget.delay * 1000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color
                .withOpacity(widget.opacity * (1 - _animation.value)),
          ),
        );
      },
    );
  }
}
