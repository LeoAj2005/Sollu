import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';

class OverlayService {
  static Future<bool> requestPermission() async {
    final status = await Permission.systemAlertWindow.request();
    
    // If the dialog was dismissed or denied, take the user to the system settings page
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
  }

  static Future<void> closeOverlay() async {
    await FlutterOverlayWindow.closeOverlay();
  }

  static Future<void> sendLyricsToOverlay(String title, String lyric) async {
    await FlutterOverlayWindow.shareData({
      'title': title,
      'lyric': lyric,
    });
  }
}