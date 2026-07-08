import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/api_service.dart';
import '../../services/storage/storage_service.dart';
import '../../services/media_session/media_session_service.dart';
import '../../data/models/song_meta.dart';
import '../../data/models/song_with_lyrics.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final currentSongProvider = StreamProvider<SongMeta?>((ref) {
  return MediaSessionService.instance.currentSongStream;
});

final lyricsProvider = FutureProvider<SongWithLyrics?>((ref) async {
  final song = ref.watch(currentSongProvider).value;
  if (song == null) return null;

  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  
  // Try local storage first
  final stored = await storage.getLyrics('${song.title}_${song.artist}');
  if (stored != null) return stored;
  
  // Fetch from API
  final lyrics = await api.fetchLyrics(song);
  if (lyrics != null) {
    await storage.insertLyrics(lyrics);
  }
  return lyrics;
});

final savedLyricsProvider = FutureProvider<List<SongWithLyrics>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getAllLyrics();
});