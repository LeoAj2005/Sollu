import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';

class SavedLyricsScreen extends ConsumerWidget {
  const SavedLyricsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLyrics = ref.watch(savedLyricsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Lyrics')),
      body: savedLyrics.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (lyrics) => lyrics.isEmpty
            ? const Center(child: Text('No saved lyrics'))
            : ListView.builder(
                itemCount: lyrics.length,
                itemBuilder: (context, index) {
                  final lyric = lyrics[index];
                  return ListTile(
                    title: Text(lyric.title),
                    subtitle: Text(lyric.artist),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await ref.read(storageServiceProvider).deleteLyrics(lyric.id);
                        ref.invalidate(savedLyricsProvider);
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}