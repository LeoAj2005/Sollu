enum LyricsType {
  synced,
  plain,
  none;

  String get name {
    switch (this) {
      case LyricsType.synced: return 'synced';
      case LyricsType.plain: return 'plain';
      case LyricsType.none: return 'none';
    }
  }

  static LyricsType fromString(String? value) {
    switch (value) {
      case 'synced': return LyricsType.synced;
      case 'plain': return LyricsType.plain;
      default: return LyricsType.none;
    }
  }
}