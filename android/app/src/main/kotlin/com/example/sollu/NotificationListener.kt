package com.example.sollu

import android.content.ComponentName
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.service.notification.NotificationListenerService
import android.util.Log

class NotificationListener : NotificationListenerService() {

    private var activeControllers: MutableList<MediaController> = mutableListOf()

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d("FastLyrics", "Notification Listener Connected")
        
        val mediaSessionManager = getSystemService(MEDIA_SESSION_SERVICE) as MediaSessionManager
        val component = ComponentName(this, NotificationListener::class.java)
        
        val handlers = mediaSessionManager.getActiveSessions(component)
        activeControllers.clear()
        activeControllers.addAll(handlers)
        
        handlers.forEach { controller ->
            controller.registerCallback(object : MediaController.Callback() {
                override fun onMetadataChanged(metadata: MediaMetadata?) {
                    super.onMetadataChanged(metadata)
                    sendMetadataToFlutter(controller, metadata)
                }
                override fun onPlaybackStateChanged(s: PlaybackState?) {
                    super.onPlaybackStateChanged(s)
                    sendMetadataToFlutter(controller, controller.metadata)
                }
            })
            
            // Send initial state
            if (controller.metadata != null) {
                sendMetadataToFlutter(controller, controller.metadata)
            }
        }
    }

    private fun sendMetadataToFlutter(controller: MediaController, metadata: MediaMetadata?) {
        if (metadata == null) return
        
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: return
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
        val duration = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION).toInt()
        val position = controller.playbackState?.position?.toInt() ?: 0
        
        val songData = mapOf(
            "title" to title,
            "artist" to artist,
            "duration" to duration,
            "position" to position
        )
        
        // Send to Flutter via EventChannel stream handler
        MainActivity.eventSink?.success(songData)
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d("FastLyrics", "Notification Listener Disconnected")
    }
}