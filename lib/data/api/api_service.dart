import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_meta.dart';
import '../models/song_with_lyrics.dart';
import '../../utils/utils.dart';
import '../models/lyrics_type.dart';

class ApiService {
  // Add skipSource parameter
  Future<SongWithLyrics?> fetchLyrics(SongMeta song, {String? skipSource}) async {
    // 1. Try LRCLIB
    if (skipSource != "LRCLIB") {
      var lyrics = await _tryLrclib(song);
      if (lyrics != null) return lyrics;
    }

    // 2. Fallback to Lyrics.ovh
    if (skipSource != "Lyrics.ovh") {
      var lyrics = await _tryLyricsOvh(song);
      if (lyrics != null) return lyrics;
    }

    return null;
  }

  Future<SongWithLyrics?> _tryLrclib(SongMeta song) async {
    try {
      final url = Uri.parse(
        'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(song.artist)}&track_name=${Uri.encodeComponent(song.title)}&duration=${song.duration}'
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['statusCode'] != 404) {
          final syncedLyrics = Utils.parseLrc(data['syncedLyrics'] as String?);
          
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
            source: "LRCLIB", // Add source
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
            source: "Lyrics.ovh", // Add source
          );
        }
      }
    } catch (e) { /* Ignore */ }
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