import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/models/song_meta.dart';

class SongInfoWidget extends StatelessWidget {
  final SongMeta song;
  const SongInfoWidget({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (song.artworkUrl != null)
            CachedNetworkImage(
              imageUrl: song.artworkUrl!,
              width: 80, height: 80, fit: BoxFit.cover,
              errorWidget: (_, __, ___) => const Icon(Icons.music_note),
            )
          else
            Container(
              width: 80, height: 80,
              color: Colors.grey[300],
              child: const Icon(Icons.music_note, size: 40),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(song.title, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(song.artist, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}