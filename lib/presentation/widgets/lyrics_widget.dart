import 'package:flutter/material.dart';
import 'package:sollu/data/models/song_with_lyrics.dart';
import 'package:sollu/data/models/lyrics_type.dart';
import 'package:sollu/data/models/song_meta.dart';
import 'package:sollu/data/models/synced_lyrics.dart';
import 'package:sollu/utils/utils.dart';

class LyricsWidget extends StatefulWidget {
  final SongWithLyrics lyrics;
  final SongMeta? currentSong;

  const LyricsWidget({super.key, required this.lyrics, this.currentSong});

  @override
  State<LyricsWidget> createState() => _LyricsWidgetState();
}

class _LyricsWidgetState extends State<LyricsWidget> {
  final ScrollController _scrollController = ScrollController();
  int _currentLineIndex = -1;
  SyncedLyrics? _parsedLyrics;

  @override
  void initState() {
    super.initState();
    _parseLyrics();
    _updateCurrentLine();
  }

  @override
  void didUpdateWidget(covariant LyricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lyrics.syncedLyrics != widget.lyrics.syncedLyrics) {
      _parseLyrics();
    }
    _updateCurrentLine();
  }

  void _parseLyrics() {
    if (widget.lyrics.lyricsType == LyricsType.synced && widget.lyrics.syncedLyrics != null) {
      setState(() {
        _parsedLyrics = Utils.parseLrc(widget.lyrics.syncedLyrics!);
        _currentLineIndex = -1; // Reset tracking index for new lyrics
      });
    } else {
      setState(() {
        _parsedLyrics = null;
      });
    }
  }

  void _updateCurrentLine() {
    if (_parsedLyrics == null || widget.currentSong == null) return;
    
    final currentPosition = widget.currentSong!.position;
    final lines = _parsedLyrics!.lines;
    
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
    
    // Approximate line offset calculation (accounting for custom padding/height)
    // For completely pixel-perfect variable text sizes, 'scrollable_positioned_list' dependency is highly recommended
    final offset = (index * 54.0) - (MediaQuery.of(context).size.height * 0.3);
    
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_parsedLyrics != null) {
      final lines = _parsedLyrics!.lines;
      
      return ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
            stops: [0.0, 0.15, 0.85, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.35,
            bottom: MediaQuery.of(context).size.height * 0.45,
          ),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final isCurrent = index == _currentLineIndex;
            return GestureDetector(
              onTap: () {
                // Future: implement seek using lines[index].timestamp
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 24.0),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isCurrent ? 26 : 20,
                    height: 1.4,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.4),
                  ),
                  child: Text(lines[index].text),
                ),
              ),
            );
          },
        ),
      );
    } else if (widget.lyrics.lyrics != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
        child: Text(
          widget.lyrics.lyrics!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 19, 
            height: 1.7,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    return const Center(
      child: Text(
        'No lyrics available', 
        style: TextStyle(color: Colors.white60, fontSize: 16),
      ),
    );
  }
}