# Camera FPS Inspector

> **camera `^0.12.0+1`** 패키지를 사용하여 기기 카메라의 FPS 범위를 분석하는 Flutter 앱

---

## 📱 주요 기능

| 기능 | 설명 |
|------|------|
| 🔍 **FPS 범위 분석** | 6가지 ResolutionPreset별 FPS 범위를 자동 측정 |
| 📊 **시각적 차트** | 프리셋별 FPS를 막대 차트로 비교 |
| 🎥 **라이브 프리뷰** | 실시간 카메라 프리뷰와 라이브 FPS 오버레이 |
| 📋 **결과 복사** | 측정 결과를 클립보드로 복사 |
| 🏷️ **FPS 카테고리** | 표준/HFR/슬로우모션/초고속 자동 분류 |

---

## 🏗️ 프로젝트 구조

```
camera_fps_inspector/
├── lib/
│   ├── main.dart                        # 앱 진입점
│   ├── models/
│   │   └── fps_range_model.dart         # FPS 범위 데이터 모델
│   ├── screens/
│   │   ├── home_screen.dart             # 홈 화면 (카메라 목록)
│   │   ├── camera_inspector_screen.dart # FPS 분석 화면
│   │   └── result_detail_screen.dart    # 상세 결과 화면
│   ├── widgets/
│   │   ├── fps_range_card.dart          # 프리셋별 FPS 카드
│   │   ├── fps_bar_chart.dart           # FPS 막대 차트
│   │   └── camera_preview_widget.dart   # 카메라 프리뷰 위젯
│   └── utils/
│       └── camera_fps_analyzer.dart     # FPS 분석 유틸리티
├── android/
│   └── app/src/main/AndroidManifest.xml # 카메라 권한 설정
├── ios/
│   └── Runner/Info.plist                # iOS 카메라 권한 설정
└── pubspec.yaml
```

---

## 📦 사용 패키지

```yaml
dependencies:
  camera: ^0.12.0+1        # 카메라 접근 및 FPS 측정
  permission_handler: ^11.3.1  # 런타임 권한 처리
  fl_chart: ^0.70.2            # 차트 시각화
  share_plus: ^10.1.4          # 결과 공유
```

---

## 🚀 빌드 및 실행

### 전제 조건
- Flutter SDK `>=3.9.0`
- Android SDK (minSdk 21+, Camera2/CameraX 지원)
- Xcode (iOS 13.0+)

### 실행

```bash
# 의존성 설치
flutter pub get

# Android 실행
flutter run -d android

# iOS 실행 (M1/M2 Mac)
cd ios && pod install && cd ..
flutter run -d ios
```

---

## 📐 FPS 분석 원리

### `camera ^0.12.0+1` API

```dart
// 1. CameraController 초기화
final controller = CameraController(
  camera,
  ResolutionPreset.high,
  enableAudio: false,
);
await controller.initialize();

// 2. CameraValue.fps 로 현재 FPS 읽기
final currentFps = controller.value.fps;

// 3. 프리뷰 해상도 확인
final previewSize = controller.value.previewSize;
```

### 측정 방식

각 `ResolutionPreset`에 대해:
1. `CameraController` 생성 및 초기화
2. `controller.value.fps` 값 수집
3. `controller.value.previewSize` 로 실제 해상도 확인
4. 컨트롤러 dispose → 다음 프리셋으로 반복

### 플랫폼별 구현

| 플랫폼 | 구현 | FPS 정보 소스 |
|--------|------|--------------|
| **Android** | `camera_android_camerax` (기본) | `CameraX StreamInfo` |
| **iOS** | `camera_avfoundation` | `AVCaptureDevice.activeFormat` |

---

## 🎨 FPS 범주 기준

| FPS | 범주 | 색상 | 용도 |
|-----|------|------|------|
| ≥ 240 fps | 초고속 촬영 | 🩷 핑크 | 극단적 슬로우모션 |
| ≥ 120 fps | 슬로우 모션 | 🟠 오렌지 | 4× 슬로우모션 |
| ≥ 60 fps | 고프레임률 (HFR) | 🟢 초록 | 부드러운 영상 |
| ≥ 30 fps | 표준 | 🔵 파랑 | 일반 촬영 |
| < 30 fps | 저프레임률 | ⚫ 회색 | 제한된 환경 |

---

## 🔐 권한

### Android (`AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

### iOS (`Info.plist`)
```xml
<key>NSCameraUsageDescription</key>
<string>카메라의 FPS 범위를 분석하기 위해 카메라 접근이 필요합니다.</string>
<key>NSMicrophoneUsageDescription</key>
<string>카메라 초기화를 위해 마이크 접근이 필요합니다.</string>
```

---

## 📝 주요 화면

### 1. 홈 화면
- 기기에서 감지된 카메라 목록 표시
- FPS 범주 안내
- 각 카메라로 분석 화면 진입

### 2. FPS 분석 화면
- **FPS 분석 시작** FAB: 6개 프리셋 순차 분석
- 진행 상황 표시 (단계별 프로그레스 바)
- 분석 요약 카드 (최대 FPS, 지원 프리셋 수)
- 프리셋별 FPS 막대 차트
- 각 프리셋 FPS 범위 카드

### 3. 라이브 프리뷰
- 실시간 카메라 영상
- FPS 오버레이 표시
- 현재 해상도 정보

### 4. 상세 결과 화면
- 카메라 메타 정보
- FPS 비교 차트
- 카테고리 분포
- 결과 클립보드 복사

---

## ⚠️ 참고 사항

1. **에뮬레이터**: FPS 값이 실제 기기와 다를 수 있습니다.
2. **카메라 권한**: 첫 실행 시 카메라 권한을 반드시 허용해야 합니다.
3. **분석 시간**: 6개 프리셋 분석에 약 10~20초 소요됩니다.
4. **Android CameraX**: `camera_android_camerax`가 기본 구현체입니다. Camera2를 사용하려면 pubspec에서 `camera_android`를 명시적으로 지정하세요.

---

## 🛠️ 개발 환경

- **Flutter**: ≥ 3.9.0
- **Dart**: ≥ 3.9.0
- **camera**: 0.12.0+1 (최신)
- **Android**: minSdk 21 / targetSdk 35
- **iOS**: 13.0+
