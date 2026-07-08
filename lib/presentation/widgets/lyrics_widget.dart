import 'package:flutter/material.dart';
import '../../data/models/song_with_lyrics.dart';
import '../../data/models/lyrics_type.dart';

class LyricsWidget extends StatelessWidget {
  final SongWithLyrics lyrics;
  const LyricsWidget({super.key, required this.lyrics});

  @override
  Widget build(BuildContext context) {
    if (lyrics.lyricsType == LyricsType.synced && lyrics.syncedLyrics != null) {
      return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: lyrics.syncedLyrics!.lines.length,
        itemBuilder: (context, index) {
          final line = lyrics.syncedLyrics!.lines[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(line.text, style: Theme.of(context).textTheme.bodyLarge),
          );
        },
      );
    } else if (lyrics.lyrics != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(lyrics.lyrics!, style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    return const Center(child: Text('No lyrics available'));
  }
}