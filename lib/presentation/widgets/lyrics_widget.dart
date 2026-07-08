import 'package:flutter/material.dart';
import 'package:sollu/data/models/song_with_lyrics.dart';
import 'package:sollu/data/models/lyrics_type.dart';
import 'package:sollu/data/models/song_meta.dart';

class LyricsWidget extends StatefulWidget {
  final SongWithLyrics lyrics;
  final SongMeta? currentSong;

  const LyricsWidget({super.key, required this.lyrics, this.currentSong});

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _currentLineIndex = 0;

  @override
  void initState() {
    super.initState();
    _updateCurrentLine();
  }

  @override
  void didUpdateWidget(covariant LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateCurrentLine();
  }

  void _updateCurrentLine() {
    if (widget.lyrics.lyricsType != LyricsType.synced || widget.currentSong == null) return;
    
    final currentPosition = widget.currentSong!.position;
    final lines = widget.lyrics.syncedLyrics!.lines;
    
    int newIndex = 0;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].timestamp <= currentPosition) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLineIndex) {
      setState(() {
        _currentLineIndex = newIndex;
      });
      _scrollToLine(newIndex);
    }
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;
    final offset = (index * 60.0) - 150; // Approximate line height - screen offset
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lyrics.lyricsType == LyricsType.synced && widget.lyrics.syncedLyrics != null) {
      final lines = widget.lyrics.syncedLyrics!.lines;
      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0).copyWith(top: MediaQuery.of(context).size.height / 3, bottom: MediaQuery.of(context).size.height / 2),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final isCurrent = index == _currentLineIndex;
          return GestureDetector(
            onTap: () {
              // In a real app, you'd trigger a seek event to the media player here
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: isCurrent ? 24 : 18,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.5),
                ),
                child: Text(lines[index].text),
              ),
            ),
          );
        },
      );
    } else if (widget.lyrics.lyrics != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(widget.lyrics.lyrics!, style: Theme.of(context).textTheme.bodyLarge),
      );
    }
    return const Center(child: Text('No lyrics available'));
  }
}