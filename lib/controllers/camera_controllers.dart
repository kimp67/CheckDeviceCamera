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

  // ── 실시간 FPS 측정용 내부 변수 ─────────────────────────
  int _frameCount = 0;
  DateTime? _fpsWindowStart;

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
      _startLiveFpsMeasure(ctrl);
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
    _frameCount = 0;
    _fpsWindowStart = null;
    final ctrl = previewController.value;
    previewController.value = null;
    // 이미지 스트림이 실행 중인 경우 명시적으로 정지
    if (ctrl != null && ctrl.value.isStreamingImages) {
      await ctrl.stopImageStream();
    }
    await ctrl?.dispose();
  }

  /// startImageStream()으로 실제 프레임을 카운트하여 실시간 FPS를 계산합니다.
  ///
  /// 1초(1000ms) 단위 슬라이딩 윈도우로 FPS를 갱신하므로
  /// [CameraValue.fps] 필드 없이도 정확한 실시간 FPS를 얻을 수 있습니다.
  void _startLiveFpsMeasure(CameraController ctrl) {
    _frameCount = 0;
    _fpsWindowStart = DateTime.now();

    ctrl.startImageStream((CameraImage image) {
      // 프리뷰가 중단된 경우 더 이상 카운트하지 않음
      if (!showPreview.value) return;

      _frameCount++;
      final now = DateTime.now();
      final elapsed = now.difference(_fpsWindowStart!).inMilliseconds;

      // 1초(1000ms)마다 FPS 값 갱신 후 윈도우 리셋
      if (elapsed >= 1000) {
        liveFps.value = (_frameCount * 1000) / elapsed;
        _frameCount = 0;
        _fpsWindowStart = now;
      }
    });
  }
}
