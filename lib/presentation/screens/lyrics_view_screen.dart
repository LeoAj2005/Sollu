import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sollu/data/models/song_meta.dart';
import 'package:sollu/data/models/song_with_lyrics.dart';
import 'package:sollu/presentation/providers/providers.dart';
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
      // Ask Android for the current song explicitly when app reopens
      MediaSessionService.instance.getCurrentMedia();
    }
  }

  Future<void> _checkPermission() async {
    final hasPerm = await MediaSessionService.instance.checkPermission();
    if (mounted) setState(() => _hasPermission = hasPerm);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Force switch the lyrics source
  void _switchSource(String? currentSource) {
    String? nextSource;
    if (currentSource == "LRCLIB") {
      nextSource = "Lyrics.ovh";
    } else if (currentSource == "Lyrics.ovh") {
      nextSource = "LRCLIB";
    } else {
      nextSource = null; // Try all again
    }

    ref.read(skipSourceProvider.notifier).state = nextSource;
    ref.read(lyricsRefreshTriggerProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(enrichedSongProvider);
    final lyricsAsync = ref.watch(lyricsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: !_hasPermission
          ? _buildPermissionRequest()
          : Stack(
              fit: StackFit.expand,
              children: [
                // Dynamic Blurred Background
                songAsync.when(
                  loading: () => Container(color: Theme.of(context).colorScheme.surface),
                  error: (_, __) => Container(color: Theme.of(context).colorScheme.surface),
                  data: (song) => song?.artworkUrl != null
                      ? CachedNetworkImage(
                          imageUrl: song!.artworkUrl!,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.7),
                          colorBlendMode: BlendMode.darken,
                          errorWidget: (_, __, ___) => Container(color: Theme.of(context).colorScheme.surface),
                        )
                      : Container(color: Theme.of(context).colorScheme.surface),
                ),
                
                // Content
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: kToolbarHeight),
                      songAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (song) => _buildMiniPlayer(context, song, lyricsAsync.value),
                      ),
                      Expanded(
                        child: lyricsAsync.when(
                          loading: () => _buildLoadingShimmer(),
                          error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                          data: (lyrics) {
                            if (lyrics == null) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Text(
                                    'No lyrics found.\nTry switching sources below.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                                  ),
                                ),
                              );
                            }
                            return LyricsWidget(lyrics: lyrics, currentSong: songAsync.value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, SongMeta? song, SongWithLyrics? lyrics) {
    if (song == null || song.title == 'Unknown') {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'Play a song on Spotify, YouTube Music, etc.',
          style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          if (song.artworkUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: song.artworkUrl!,
                width: 50, height: 50, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.grey),
              ),
            )
          else
            Container(width: 50, height: 50, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
                if (lyrics?.source != null)
                  Text('Source: ${lyrics!.source}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          // Switch Source Button
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: () => _switchSource(lyrics?.source),
            tooltip: 'Switch Source',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.white24,
      highlightColor: Colors.white10,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 15,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            height: 20,
            width: double.infinity,
            color: Colors.white,
          ),
        ),
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
            const Icon(Icons.graphic_eq, size: 80, color: Colors.deepPurple),
            const SizedBox(height: 24),
            Text(
              'Sollu needs Notification Access to read your currently playing song.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => MediaSessionService.instance.requestPermission(),
              icon: const Icon(Icons.security),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}