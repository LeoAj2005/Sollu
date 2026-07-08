import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/song_info_widget.dart';
import '../widgets/lyrics_widget.dart';

class LyricsViewScreen extends ConsumerWidget {
  const LyricsViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final lyricsAsync = ref.watch(lyricsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Sollu')),  // Updated app name
      body: currentSong.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (song) {
          if (song == null) return const Center(child: Text('No song playing'));
          
          return Column(
            children: [
              SongInfoWidget(song: song),
              Expanded(
                child: lyricsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (lyrics) => lyrics == null 
                      ? const Center(child: Text('No lyrics found'))
                      : LyricsWidget(lyrics: lyrics),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}