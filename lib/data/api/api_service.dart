import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/song_meta.dart';
import '../models/song_with_lyrics.dart';
import '../models/lyrics_type.dart';

class ApiService {
  final http.Client _client = http.Client();
  static const String _neteaseWorker = 'https://gentle-morning-7966.nullbyteai01.workers.dev';
  static const String _userAgent = 'Sollu Lyrics App (Flutter)';

  // Normalize: strip spaces and non-word characters, lower-case, Unicode-aware
  String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '') // remove all whitespace
        .replaceAll(RegExp(r'[^\w]', unicode: true), ''); // keep only word chars
  }

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

  /// Fetches lyrics concurrently from all enabled sources and prioritizes synced lyrics.
  Future<SongWithLyrics?> fetchLyrics(
    SongMeta song,
    Map<String, bool> enabledSources, {
    String? forceSource,
  }) async {
    final bool useLrclib = forceSource == null ? (enabledSources['LRCLIB'] ?? false) : forceSource == 'LRCLIB';
    final bool useNetease = forceSource == null ? (enabledSources['Netease'] ?? false) : forceSource == 'Netease';
    final bool useOvh = forceSource == null ? (enabledSources['Lyrics.ovh'] ?? false) : forceSource == 'Lyrics.ovh';

    debugPrint("=========================================");
    debugPrint("fetchLyrics START (Concurrent Mode)");
    debugPrint("Song: ${song.title} by ${song.artist}");
    debugPrint("Will use -> LRCLIB: $useLrclib, Netease: $useNetease, Ovh: $useOvh");
    debugPrint("=========================================");

    // Create a list of futures to run concurrently
    final List<Future<SongWithLyrics?>> futures = [];
    
    if (useLrclib) futures.add(_tryLrclib(song));
    if (useNetease) futures.add(_tryNetease(song));
    if (useOvh) futures.add(_tryLyricsOvh(song));

    if (futures.isEmpty) return null;

    // Wait for all HTTP requests to resolve simultaneously
    final List<SongWithLyrics?> results = await Future.wait(futures);

    // Filter out null responses into a clean list
    final List<SongWithLyrics> candidates = results.whereType<SongWithLyrics>().toList();

    if (candidates.isEmpty) {
      debugPrint("fetchLyrics END (No lyrics found from any enabled source)");
      return null;
    }

    // Prioritize Synced Lyrics first (LRCLIB > Netease)
    if (useLrclib) {
      final lrclibMatch = candidates.firstWhere((c) => c.source == "LRCLIB" && c.lyricsType == LyricsType.synced, orElse: () => candidates.first);
      if (lrclibMatch.lyricsType == LyricsType.synced) return lrclibMatch;
    }
    
    final syncedMatch = candidates.firstWhere((c) => c.lyricsType == LyricsType.synced, orElse: () => candidates.first);
    if (syncedMatch.lyricsType == LyricsType.synced) return syncedMatch;

    // Fallback: If no synced lyrics are found, return the first available plain text candidate
    return candidates.first;
  }

  // --------------------------------------------------------------------------
  // LRCLIB
  // --------------------------------------------------------------------------
  Future<SongWithLyrics?> _tryLrclib(SongMeta song) async {
    try {
      return await _retry(() async {
        final stopwatch = Stopwatch()..start();
        const headers = {'User-Agent': _userAgent};

        final durationSeconds = song.duration > 1000 ? song.duration ~/ 1000 : song.duration;

        final params = <String, String>{
          'artist_name': song.artist,
          'track_name': song.title,
          if (durationSeconds > 0) 'duration': durationSeconds.toString(),
          if (song.album != null && song.album!.isNotEmpty) 'album_name': song.album!,
        };

        final uri = Uri.https('lrclib.net', '/api/get', params);
        final response = await _client.get(uri, headers: headers).timeout(const Duration(seconds: 15));

        stopwatch.stop();
        if (response.statusCode != 200) {
          debugPrint("LRCLIB failed: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)");
          return null;
        }

        final data = json.decode(response.body);
        if (data != null && data['statusCode'] != 404) {
          final synced = data['syncedLyrics'] as String?;
          final plain = data['plainLyrics'] as String?;
          if (synced != null || plain != null) {
            return SongWithLyrics(
              id: '${song.title}_${song.artist}',
              title: song.title,
              artist: song.artist,
              lyrics: plain,
              syncedLyrics: synced,
              lyricsType: synced != null
                  ? LyricsType.synced
                  : (plain != null ? LyricsType.plain : LyricsType.none),
              fetchedAt: DateTime.now(),
              source: "LRCLIB",
            );
          }
        }
        return null;
      });
    } catch (e) {
      debugPrint("LRCLIB Error: $e");
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Lyrics.ovh
  // --------------------------------------------------------------------------
  Future<SongWithLyrics?> _tryLyricsOvh(SongMeta song) async {
    try {
      return await _retry(() async {
        final stopwatch = Stopwatch()..start();
        final uri = Uri.parse('https://api.lyrics.ovh/v1/${Uri.encodeComponent(song.artist)}/${Uri.encodeComponent(song.title)}');
        
        final response = await _client.get(uri, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 15));
        stopwatch.stop();

        if (response.statusCode != 200) {
          debugPrint("Lyrics.ovh failed: ${response.statusCode} (${stopwatch.elapsedMilliseconds}ms)");
          return null;
        }

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
        return null;
      });
    } catch (e) {
      debugPrint("Lyrics.ovh Error: $e");
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Netease (via worker)
  // --------------------------------------------------------------------------
  Future<SongWithLyrics?> _tryNetease(SongMeta song) async {
    try {
      return await _retry(() async {
        final stopwatch = Stopwatch()..start();
        final mainArtist = song.artist.split(',').first.trim();
        final searchQuery = '${song.title} $mainArtist';
        
        // Clean URL building via Uri.parse parsing queryParameters natively
        final baseWorkerUri = Uri.parse(_neteaseWorker);
        final searchUrl = Uri(
          scheme: baseWorkerUri.scheme,
          host: baseWorkerUri.host,
          path: '${baseWorkerUri.path}/api/search/get',
          queryParameters: {
            's': searchQuery,
            'type': '1',
            'offset': '0',
            'limit': '10',
          },
        );

        final searchRes = await _client.get(
          searchUrl,
          headers: {
            'Referer': 'https://music.163.com',
            'User-Agent': _userAgent,
          },
        ).timeout(const Duration(seconds: 15));
        
        stopwatch.stop();

        if (searchRes.statusCode != 200) {
          debugPrint("Netease search failed: ${searchRes.statusCode} (${stopwatch.elapsedMilliseconds}ms)");
          return null;
        }

        final searchData = json.decode(searchRes.body);
        if (searchData['code'] == 200 && (searchData['result']['songCount'] ?? 0) > 0) {
          final songs = searchData['result']['songs'] as List;
          Map<String, dynamic>? matchedSong;

          final targetNormalized = _normalize(song.artist);

          for (var s in songs) {
            final artists = (s['artists'] as List?)?.map((a) => a['name'] as String? ?? '').toList() ?? [];
            if (artists.any((a) {
              final norm = _normalize(a);
              return norm.contains(targetNormalized) || targetNormalized.contains(norm);
            })) {
              matchedSong = s as Map<String, dynamic>?;
              break;
            }
          }
          
          matchedSong ??= songs.first as Map<String, dynamic>?;
          final songId = matchedSong?['id'];

          if (songId != null) {
            final lyricsUrl = Uri.parse('$_neteaseWorker/api/song/lyric?id=$songId&lv=1&kv=1&tv=-1');
            final lyricsRes = await _client.get(
              lyricsUrl,
              headers: {
                'Referer': 'https://music.163.com',
                'User-Agent': _userAgent,
              },
            ).timeout(const Duration(seconds: 15));

            if (lyricsRes.statusCode == 200) {
              final lyricsData = json.decode(lyricsRes.body);
              final lrcStr = lyricsData['lrc']?['lyric'] as String?;
              if (lrcStr != null && lrcStr.isNotEmpty) {
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
    } catch (e) {
      debugPrint("Netease Error: $e");
      return null;
    }
  }

  // --------------------------------------------------------------------------
  // Artwork (iTunes)
  // --------------------------------------------------------------------------
  Future<String?> fetchArtwork(String title, String artist) async {
    try {
      final uri = Uri.https(
        'itunes.apple.com',
        '/search',
        {
          'term': '$artist $title',
          'entity': 'song',
          'limit': '1',
        },
      );
      final response = await _client.get(uri, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['resultCount'] > 0) {
          String? art = data['results'][0]['artworkUrl100'];
          if (art != null) return art.replaceAll('100x100', '600x600');
        }
      }
    } catch (e) {
      // Clean silent fail
    }
    return null;
  }

  // --------------------------------------------------------------------------
  // Search (LRCLIB)
  // --------------------------------------------------------------------------
  Future<List<SongMeta>> searchSongs(String query) async {
    try {
      final uri = Uri.https('lrclib.net', '/api/search', {'q': query});
      final response = await _client.get(uri, headers: {'User-Agent': _userAgent}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map<SongMeta>((item) {
          final durationDouble = (item['duration'] as num?)?.toDouble() ?? 0.0;
          return SongMeta(
            title: item['trackName'] as String? ?? 'Unknown',
            artist: item['artistName'] as String? ?? 'Unknown',
            duration: (durationDouble * 1000).toInt(),
            album: item['albumName'] as String?,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint("Search Error: $e");
    }
    return [];
  }
}