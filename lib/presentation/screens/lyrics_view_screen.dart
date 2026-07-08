import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sollu/presentation/providers/providers.dart';
import 'package:sollu/presentation/widgets/song_info_widget.dart';
import 'package:sollu/presentation/widgets/lyrics_widget.dart';
import 'package:sollu/services/media_session/media_session_service.dart';

class LyricsViewScreen extends ConsumerStatefulWidget {
  const LyricsViewScreen({super.key});

  @override
  ConsumerState<LyricsViewScreen> createState() => _LyricsViewScreenState();
}

class _LyricsViewScreenState extends ConsumerState<LyricsViewScreen> with WidgetsBindingObserver {
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final hasPerm = await MediaSessionService.instance.checkPermission();
    setState(() => _hasPermission = hasPerm);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final lyricsAsync = ref.watch(lyricsProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Sollu')),
      body: !_hasPermission
          ? _buildPermissionRequest()
          : currentSong.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (song) {
                if (song == null || song.title == 'Unknown') {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Play a song on Spotify, YouTube Music, or any other media app to see lyrics here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: [
                    SongInfoWidget(song: song),
                    Expanded(
                      child: lyricsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                        data: (lyrics) => lyrics == null 
                            ? const Center(child: Text('No lyrics found for this song'))
                            : LyricsWidget(lyrics: lyrics, currentSong: song),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'Sollu needs Notification Access to read your currently playing song.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => MediaSessionService.instance.requestPermission(),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}