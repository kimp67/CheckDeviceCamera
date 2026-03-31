import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../bindings/app_bindings.dart';
import '../controllers/camera_controllers.dart';
import '../theme/app_theme.dart';
import 'camera_inspector_screen.dart';

/// 홈 화면 - GetView<CameraListController> 사용
class HomeScreen extends GetView<CameraListController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgDark, AppTheme.bgDeep, AppTheme.bgDark],
          ),
        ),
        child: SafeArea(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryLight),
              );
            }
            return _buildContent(context);
          }),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5.h),
          _buildHeader(),
          SizedBox(height: 4.h),
          _buildCameraSection(),
          SizedBox(height: 3.h),
          _buildFpsCategoryGuide(),
          SizedBox(height: 3.h),
          _buildFooter(),
          SizedBox(height: 3.h),
        ],
      ),
    );
  }

  // ── 헤더 ───────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PulsingIcon(),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Camera FPS',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Inspector',
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 0.9,
                    ),
                  ),
                ],
              ),
            ),
            // 새로고침 버튼
            IconButton(
              onPressed: controller.refresh,
              icon: Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: controller.isLoading.value
                      ? SizedBox(
                          key: const ValueKey('loading'),
                          width: 5.w,
                          height: 5.w,
                          child: const CircularProgressIndicator(
                            color: AppTheme.primaryLight,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          key: const ValueKey('refresh'),
                          Icons.refresh_rounded,
                          color: AppTheme.textSecondary,
                          size: 6.w,
                        ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        // 설명 배지
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3949AB).withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.speed_rounded,
                color: const Color(0xFF7986CB),
                size: 3.5.w,
              ),
              SizedBox(width: 1.5.w),
              Text(
                '기기 카메라의 FPS 범위를 분석합니다',
                style: TextStyle(
                  color: const Color(0xFF9FA8DA),
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── 카메라 목록 섹션 ────────────────────────────────────
  Widget _buildCameraSection() {
    return Obx(() {
      if (controller.errorMessage.value.isNotEmpty) {
        return _buildErrorCard();
      }
      if (controller.cameras.isEmpty) {
        return _buildNoCameraCard();
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '감지된 카메라',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${controller.cameras.length}개',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ...controller.cameras.asMap().entries.map(
            (e) => Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: _CameraCard(camera: e.value, index: e.key),
            ),
          ),
        ],
      );
    });
  }

  // ── FPS 범주 안내 ──────────────────────────────────────
  Widget _buildFpsCategoryGuide() {
    final items = [
      ('≥240', '초고속', AppTheme.fpsUltra),
      ('≥120', '슬로우모션', AppTheme.fpsSlow),
      ('≥60', '고프레임률', AppTheme.fpsHFR),
      ('≥30', '표준', AppTheme.fpsStandard),
      ('<30', '저프레임률', AppTheme.fpsLow),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FPS 범주 안내',
          style: TextStyle(
            color: AppTheme.textHint,
            fontSize: 13.sp,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 1.5.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: items
              .map(
                (item) =>
                    _FpsChip(fps: item.$1, label: item.$2, color: item.$3),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'camera ^0.12.0+1  ·  GetX ^4.7.3  ·  Sizer ^1.0.5',
        style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp),
      ),
    );
  }

  Widget _buildNoCameraCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.no_photography_rounded, color: Colors.red, size: 12.w),
          SizedBox(height: 2.h),
          Text(
            '카메라를 찾을 수 없습니다',
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '기기에 카메라가 없거나 카메라 권한이 거부되었습니다.',
            style: TextStyle(color: AppTheme.textHint, fontSize: 10.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 10.w,
          ),
          SizedBox(height: 1.5.h),
          Text(
            '카메라 초기화 오류',
            style: TextStyle(
              color: Colors.orangeAccent,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            controller.errorMessage.value,
            style: TextStyle(color: AppTheme.textHint, fontSize: 11.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }
}

// ── 카메라 카드 ─────────────────────────────────────────────
class _CameraCard extends StatelessWidget {
  final CameraDescription camera;
  final int index;

  const _CameraCard({required this.camera, required this.index});

  @override
  Widget build(BuildContext context) {
    final isBack = camera.lensDirection == CameraLensDirection.back;
    final isFront = camera.lensDirection == CameraLensDirection.front;

    final icon = isBack
        ? Icons.camera_rear_rounded
        : isFront
        ? Icons.camera_front_rounded
        : Icons.usb_rounded;

    final gradientColors = isBack
        ? [const Color(0xFF1565C0), const Color(0xFF0D47A1)]
        : isFront
        ? [const Color(0xFF6A1B9A), const Color(0xFF4A148C)]
        : [const Color(0xFF2E7D32), const Color(0xFF1B5E20)];

    final directionLabel = isBack
        ? '후면 카메라'
        : isFront
        ? '전면 카메라'
        : '외부 카메라';

    return InkWell(
      onTap: () {
        // GetX: InspectorController를 동적으로 put하고 화면 이동
        Get.put(
          InspectorController(camera: camera),
          tag: camera.name,
          permanent: false,
        );
        Get.to(
          () => CameraInspectorScreen(cameraTag: camera.name),
          binding: InspectorBinding(camera: camera),
          transition: Transition.rightToLeft,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              gradientColors[0].withValues(alpha: 0.3),
              gradientColors[1].withValues(alpha: 0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradientColors[0].withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 13.w,
              height: 13.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 6.w),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    directionLabel,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'Camera ${index + 1}  ·  ${camera.name}',
                    style: TextStyle(color: AppTheme.textHint, fontSize: 13.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textSecondary,
                size: 4.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FPS 범주 칩 ──────────────────────────────────────────────
class _FpsChip extends StatelessWidget {
  final String fps;
  final String label;
  final Color color;

  const _FpsChip({required this.fps, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2.w,
            height: 2.w,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 1.5.w),
          Text(
            '$fps fps  $label',
            style: TextStyle(
              color: color,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 박동 아이콘 애니메이션 ──────────────────────────────────────
class _PulsingIcon extends StatefulWidget {
  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.scale(
        scale: _anim.value,
        child: Container(
          width: 14.w,
          height: 14.w,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.camera_enhance_rounded,
            color: AppTheme.primaryLight,
            size: 7.w,
          ),
        ),
      ),
    );
  }
}
