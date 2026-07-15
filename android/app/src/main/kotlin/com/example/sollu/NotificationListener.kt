package com.example.sollu

import android.content.ComponentName
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.service.notification.NotificationListenerService
import android.util.Log

class NotificationListener : NotificationListenerService() {

    // Companion object allows MainActivity or other components to access the active session globally
    companion object {
        var activeController: MediaController? = null
    }

    private var activeControllers: MutableList<MediaController> = mutableListOf()

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d("Sollu", "Notification Listener Connected")
        
        val mediaSessionManager = getSystemService(MEDIA_SESSION_SERVICE) as MediaSessionManager
        val component = ComponentName(this, NotificationListener::class.java)
        
        try {
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
                
                if (controller.metadata != null) {
                    sendMetadataToFlutter(controller, controller.metadata)
                }
            }
        } catch (e: SecurityException) {
            Log.e("Sollu", "SecurityException: Need notification access permission.", e)
        }
    }

    private fun sendMetadataToFlutter(controller: MediaController, metadata: MediaMetadata?) {
        if (metadata == null) return
        
        val title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE) ?: return
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST) ?: "Unknown"
        val duration = if (metadata.containsKey(MediaMetadata.METADATA_KEY_DURATION)) {
            metadata.getLong(MediaMetadata.METADATA_KEY_DURATION).toInt()
        } else { 
            0 
        }
        
        val playbackState = controller.playbackState?.state
        val isPlaying = playbackState == PlaybackState.STATE_PLAYING
        
        // Stream updates when actively playing or paused
        if (playbackState == PlaybackState.STATE_PLAYING || playbackState == PlaybackState.STATE_PAUSED) {
            activeController = controller // Save the active controller globally
            
            val position = controller.playbackState?.position?.toInt() ?: 0
            
            val songData = mapOf(
                "title" to title,
                "artist" to artist,
                "duration" to duration,
                "position" to position,
                "isPlaying" to isPlaying // NEW
            )
            
            MainActivity.eventSink?.success(songData)
        }
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        activeController = null // Clear reference on disconnect to prevent memory leaks
        Log.d("Sollu", "Notification Listener Disconnected")
    }
}