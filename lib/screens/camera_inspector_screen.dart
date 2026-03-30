import 'package:flutter/material.dart';
import 'package:flutter_sizer/flutter_sizer.dart';
import 'package:get/get.dart';
import '../controllers/camera_controllers.dart';
import '../theme/app_theme.dart';
import '../widgets/fps_range_card.dart';
import '../widgets/fps_bar_chart.dart';
import '../widgets/camera_preview_widget.dart';
import 'result_detail_screen.dart';

/// FPS 분석 화면 - GetView<InspectorController>
class CameraInspectorScreen extends GetView<InspectorController> {
  /// HomeScreen에서 Get.put 시 사용한 tag와 동일해야 합니다.
  final String cameraTag;

  const CameraInspectorScreen({super.key, required this.cameraTag});

  @override
  String? get tag => cameraTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 라이브 프리뷰 (Obx로 조건부 표시)
          Obx(() {
            final showPreview = controller.showPreview.value;
            final previewCtrl = controller.previewController.value;
            if (!showPreview || previewCtrl == null) {
              return const SizedBox.shrink();
            }
            return CameraPreviewWidget(
              controller: previewCtrl,
              liveFps: controller.liveFps.value,
              onClose: controller.toggleLivePreview,
            );
          }),
          Expanded(
            child: Obx(() => _buildBody()),
          ),
        ],
      ),
      floatingActionButton: _buildFabs(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        controller.directionLabel,
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
      ),
      actions: [
        Obx(() => controller.hasResult
            ? IconButton(
                icon: Icon(Icons.info_outline_rounded, size: 6.w),
                tooltip: '상세 보기',
                onPressed: () => Get.to(
                  () => ResultDetailScreen(cameraTag: cameraTag),
                  transition: Transition.downToUp,
                ),
              )
            : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildBody() {
    if (controller.hasError) return _buildErrorState();
    if (controller.isAnalyzing.value) return _buildAnalyzingState();
    if (!controller.hasResult) return _buildIdleState();
    return _buildResultState();
  }

  // ── 유휴 상태 ──────────────────────────────────────────
  Widget _buildIdleState() {
    final features = [
      (Icons.speed_rounded, '6가지 해상도 프리셋 분석'),
      (Icons.video_settings_rounded, '실시간 FPS 측정'),
      (Icons.bar_chart_rounded, '시각적 FPS 비교 차트'),
      (Icons.info_rounded, '프레임률 카테고리 분류'),
    ];

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.analytics_outlined,
                color: AppTheme.primaryLight,
                size: 12.w,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              '${controller.directionLabel}\nFPS 범위 분석',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              '아래 버튼을 눌러 이 카메라가 지원하는\n모든 해상도 프리셋의 FPS 범위를 분석합니다.',
              style: TextStyle(
                color: AppTheme.textHint,
                fontSize: 10.sp,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ...features.map(
              (f) => Padding(
                padding: EdgeInsets.symmetric(vertical: 0.6.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.$1, color: AppTheme.primaryLight, size: 4.5.w),
                    SizedBox(width: 2.w),
                    Text(
                      f.$2,
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 분석 중 상태 ───────────────────────────────────────
  Widget _buildAnalyzingState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: CircularProgressIndicator(
                    value: controller.analyzeProgress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryLight),
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '카메라 분석 중',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.5.h),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    controller.progressMessage.value,
                    key: ValueKey(controller.progressMessage.value),
                    style: TextStyle(
                        color: AppTheme.primaryLight, fontSize: 10.sp),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 3.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: controller.analyzeProgress,
                    minHeight: 1.h,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryLight),
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${controller.progressStep.value} / ${controller.totalSteps}',
                  style: TextStyle(
                      color: AppTheme.textDisabled, fontSize: 9.sp),
                ),
              ],
            )),
      ),
    );
  }

  // ── 결과 상태 ──────────────────────────────────────────
  Widget _buildResultState() {
    return Obx(() {
      final ranges = controller.fpsRanges;
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
              child: _buildSummaryCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 0),
              child: FpsBarChart(fpsRanges: ranges),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 1.h),
              child: Text(
                '해상도 프리셋별 FPS 범위',
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
                padding:
                    EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.6.h),
                child: FpsRangeCard(fpsRange: ranges[i]),
              ),
              childCount: ranges.length,
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 12.h)),
        ],
      );
    });
  }

  // ── 요약 카드 ──────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Obx(() {
      final maxFps = controller.maxFps;
      final catColor = AppTheme.fpsColor(maxFps);

      return Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primary.withValues(alpha: 0.4),
              AppTheme.primaryDark.withValues(alpha: 0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.summarize_rounded,
                    color: AppTheme.primaryLight, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  '분석 요약',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                _StatItem(
                  label: '최대 FPS',
                  value: '${maxFps.toStringAsFixed(0)} fps',
                  color: AppTheme.primaryLight,
                ),
                SizedBox(width: 2.w),
                _StatItem(
                  label: '지원 프리셋',
                  value:
                      '${controller.supportedRanges.length} / ${controller.fpsRanges.length}',
                  color: const Color(0xFF66BB6A),
                ),
                SizedBox(width: 2.w),
                _StatItem(
                  label: '카테고리',
                  value: controller.maxCategory,
                  color: catColor,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // ── 오류 상태 ──────────────────────────────────────────
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    color: Colors.redAccent, size: 16.w),
                SizedBox(height: 2.h),
                Text(
                  '오류 발생',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 1.5.h),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(
                      color: AppTheme.textHint, fontSize: 9.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 3.h),
                ElevatedButton.icon(
                  onPressed: controller.startAnalysis,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('다시 시도'),
                ),
              ],
            )),
      ),
    );
  }

  // ── FAB 버튼 그룹 ──────────────────────────────────────
  Widget _buildFabs() {
    return Obx(() => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 라이브 프리뷰 FAB
            FloatingActionButton.small(
              heroTag: 'preview_fab_$cameraTag',
              onPressed: controller.toggleLivePreview,
              tooltip: controller.showPreview.value ? '프리뷰 닫기' : '라이브 프리뷰',
              backgroundColor: controller.showPreview.value
                  ? Colors.red.withValues(alpha: 0.8)
                  : AppTheme.primary,
              child: Icon(
                controller.showPreview.value
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 1.5.h),
            // 분석 FAB
            FloatingActionButton.extended(
              heroTag: 'analyze_fab_$cameraTag',
              onPressed: controller.isAnalyzing.value
                  ? null
                  : controller.startAnalysis,
              backgroundColor: controller.isAnalyzing.value
                  ? Colors.grey.shade800
                  : AppTheme.primary,
              icon: controller.isAnalyzing.value
                  ? SizedBox(
                      width: 5.w,
                      height: 5.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.analytics_rounded, color: Colors.white),
              label: Text(
                controller.isAnalyzing.value ? '분석 중...' : 'FPS 분석 시작',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ],
        ));
  }
}

// ── 통계 아이템 ──────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: AppTheme.textHint, fontSize: 8.sp),
            ),
            SizedBox(height: 0.4.h),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
