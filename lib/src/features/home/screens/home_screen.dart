import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fan_chant/src/core/theme/colors.dart';
import 'package:fan_chant/src/core/theme/app_dimensions.dart';
import 'package:fan_chant/src/core/theme/text_styles.dart';
import 'package:fan_chant/src/features/song_recognition/screens/song_recognition_screen.dart';
import 'package:fan_chant/src/features/favorites/screens/favorites_screen.dart';
import 'package:fan_chant/src/features/fan_chant_list/screens/fan_chant_list_screen.dart';
import 'package:flutter_remix/flutter_remix.dart';

/// 선택된 탭 인덱스를 관리하는 프로바이더
final selectedTabProvider = StateProvider<int>((ref) => 0);

/// 홈 화면 (바텀 네비게이션과 PageView 포함)
class HomeScreen extends ConsumerStatefulWidget {
  /// 생성자
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // 페이지 컨트롤러
  late final PageController _pageController;

  // 페이지 목록 - 미리 생성하여 재사용
  final List<Widget> _pages = [
    const SongRecognitionScreen(),
    const FanChantListScreen(),
    const FavoritesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 현재 선택된 탭 인덱스
    final selectedTab = ref.watch(selectedTabProvider);

    // PageStorage에서 사용할 키
    final pageStorageBucket = PageStorageBucket();

    return Scaffold(
      body: PageStorage(
        bucket: pageStorageBucket,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // 스와이프로 페이지 전환 방지
          onPageChanged: (index) {
            // 페이지가 변경되면 선택된 탭 업데이트
            ref.read(selectedTabProvider.notifier).state = index;
          },
          children: _pages,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(selectedTab),
    );
  }

  /// 하단 탭바 위젯
  Widget _buildBottomNavigationBar(int selectedTab) {
    return SafeArea(
      child: Container(
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
            // 인식 탭
            _buildBottomNavItem(
              FlutterRemix.mic_line,
              '인식',
              isSelected: selectedTab == 0,
              onTap: () => _onTabTapped(0),
            ),

            // 응원법 탭
            _buildBottomNavItem(
              FlutterRemix.music_2_line,
              '응원법',
              isSelected: selectedTab == 1,
              onTap: () => _onTabTapped(1),
            ),

            // 찜 탭
            _buildBottomNavItem(
              FlutterRemix.heart_line,
              '찜',
              isSelected: selectedTab == 2,
              onTap: () => _onTabTapped(2),
            ),
          ],
        ),
      ),
    );
  }

  /// 하단 탭바 아이템 위젯
  Widget _buildBottomNavItem(
    IconData icon,
    String label, {
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
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

  /// 탭 탭했을 때 처리
  void _onTabTapped(int index) {
    // 페이지 컨트롤러로 페이지 이동
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // 상태 업데이트
    ref.read(selectedTabProvider.notifier).state = index;
  }
}
