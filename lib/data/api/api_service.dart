import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:http/http.dart' as http;
import '../models/song_meta.dart';
import '../models/song_with_lyrics.dart';
import '../models/lyrics_type.dart';

class ApiService {
  // Deezer JWT Cache
  String? _deezerJwt;
  DateTime? _deezerJwtExpiry;

  // Retry helper
  Future<T> _retry<T>(Future<T> Function() fn, {int retries = 2}) async {
    for (int i = 0; i < retries; i++) {
      try {
        return await fn();
      } catch (e) {
        if (i == retries - 1) rethrow;
        debugPrint("Retry attempt ${i + 1} after error: $e");
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
    throw Exception("Failed after $retries retries");
  }

  Future<SongWithLyrics?> fetchLyrics(SongMeta song, Map<String, bool> enabledSources, {String? forceSource}) async {
    SongWithLyrics? lyrics;

    bool useLrclib = forceSource == null ? (enabledSources['LRCLIB'] ?? false) : forceSource == 'LRCLIB';
    bool useDeezer = forceSource == null ? (enabledSources['Deezer'] ?? false) : forceSource == 'Deezer';
    bool useNetease = forceSource == null ? (enabledSources['Netease'] ?? false) : forceSource == 'Netease';
    bool useOvh = forceSource == null ? (enabledSources['Lyrics.ovh'] ?? false) : forceSource == 'Lyrics.ovh';

    // Pass 1: Synced Lyrics
    if (useLrclib) {
      lyrics = await _tryLrclib(song, syncOnly: true);
      if (lyrics != null) return lyrics;
    }
    if (useDeezer) {
      lyrics = await _tryDeezer(song, syncOnly: true);
      if (lyrics != null) return lyrics;
    }
    if (useNetease) {
      lyrics = await _tryNetease(song, syncOnly: true);
      if (lyrics != null) return lyrics;
    }

    // Pass 2: Plain Lyrics
    if (useLrclib) {
      lyrics = await _tryLrclib(song);
      if (lyrics != null) return lyrics;
    }
    if (useDeezer) {
      lyrics = await _tryDeezer(song);
      if (lyrics != null) return lyrics;
    }
    if (useNetease) {
      lyrics = await _tryNetease(song);
      if (lyrics != null) return lyrics;
    }
    if (useOvh) {
      lyrics = await _tryLyricsOvh(song);
      if (lyrics != null) return lyrics;
    }

    return null;
  }

  Future<SongWithLyrics?> _tryLrclib(SongMeta song, {bool syncOnly = false}) async {
    try {
      return await _retry(() async {
        final stopwatch = Stopwatch()..start();
        const headers = {'User-Agent': 'Sollu Lyrics App (Flutter)'};

        if (song.duration > 0) {
          final urlStr1 = 'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(song.artist)}&track_name=${Uri.encodeComponent(song.title)}&duration=${song.duration}';
          final url1 = Uri.parse(urlStr1);
          final response1 = await http.get(url1, headers: headers).timeout(const Duration(seconds: 15));
          debugPrint("LRCLIB (with duration ${song.duration}): Status ${response1.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms");

          if (response1.statusCode == 200) {
            final data = json.decode(response1.body);
            if (data != null && data['statusCode'] != 404) {
              final syncedLyricsStr = data['syncedLyrics'] as String?;
              if (!(syncOnly && syncedLyricsStr == null)) {
                return SongWithLyrics(
                  id: '${song.title}_${song.artist}',
                  title: song.title,
                  artist: song.artist,
                  lyrics: data['plainLyrics'] as String?,
                  syncedLyrics: syncedLyricsStr,
                  lyricsType: syncedLyricsStr != null ? LyricsType.synced : (data['plainLyrics'] != null ? LyricsType.plain : LyricsType.none),
                  fetchedAt: DateTime.now(),
                  source: "LRCLIB",
                );
              }
            }
          }
        }

        final urlStr2 = 'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(song.artist)}&track_name=${Uri.encodeComponent(song.title)}';
        final url2 = Uri.parse(urlStr2);
        final response2 = await http.get(url2, headers: headers).timeout(const Duration(seconds: 15));
        debugPrint("LRCLIB (without duration): Status ${response2.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms");

        if (response2.statusCode == 200) {
          final data = json.decode(response2.body);
          if (data != null && data['statusCode'] != 404) {
            final syncedLyricsStr = data['syncedLyrics'] as String?;
            if (syncOnly && syncedLyricsStr == null) return null;

            return SongWithLyrics(
              id: '${song.title}_${song.artist}',
              title: song.title,
              artist: song.artist,
              lyrics: data['plainLyrics'] as String?,
              syncedLyrics: syncedLyricsStr,
              lyricsType: syncedLyricsStr != null ? LyricsType.synced : (data['plainLyrics'] != null ? LyricsType.plain : LyricsType.none),
              fetchedAt: DateTime.now(),
              source: "LRCLIB",
            );
          }
        }
        return null;
      });
    } catch (e) { debugPrint("LRCLIB Error: $e"); }
    return null;
  }

  Future<SongWithLyrics?> _tryLyricsOvh(SongMeta song) async {
    try {
      return await _retry(() async {
        final stopwatch = Stopwatch()..start();
        final url = Uri.parse('https://api.lyrics.ovh/v1/${Uri.encodeComponent(song.artist)}/${Uri.encodeComponent(song.title)}');
        final response = await http.get(url).timeout(const Duration(seconds: 15));
        stopwatch.stop();
        
        debugPrint("Lyrics.ovh: Status ${response.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms");
        
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
        return null;
      });
    } catch (e) { debugPrint("Lyrics.ovh Error: $e"); }
    return null;
  }

  Future<String?> _getDeezerJwt() async {
    if (_deezerJwt != null && _deezerJwtExpiry != null && DateTime.now().isBefore(_deezerJwtExpiry!)) {
      return _deezerJwt;
    }

    try {
      final authRes = await http.post(Uri.parse('https://auth.deezer.com/login/anonymous?jo=p')).timeout(const Duration(seconds: 15));
      if (authRes.statusCode == 200) {
        final authData = json.decode(authRes.body);
        _deezerJwt = authData['jwt'];
        _deezerJwtExpiry = DateTime.now().add(const Duration(minutes: 50));
        return _deezerJwt;
      }
    } catch (e) { debugPrint("Deezer Auth Error: $e"); }
    return null;
  }

  Future<SongWithLyrics?> _tryDeezer(SongMeta song, {bool syncOnly = false}) async {
    try {
      return await _retry(() async {
        final jwt = await _getDeezerJwt();
        if (jwt == null) return null;

        final stopwatch = Stopwatch()..start();
        final graphqlUrl = Uri.parse('https://pipe.deezer.com/api');
        
        final graphqlBody = json.encode({
          "operationName": "SearchAndLyrics",
          "query": r"""
            query SearchAndLyrics($query: String!) {
              search(query: $query) {
                results {
                  tracks {
                    edges {
                      node {
                        id
                        title
                        contributors {
                          edges {
                            node {
                              name
                              role
                            }
                          }
                        }
                        lyrics {
                          synchronizedLines {
                            lrcTimestamp
                            line
                          }
                          text
                        }
                      }
                    }
                  }
                }
              }
            }
          """,
          "variables": {"query": "${song.artist} ${song.title}"}
        });

        final res = await http.post(
          graphqlUrl,
          headers: {
            'Authorization': 'Bearer $jwt',
            'Content-Type': 'application/json',
          },
          body: graphqlBody,
        ).timeout(const Duration(seconds: 15));
        stopwatch.stop();
        
        debugPrint("Deezer: Status ${res.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms");

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          final edges = data['data']?['search']?['results']?['tracks']?['edges'] as List?;
          
          if (edges != null && edges.isNotEmpty) {
            Map<String, dynamic>? bestTrack;
            for (var edge in edges) {
              final node = edge['node'];
              final contributorEdges = node['contributors']?['edges'] as List?;
              if (contributorEdges != null) {
                for (var cEdge in contributorEdges) {
                  final name = cEdge['node']?['name'] as String? ?? "";
                  final role = cEdge['node']?['role'] as String? ?? "";
                  if (role.toLowerCase() == 'main' && name.toLowerCase() == song.artist.toLowerCase()) {
                    bestTrack = node as Map<String, dynamic>?;
                    break;
                  }
                }
              }
              if (bestTrack != null) break;
            }
            bestTrack ??= edges.first['node'] as Map<String, dynamic>?;

            final syncedLines = bestTrack?['lyrics']?['synchronizedLines'] as List?;
            final plainText = bestTrack?['lyrics']?['text'] as String?;

            if (syncedLines != null && syncedLines.isNotEmpty) {
              final lrcBuffer = StringBuffer();
              for (var line in syncedLines) {
                final timestamp = line['lrcTimestamp'] as String? ?? "";
                final text = line['line'] as String? ?? "";
                lrcBuffer.writeln('$timestamp$text');
              }
              
              final lrcStr = lrcBuffer.toString();
              if (syncOnly && lrcStr.isEmpty) return null;
              
              return SongWithLyrics(
                id: '${song.title}_${song.artist}',
                title: song.title,
                artist: song.artist,
                lyrics: plainText,
                syncedLyrics: lrcStr,
                lyricsType: LyricsType.synced,
                fetchedAt: DateTime.now(),
                source: "Deezer",
              );
            } else if (plainText != null && plainText.isNotEmpty) {
               return SongWithLyrics(
                id: '${song.title}_${song.artist}',
                title: song.title,
                artist: song.artist,
                lyrics: plainText,
                syncedLyrics: null,
                lyricsType: LyricsType.plain,
                fetchedAt: DateTime.now(),
                source: "Deezer",
              );
            }
          } else {
            debugPrint("Deezer: Search returned 0 tracks.");
          }
        } else {
          debugPrint("Deezer: GraphQL failed. Body: ${res.body}");
        }
        return null;
      });
    } catch (e) { debugPrint("Deezer Error: $e"); }
    return null;
  }

  Future<SongWithLyrics?> _tryNetease(SongMeta song, {bool syncOnly = false}) async {
    try {
      return await _retry(() async {
        final stopwatch = Stopwatch()..start();
        
        // FIX: Route through Cloudflare Worker to bypass geographic blocks and timeouts
        const baseUrl = 'https://gentle-morning-7966.nullbyteai01.workers.dev';
        
        final searchUrl = Uri.parse(
          '$baseUrl/api/search/get?s=${Uri.encodeQueryComponent('${song.title} ${song.artist}')}&type=1&offset=0&limit=10'
        );
        final searchRes = await http.get(
          searchUrl,
          headers: {
            'Referer': 'https://music.163.com',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ).timeout(const Duration(seconds: 15));
        stopwatch.stop();
        
        debugPrint("Netease Search (via Worker): Status ${searchRes.statusCode}, Time: ${stopwatch.elapsedMilliseconds}ms");

        if (searchRes.statusCode == 200) {
          final searchData = json.decode(searchRes.body);
          if (searchData['code'] == 200 && searchData['result']['songCount'] > 0) {
            final songs = searchData['result']['songs'] as List;
            Map<String, dynamic>? matchedSong;
            
            for (var s in songs) {
              final artists = (s['artists'] as List?)?.map((a) => a['name'] as String? ?? '').toList() ?? [];
              if (artists.any((name) => name.toLowerCase() == song.artist.toLowerCase())) {
                matchedSong = s as Map<String, dynamic>?;
                break;
              }
            }
            matchedSong ??= songs.first as Map<String, dynamic>?;
            
            final songId = matchedSong?['id'];
            
            final lyricsUrl = Uri.parse('$baseUrl/api/song/lyric?id=$songId&lv=1&kv=1&tv=-1');
            final lyricsRes = await http.get(
              lyricsUrl,
              headers: {
                'Referer': 'https://music.163.com',
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              },
            ).timeout(const Duration(seconds: 15));
            
            if (lyricsRes.statusCode == 200) {
              final lyricsData = json.decode(lyricsRes.body);
              final lrcStr = lyricsData['lrc']?['lyric'] as String?;
              
              if (lrcStr != null && lrcStr.isNotEmpty) {
                if (syncOnly && lrcStr.isEmpty) return null;
                
                return SongWithLyrics(
                  id: '${song.title}_${song.artist}',
                  title: song.title,
                  artist: song.artist,
                  lyrics: null,
                  syncedLyrics: lrcStr,
                  lyricsType: LyricsType.synced,
                  fetchedAt: DateTime.now(),
                  source: "Netease",
                );
              }
            }
          }
        }
        return null;
      });
    } catch (e) { debugPrint("Netease Error: $e"); }
    return null;
  }

  Future<String?> fetchArtwork(String title, String artist) async {
    try {
      final url = Uri.parse('https://itunes.apple.com/search?term=${Uri.encodeComponent('$artist $title')}&entity=song&limit=1');
      final response = await http.get(url).timeout(const Duration(seconds: 15));
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
      final response = await http.get(url).timeout(const Duration(seconds: 15));
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