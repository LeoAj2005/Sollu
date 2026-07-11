import 'lyrics_type.dart';

class SongWithLyrics {
  final String id;
  final String title;
  final String artist;
  final String? lyrics;
  final String? syncedLyrics; // Changed to String? to hold the raw LRC data
  final LyricsType lyricsType;
  final DateTime fetchedAt;
  final String? source;

  SongWithLyrics({
    required this.id,
    required this.title,
    required this.artist,
    this.lyrics,
    this.syncedLyrics,
    required this.lyricsType,
    required this.fetchedAt,
    this.source,
  });

  factory SongWithLyrics.fromJson(Map<String, dynamic> json) {
    return SongWithLyrics(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      lyrics: json['lyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?, // Directly parsed as a String?
      lyricsType: LyricsType.fromString(json['lyricsType'] as String?),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'lyrics': lyrics,
    'syncedLyrics': syncedLyrics, // Safely serialized directly as a String?
    'lyricsType': lyricsType.name,
    'fetchedAt': fetchedAt.toIso8601String(),
    'source': source,
  };
}