import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../models/fps_range_model.dart';
import '../theme/app_theme.dart';

/// 프리셋별 FPS 범위를 표시하는 카드 위젯
class FpsRangeCard extends StatelessWidget {
  final FpsRangeInfo fpsRange;
  final bool showDetails;

  const FpsRangeCard({
    super.key,
    required this.fpsRange,
    this.showDetails = false,
  });

  Color get _accentColor =>
      fpsRange.isSupported ? AppTheme.fpsColor(fpsRange.maxFps) : Colors.grey;

  Color get _bgColor => fpsRange.isSupported
      ? AppTheme.fpsBgColor(fpsRange.maxFps).withValues(alpha: 0.25)
      : const Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _accentColor.withValues(
            alpha: fpsRange.isSupported ? 0.4 : 0.2,
          ),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(),
          SizedBox(height: 1.5.h),
          if (fpsRange.isSupported) ...[
            _buildFpsDisplay(),
            if (showDetails) ...[
              SizedBox(height: 1.5.h),
              _buildProgressBar(),
              SizedBox(height: 1.h),
              _buildDetailRow('해상도 레이블', fpsRange.label),
            ],
          ] else
            _buildUnsupportedRow(),
        ],
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      children: [
        // 프리셋 배지
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: _accentColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _accentColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            fpsRange.resolutionPreset.name,
            style: TextStyle(
              color: _accentColor,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(width: 2.5.w),
        Expanded(
          child: Text(
            fpsRange.resolutionPreset.typicalResolution,
            style: TextStyle(color: AppTheme.textHint, fontSize: 8.5.sp),
          ),
        ),
        // 카테고리 태그
        if (fpsRange.isSupported)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              fpsRange.frameRateCategoryKo,
              style: TextStyle(
                color: _accentColor,
                fontSize: 7.5.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFpsDisplay() {
    return Row(
      children: [
        Expanded(
          child: _FpsValue(
            label: 'MIN',
            fps: fpsRange.minFps,
            color: Colors.white60,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.w),
          child: Column(
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                color: _accentColor.withValues(alpha: 0.6),
                size: 4.5.w,
              ),
              Text(
                'FPS',
                style: TextStyle(
                  color: AppTheme.textDisabled,
                  fontSize: 7.5.sp,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _FpsValue(
            label: 'MAX',
            fps: fpsRange.maxFps,
            color: _accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    const maxPossible = 240.0;
    final progress = (fpsRange.maxFps / maxPossible).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FPS 수준',
              style: TextStyle(color: AppTheme.textDisabled, fontSize: 8.sp),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}% (최대 240 기준)',
              style: TextStyle(
                color: _accentColor.withValues(alpha: 0.7),
                fontSize: 8.sp,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            minHeight: 0.8.h,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(color: AppTheme.textDisabled, fontSize: 8.sp),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 8.sp,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnsupportedRow() {
    return Row(
      children: [
        Icon(Icons.block_rounded, color: Colors.red, size: 4.w),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            fpsRange.errorMessage ?? '이 기기에서 지원되지 않는 해상도',
            style: TextStyle(color: Colors.red.shade300, fontSize: 8.5.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── FPS 수치 표시 서브 위젯 ─────────────────────────────────────
class _FpsValue extends StatelessWidget {
  final String label;
  final double fps;
  final Color color;

  const _FpsValue({
    required this.label,
    required this.fps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textDisabled,
            fontSize: 8.sp,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 0.3.h),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: fps.toStringAsFixed(fps == fps.roundToDouble() ? 0 : 1),
                style: TextStyle(
                  color: color,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: ' fps',
                style: TextStyle(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 8.5.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
