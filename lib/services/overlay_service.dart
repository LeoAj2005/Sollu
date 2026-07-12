import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class OverlayService {
  static Future<bool> requestPermission() async {
    final status = await Permission.systemAlertWindow.request();
    if (!status.isGranted) {
      await openAppSettings();
    }
    return status.isGranted;
  }

  static Future<void> showOverlay() async {
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "Sollu Lyrics",
      overlayContent: 'Lyrics Active',
      flag: OverlayFlag.defaultFlag,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      height: 100,
      width: 250,
    );
    debugPrint("OverlayService: Overlay shown.");
  }

  static Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
    debugPrint("OverlayService: Overlay closed.");
  }

  static Future<void> sendLyricsToOverlay(String title, String lyric) async {
    try {
      await FlutterOverlayWindow.shareData({
        'title': title,
        'lyric': lyric,
      });
      debugPrint("OverlayService: Sent data to overlay -> $lyric");
    } catch (e) {
      debugPrint("OverlayService Error sending data: $e");
    }
  }
}