import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../models/fps_range_model.dart';
import '../utils/camera_fps_analyzer.dart';

/// 홈 화면 - 카메라 목록 관리 Controller
class CameraListController extends GetxController {
  // ── Observable 상태 ──────────────────────────────────
  final RxList<CameraDescription> cameras = <CameraDescription>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      final list = await availableCameras();
      cameras.assignAll(list);
    } on CameraException catch (e) {
      errorMessage.value = '${e.code}: ${e.description}';
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 카메라 목록 새로고침
  Future<void> refresh() => _loadCameras();

  /// 렌즈 방향 레이블
  String lensLabel(CameraDescription camera) =>
      CameraFpsAnalyzer.lensDirectionToKorean(camera.lensDirection);
}

/// Inspector 화면 - FPS 분석 Controller
class InspectorController extends GetxController {
  final CameraDescription camera;

  InspectorController({required this.camera});

  // ── Observable 상태 ──────────────────────────────────
  final RxList<FpsRangeInfo> fpsRanges = <FpsRangeInfo>[].obs;
  final RxBool isAnalyzing = false.obs;
  final RxString progressMessage = ''.obs;
  final RxInt progressStep = 0.obs;
  final RxString errorMessage = ''.obs;

  // ── 라이브 프리뷰 ────────────────────────────────────
  final Rx<CameraController?> previewController = Rx<CameraController?>(null);
  final RxBool showPreview = false.obs;
  final RxDouble liveFps = 0.0.obs;

  // ── 계산된 값 (Getter) ───────────────────────────────
  List<FpsRangeInfo> get supportedRanges =>
      fpsRanges.where((r) => r.isSupported).toList();

  double get maxFps => supportedRanges.isEmpty
      ? 0.0
      : supportedRanges.map((r) => r.maxFps).reduce((a, b) => a > b ? a : b);

  int get totalSteps => CameraFpsAnalyzer.presetPairs.length;

  double get analyzeProgress =>
      totalSteps > 0 ? (progressStep.value / totalSteps).clamp(0.0, 1.0) : 0.0;

  bool get hasResult => fpsRanges.isNotEmpty;
  bool get hasError => errorMessage.value.isNotEmpty;

  String get directionLabel =>
      CameraFpsAnalyzer.lensDirectionToKorean(camera.lensDirection);

  String get maxCategory {
    final fps = maxFps;
    if (fps >= 240) return '초고속';
    if (fps >= 120) return '슬로우-Mo';
    if (fps >= 60) return 'HFR';
    if (fps >= 30) return '표준';
    return '저속';
  }

  @override
  void onClose() {
    previewController.value?.dispose();
    super.onClose();
  }

  // ── FPS 분석 ─────────────────────────────────────────
  Future<void> startAnalysis() async {
    if (isAnalyzing.value) return;

    isAnalyzing.value = true;
    fpsRanges.clear();
    errorMessage.value = '';
    progressStep.value = 0;
    progressMessage.value = '분석을 시작합니다...';

    try {
      final ranges = await CameraFpsAnalyzer.analyzeFpsRanges(
        camera,
        onProgress: (msg) {
          progressMessage.value = msg;
          progressStep.value++;
        },
      );
      fpsRanges.assignAll(ranges);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isAnalyzing.value = false;
    }
  }

  // ── 라이브 프리뷰 토글 ───────────────────────────────
  Future<void> toggleLivePreview() async {
    if (showPreview.value) {
      await _stopPreview();
    } else {
      await _startPreview();
    }
  }

  Future<void> _startPreview() async {
    final ctrl = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    try {
      await ctrl.initialize();
      previewController.value = ctrl;
      showPreview.value = true;
      _pollLiveFps(ctrl);
    } catch (e) {
      await ctrl.dispose();
      Get.snackbar(
        '프리뷰 오류',
        '프리뷰 시작 실패: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFB71C1C),
        colorText: const Color(0xFFFFFFFF),
      );
    }
  }

  Future<void> _stopPreview() async {
    showPreview.value = false;
    liveFps.value = 0;
    final ctrl = previewController.value;
    previewController.value = null;
    await ctrl?.dispose();
  }

  void _pollLiveFps(CameraController ctrl) {
    Future.doWhile(() async {
      if (!showPreview.value || previewController.value == null) return false;
      if (ctrl.value.isInitialized) {
        liveFps.value = ctrl.value.fps;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      return showPreview.value;
    });
  }
}
