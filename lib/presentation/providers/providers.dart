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

// Fetch high-res artwork
final enrichedSongProvider = FutureProvider<SongMeta?>((ref) async {
  final song = ref.watch(currentSongProvider).value;
  if (song == null || song.title == 'Unknown') return null;

  final api = ref.watch(apiServiceProvider);
  final artworkUrl = await api.fetchArtwork(song.title, song.artist);
  
  // Preserve the live position from the stream
  return SongMeta(
    title: song.title,
    artist: song.artist,
    duration: song.duration,
    position: song.position,
    album: song.album,
    artworkUrl: artworkUrl,
  );
});

// Trigger to force switch lyrics source
final lyricsRefreshTriggerProvider = StateProvider<int>((ref) => 0);
final skipSourceProvider = StateProvider<String?>((ref) => null);

final lyricsProvider = FutureProvider<SongWithLyrics?>((ref) async {
  // Watch the trigger and skipSource so it rebuilds when we change them
  final trigger = ref.watch(lyricsRefreshTriggerProvider);
  final skipSource = ref.watch(skipSourceProvider);
  
  // ONLY watch title and artist to prevent refetching on position updates!
  final title = ref.watch(enrichedSongProvider.select((s) => s.value?.title));
  final artist = ref.watch(enrichedSongProvider.select((s) => s.value?.artist));
  final duration = ref.watch(enrichedSongProvider.select((s) => s.value?.duration));
  
  if (title == null || artist == null || title == 'Unknown') return null;

  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  
  final songMeta = SongMeta(title: title, artist: artist, duration: duration ?? 0);
  
  // Only use cache if we are NOT forcing a refresh
  if (trigger == 0) {
    final stored = await storage.getLyrics('${songMeta.title}_${songMeta.artist}');
    if (stored != null) return stored;
  }
  
  final lyrics = await api.fetchLyrics(songMeta, skipSource: skipSource);
  if (lyrics != null) {
    await storage.insertLyrics(lyrics);
  }
  return lyrics;
});

final manualLyricsProvider = FutureProvider.family<SongWithLyrics?, SongMeta>((ref, song) async {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  
  final stored = await storage.getLyrics('${song.title}_${song.artist}');
  if (stored != null) return stored;
  
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