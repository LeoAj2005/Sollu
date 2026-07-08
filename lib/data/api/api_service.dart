import '../models/song_meta.dart';
import '../models/song_with_lyrics.dart';
import '../models/lyrics_type.dart';

class ApiService {
  Future<SongWithLyrics?> fetchLyrics(SongMeta song) async {
    // Mock implementation for structure. In reality, you'd hit Musixmatch/Genius here.
    // Using a fake delay to simulate network request.
    await Future.delayed(const Duration(seconds: 1));
    
    return SongWithLyrics(
      id: '${song.title}_${song.artist}',
      title: song.title,
      artist: song.artist,
      lyrics: 'These are the mock lyrics for ${song.title}',
      syncedLyrics: null,
      lyricsType: LyricsType.plain,
      fetchedAt: DateTime.now(),
    );
  }

  Future<List<SongMeta>> searchSongs(String query) async {
    // Mock search
    await Future.delayed(const Duration(seconds: 1));
    return [
      SongMeta(title: '$query - Song 1', artist: 'Artist 1', duration: 180000),
      SongMeta(title: '$query - Song 2', artist: 'Artist 2', duration: 210000),
    ];
  }
}