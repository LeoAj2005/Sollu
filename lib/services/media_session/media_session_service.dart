import 'dart:async';
import 'package:flutter/services.dart';
import '../../data/models/song_meta.dart';

class MediaSessionService {
  static const MethodChannel _channel = MethodChannel('io.github.teccheck.fastlyrics/media');
  static MediaSessionService? _instance;
  
  final StreamController<SongMeta?> _songController = StreamController.broadcast();
  SongMeta? _currentSong;
  
  MediaSessionService._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  static MediaSessionService get instance {
    _instance ??= MediaSessionService._();
    return _instance!;
  }
  
  Stream<SongMeta?> get currentSongStream => _songController.stream;
  SongMeta? get currentSong => _currentSong;
  
  Future<void> initialize() async {
    try {
      final song = await _channel.invokeMethod<Map>('getCurrentSong');
      _updateCurrentSong(song);
    } catch (e) {
      // Platform error handling
    }
  }
  
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onSongChanged') {
      _updateCurrentSong(call.arguments as Map?);
    }
  }
  
  void _updateCurrentSong(Map? data) {
    if (data == null) {
      _currentSong = null;
    } else {
      _currentSong = SongMeta(
        title: data['title'] as String? ?? 'Unknown',
        artist: data['artist'] as String? ?? 'Unknown',
        duration: data['duration'] as int? ?? 0,
        album: data['album'] as String?,
        artworkUrl: data['artworkUrl'] as String?,
      );
    }
    _songController.add(_currentSong);
  }
  
  void dispose() {
    _songController.close();
  }
}