import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// 카메라 라이브 프리뷰 위젯 (FPS 오버레이 포함)
class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final double liveFps;
  final VoidCallback? onClose;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    required this.liveFps,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 220,
      color: Colors.black,
      child: Stack(
        children: [
          // 카메라 프리뷰
          Center(
            child: CameraPreview(controller),
          ),

          // 상단 그라디언트 오버레이
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 하단 그라디언트 오버레이
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // FPS 오버레이 (좌측 상단)
          Positioned(
            top: 12,
            left: 12,
            child: _buildFpsOverlay(context),
          ),

          // 해상도 정보 (좌측 하단)
          Positioned(
            bottom: 12,
            left: 12,
            child: _buildResolutionOverlay(context),
          ),

          // 닫기 버튼 (우측 상단)
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
              color: Colors.white70,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black38,
              ),
            ),
          ),

          // LIVE 배지 (우측 하단)
          Positioned(
            bottom: 12,
            right: 12,
            child: _buildLiveBadge(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFpsOverlay(BuildContext context) {
    final fpsColor = _fpsColor(liveFps);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fpsColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, color: fpsColor, size: 14),
          const SizedBox(width: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: liveFps > 0 ? liveFps.toStringAsFixed(1) : '--.-',
                  style: TextStyle(
                    color: fpsColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                TextSpan(
                  text: ' fps',
                  style: TextStyle(
                    color: fpsColor.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionOverlay(BuildContext context) {
    final previewSize = controller.value.previewSize;
    final resStr = previewSize != null
        ? '${previewSize.width.toInt()}×${previewSize.height.toInt()}'
        : '–';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.aspect_ratio_rounded,
              color: Colors.white54, size: 12),
          const SizedBox(width: 4),
          Text(
            resStr,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record_rounded,
              color: Colors.white, size: 8),
          SizedBox(width: 4),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Color _fpsColor(double fps) {
    if (fps >= 60) return const Color(0xFF4CAF50);
    if (fps >= 30) return const Color(0xFF42A5F5);
    if (fps > 0) return const Color(0xFFFFB74D);
    return Colors.white54;
  }
}
