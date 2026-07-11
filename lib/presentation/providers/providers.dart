import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:shared_preferences/shared_preferences.dart'; Not used after "Add foreground service permissions, enhance media handling, and improve lyrics fetching logic" Commit
import '../../data/api/api_service.dart';
import '../../services/storage/storage_service.dart';
import '../../services/media_session/media_session_service.dart';
import '../../services/overlay_service.dart';
import '../../data/models/song_meta.dart';
import '../../data/models/song_with_lyrics.dart';
import '../../data/models/lyrics_type.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

final currentSongProvider = StreamProvider<SongMeta?>((ref) {
  return MediaSessionService.instance.currentSongStream;
});

final songMetadataProvider = StreamProvider<SongMeta?>((ref) {
  return MediaSessionService.instance.currentSongStream
      .distinct((a, b) => a?.title == b?.title && a?.artist == b?.artist);
});

final enrichedSongProvider = FutureProvider<SongMeta?>((ref) async {
  final song = ref.watch(songMetadataProvider).value;
  if (song == null || song.title == 'Unknown') return null;

  final api = ref.watch(apiServiceProvider);
  final artworkUrl = await api.fetchArtwork(song.title, song.artist);
  
  return SongMeta(
    title: song.title,
    artist: song.artist,
    duration: song.duration,
    position: song.position,
    album: song.album,
    artworkUrl: artworkUrl,
  );
});

final lyricsRefreshTriggerProvider = StateProvider<int>((ref) => 0);

// Sources state provider
final enabledSourcesProvider = StateNotifierProvider<EnabledSourcesNotifier, Map<String, bool>>((ref) {
  return EnabledSourcesNotifier();
});

class EnabledSourcesNotifier extends StateNotifier<Map<String, bool>> {
  EnabledSourcesNotifier() : super({
    'LRCLIB': true,
    'Lyrics.ovh': true,
    'lyricstranslate.com': true,
    'genius.com': true,
    'azlyrics.com': true,
    'lyricsify.com': true,
    'findmusicbylyrics.com': true,
    'lyrics.com': true,
  });

  void toggleSource(String source) {
    state = {...state, source: !(state[source] ?? true)};
  }
}

final lyricsProvider = FutureProvider<SongWithLyrics?>((ref) async {
  final trigger = ref.watch(lyricsRefreshTriggerProvider);
  final enabledSources = ref.watch(enabledSourcesProvider);
  
  final song = ref.watch(enrichedSongProvider).value;
  if (song == null || song.title == 'Unknown') return null;

  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  
  if (trigger == 0) {
    final stored = await storage.getLyrics('${song.title}_${song.artist}');
    if (stored != null) return stored;
  }
  
  final lyrics = await api.fetchLyrics(song, enabledSources);
  if (lyrics != null) {
    await storage.insertLyrics(lyrics);
  }
  return lyrics;
});

final manualLyricsProvider = FutureProvider.family<SongWithLyrics?, SongMeta>((ref, song) async {
  final api = ref.watch(apiServiceProvider);
  final storage = ref.watch(storageServiceProvider);
  final enabledSources = ref.watch(enabledSourcesProvider);
  
  final stored = await storage.getLyrics('${song.title}_${song.artist}');
  if (stored != null) return stored;
  
  final lyrics = await api.fetchLyrics(song, enabledSources);
  if (lyrics != null) {
    await storage.insertLyrics(lyrics);
  }
  return lyrics;
});

final savedLyricsProvider = FutureProvider<List<SongWithLyrics>>((ref) async {
  final storage = ref.watch(storageServiceProvider);
  return storage.getAllLyrics();
});

final bubbleToggleProvider = StateProvider<bool>((ref) => false);

final overlayLyricsPusherProvider = Provider((ref) {
  ref.listen<bool>(bubbleToggleProvider, (_, isOn) async {
    if (isOn) {
      final hasPerm = await OverlayService.requestPermission();
      if (hasPerm) {
        await OverlayService.showOverlay();
      } else {
        ref.read(bubbleToggleProvider.notifier).state = false;
      }
    } else {
      await OverlayService.closeOverlay();
    }
  });

  ref.listen<AsyncValue<SongWithLyrics?>>(lyricsProvider, (_, asyncLyrics) {
    final lyrics = asyncLyrics.value;
    if (ref.read(bubbleToggleProvider)) {
      final song = ref.read(enrichedSongProvider).value;
      if (lyrics != null && song != null) {
        String line = "No synced lyrics";
        if (lyrics.lyricsType == LyricsType.synced) {
          line = lyrics.syncedLyrics!.lines.first.text;
        } else if (lyrics.lyrics != null) {
          line = lyrics.lyrics!.split('\n').first;
        }
        OverlayService.sendLyricsToOverlay(song.title, line);
      }
    }
  });

  ref.listen<AsyncValue<SongMeta?>>(currentSongProvider, (_, asyncSong) {
    final song = asyncSong.value;
    if (ref.read(bubbleToggleProvider) && song != null) {
      final lyrics = ref.read(lyricsProvider).value;
      if (lyrics != null && lyrics.lyricsType == LyricsType.synced) {
        final lines = lyrics.syncedLyrics!.lines;
        int idx = 0;
        for (int i = 0; i < lines.length; i++) {
          if (lines[i].timestamp <= song.position) {
            idx = i;
          } else {
            break;
          }
        }
        OverlayService.sendLyricsToOverlay(song.title, lines[idx].text);
      }
    }
  });
});