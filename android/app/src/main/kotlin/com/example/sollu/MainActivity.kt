package com.example.sollu

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    
    companion object {
        var eventSink: EventChannel.EventSink? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Event channel for continuous media updates
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "io.github.sollu/media_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
        
        // Method channel for requesting permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.github.sollu/media").setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    startActivity(intent)
                    result.success(true)
                }
                "checkPermission" -> {
                    val enabledListeners = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
                    val packageName = packageName
                    result.success(enabledListeners?.contains(packageName) == true)
                }
                else -> result.notImplemented()
            }
        }
    }
}