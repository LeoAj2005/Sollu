package com.example.sollu

import android.content.Intent
import android.media.MediaMetadata
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
        
        // Method channel for requesting permissions and polling state
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
                // Fetch the current song information on app resume/UI refresh
                "getCurrentMedia" -> {
                    val controller = NotificationListener.activeController
                    val metadata = controller?.metadata
                    val playbackState = controller?.playbackState?.state
                    val isPlaying = playbackState == android.media.session.PlaybackState.STATE_PLAYING
                    
                    if (controller != null && metadata != null && 
                        (playbackState == android.media.session.PlaybackState.STATE_PLAYING || 
                         playbackState == android.media.session.PlaybackState.STATE_PAUSED)) {
                        
                        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE)
                        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
                        val duration = if (metadata.containsKey(MediaMetadata.METADATA_KEY_DURATION)) {
                            metadata.getLong(MediaMetadata.METADATA_KEY_DURATION).toInt()
                        } else { 
                            0 
                        }
                        val position = controller.playbackState?.position?.toInt() ?: 0
                        
                        val songData = mapOf(
                            "title" to title,
                            "artist" to artist,
                            "duration" to duration,
                            "position" to position,
                            "isPlaying" to isPlaying // NEW
                        )
                        result.success(songData)
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}