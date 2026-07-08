import 'synced_lyrics.dart';
import 'lyrics_type.dart';

class SongWithLyrics {
  final String id;
  final String title;
  final String artist;
  final String? lyrics;
  final SyncedLyrics? syncedLyrics;
  final LyricsType lyricsType;
  final DateTime fetchedAt;

  SongWithLyrics({
    required this.id,
    required this.title,
    required this.artist,
    this.lyrics,
    this.syncedLyrics,
    required this.lyricsType,
    required this.fetchedAt,
  });

  factory SongWithLyrics.fromJson(Map<String, dynamic> json) {
    return SongWithLyrics(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      lyrics: json['lyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] != null
          ? SyncedLyrics.fromJson(json['syncedLyrics'] as Map<String, dynamic>)
          : null,
      lyricsType: LyricsType.fromString(json['lyricsType'] as String?),
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'lyrics': lyrics,
    'syncedLyrics': syncedLyrics?.toJson(),
    'lyricsType': lyricsType.name,
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}