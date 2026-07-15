import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  int _currentLineIndex = 0;
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
      _parsedLyrics = Utils.parseLrc(widget.lyrics.syncedLyrics!);
    } else {
      _parsedLyrics = null;
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
    if (!_itemScrollController.isAttached) return;
    
    // alignment 0.4 keeps the active lyric line consistently positioned at 40% from the top of the viewport
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.4,
    );
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
            colors: [Colors.transparent, Colors.black, Colors.transparent],
            stops: [0.0, 0.2, 0.8],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.4,
            bottom: MediaQuery.of(context).size.height * 0.4,
          ),
          itemCount: lines.length,
          itemBuilder: (context, index) {
            final isCurrent = index == _currentLineIndex;
            return GestureDetector(
              onTap: () {
                // Future: implement seek using lines[index].timestamp
              },
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                textAlign: TextAlign.center,
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
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 32.0),
        child: Text(
          widget.lyrics.lyrics!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 18, 
            height: 1.6,
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