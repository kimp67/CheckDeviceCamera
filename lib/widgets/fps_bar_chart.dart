import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../models/fps_range_model.dart';
import '../theme/app_theme.dart';

/// FPS 막대 차트 위젯 - Sizer 반응형 사이즈 적용
class FpsBarChart extends StatelessWidget {
  final List<FpsRangeInfo> fpsRanges;
  final bool showTitle;

  const FpsBarChart({
    super.key,
    required this.fpsRanges,
    this.showTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final supported = fpsRanges.where((r) => r.isSupported).toList();
    if (supported.isEmpty) return const SizedBox.shrink();

    final maxFps = supported
        .map((r) => r.maxFps)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  color: AppTheme.primaryLight,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'FPS 비교 차트',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
          SizedBox(
            height: 20.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y축 레이블
                SizedBox(
                  width: 9.w,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _yLabel(maxFps.toStringAsFixed(0)),
                      _yLabel((maxFps * 0.75).toStringAsFixed(0)),
                      _yLabel((maxFps * 0.5).toStringAsFixed(0)),
                      _yLabel((maxFps * 0.25).toStringAsFixed(0)),
                      _yLabel('0'),
                    ],
                  ),
                ),
                SizedBox(width: 2.w),
                // 차트 영역
                Expanded(
                  child: Stack(
                    children: [
                      // 격자선
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          5,
                          (_) => Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 바
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: fpsRanges
                            .map(
                              (r) => Expanded(
                                child: _Bar(range: r, maxFps: maxFps),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          // X축 레이블
          Row(
            children: [
              SizedBox(width: 11.w),
              ...fpsRanges.map(
                (r) => Expanded(
                  child: Text(
                    r.resolutionPreset.name,
                    style: TextStyle(
                      color: AppTheme.textDisabled,
                      fontSize: 7.sp,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _yLabel(String text) => Text(
    text,
    style: TextStyle(color: AppTheme.textDisabled, fontSize: 7.sp),
    textAlign: TextAlign.right,
  );

  Widget _buildLegend() {
    final items = [
      ('≥240 초고속', AppTheme.fpsUltra),
      ('≥120 슬로우', AppTheme.fpsSlow),
      ('≥60 HFR', AppTheme.fpsHFR),
      ('≥30 표준', AppTheme.fpsStandard),
    ];
    return Wrap(
      spacing: 3.w,
      runSpacing: 0.5.h,
      children: items.map((l) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 2.w,
              height: 2.w,
              decoration: BoxDecoration(color: l.$2, shape: BoxShape.circle),
            ),
            SizedBox(width: 1.w),
            Text(
              l.$1,
              style: TextStyle(color: AppTheme.textDisabled, fontSize: 7.5.sp),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── 막대 바 위젯 ─────────────────────────────────────────────
class _Bar extends StatelessWidget {
  final FpsRangeInfo range;
  final double maxFps;

  const _Bar({required this.range, required this.maxFps});

  @override
  Widget build(BuildContext context) {
    final chartH = 20.h - 2.h; // 격자 높이

    if (!range.isSupported || maxFps == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 2.h,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final barH = (range.maxFps / maxFps) * chartH;
    final color = AppTheme.fpsColor(range.maxFps);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // FPS 수치
          if (barH > 2.5.h)
            Padding(
              padding: EdgeInsets.only(bottom: 0.3.h),
              child: Text(
                range.maxFps.toStringAsFixed(0),
                style: TextStyle(
                  color: color,
                  fontSize: 7.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          // 막대
          Container(
            height: barH.clamp(1.0, chartH),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0.5)],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
