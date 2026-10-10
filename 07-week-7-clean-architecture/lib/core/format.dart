String _two(int value) => value.toString().padLeft(2, '0');

/// Format ringkas: `HH:mm · d/M/yyyy` (waktu lokal).
String formatShortDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  return '${_two(local.hour)}:${_two(local.minute)} · '
      '${local.day}/${local.month}/${local.year}';
}

/// Format lengkap memakai representasi DateTime lokal.
String formatFullDateTime(DateTime dateTime) => dateTime.toLocal().toString();

/// Parsing id dari path parameter rute; mengembalikan [fallback] bila invalid.
int parseRouteId(String? raw, {int fallback = 0}) =>
    int.tryParse(raw ?? '') ?? fallback;
