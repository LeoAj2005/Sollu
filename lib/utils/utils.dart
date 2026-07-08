class Utils {
  static String formatDuration(int milliseconds) {
    int minutes = (milliseconds / 60000).floor();
    int seconds = ((milliseconds % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}