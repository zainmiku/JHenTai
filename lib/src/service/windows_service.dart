import 'dart:math';

import 'package:get/get.dart';
import 'package:jhentai/src/service/storage_service.dart';
import 'package:jhentai/src/utils/screen_size_util.dart';
import 'package:resizable_widget/resizable_widget.dart';
import 'package:throttling/throttling.dart';

import '../utils/log.dart';

class WindowService extends GetxService {
  final StorageService storageService = Get.find<StorageService>();

  bool inited = false;

  double windowWidth = 1280;
  double windowHeight = 720;
  
  bool isMaximized = false;
  bool isFullScreen = false;
  
  double leftColumnWidthRatio = 1 - 0.618;

  final Debouncing windowResizedDebouncing = Debouncing(duration: const Duration(milliseconds: 300));
  final Debouncing columnResizedDebouncing = Debouncing(duration: const Duration(milliseconds: 300));

  static void init() {
    Get.put(WindowService(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    windowWidth = storageService.read('windowWidth') ?? windowWidth;
    windowHeight = storageService.read('windowHeight') ?? windowHeight;
    isMaximized = storageService.read('windowMaximize') ?? false;
    isFullScreen = storageService.read('windowFullScreen') ?? false;
    leftColumnWidthRatio = storageService.read('leftColumnWidthRatio') ?? leftColumnWidthRatio;
    leftColumnWidthRatio = max(0.01, leftColumnWidthRatio);
  }

  void handleColumnResized(List<WidgetSizeInfo> infoList) {
    if (leftColumnWidthRatio == infoList[0].percentage) {
      return;
    }

    columnResizedDebouncing.debounce(() {
      leftColumnWidthRatio = max(0.01, infoList[0].percentage);

      Log.info('Resize left column ratio to: $leftColumnWidthRatio');
      storageService.write('leftColumnWidthRatio', leftColumnWidthRatio);
    });
  }

  void handleWindowResized() {
    windowResizedDebouncing.debounce(() {
      windowWidth = fullScreenWidth;
      windowHeight = screenHeight;

      Log.info('Resize window to: $windowWidth x $windowHeight');

      storageService.write('windowWidth', windowWidth);
      storageService.write('windowHeight', windowHeight);
    });
  }

  void saveMaximizeWindow(bool isMaximized) {
    Log.info(isMaximized ? 'Maximized window' : 'Restored window');
    
    this.isMaximized = isMaximized;
    storageService.write('windowMaximize', isMaximized);
  }

  void saveFullScreen(bool isFullScreen) {
    Log.info(isFullScreen ? 'Enter full screen' : 'Leave full screen');
    
    this.isFullScreen = isFullScreen;
    storageService.write('windowFullScreen', isFullScreen);
  }
}
