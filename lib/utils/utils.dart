import 'package:sollu/data/models/synced_lyrics.dart';

class Utils {
  static String formatDuration(int milliseconds) {
    int minutes = (milliseconds / 60000).floor();
    int seconds = ((milliseconds % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  static SyncedLyrics? parseLrc(String? lrcString) {
    if (lrcString == null || lrcString.isEmpty) return null;
    
    final lines = <SyncedLyricLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');
    
    for (final line in lrcString.split('\n')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3)!;
        final ms = int.parse(msStr) * (msStr.length == 2 ? 10 : 1);
        final text = match.group(4)?.trim() ?? '';
        
        final timestamp = Duration(minutes: min, seconds: sec, milliseconds: ms).inMilliseconds;
        if (text.isNotEmpty) {
          lines.add(SyncedLyricLine(timestamp: timestamp, text: text));
        }
      }
    }
    
    return lines.isNotEmpty ? SyncedLyrics(lines: lines) : null;
  }
}