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
      setState(() => _currentLineIndex = newIndex);
      _scrollToLine(newIndex);
    }
  }

  void _scrollToLine(int index) {
    if (!_scrollController.hasClients) return;
    // Approximate line height of 40.0
    final offset = (index * 40.0) - (MediaQuery.of(context).size.height / 3);
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
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
      
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black, Colors.transparent],
            stops: [0.0, 0.2, 0.8],
          ).createShader(bounds);
        },
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.4,
            bottom: MediaQuery.of(context).size.height * 0.4,
          ),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final isCurrent = index == _currentLineIndex;
            return GestureDetector(
              onTap: () {
                // Future: implement seek
              },
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: isCurrent ? 28 : 20,
                  height: 1.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
                  child: Text(lines[index].text),
                ),
              ),
            );
          },
        ),
      );
    } else if (widget.lyrics.lyrics != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          widget.lyrics.lyrics!,
          style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.6),
        ),
      );
    }
    return const Center(child: Text('No lyrics available', style: TextStyle(color: Colors.white)));
  }
}