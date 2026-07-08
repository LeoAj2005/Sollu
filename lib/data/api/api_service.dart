import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song_meta.dart';
import '../models/song_with_lyrics.dart';
import '../../utils/utils.dart';
import '../models/lyrics_type.dart';

class ApiService {
  Future<SongWithLyrics?> fetchLyrics(SongMeta song) async {
    final url = Uri.parse(
      'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(song.artist)}&track_name=${Uri.encodeComponent(song.title)}&duration=${song.duration}'
    );
    
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['statusCode'] == 404 || data == null) return null;
      
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
      );
    }
    return null;
  }

  Future<List<SongMeta>> searchSongs(String query) async {
    final url = Uri.parse('https://lrclib.net/api/search?q=${Uri.encodeComponent(query)}');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as List;
      return data.map<SongMeta>((item) => SongMeta(
        title: item['trackName'] as String? ?? 'Unknown',
        artist: item['artistName'] as String? ?? 'Unknown',
        duration: item['duration'] as int? ?? 0,
        album: item['albumName'] as String?,
      )).toList();
    }
    return [];
  }
}