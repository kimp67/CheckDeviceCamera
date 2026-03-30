/// FPS 범위 정보를 담는 모델 클래스
class FpsRangeInfo {
  final double minFps;
  final double maxFps;
  final String label;
  final ResolutionPresetInfo resolutionPreset;
  final bool isSupported;
  final String? errorMessage;

  const FpsRangeInfo({
    required this.minFps,
    required this.maxFps,
    required this.label,
    required this.resolutionPreset,
    this.isSupported = true,
    this.errorMessage,
  });

  bool get isHighFrameRate => maxFps >= 60;
  bool get isSlowMotion => maxFps >= 120;
  bool get isUltraSlowMotion => maxFps >= 240;

  String get frameRateCategory {
    if (maxFps >= 240) return 'Ultra Slow Motion';
    if (maxFps >= 120) return 'Slow Motion';
    if (maxFps >= 60) return 'High Frame Rate';
    if (maxFps >= 30) return 'Standard';
    return 'Low Frame Rate';
  }

  String get frameRateCategoryKo {
    if (maxFps >= 240) return '초고속 촬영';
    if (maxFps >= 120) return '슬로우 모션';
    if (maxFps >= 60) return '고프레임률';
    if (maxFps >= 30) return '표준';
    return '저프레임률';
  }
}

/// 해상도 프리셋 정보
class ResolutionPresetInfo {
  final String name;
  final String description;
  final String typicalResolution;

  const ResolutionPresetInfo({
    required this.name,
    required this.description,
    required this.typicalResolution,
  });

  static const low = ResolutionPresetInfo(
    name: 'low',
    description: '낮은 해상도',
    typicalResolution: '240p / 352×288',
  );

  static const medium = ResolutionPresetInfo(
    name: 'medium',
    description: '중간 해상도',
    typicalResolution: '480p / 640×480',
  );

  static const high = ResolutionPresetInfo(
    name: 'high',
    description: '높은 해상도',
    typicalResolution: '720p / 1280×720',
  );

  static const veryHigh = ResolutionPresetInfo(
    name: 'veryHigh',
    description: '매우 높은 해상도',
    typicalResolution: '1080p / 1920×1080',
  );

  static const ultraHigh = ResolutionPresetInfo(
    name: 'ultraHigh',
    description: '초고해상도',
    typicalResolution: '2160p / 3840×2160 (4K)',
  );

  static const max = ResolutionPresetInfo(
    name: 'max',
    description: '최대 해상도',
    typicalResolution: '기기 최대 해상도',
  );
}

/// 카메라 전체 정보
class CameraCapabilityInfo {
  final String cameraName;
  final String lensDirection;
  final List<FpsRangeInfo> fpsRanges;
  final DateTime measuredAt;

  const CameraCapabilityInfo({
    required this.cameraName,
    required this.lensDirection,
    required this.fpsRanges,
    required this.measuredAt,
  });

  double get maxSupportedFps {
    if (fpsRanges.isEmpty) return 0;
    return fpsRanges
        .where((r) => r.isSupported)
        .map((r) => r.maxFps)
        .fold(0.0, (a, b) => a > b ? a : b);
  }

  double get minSupportedFps {
    if (fpsRanges.isEmpty) return 0;
    return fpsRanges
        .where((r) => r.isSupported)
        .map((r) => r.minFps)
        .fold(double.infinity, (a, b) => a < b ? a : b);
  }
}
