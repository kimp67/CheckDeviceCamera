import 'package:camera/camera.dart';
import '../models/fps_range_model.dart';

/// 카메라 FPS 분석 유틸리티
class CameraFpsAnalyzer {
  /// camera 패키지의 ResolutionPreset 목록
  static const List<(ResolutionPreset, ResolutionPresetInfo)> presetPairs = [
    (ResolutionPreset.low, ResolutionPresetInfo.low),
    (ResolutionPreset.medium, ResolutionPresetInfo.medium),
    (ResolutionPreset.high, ResolutionPresetInfo.high),
    (ResolutionPreset.veryHigh, ResolutionPresetInfo.veryHigh),
    (ResolutionPreset.ultraHigh, ResolutionPresetInfo.ultraHigh),
    (ResolutionPreset.max, ResolutionPresetInfo.max),
  ];

  /// 카메라 컨트롤러를 통해 FPS 범위 정보를 수집합니다.
  ///
  /// camera ^0.12.0+1 에서는 [CameraController.value]에
  /// [CameraValue.fps], [CameraValue.frameRateRange] 등의
  /// 정보가 초기화 후 제공됩니다.
  static Future<List<FpsRangeInfo>> analyzeFpsRanges(
    CameraDescription camera, {
    void Function(String message)? onProgress,
  }) async {
    final List<FpsRangeInfo> results = [];

    for (final (preset, presetInfo) in presetPairs) {
      onProgress?.call('${presetInfo.description} (${presetInfo.name}) 분석 중...');

      CameraController? controller;
      try {
        controller = CameraController(
          camera,
          preset,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await controller.initialize();

        // camera 0.12.x: CameraValue에서 FPS 범위 정보 읽기
        final cameraValue = controller.value;

        // frameRateRange: 기기가 해당 preset에서 지원하는 FPS 범위
        final frameRateRange = cameraValue.fps;

        // previewSize로 실제 해상도 확인
        final previewSize = cameraValue.previewSize;
        final resolutionStr = previewSize != null
            ? '${previewSize.width.toInt()}×${previewSize.height.toInt()}'
            : '알 수 없음';

        // camera 0.12.0에서의 fps 접근 방식
        // CameraValue.fps는 현재 실행 중인 FPS (double)
        // 최소/최대 FPS 범위는 플랫폼별로 다름
        double minFps = 1.0;
        double maxFps = frameRateRange;

        // 실제 FPS 범위는 컨트롤러 값에서 가져옴
        // Android CameraX: frameRateRange 필드 존재
        // iOS AVFoundation: activeFormat.videoSupportedFrameRateRanges
        // camera 플러그인은 플랫폼 구현에 따라 다름

        results.add(
          FpsRangeInfo(
            minFps: minFps,
            maxFps: maxFps,
            label: '${presetInfo.name} ($resolutionStr)',
            resolutionPreset: presetInfo,
            isSupported: true,
          ),
        );
      } on CameraException catch (e) {
        results.add(
          FpsRangeInfo(
            minFps: 0,
            maxFps: 0,
            label: presetInfo.name,
            resolutionPreset: presetInfo,
            isSupported: false,
            errorMessage: '${e.code}: ${e.description}',
          ),
        );
      } catch (e) {
        results.add(
          FpsRangeInfo(
            minFps: 0,
            maxFps: 0,
            label: presetInfo.name,
            resolutionPreset: presetInfo,
            isSupported: false,
            errorMessage: e.toString(),
          ),
        );
      } finally {
        await controller?.dispose();
      }

      // 컨트롤러 재생성 전 잠시 대기
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return results;
  }

  /// 렌즈 방향을 한국어로 변환
  static String lensDirectionToKorean(CameraLensDirection direction) {
    switch (direction) {
      case CameraLensDirection.front:
        return '전면 카메라';
      case CameraLensDirection.back:
        return '후면 카메라';
      case CameraLensDirection.external:
        return '외부 카메라';
    }
  }

  /// FPS 값에 따른 색상 반환
  static (int r, int g, int b) fpsToColorRgb(double fps) {
    if (fps >= 240) return (255, 0, 128);   // 핑크 (Ultra Slow-Mo)
    if (fps >= 120) return (255, 64, 0);    // 오렌지 (Slow-Mo)
    if (fps >= 60) return (0, 200, 100);    // 초록 (HFR)
    if (fps >= 30) return (0, 120, 255);    // 파랑 (Standard)
    return (150, 150, 150);                 // 회색 (Low)
  }
}
