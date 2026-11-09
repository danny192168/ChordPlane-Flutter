import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'local_store.dart';
import 'offline_models.dart';

class OfflineFileService {
  static Future<void> exportSong(Song song) async {
    final bytes = utf8.encode(
      jsonEncode({
        'format': 'chordplane-song',
        'version': 1,
        'song': song.toJson(),
      }),
    );
    await FilePicker.saveFile(
      dialogTitle: 'Export song',
      fileName: '${_safeName(song.title)}.chordsong',
      bytes: bytes,
    );
  }

  static Future<Song?> importSong() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['chordsong', 'json'],
    );
    final data = result == null ? null : await result.readAsBytes();
    if (data == null) return null;

    final decoded = jsonDecode(utf8.decode(data));
    if (decoded is! Map || decoded['format'] != 'chordplane-song') {
      throw const FormatException('This is not a ChordPlane song file.');
    }
    return Song.fromJson(Map<String, dynamic>.from(decoded['song'] as Map));
  }

  static Future<void> exportSetlist(Setlist setlist, LocalStore store) async {
    final bytes = utf8.encode(
      jsonEncode({
        'format': 'chordplane-setlist',
        'version': 1,
        'setlist': {
          ...setlist.toJson(),
          'songs': store.songsForSetlist(setlist).map((song) => song.toJson()),
        },
      }),
    );
    await FilePicker.saveFile(
      dialogTitle: 'Export setlist',
      fileName: '${_safeName(setlist.title)}.chordset',
      bytes: bytes,
    );
  }

  static Future<ImportedSetlist?> importSetlist() async {
    final result = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['chordset', 'json'],
    );
    final data = result == null ? null : await result.readAsBytes();
    if (data == null) return null;

    final decoded = jsonDecode(utf8.decode(data));
    if (decoded is! Map || decoded['format'] != 'chordplane-setlist') {
      throw const FormatException('This is not a ChordPlane setlist file.');
    }

    final rawSetlist = Map<String, dynamic>.from(decoded['setlist'] as Map);
    final songs = [
      for (final json in (rawSetlist['songs'] as List? ?? []))
        Song.fromJson(Map<String, dynamic>.from(json as Map)),
    ];
    return ImportedSetlist(setlist: Setlist.fromJson(rawSetlist), songs: songs);
  }

  static Future<void> printSong(Song song) async {
    await Printing.layoutPdf(
      onLayout: (_) => _document([
        pw.Text(song.title, style: pw.TextStyle(fontSize: 22)),
        pw.Text(song.artist),
        pw.Text('Key: ${song.key}'),
        pw.SizedBox(height: 16),
        pw.Text(song.lyrics),
      ]),
    );
  }

  static Future<void> printSetlist(Setlist setlist, LocalStore store) async {
    final songs = store.songsForSetlist(setlist);
    await Printing.layoutPdf(
      onLayout: (_) => _document([
        pw.Text(setlist.title, style: pw.TextStyle(fontSize: 22)),
        if (setlist.description.isNotEmpty) pw.Text(setlist.description),
        pw.SizedBox(height: 16),
        for (var index = 0; index < songs.length; index++)
          pw.Text(
            '${index + 1}. ${songs[index].title} - ${songs[index].artist}',
          ),
      ]),
    );
  }

  static Future<Uint8List> _document(List<pw.Widget> widgets) async {
    final document = pw.Document();
    document.addPage(pw.MultiPage(build: (_) => widgets));
    return Uint8List.fromList(await document.save());
  }

  static String _safeName(String value) {
    final name = value.trim().replaceAll(RegExp(r'[^\w\-. ]'), '');
    return name.isEmpty ? 'chordplane-export' : name;
  }
}

class ImportedSetlist {
  const ImportedSetlist({required this.setlist, required this.songs});

  final Setlist setlist;
  final List<Song> songs;
}
