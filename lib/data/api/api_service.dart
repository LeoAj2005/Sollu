import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_meta.dart';
import '../models/song_with_lyrics.dart';
import '../../utils/utils.dart';
import '../models/lyrics_type.dart';

class ApiService {
  // Main fetcher that orchestrates the providers
  Future<SongWithLyrics?> fetchLyrics(SongMeta song, Map<String, bool> enabledSources) async {
    SongWithLyrics? lyrics;

    // Pass 1: Try to find Synced Lyrics first
    if (enabledSources['LRCLIB'] ?? false) {
      lyrics = await _tryLrclib(song, syncOnly: true);
      if (lyrics != null) return lyrics;
    }

    // Pass 2: Fallback to Plain Lyrics
    if (enabledSources['LRCLIB'] ?? false) {
      lyrics = await _tryLrclib(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['Lyrics.ovh'] ?? false) {
      lyrics = await _tryLyricsOvh(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['genius.com'] ?? false) {
      lyrics = await _tryGenius(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['azlyrics.com'] ?? false) {
      lyrics = await _tryAzLyrics(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['lyricstranslate.com'] ?? false) {
      lyrics = await _tryLyricsTranslate(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['lyricsify.com'] ?? false) {
      lyrics = await _tryLyricsify(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['findmusicbylyrics.com'] ?? false) {
      lyrics = await _tryFindMusicByLyrics(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['lyrics.com'] ?? false) {
      lyrics = await _tryLyricsDotCom(song);
      if (lyrics != null) return lyrics;
    }

    return null; // No Lyrics Available
  }

  Future<SongWithLyrics?> _tryLrclib(SongMeta song, {bool syncOnly = false}) async {
    try {
      final url = Uri.parse(
        'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(song.artist)}&track_name=${Uri.encodeComponent(song.title)}&duration=${song.duration}'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['statusCode'] != 404) {
          final syncedLyrics = Utils.parseLrc(data['syncedLyrics'] as String?);
          
          if (syncOnly && syncedLyrics == null) return null; // Skip if we only want synced

          return SongWithLyrics(
            id: '${song.title}_${song.artist}',
            title: song.title,
            artist: song.artist,
            lyrics: data['plainLyrics'] as String?,
            syncedLyrics: syncedLyrics,
            lyricsType: syncedLyrics != null 
                ? LyricsType.synced 
                : (data['plainLyrics'] != null ? LyricsType.plain : LyricsType.none),
            fetchedAt: DateTime.now(),
            source: "LRCLIB",
          );
        }
      }
    } catch (e) { /* Ignore */ }
    return null;
  }

  Future<SongWithLyrics?> _tryLyricsOvh(SongMeta song) async {
    try {
      final url = Uri.parse(
        'https://api.lyrics.ovh/v1/${Uri.encodeComponent(song.artist)}/${Uri.encodeComponent(song.title)}'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final plainLyrics = data['lyrics'] as String?;
        
        if (plainLyrics != null && plainLyrics.trim().isNotEmpty) {
          return SongWithLyrics(
            id: '${song.title}_${song.artist}',
            title: song.title,
            artist: song.artist,
            lyrics: plainLyrics,
            syncedLyrics: null,
            lyricsType: LyricsType.plain,
            fetchedAt: DateTime.now(),
            source: "Lyrics.ovh",
          );
        }
      }
    } catch (e) { /* Ignore */ }
    return null;
  }

  // Note: The following are structural stubs. Web scraping these sites directly via HTTP 
  // often results in 403 Forbidden or CAPTCHAs. They are wired up so that if you 
  // implement proper scraping or API calls later, they will work seamlessly.
  Future<SongWithLyrics?> _tryGenius(SongMeta song) async => _tryScrape(song, "genius.com");
  Future<SongWithLyrics?> _tryAzLyrics(SongMeta song) async => _tryScrape(song, "azlyrics.com");
  Future<SongWithLyrics?> _tryLyricsTranslate(SongMeta song) async => _tryScrape(song, "lyricstranslate.com");
  Future<SongWithLyrics?> _tryLyricsify(SongMeta song) async => _tryScrape(song, "lyricsify.com");
  Future<SongWithLyrics?> _tryFindMusicByLyrics(SongMeta song) async => _tryScrape(song, "findmusicbylyrics.com");
  Future<SongWithLyrics?> _tryLyricsDotCom(SongMeta song) async => _tryScrape(song, "lyrics.com");

  Future<SongWithLyrics?> _tryScrape(SongMeta song, String sourceName) async {
    // Placeholder for actual scraping logic. 
    // Example: Fetch HTML, parse with html package, extract text.
    return null;
  }

  Future<String?> fetchArtwork(String title, String artist) async {
    try {
      final url = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent('$artist $title')}&entity=song&limit=1'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          String? art = data['results'][0]['artworkUrl100'];
          if (art != null) return art.replaceAll('100x100', '600x600');
        }
      }
    } catch (e) { /* Ignore */ }
    return null;
  }

  Future<List<SongMeta>> searchSongs(String query) async {
    try {
      final url = Uri.parse('https://lrclib.net/api/search?q=${Uri.encodeComponent(query)}');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map<SongMeta>((item) => SongMeta(
          title: item['trackName'] as String? ?? 'Unknown',
          artist: item['artistName'] as String? ?? 'Unknown',
          duration: item['duration'] as int? ?? 0,
          album: item['albumName'] as String?,
        )).toList();
      }
    } catch (e) { /* Ignore */ }
    return [];
  }
}