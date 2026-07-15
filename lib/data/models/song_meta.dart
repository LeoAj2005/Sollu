class SongMeta {
  final String title;
  final String artist;
  final int duration;
  final String? album;
  final String? artworkUrl;
  final int position;    // Current playback position in ms
  final bool isPlaying;  // Track playback state

  SongMeta({
    required this.title,
    required this.artist,
    required this.duration,
    this.album,
    this.artworkUrl,
    this.position = 0,
    this.isPlaying = false,
  });

  factory SongMeta.fromJson(Map<String, dynamic> json) {
    return SongMeta(
      title: json['title'] as String,
      artist: json['artist'] as String,
      duration: json['duration'] as int,
      album: json['album'] as String?,
      artworkUrl: json['artworkUrl'] as String?,
      position: json['position'] as int? ?? 0,
      isPlaying: json['isPlaying'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'artist': artist,
    'duration': duration,
    'album': album,
    'artworkUrl': artworkUrl,
    'position': position,
    'isPlaying': isPlaying,
  };
}