import 'package:flutter_test/flutter_test.dart';
import 'package:camera_fps_inspector/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CameraFpsInspectorApp());
    // Sizer + GetMaterialApp 기본 렌더링 확인
    expect(find.byType(CameraFpsInspectorApp), findsOneWidget);
  });
}
