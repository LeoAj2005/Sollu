import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sollu/data/models/lyrics_type.dart';
import 'package:sollu/presentation/providers/providers.dart';
import 'package:sollu/utils/utils.dart';

class FloatingLyricsBubble extends ConsumerStatefulWidget {
  const FloatingLyricsBubble({super.key});

  @override
  ConsumerState<FloatingLyricsBubble> createState() => _FloatingLyricsBubbleState();
}

class _FloatingLyricsBubbleState extends ConsumerState<FloatingLyricsBubble> {
  Offset _position = const Offset(20, 200);
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final showBubble = ref.watch(bubbleToggleProvider);
    if (!showBubble) return const SizedBox.shrink();

    final lyricsAsync = ref.watch(lyricsProvider);
    final liveSong = ref.watch(currentSongProvider).value;

    String currentLine = "No lyrics playing...";

    lyricsAsync.whenData((lyrics) {
      if (lyrics != null && lyrics.lyricsType == LyricsType.synced && lyrics.syncedLyrics != null && liveSong != null) {
        final parsed = Utils.parseLrc(lyrics.syncedLyrics!);
        if (parsed != null) {
          final lines = parsed.lines;
          int idx = 0;
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].timestamp <= liveSong.position) {
              idx = i;
            } else {
              break;
            }
          }
          currentLine = lines[idx].text;
        }
      } else if (lyrics != null && lyrics.lyrics != null) {
        currentLine = lyrics.lyrics!.split('\n').first;
      } else if (lyrics == null) {
        currentLine = "Lyrics not found";
      }
    });

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() => _position += details.delta);
        },
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        child: Container(
          constraints: BoxConstraints(maxWidth: _isExpanded ? 250 : 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note, color: Colors.deepPurple[200], size: 14),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      liveSong?.title ?? "Unknown",
                      style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                currentLine,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                maxLines: _isExpanded ? 5 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}