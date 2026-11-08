import 'i18n.dart';

/// The API may send dates without a timezone (SQLite): they are UTC.
DateTime parseApiDate(String value) {
  final hasZone = RegExp(r'([zZ]|[+-]\d\d:?\d\d)$').hasMatch(value);
  return DateTime.parse(hasZone ? value : '${value}Z').toLocal();
}

/// Short relative age, like the website: "just now", "12 min", "3 h", "100 d".
String timeAgo(String value, Translate t) {
  final seconds = DateTime.now().difference(parseApiDate(value)).inSeconds;
  if (seconds < 60) return t('just now', "à l'instant", 'ahora');
  if (seconds < 3600) return '${seconds ~/ 60} min';
  if (seconds < 86400) return '${seconds ~/ 3600} h';
  return '${seconds ~/ 86400} ${t('d', 'j', 'd')}';
}

/// "04/07 04:24": day/month in French and Spanish, month/day in English.
String shortDate(String value, Translate t) {
  final d = parseApiDate(value);
  String pad(int n) => n.toString().padLeft(2, '0');
  final day = pad(d.day);
  final month = pad(d.month);
  return '${t('$month/$day', '$day/$month', '$day/$month')} ${pad(d.hour)}:${pad(d.minute)}';
}
