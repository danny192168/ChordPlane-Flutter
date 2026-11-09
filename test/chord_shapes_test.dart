import 'package:flutter_test/flutter_test.dart';

import 'package:chordplane/core/chord_shapes.dart';

void main() {
  test('provides common alternative chord shapes', () {
    for (final chord in ['A7', 'Cmaj7', 'C#m', 'Dsus4', 'F#m', 'G7']) {
      final shape = chordShapeFor(chord);
      expect(shape, isNotNull, reason: 'Missing shape for $chord');
      expect(shape!.frets, hasLength(6));
      expect(shape.fingers, hasLength(6));
    }
  });

  test('supports flat chord names through enharmonic aliases', () {
    expect(chordShapeFor('Bb'), isNotNull);
    expect(chordShapeFor('Db'), isNotNull);
    expect(chordShapeFor('F#'), isNotNull);
  });
}
