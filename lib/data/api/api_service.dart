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

    if (enabledSources['Deezer'] ?? false) {
      lyrics = await _tryDeezer(song, syncOnly: true);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['Netease'] ?? false) {
      lyrics = await _tryNetease(song, syncOnly: true);
      if (lyrics != null) return lyrics;
    }

    // Pass 2: Fallback to Plain Lyrics
    if (enabledSources['LRCLIB'] ?? false) {
      lyrics = await _tryLrclib(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['Deezer'] ?? false) {
      lyrics = await _tryDeezer(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['Netease'] ?? false) {
      lyrics = await _tryNetease(song);
      if (lyrics != null) return lyrics;
    }

    if (enabledSources['Lyrics.ovh'] ?? false) {
      lyrics = await _tryLyricsOvh(song);
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
          
          if (syncOnly && syncedLyrics == null) return null;

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

  Future<SongWithLyrics?> _tryDeezer(SongMeta song, {bool syncOnly = false}) async {
    try {
      // 1. Search for track ID
      final searchUrl = Uri.parse(
        'https://api.deezer.com/search?q=${Uri.encodeQueryComponent('artist:"${song.artist}" track:"${song.title}"')}&limit=1'
      );
      final searchRes = await http.get(searchUrl).timeout(const Duration(seconds: 5));
      
      if (searchRes.statusCode == 200) {
        final searchData = json.decode(searchRes.body);
        if (searchData['total'] > 0) {
          final trackId = searchData['data'][0]['id'];
          
          // 2. Get Anonymous JWT
          final authRes = await http.post(
            Uri.parse('https://auth.deezer.com/login/anonymous?jo=p')
          ).timeout(const Duration(seconds: 5));
          
          if (authRes.statusCode == 200) {
            final authData = json.decode(authRes.body);
            final jwt = authData['jwt'];
            
            if (jwt != null) {
              // 3. GraphQL Request for Synced Lyrics
              final graphqlUrl = Uri.parse('https://pipe.deezer.com/api');
              final graphqlBody = json.encode({
                "operationName": "SynchronizedLyrics",
                "query": r"query SynchronizedLyrics($track_id: String!) { track(track_id: $track_id) { lyrics { synchronizedLines } } }",
                "variables": {"track_id": trackId.toString()}
              });

              final lyricsRes = await http.post(
                graphqlUrl,
                headers: {
                  'Authorization': 'Bearer $jwt',
                  'Content-Type': 'application/json',
                },
                body: graphqlBody,
              ).timeout(const Duration(seconds: 5));
              
              if (lyricsRes.statusCode == 200) {
                final lyricsData = json.decode(lyricsRes.body);
                final synchronizedLines = lyricsData['data']?['track']?['lyrics']?['synchronizedLines'] as List?;
                
                if (synchronizedLines != null && synchronizedLines.isNotEmpty) {
                  // Build LRC string manually
                  final lrcBuffer = StringBuffer();
                  for (var line in synchronizedLines) {
                    final ms = line['milliseconds'] as int? ?? 0;
                    final text = line['line'] as String? ?? '';
                    final min = (ms ~/ 60000).toString().padLeft(2, '0');
                    final sec = ((ms % 60000) ~/ 1000).toString().padLeft(2, '0');
                    final hund = ((ms % 1000) ~/ 10).toString().padLeft(2, '0');
                    lrcBuffer.writeln('[$min:$sec.$hund]$text');
                  }
                  
                  final lrc = lrcBuffer.toString();
                  final syncedLyrics = Utils.parseLrc(lrc);
                  
                  if (syncOnly && syncedLyrics == null) return null;
                  
                  return SongWithLyrics(
                    id: '${song.title}_${song.artist}',
                    title: song.title,
                    artist: song.artist,
                    lyrics: syncedLyrics == null ? lrc : null,
                    syncedLyrics: syncedLyrics,
                    lyricsType: syncedLyrics != null ? LyricsType.synced : LyricsType.plain,
                    fetchedAt: DateTime.now(),
                    source: "Deezer",
                  );
                }
              }
            }
          }
        }
      }
    } catch (e) { /* Ignore */ }
    return null;
  }

  Future<SongWithLyrics?> _tryNetease(SongMeta song, {bool syncOnly = false}) async {
    try {
      // 1. Search for song ID
      final searchUrl = Uri.parse('https://music.163.com/api/search/get');
      // Netease requires POST and specific headers
      final searchRes = await http.post(
        searchUrl,
        headers: {
          'Referer': 'https://music.163.com',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
        body: {
          's': '${song.title} ${song.artist}',
          'type': '1',
          'offset': '0',
          'limit': '1',
        },
      ).timeout(const Duration(seconds: 5));
      
      if (searchRes.statusCode == 200) {
        final searchData = json.decode(searchRes.body);
        if (searchData['code'] == 200 && searchData['result']['songCount'] > 0) {
          final songId = searchData['result']['songs'][0]['id'];
          
          // 2. Fetch Lyrics
          final lyricsUrl = Uri.parse('https://music.163.com/api/song/lyric?id=$songId&lv=1&kv=1&tv=-1');
          final lyricsRes = await http.get(
            lyricsUrl,
            headers: {
              'Referer': 'https://music.163.com',
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            },
          ).timeout(const Duration(seconds: 5));
          
          if (lyricsRes.statusCode == 200) {
            final lyricsData = json.decode(lyricsRes.body);
            final lrc = lyricsData['lrc']?['lyric'] as String?;
            
            if (lrc != null && lrc.isNotEmpty) {
              final syncedLyrics = Utils.parseLrc(lrc);
              if (syncOnly && syncedLyrics == null) return null;
              
              return SongWithLyrics(
                id: '${song.title}_${song.artist}',
                title: song.title,
                artist: song.artist,
                lyrics: syncedLyrics == null ? lrc : null,
                syncedLyrics: syncedLyrics,
                lyricsType: syncedLyrics != null ? LyricsType.synced : LyricsType.plain,
                fetchedAt: DateTime.now(),
                source: "Netease",
              );
            }
          }
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