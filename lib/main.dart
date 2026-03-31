import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:get/get.dart';
import 'bindings/app_bindings.dart';
import 'routes/app_routes.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CameraFpsInspectorApp());
}

class CameraFpsInspectorApp extends StatelessWidget {
  const CameraFpsInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // flutter_sizer: Sizer 위젯으로 MaterialApp을 감싸야
    //                .w / .h / .sp 반응형 단위가 동작합니다.
    return Sizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          title: 'Camera FPS Inspector',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          initialRoute: AppRoutes.home,
          initialBinding: HomeBinding(),
          getPages: [
            GetPage(
              name: AppRoutes.home,
              page: () => const HomeScreen(),
              binding: HomeBinding(),
            ),
          ],
          // 기본 전환 애니메이션
          defaultTransition: Transition.fadeIn,
        );
      },
    );
  }
}
