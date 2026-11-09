import 'package:flutter_test/flutter_test.dart';

import 'package:chordplane/core/chord_transposer.dart';

void main() {
  test('adds brackets to chord-only lines', () {
    expect(
      addChordBrackets('G        D        Em\nAmazing grace'),
      '[G]        [D]        [Em]\nAmazing grace',
    );
  });

  test('does not treat words as chords', () {
    expect(addChordBrackets('Amazing grace'), 'Amazing grace');
  });

  test('converts angle-bracket chords to the stored format', () {
    expect(addChordBrackets('<G> Amazing grace'), '[G] Amazing grace');
  });

  test('transposition clamps to the supported range', () {
    expect(transposeKey('C', 12), 'B');
    expect(transposeKey('C', -12), 'C#');
  });
}
