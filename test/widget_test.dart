// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chordplane/core/offline_models.dart';
import 'package:chordplane/main.dart';

void main() {
  testWidgets('ChordPlane app loads', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ChordPlaneApp());
    await tester.pumpAndSettle();

    expect(find.text('My songs'), findsOneWidget);
  });

  testWidgets('saving a new song returns to the songs list', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ChordPlaneApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Amazing Grace');
    await tester.enterText(find.byType(TextFormField).at(1), 'Traditional');
    await tester.enterText(find.byType(TextFormField).at(2), 'G');
    await tester.enterText(
      find.byType(TextFormField).at(4),
      '[G]Amazing grace',
    );
    await tester.scrollUntilVisible(
      find.byIcon(Icons.save_outlined),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byIcon(Icons.save_outlined));
    await tester.pumpAndSettle();

    expect(find.text('My songs'), findsOneWidget);
    expect(find.text('Amazing Grace'), findsOneWidget);
  });

  testWidgets('opening a song renders the detail screen', (
    WidgetTester tester,
  ) async {
    final song = Song(
      id: 'song-1',
      title: 'Amazing Grace',
      artist: 'Traditional',
      key: 'G',
      lyrics: '[G]Amazing grace',
    );
    SharedPreferences.setMockInitialValues({
      'offline_songs': '[${songJson(song)}]',
    });
    await tester.pumpWidget(const ChordPlaneApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Amazing Grace'));
    await tester.pumpAndSettle();

    expect(find.text('Key: G'), findsOneWidget);
    expect(find.byType(SelectableText), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('song controls and chord reference fit without overflow', (
    WidgetTester tester,
  ) async {
    final song = Song(
      id: 'song-2',
      title: 'Chord Variations',
      artist: 'Traditional',
      key: 'C',
      lyrics: ('[C]Verse\n\n[D]Bridge\n\n[G]Chorus\n\n' * 12),
    );
    SharedPreferences.setMockInitialValues({
      'offline_songs': '[${songJson(song)}]',
    });
    await tester.pumpWidget(const ChordPlaneApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chord Variations'));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).first, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_left), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView).first, const Offset(0, 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.grid_view_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Chords in this song'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

String songJson(Song song) {
  return jsonEncode(song.toJson());
}
