import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'services/permissions/permission_service.dart';
import 'services/media_session/media_session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await MediaSessionService.instance.initialize();
  await PermissionService.requestNotificationPermission();
  
  runApp(
    const ProviderScope(
      child: SolluApp(),
    ),
  );
}