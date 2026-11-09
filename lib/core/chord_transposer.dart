const _chromaticNotes = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

const _flatToSharp = {
  'DB': 'C#',
  'EB': 'D#',
  'GB': 'F#',
  'AB': 'G#',
  'BB': 'A#',
};

String addChordBrackets(String lyrics) {
  return lyrics
      .split('\n')
      .map(_normalizeChordMarkers)
      .map(_addChordBracketsToLine)
      .join('\n');
}

String _normalizeChordMarkers(String line) {
  return line.replaceAllMapped(
    RegExp(r'<([A-Ga-g][#b]?(?:m|maj|min|dim|aug|sus|add)?[0-9]*)>'),
    (match) => '[${match.group(1)}]',
  );
}

String _addChordBracketsToLine(String line) {
  if (line.trim().isEmpty || line.contains('[')) return line;

  final matches = RegExp(
    r'(?<![A-Za-z])([A-Ga-g])([#b]?)(m|maj|min|dim|aug|sus|add)?([0-9]*)(?![A-Za-z])',
  ).allMatches(line).toList();
  if (matches.isEmpty) return line;

  final tokens = line.trim().split(RegExp(r'\s+'));
  final isChordLine =
      tokens.length > 1 && tokens.every((token) => _isChordToken(token));
  final hasExplicitChordShape = matches.any(
    (match) =>
        (match.group(2)?.isNotEmpty ?? false) ||
        (match.group(3)?.isNotEmpty ?? false) ||
        (match.group(4)?.isNotEmpty ?? false),
  );
  if (!isChordLine && !hasExplicitChordShape) return line;

  return line.replaceAllMapped(
    RegExp(
      r'(?<![A-Za-z])([A-Ga-g])([#b]?)(m|maj|min|dim|aug|sus|add)?([0-9]*)(?![A-Za-z])',
    ),
    (match) => '[${match.group(0)!}]',
  );
}

bool _isChordToken(String token) {
  return RegExp(r'^[A-Ga-g][#b]?(m|maj|min|dim|aug|sus|add)?[0-9]*$')
      .hasMatch(token);
}

String transposeLyrics(String lyrics, int semitones) {
  final offset = semitones.clamp(-11, 11);
  return lyrics.replaceAllMapped(
    RegExp(
      r'(?<![A-Za-z])([A-Ga-g])([#b]?)(m|maj|min|dim|aug|sus|add)?([0-9]*)(?![A-Za-z])',
    ),
    (match) {
      final note = '${match.group(1)!.toUpperCase()}${match.group(2) ?? ''}';
      final normalized = _flatToSharp[note.toUpperCase()] ?? note;
      final index = _chromaticNotes.indexOf(normalized);
      if (index == -1) return match.group(0)!;
      final transposed = _chromaticNotes[_wrappedIndex(index + offset)];
      final suffix = '${match.group(3) ?? ''}${match.group(4) ?? ''}';
      return '$transposed$suffix';
    },
  );
}

String transposeKey(String key, int semitones) {
  final offset = semitones.clamp(-11, 11);
  final index = _chromaticNotes.indexOf(key.replaceAll('b', '#'));
  if (index == -1) return key;
  return _chromaticNotes[_wrappedIndex(index + offset)];
}

int _wrappedIndex(int index) {
  return ((index % _chromaticNotes.length) + _chromaticNotes.length) %
      _chromaticNotes.length;
}
