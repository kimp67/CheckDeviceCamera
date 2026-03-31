import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:camera/camera.dart';
import '../theme/app_theme.dart';

/// 카메라 라이브 프리뷰 위젯 (FPS 오버레이 포함) - Sizer 반응형
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
    if (!controller.value.isInitialized) return const SizedBox.shrink();

    return Container(
      height: 28.h,
      color: Colors.black,
      child: Stack(
        children: [
          // 카메라 프리뷰
          Center(child: CameraPreview(controller)),

          // 상단 그라디언트 오버레이
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 8.h,
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
            height: 8.h,
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
            top: 1.5.h,
            left: 3.w,
            child: _FpsOverlay(fps: liveFps),
          ),

          // 해상도 정보 (좌측 하단)
          Positioned(
            bottom: 1.5.h,
            left: 3.w,
            child: _ResolutionOverlay(
              previewSize: controller.value.previewSize,
            ),
          ),

          // 닫기 버튼 (우측 상단)
          Positioned(
            top: 0.5.h,
            right: 1.w,
            child: IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, size: 5.5.w),
              color: Colors.white70,
              style: IconButton.styleFrom(backgroundColor: Colors.black38),
            ),
          ),

          // LIVE 배지 (우측 하단)
          Positioned(bottom: 1.5.h, right: 3.w, child: _LiveBadge()),
        ],
      ),
    );
  }
}

// ── FPS 오버레이 ──────────────────────────────────────────────
class _FpsOverlay extends StatelessWidget {
  final double fps;
  const _FpsOverlay({required this.fps});

  Color get _color {
    if (fps >= 60) return AppTheme.fpsHFR;
    if (fps >= 30) return AppTheme.primaryLight;
    if (fps > 0) return const Color(0xFFFFB74D);
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed_rounded, color: _color, size: 3.5.w),
          SizedBox(width: 1.w),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: fps > 0 ? fps.toStringAsFixed(1) : '--.-',
                  style: TextStyle(
                    color: _color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.sp,
                  ),
                ),
                TextSpan(
                  text: ' fps',
                  style: TextStyle(
                    color: _color.withValues(alpha: 0.7),
                    fontSize: 8.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 해상도 오버레이 ───────────────────────────────────────────
class _ResolutionOverlay extends StatelessWidget {
  final Size? previewSize;
  const _ResolutionOverlay({this.previewSize});

  @override
  Widget build(BuildContext context) {
    final resStr = previewSize != null
        ? '${previewSize!.width.toInt()}×${previewSize!.height.toInt()}'
        : '–';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.aspect_ratio_rounded, color: Colors.white54, size: 3.w),
          SizedBox(width: 1.w),
          Text(
            resStr,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 8.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── LIVE 배지 ─────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_manual_record_rounded,
            color: Colors.white,
            size: 2.w,
          ),
          SizedBox(width: 1.w),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7.5.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
