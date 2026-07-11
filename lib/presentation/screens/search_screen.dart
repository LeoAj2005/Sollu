import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sollu/presentation/providers/providers.dart';
import 'package:sollu/data/models/song_meta.dart';
import 'package:sollu/presentation/widgets/lyrics_widget.dart';
import 'package:sollu/presentation/widgets/song_info_widget.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<SongMeta> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _search() async {
    final query = _controller.text;
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final api = ref.read(apiServiceProvider);
      final results = await api.searchSongs(query);
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _errorMessage = "No songs found. Try another keyword.";
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error searching: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Lyrics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Song title or artist',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final song = _results[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  leading: const Icon(Icons.music_note),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchedLyricsScreen(song: song),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SearchedLyricsScreen extends ConsumerWidget {
  final SongMeta song;
  const SearchedLyricsScreen({super.key, required this.song});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyricsAsync = ref.watch(manualLyricsProvider(song));
    
    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: Column(
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
      ),
    );
  }
}