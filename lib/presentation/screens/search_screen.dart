import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../data/models/song_meta.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  List<SongMeta> _results = [];
  bool _isLoading = false;

  Future<void> _search() async {
    if (_controller.text.isEmpty) return;
    setState(() => _isLoading = true);
    
    final api = ref.read(apiServiceProvider);
    _results = await api.searchSongs(_controller.text);
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Search songs',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final song = _results[index];
                return ListTile(
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}