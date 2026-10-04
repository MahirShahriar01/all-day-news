/// Two-letter monogram used when a website has no logo.
String initials(String text) {
  final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '?';
  if (words.length == 1) return words.first.substring(0, words.first.length.clamp(0, 2)).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

bool isVideoUrl(String url) => RegExp(r'\.(mp4|webm|m4v|mov)(\?|$)', caseSensitive: false).hasMatch(url);
