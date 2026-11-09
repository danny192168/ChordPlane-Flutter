class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.key,
    required this.lyrics,
    this.youtubeUrl = '',
    this.isFavorite = false,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String artist;
  final String key;
  final String lyrics;
  final String youtubeUrl;
  final bool isFavorite;
  final DateTime? updatedAt;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? key,
    String? lyrics,
    String? youtubeUrl,
    bool? isFavorite,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      key: key ?? this.key,
      lyrics: lyrics ?? this.lyrics,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'key': key,
    'lyrics': lyrics,
    'youtubeUrl': youtubeUrl,
    'isFavorite': isFavorite,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      key: json['key'] as String? ?? '',
      lyrics: json['lyrics'] as String? ?? '',
      youtubeUrl: json['youtubeUrl'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class Setlist {
  const Setlist({
    required this.id,
    required this.title,
    required this.songIds,
    this.description = '',
    this.updatedAt,
  });

  final String id;
  final String title;
  final List<String> songIds;
  final String description;
  final DateTime? updatedAt;

  Setlist copyWith({
    String? id,
    String? title,
    List<String>? songIds,
    String? description,
    DateTime? updatedAt,
  }) {
    return Setlist(
      id: id ?? this.id,
      title: title ?? this.title,
      songIds: songIds ?? this.songIds,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'songIds': songIds,
    'description': description,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory Setlist.fromJson(Map<String, dynamic> json) {
    return Setlist(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      songIds: [
        for (final id in (json['songIds'] as List? ?? [])) id as String,
      ],
      description: json['description'] as String? ?? '',
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

DateTime? _parseDate(Object? value) {
  if (value is! String) return null;
  return DateTime.tryParse(value);
}
