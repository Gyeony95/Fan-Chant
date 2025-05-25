import 'package:flutter/material.dart';

/// 이미지 로딩 실패 시 플레이스홀더를 표시하는 안전한 이미지 위젯
class SafeImage extends StatelessWidget {
  /// 이미지 URL
  final String? imageUrl;

  /// 이미지 너비
  final double? width;

  /// 이미지 높이
  final double? height;

  /// 이미지 채우기 방식
  final BoxFit fit;

  /// 이미지 테두리 반경
  final BorderRadius? borderRadius;

  /// 플레이스홀더 아이콘
  final IconData placeholderIcon;

  /// 플레이스홀더 색상
  final Color placeholderColor;

  /// 생성자
  const SafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.music_note,
    this.placeholderColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    // URL이 유효하지 않으면 플레이스홀더 표시
    if (imageUrl == null || imageUrl!.isEmpty || imageUrl == "file:///") {
      return _buildPlaceholder();
    }

    // 이미지 로드 시도 및 에러 처리
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return _buildLoadingPlaceholder();
        },
      ),
    );
  }

  /// 플레이스홀더 위젯 생성
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor.withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child: Icon(
          placeholderIcon,
          color: placeholderColor,
          size: (width != null && height != null)
              ? (width! < height! ? width! / 2 : height! / 2)
              : 24,
        ),
      ),
    );
  }

  /// 로딩 중 플레이스홀더 위젯 생성
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: placeholderColor.withOpacity(0.1),
        borderRadius: borderRadius ?? BorderRadius.zero,
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(placeholderColor),
          ),
        ),
      ),
    );
  }
}
