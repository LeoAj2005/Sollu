import 'dart:async';
import 'package:flutter/services.dart';
import '../../data/models/song_meta.dart';

class MediaSessionService {
  static const EventChannel _eventChannel = EventChannel('io.github.sollu/media_events');
  static const MethodChannel _methodChannel = MethodChannel('io.github.sollu/media');
  
  static MediaSessionService? _instance;
  final StreamController<SongMeta?> _songController = StreamController.broadcast();
  SongMeta? _currentSong;
  Timer? _positionTimer;
  
  MediaSessionService._() {
    _eventChannel.receiveBroadcastStream().listen((dynamic data) {
      if (data is Map) {
        _currentSong = SongMeta(
          title: data['title'] as String? ?? 'Unknown',
          artist: data['artist'] as String? ?? 'Unknown',
          duration: data['duration'] as int? ?? 0,
          position: data['position'] as int? ?? 0,
        );
        _songController.add(_currentSong);
        _startPositionTimer();
      }
    }, onError: (e) {
      // Handle error
    });
  }
  
  static MediaSessionService get instance {
    _instance ??= MediaSessionService._();
    return _instance!;
  }
  
  // Add this method to satisfy main.dart and initialization_service.dart
  Future<void> initialize() async {
    // Initialization is handled in the constructor, but we provide this
    // for an explicit initialization point if needed later.
  }
  
  Stream<SongMeta?> get currentSongStream => _songController.stream;
  SongMeta? get currentSong => _currentSong;
  
  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentSong != null && _currentSong!.duration > 0) {
        _currentSong = SongMeta(
          title: _currentSong!.title,
          artist: _currentSong!.artist,
          duration: _currentSong!.duration,
          position: _currentSong!.position + 1000,
        );
        _songController.add(_currentSong);
      }
    });
  }
  
  Future<bool> checkPermission() async {
    try {
      return await _methodChannel.invokeMethod('checkPermission');
    } catch (e) {
      return false;
    }
  }
  
  Future<void> requestPermission() async {
    try {
      await _methodChannel.invokeMethod('requestPermission');
    } catch (e) {
      // Handle error
    }
  }
  
  void dispose() {
    _positionTimer?.cancel();
    _songController.close();
  }
}