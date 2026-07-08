class SyncedLyricLine {
  final int timestamp;
  final String text;

  SyncedLyricLine({required this.timestamp, required this.text});

  factory SyncedLyricLine.fromJson(Map<String, dynamic> json) {
    return SyncedLyricLine(
      timestamp: json['timestamp'] as int,
      text: json['text'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'timestamp': timestamp, 'text': text};
}

class SyncedLyrics {
  final List<SyncedLyricLine> lines;
  final int? offset;

  SyncedLyrics({required this.lines, this.offset});

  factory SyncedLyrics.fromJson(Map<String, dynamic> json) {
    return SyncedLyrics(
      lines: (json['lines'] as List)
          .map((e) => SyncedLyricLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      offset: json['offset'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'lines': lines.map((e) => e.toJson()).toList(),
    'offset': offset,
  };
}