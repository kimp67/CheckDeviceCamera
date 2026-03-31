import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../models/fps_range_model.dart';

/// 카메라 FPS 분석 유틸리티
class CameraFpsAnalyzer {
  /// camera 패키지의 플랫폼 채널 이름
  /// (camera_platform_interface의 MethodChannelCamera 와 동일한 채널)
  static const MethodChannel _cameraChannel =
      MethodChannel('plugins.flutter.io/camera');

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
  /// camera ^0.12.0+1 의 [CameraValue] 에는 fps 필드가 없으므로,
  /// 플랫폼 채널(MethodChannel)을 통해 네이티브 레이어에서 직접
  /// FPS 범위를 조회합니다.
  ///
  /// - Android : CameraX `CameraInfo.getSupportedFrameRateRanges()` 호출
  /// - iOS     : AVFoundation `activeFormat.videoSupportedFrameRateRanges` 호출
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

        // previewSize로 실제 해상도 확인
        final cameraValue = controller.value;
        final previewSize = cameraValue.previewSize;
        final resolutionStr = previewSize != null
            ? '${previewSize.width.toInt()}×${previewSize.height.toInt()}'
            : '알 수 없음';

        // 플랫폼 채널을 통해 네이티브에서 실제 FPS 범위 조회
        final (double minFps, double maxFps) = await _getFpsRangeFromPlatform(
          cameraName: camera.name,
          preset: preset,
        );

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

  /// 플랫폼 채널을 통해 네이티브 레이어에서 FPS 범위를 조회합니다.
  ///
  /// Android (CameraX):
  ///   `CameraInfo.getSupportedFrameRateRanges()` 를 통해 지원되는
  ///   [Range<Integer>] 목록을 반환받아 최솟값/최댓값을 추출합니다.
  ///
  /// iOS (AVFoundation):
  ///   `AVCaptureDevice.activeFormat.videoSupportedFrameRateRanges` 를 통해
  ///   지원되는 [AVFrameRateRange] 목록을 반환받아 최솟값/최댓값을 추출합니다.
  ///
  /// 플랫폼 채널 호출에 실패하거나 응답이 없는 경우에는
  /// [_getFallbackFps]의 preset 기반 추정값으로 fallback 합니다.
  static Future<(double min, double max)> _getFpsRangeFromPlatform({
    required String cameraName,
    required ResolutionPreset preset,
  }) async {
    try {
      if (Platform.isAndroid) {
        // Android: CameraX 플랫폼 채널로 지원 FPS 범위 요청
        // 채널명: 'plugins.flutter.io/camera'
        // 메서드: 'getSupportedFrameRateRanges'
        final result = await _cameraChannel.invokeMethod<List<dynamic>>(
          'getSupportedFrameRateRanges',
          <String, dynamic>{
            'cameraName': cameraName,
            'resolutionPreset': _serializeResolutionPreset(preset),
          },
        );

        if (result != null && result.isNotEmpty) {
          double minFps = double.infinity;
          double maxFps = 0.0;

          for (final range in result) {
            if (range is Map) {
              final lower = (range['lower'] as num?)?.toDouble() ?? 0.0;
              final upper = (range['upper'] as num?)?.toDouble() ?? 0.0;
              if (lower < minFps) minFps = lower;
              if (upper > maxFps) maxFps = upper;
            }
          }

          if (maxFps > 0) {
            return (minFps == double.infinity ? 1.0 : minFps, maxFps);
          }
        }
      } else if (Platform.isIOS) {
        // iOS: AVFoundation 플랫폼 채널로 지원 FPS 범위 요청
        // 채널명: 'plugins.flutter.io/camera'
        // 메서드: 'getSupportedFrameRateRanges'
        final result = await _cameraChannel.invokeMethod<List<dynamic>>(
          'getSupportedFrameRateRanges',
          <String, dynamic>{
            'cameraName': cameraName,
            'resolutionPreset': _serializeResolutionPreset(preset),
          },
        );

        if (result != null && result.isNotEmpty) {
          double minFps = double.infinity;
          double maxFps = 0.0;

          for (final range in result) {
            if (range is Map) {
              final lower = (range['minFrameRate'] as num?)?.toDouble() ?? 0.0;
              final upper = (range['maxFrameRate'] as num?)?.toDouble() ?? 0.0;
              if (lower < minFps) minFps = lower;
              if (upper > maxFps) maxFps = upper;
            }
          }

          if (maxFps > 0) {
            return (minFps == double.infinity ? 1.0 : minFps, maxFps);
          }
        }
      }
    } on MissingPluginException {
      // 플랫폼 채널 메서드가 네이티브에 구현되지 않은 경우 → fallback
    } on PlatformException {
      // 네이티브 호출 중 오류 발생 → fallback
    }

    // 플랫폼 채널 조회 실패 시: preset 기반 추정값 사용
    return _getFallbackFps(preset);
  }

  /// 플랫폼 채널 조회 실패 시 사용하는 preset별 FPS 추정값
  static (double min, double max) _getFallbackFps(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
      case ResolutionPreset.medium:
      case ResolutionPreset.high:
        return (1.0, 30.0);
      case ResolutionPreset.veryHigh:
        return (1.0, 60.0);
      case ResolutionPreset.ultraHigh:
        return (1.0, 30.0); // 4K는 일반적으로 30fps
      case ResolutionPreset.max:
        return (1.0, 60.0);
    }
  }

  /// [ResolutionPreset] → 플랫폼 채널 전달용 문자열 직렬화
  /// (camera_platform_interface의 _serializeResolutionPreset 와 동일한 규칙)
  static String _serializeResolutionPreset(ResolutionPreset preset) {
    switch (preset) {
      case ResolutionPreset.low:
        return 'low';
      case ResolutionPreset.medium:
        return 'medium';
      case ResolutionPreset.high:
        return 'high';
      case ResolutionPreset.veryHigh:
        return 'veryHigh';
      case ResolutionPreset.ultraHigh:
        return 'ultraHigh';
      case ResolutionPreset.max:
        return 'max';
    }
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
