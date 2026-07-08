import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'media_session/media_session_service.dart';
import 'permissions/permission_service.dart';

class InitializationService {
  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize shared preferences
    await SharedPreferences.getInstance();
    
    // Initialize media session
    await MediaSessionService.instance.initialize();
    
    // Request permissions
    await PermissionService.requestNotificationPermission();
  }
}