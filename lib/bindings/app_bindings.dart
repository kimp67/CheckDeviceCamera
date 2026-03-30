import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/camera_controllers.dart';

/// 홈 화면 의존성 바인딩
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CameraListController>(() => CameraListController());
  }
}

/// Inspector 화면 의존성 바인딩
class InspectorBinding extends Bindings {
  final CameraDescription camera;
  InspectorBinding({required this.camera});

  @override
  void dependencies() {
    Get.lazyPut<InspectorController>(
      () => InspectorController(camera: camera),
      tag: camera.name,
    );
  }
}
