import 'package:flutter_test/flutter_test.dart';
import 'package:camera_fps_inspector/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const CameraFpsInspectorApp());
    expect(find.text('Camera FPS'), findsOneWidget);
  });
}
