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

  void _refreshLyrics() {
    // Reset to auto-source and refresh
    ref.read(forceSourceProvider.notifier).state = null;
    ref.read(lyricsRefreshTriggerProvider.notifier).state++;
  }

  void _showSourceDialog() {
    final enabledSources = ref.read(enabledSourcesProvider);
    final currentSource = ref.read(forceSourceProvider) ?? "Auto";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Lyrics Source'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          children: <Widget>[
            _buildDialogOption(context, "Auto (Recommended)", currentSource == "Auto", () {
              ref.read(forceSourceProvider.notifier).state = null;
              ref.read(lyricsRefreshTriggerProvider.notifier).state++;
              Navigator.pop(context);
            }),
            if (enabledSources['LRCLIB'] ?? false)
              _buildDialogOption(context, "LRCLIB (Synced/Plain)", currentSource == "LRCLIB", () {
                ref.read(forceSourceProvider.notifier).state = "LRCLIB";
                ref.read(lyricsRefreshTriggerProvider.notifier).state++;
                Navigator.pop(context);
              }),
            if (enabledSources['Deezer'] ?? false)
              _buildDialogOption(context, "Deezer (Synced)", currentSource == "Deezer", () {
                ref.read(forceSourceProvider.notifier).state = "Deezer";
                ref.read(lyricsRefreshTriggerProvider.notifier).state++;
                Navigator.pop(context);
              }),
            if (enabledSources['Netease'] ?? false)
              _buildDialogOption(context, "Netease (Synced)", currentSource == "Netease", () {
                ref.read(forceSourceProvider.notifier).state = "Netease";
                ref.read(lyricsRefreshTriggerProvider.notifier).state++;
                Navigator.pop(context);
              }),
            if (enabledSources['Lyrics.ovh'] ?? false)
              _buildDialogOption(context, "Lyrics.ovh (Plain)", currentSource == "Lyrics.ovh", () {
                ref.read(forceSourceProvider.notifier).state = "Lyrics.ovh";
                ref.read(lyricsRefreshTriggerProvider.notifier).state++;
                Navigator.pop(context);
              }),
          ],
        );
      },
    );
  }

  Widget _buildDialogOption(BuildContext context, String title, bool isSelected, VoidCallback onTap) {
    return ListTile(
      title: Text(title, style: TextStyle(color: isSelected ? Theme.of(context).colorScheme.primary : null)),
      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(enrichedSongProvider);
    final liveSong = ref.watch(currentSongProvider).value;
    final lyricsAsync = ref.watch(lyricsProvider);
    final isBubbleActive = ref.watch(bubbleToggleProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isBubbleActive ? Icons.bubble_chart : Icons.bubble_chart_outlined,
              color: Colors.white,
            ),
            onPressed: () => ref.read(bubbleToggleProvider.notifier).state = !isBubbleActive,
            tooltip: 'Toggle Floating Bubble',
          ),
        ],
      ),
      body: !_hasPermission
          ? _buildPermissionRequest()
          : Stack(
              fit: StackFit.expand,
              children: [
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
                                    'No Lyrics Available.\nTry switching sources below.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                                  ),
                                ),
                              );
                            }
                            return LyricsWidget(lyrics: lyrics, currentSong: liveSong);
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

    String activeSource = ref.watch(forceSourceProvider) ?? "Auto";

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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.source, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(
                      'Source: ${lyrics?.source ?? activeSource}', 
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Switch Source Dialog Button
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            onPressed: _showSourceDialog,
            tooltip: 'Select Source',
          ),
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshLyrics,
            tooltip: 'Refresh Lyrics',
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