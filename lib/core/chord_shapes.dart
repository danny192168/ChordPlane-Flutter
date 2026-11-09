class ChordShape {
  const ChordShape({
    required this.name,
    required this.frets,
    required this.fingers,
    this.baseFret = 1,
  });

  final String name;
  final List<int> frets;
  final List<int> fingers;
  final int baseFret;
}

const commonChordShapes = <String, ChordShape>{
  'A': ChordShape(
    name: 'A',
    frets: [0, 0, 2, 2, 2, 0],
    fingers: [0, 0, 1, 2, 3, 0],
  ),
  'Am': ChordShape(
    name: 'Am',
    frets: [-1, 0, 2, 2, 1, 0],
    fingers: [0, 0, 2, 3, 1, 0],
  ),
  'A7': ChordShape(
    name: 'A7',
    frets: [0, 0, 2, 0, 2, 0],
    fingers: [0, 0, 2, 0, 3, 0],
  ),
  'Amaj7': ChordShape(
    name: 'Amaj7',
    frets: [0, 0, 2, 1, 2, 0],
    fingers: [0, 0, 2, 1, 3, 0],
  ),
  'Aadd9': ChordShape(
    name: 'Aadd9',
    frets: [0, 0, 2, 4, 2, 0],
    fingers: [0, 0, 1, 3, 2, 0],
  ),
  'A#': ChordShape(
    name: 'A#',
    frets: [1, 3, 3, 2, 1, 1],
    fingers: [1, 3, 4, 2, 1, 1],
  ),
  'A#m': ChordShape(
    name: 'A#m',
    frets: [1, 3, 3, 1, 1, 1],
    fingers: [1, 3, 4, 1, 1, 1],
  ),
  'Am7': ChordShape(
    name: 'Am7',
    frets: [-1, 0, 2, 0, 1, 0],
    fingers: [0, 0, 2, 0, 1, 0],
  ),
  'Asus4': ChordShape(
    name: 'Asus4',
    frets: [0, 0, 2, 2, 3, 0],
    fingers: [0, 0, 1, 2, 3, 0],
  ),
  'B': ChordShape(
    name: 'B',
    frets: [-1, 2, 4, 4, 4, 2],
    fingers: [0, 1, 3, 3, 3, 1],
    baseFret: 2,
  ),
  'Bm': ChordShape(
    name: 'Bm',
    frets: [-1, 2, 4, 4, 3, 2],
    fingers: [0, 1, 3, 4, 2, 1],
    baseFret: 2,
  ),
  'B7': ChordShape(
    name: 'B7',
    frets: [-1, 2, 1, 2, 0, 2],
    fingers: [0, 2, 1, 3, 0, 4],
  ),
  'Bm7': ChordShape(
    name: 'Bm7',
    frets: [-1, 2, 4, 2, 3, 2],
    fingers: [0, 1, 3, 1, 2, 1],
    baseFret: 2,
  ),
  'C': ChordShape(
    name: 'C',
    frets: [-1, 3, 2, 0, 1, 0],
    fingers: [0, 3, 2, 0, 1, 0],
  ),
  'C#': ChordShape(
    name: 'C#',
    frets: [-1, 4, 6, 6, 6, 4],
    fingers: [0, 1, 3, 3, 3, 1],
    baseFret: 4,
  ),
  'C#m': ChordShape(
    name: 'C#m',
    frets: [-1, 4, 6, 6, 5, 4],
    fingers: [0, 1, 3, 4, 2, 1],
    baseFret: 4,
  ),
  'C#m7': ChordShape(
    name: 'C#m7',
    frets: [-1, 4, 6, 4, 5, 4],
    fingers: [0, 1, 3, 1, 2, 1],
    baseFret: 4,
  ),
  'C7': ChordShape(
    name: 'C7',
    frets: [-1, 3, 2, 3, 1, 0],
    fingers: [0, 3, 2, 4, 1, 0],
  ),
  'Cmaj7': ChordShape(
    name: 'Cmaj7',
    frets: [-1, 3, 2, 0, 0, 0],
    fingers: [0, 3, 2, 0, 0, 0],
  ),
  'Cadd9': ChordShape(
    name: 'Cadd9',
    frets: [-1, 3, 2, 0, 3, 0],
    fingers: [0, 3, 2, 0, 4, 0],
  ),
  'Cm': ChordShape(
    name: 'Cm',
    frets: [-1, 3, 5, 5, 4, 3],
    fingers: [0, 1, 3, 4, 2, 1],
    baseFret: 3,
  ),
  'D': ChordShape(
    name: 'D',
    frets: [-1, -1, 0, 2, 3, 2],
    fingers: [0, 0, 0, 1, 3, 2],
  ),
  'D7': ChordShape(
    name: 'D7',
    frets: [-1, -1, 0, 2, 1, 2],
    fingers: [0, 0, 0, 2, 1, 3],
  ),
  'D#': ChordShape(
    name: 'D#',
    frets: [-1, 6, 8, 8, 8, 6],
    fingers: [0, 1, 3, 3, 3, 1],
    baseFret: 6,
  ),
  'Dmaj7': ChordShape(
    name: 'Dmaj7',
    frets: [-1, -1, 0, 2, 2, 2],
    fingers: [0, 0, 0, 1, 2, 3],
  ),
  'Dsus2': ChordShape(
    name: 'Dsus2',
    frets: [-1, -1, 0, 2, 3, 0],
    fingers: [0, 0, 0, 1, 2, 0],
  ),
  'Dsus4': ChordShape(
    name: 'Dsus4',
    frets: [-1, -1, 0, 2, 3, 3],
    fingers: [0, 0, 0, 1, 2, 3],
  ),
  'Dm': ChordShape(
    name: 'Dm',
    frets: [-1, -1, 0, 2, 3, 1],
    fingers: [0, 0, 0, 2, 3, 1],
  ),
  'Dm7': ChordShape(
    name: 'Dm7',
    frets: [-1, -1, 0, 2, 1, 1],
    fingers: [0, 0, 0, 2, 1, 1],
  ),
  'E': ChordShape(
    name: 'E',
    frets: [0, 2, 2, 1, 0, 0],
    fingers: [0, 2, 3, 1, 0, 0],
  ),
  'E7': ChordShape(
    name: 'E7',
    frets: [0, 2, 0, 1, 0, 0],
    fingers: [0, 2, 0, 1, 0, 0],
  ),
  'Emaj7': ChordShape(
    name: 'Emaj7',
    frets: [0, 2, 1, 1, 0, 0],
    fingers: [0, 3, 1, 2, 0, 0],
  ),
  'Esus4': ChordShape(
    name: 'Esus4',
    frets: [0, 2, 2, 2, 0, 0],
    fingers: [0, 1, 2, 3, 0, 0],
  ),
  'Em': ChordShape(
    name: 'Em',
    frets: [0, 2, 2, 0, 0, 0],
    fingers: [0, 2, 3, 0, 0, 0],
  ),
  'Em7': ChordShape(
    name: 'Em7',
    frets: [0, 2, 0, 0, 0, 0],
    fingers: [0, 2, 0, 0, 0, 0],
  ),
  'F': ChordShape(
    name: 'F',
    frets: [1, 3, 3, 2, 1, 1],
    fingers: [1, 3, 4, 2, 1, 1],
  ),
  'F#': ChordShape(
    name: 'F#',
    frets: [2, 4, 4, 3, 2, 2],
    fingers: [1, 3, 4, 2, 1, 1],
    baseFret: 2,
  ),
  'F#m': ChordShape(
    name: 'F#m',
    frets: [2, 4, 4, 2, 2, 2],
    fingers: [1, 3, 4, 1, 1, 1],
    baseFret: 2,
  ),
  'Fmaj7': ChordShape(
    name: 'Fmaj7',
    frets: [-1, -1, 3, 2, 1, 0],
    fingers: [0, 0, 4, 3, 2, 0],
  ),
  'Fm': ChordShape(
    name: 'Fm',
    frets: [1, 3, 3, 1, 1, 1],
    fingers: [1, 3, 4, 1, 1, 1],
  ),
  'F7': ChordShape(
    name: 'F7',
    frets: [1, 3, 1, 2, 1, 1],
    fingers: [1, 3, 1, 2, 1, 1],
  ),
  'Fm7': ChordShape(
    name: 'Fm7',
    frets: [1, 3, 1, 1, 1, 1],
    fingers: [1, 3, 1, 1, 1, 1],
  ),
  'G': ChordShape(
    name: 'G',
    frets: [3, 2, 0, 0, 0, 3],
    fingers: [2, 1, 0, 0, 0, 3],
  ),
  'G#': ChordShape(
    name: 'G#',
    frets: [4, 6, 6, 5, 4, 4],
    fingers: [1, 3, 4, 2, 1, 1],
    baseFret: 4,
  ),
  'G#m': ChordShape(
    name: 'G#m',
    frets: [4, 6, 6, 4, 4, 4],
    fingers: [1, 3, 4, 1, 1, 1],
    baseFret: 4,
  ),
  'G7': ChordShape(
    name: 'G7',
    frets: [3, 2, 0, 0, 0, 1],
    fingers: [3, 2, 0, 0, 0, 1],
  ),
  'Gm': ChordShape(
    name: 'Gm',
    frets: [3, 5, 5, 3, 3, 3],
    fingers: [1, 3, 4, 1, 1, 1],
    baseFret: 3,
  ),
  'Gm7': ChordShape(
    name: 'Gm7',
    frets: [3, 5, 3, 3, 3, 3],
    fingers: [1, 3, 1, 1, 1, 1],
    baseFret: 3,
  ),
  'Gmaj7': ChordShape(
    name: 'Gmaj7',
    frets: [3, 2, 0, 0, 0, 2],
    fingers: [3, 2, 0, 0, 0, 1],
  ),
  'Gsus4': ChordShape(
    name: 'Gsus4',
    frets: [3, 3, 0, 0, 1, 3],
    fingers: [2, 3, 0, 0, 1, 4],
  ),
};

ChordShape? chordShapeFor(String name) {
  final normalized = name.trim();
  final direct = commonChordShapes[normalized];
  if (direct != null) return direct;

  const aliases = {'Bb': 'A#', 'Db': 'C#', 'Eb': 'D#', 'Gb': 'F#', 'Ab': 'G#'};
  final sharpName = normalized.replaceFirstMapped(
    RegExp(r'^[A-G]b'),
    (match) => aliases[match.group(0)] ?? match.group(0)!,
  );
  return commonChordShapes[sharpName];
}
