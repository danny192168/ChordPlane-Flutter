import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'offline_models.dart';

class LocalStore extends ChangeNotifier {
  LocalStore._(this._preferences);

  static const _songsKey = 'offline_songs';
  static const _setlistsKey = 'offline_setlists';
  static const _uuid = Uuid();

  final SharedPreferences _preferences;
  List<Song> _songs = [];
  List<Setlist> _setlists = [];

  static Future<LocalStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final store = LocalStore._(preferences);
    store._songs = _decodeList(preferences.getString(_songsKey), Song.fromJson);
    store._setlists = _decodeList(
      preferences.getString(_setlistsKey),
      Setlist.fromJson,
    );
    return store;
  }

  List<Song> get songs => List.unmodifiable(_songs);
  List<Setlist> get setlists => List.unmodifiable(_setlists);

  Song? songById(String id) {
    for (final song in _songs) {
      if (song.id == id) return song;
    }
    return null;
  }

  List<Song> songsForSetlist(Setlist setlist) {
    return [for (final id in setlist.songIds) ?songById(id)];
  }

  Future<void> saveSong(Song song) async {
    final savedSong = song.copyWith(
      id: song.id.isEmpty ? _uuid.v4() : song.id,
      updatedAt: DateTime.now(),
    );
    final index = _songs.indexWhere((item) => item.id == savedSong.id);
    if (index == -1) {
      _songs = [..._songs, savedSong];
    } else {
      _songs = [..._songs]..[index] = savedSong;
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteSong(String id) async {
    _songs = _songs.where((song) => song.id != id).toList();
    _setlists = [
      for (final setlist in _setlists)
        setlist.copyWith(
          songIds: setlist.songIds.where((songId) => songId != id).toList(),
        ),
    ];
    await _save();
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    final song = songById(id);
    if (song == null) return;
    await saveSong(song.copyWith(isFavorite: !song.isFavorite));
  }

  Future<void> saveSetlist(Setlist setlist) async {
    final savedSetlist = setlist.copyWith(
      id: setlist.id.isEmpty ? _uuid.v4() : setlist.id,
      updatedAt: DateTime.now(),
    );
    final index = _setlists.indexWhere((item) => item.id == savedSetlist.id);
    if (index == -1) {
      _setlists = [..._setlists, savedSetlist];
    } else {
      _setlists = [..._setlists]..[index] = savedSetlist;
    }
    await _save();
    notifyListeners();
  }

  Future<void> deleteSetlist(String id) async {
    _setlists = _setlists.where((setlist) => setlist.id != id).toList();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _preferences.setString(
      _songsKey,
      jsonEncode(_songs.map((song) => song.toJson()).toList()),
    );
    await _preferences.setString(
      _setlistsKey,
      jsonEncode(_setlists.map((setlist) => setlist.toJson()).toList()),
    );
  }

  static List<T> _decodeList<T>(
    String? encoded,
    T Function(Map<String, dynamic>) decode,
  ) {
    if (encoded == null) return [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return [
        for (final item in decoded)
          if (item is Map) decode(Map<String, dynamic>.from(item)),
      ];
    } on FormatException {
      return [];
    }
  }
}
