import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import '../controllers/camera_controllers.dart';
import '../theme/app_theme.dart';
import '../widgets/fps_range_card.dart';
import '../widgets/fps_bar_chart.dart';

/// 상세 결과 화면 - GetView<InspectorController>
class ResultDetailScreen extends GetView<InspectorController> {
  final String cameraTag;

  const ResultDetailScreen({super.key, required this.cameraTag});

  @override
  String? get tag => cameraTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Text(
          '${controller.directionLabel} 상세 결과',
          style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.copy_rounded, size: 5.5.w),
            tooltip: '결과 복사',
            onPressed: _copyResults,
          ),
        ],
      ),
      body: Obx(
        () => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: _buildHeaderCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: FpsBarChart(
                  fpsRanges: controller.fpsRanges,
                  showTitle: true,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: _buildCategoryDistribution(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 1.h),
                child: Text(
                  '해상도 프리셋별 상세 정보',
                  style: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 9.5.sp,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 0.6.h,
                  ),
                  child: FpsRangeCard(
                    fpsRange: controller.fpsRanges[i],
                    showDetails: true,
                  ),
                ),
                childCount: controller.fpsRanges.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: _buildTechnicalInfo(),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 5.h)),
          ],
        ),
      ),
    );
  }

  // ── 헤더 카드 ──────────────────────────────────────────
  Widget _buildHeaderCard() {
    final maxFps = controller.maxFps;
    final camera = controller.camera;

    return Container(
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary.withValues(alpha: 0.5),
            AppTheme.primaryDark.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                camera.lensDirection.name == 'back'
                    ? Icons.camera_rear_rounded
                    : camera.lensDirection.name == 'front'
                    ? Icons.camera_front_rounded
                    : Icons.usb_rounded,
                color: AppTheme.primaryLight,
                size: 7.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.directionLabel,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      camera.name,
                      style: TextStyle(
                        color: AppTheme.textDisabled,
                        fontSize: 8.5.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          const Divider(color: Colors.white10),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricItem(
                label: '최대 FPS',
                value: '${maxFps.toStringAsFixed(1)} fps',
                color: AppTheme.primaryLight,
              ),
              _MetricItem(
                label: '지원 프리셋',
                value: '${controller.supportedRanges.length}종',
                color: const Color(0xFF66BB6A),
              ),
              _MetricItem(
                label: '분석 항목',
                value: '${controller.fpsRanges.length}개',
                color: const Color(0xFFFFB74D),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 카테고리 분포 ──────────────────────────────────────
  Widget _buildCategoryDistribution() {
    final supported = controller.supportedRanges;
    if (supported.isEmpty) return const SizedBox.shrink();

    final Map<String, int> cats = {};
    for (final r in supported) {
      cats[r.frameRateCategoryKo] = (cats[r.frameRateCategoryKo] ?? 0) + 1;
    }

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
          Row(
            children: [
              Icon(
                Icons.donut_large_rounded,
                color: AppTheme.primaryLight,
                size: 4.5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'FPS 범주 분포',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ...cats.entries.map((e) {
            final color = _categoryColor(e.key);
            return Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                children: [
                  Container(
                    width: 3.w,
                    height: 3.w,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    e.key,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10.sp,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.5.w,
                      vertical: 0.4.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${e.value}개 프리셋',
                      style: TextStyle(
                        color: color,
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 기술 정보 ──────────────────────────────────────────
  Widget _buildTechnicalInfo() {
    final rows = [
      ('패키지', 'camera ^0.12.0+1'),
      ('상태관리', 'GetX ^4.7.3'),
      ('반응형', 'flutter_sizer ^1.0.5'),
      ('Android', 'CameraX (camera_android_camerax)'),
      ('iOS', 'AVFoundation (camera_avfoundation)'),
      ('FPS API', 'CameraValue.fps'),
    ];

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
          Row(
            children: [
              Icon(
                Icons.code_rounded,
                color: AppTheme.primaryLight,
                size: 4.5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                '기술 정보',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          ...rows.map(
            (r) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 20.w,
                    child: Text(
                      r.$1,
                      style: TextStyle(
                        color: AppTheme.textDisabled,
                        fontSize: 8.5.sp,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 8.5.sp,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case '초고속 촬영':
        return AppTheme.fpsUltra;
      case '슬로우 모션':
        return AppTheme.fpsSlow;
      case '고프레임률':
        return AppTheme.fpsHFR;
      case '표준':
        return AppTheme.fpsStandard;
      default:
        return AppTheme.fpsLow;
    }
  }

  Future<void> _copyResults() async {
    final buf = StringBuffer();
    buf.writeln('=== Camera FPS Inspector 결과 ===');
    buf.writeln('카메라: ${controller.directionLabel}');
    buf.writeln('분석 시각: ${DateTime.now()}');
    buf.writeln();
    for (final r in controller.fpsRanges) {
      if (r.isSupported) {
        buf.writeln(
          '[${r.resolutionPreset.name}] ${r.label}: '
          'min=${r.minFps.toStringAsFixed(1)} / '
          'max=${r.maxFps.toStringAsFixed(1)} fps | ${r.frameRateCategoryKo}',
        );
      } else {
        buf.writeln('[${r.resolutionPreset.name}] 지원 안 됨: ${r.errorMessage}');
      }
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    Get.snackbar(
      '복사 완료',
      '결과가 클립보드에 복사되었습니다',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppTheme.primary,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }
}

// ── 메트릭 아이템 ─────────────────────────────────────────────
class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          label,
          style: TextStyle(color: AppTheme.textDisabled, fontSize: 8.5.sp),
        ),
      ],
    );
  }
}
