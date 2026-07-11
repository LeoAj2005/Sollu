import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/permissions/permission_service.dart';
import 'services/media_session/media_session_service.dart';
import 'presentation/screens/overlay_screen.dart';

// Main App Entry Point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await MediaSessionService.instance.initialize();
  await PermissionService.requestNotificationPermission();
  
  runApp(
    const ProviderScope(
      child: SolluApp(),
    ),
  );
}

// Overlay Entry Point (Must be top-level)
@pragma('vm:entry-point')
void overlayMain() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OverlayScreen(),
    ),
  );
}