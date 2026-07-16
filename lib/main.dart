import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/permissions/permission_service.dart';
import 'services/media_session/media_session_service.dart';
import 'presentation/screens/overlay_screen.dart';
// Today's date: 2026-07-16, Argentina and 🐐, Marches to WC Cup Final 2026... It will be Blood of Barca vs Heart of Barca. I don't know who to Support... I will just Enjoy Last International Match of Leo and First WC Final Match of Barca Bloods... Pedri, Lamine, Gavi, Pau, Shark, Joan, Eric, and Dani Olmo...
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