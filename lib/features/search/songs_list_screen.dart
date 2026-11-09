import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../core/chord_shapes.dart';
import '../../core/chord_transposer.dart';
import '../../core/local_store.dart';
import '../../core/offline_file_service.dart';
import '../../core/offline_models.dart';
import '../add_song/add_song_screen.dart';
import 'chord_diagram.dart';

class SongsListScreen extends StatefulWidget {
  const SongsListScreen({required this.store, super.key});

  final LocalStore store;

  @override
  State<SongsListScreen> createState() => _SongsListScreenState();
}

class _SongsListScreenState extends State<SongsListScreen> {
  final _searchController = TextEditingController();
  final _listController = ScrollController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final songs = widget.store.songs.where((song) {
          final query = _query.trim().toLowerCase();
          return query.isEmpty ||
              song.title.toLowerCase().contains(query) ||
              song.artist.toLowerCase().contains(query);
        }).toList()..sort((a, b) => a.artist.compareTo(b.artist));

        return Scaffold(
          appBar: AppBar(
            title: const Text('My songs'),
            actions: [
              IconButton(
                tooltip: 'Import song',
                onPressed: _importSong,
                icon: const Icon(Icons.file_open_outlined),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    hintText: 'Search songs or artists',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: songs.isEmpty
                      ? Center(
                          child: Text(
                            widget.store.songs.isEmpty
                                ? 'No songs yet. Tap Add to create one.'
                                : 'No songs found.',
                          ),
                        )
                      : Scrollbar(
                          controller: _listController,
                          thumbVisibility: true,
                          interactive: true,
                          child: ListView.separated(
                            controller: _listController,
                            itemCount: songs.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, index) =>
                                _songCard(context, songs[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _songCard(BuildContext context, Song song) {
    return Card(
      child: ListTile(
        title: Text(song.title),
        subtitle: Text('${song.artist} • ${song.key}'),
        leading: IconButton(
          tooltip: song.isFavorite ? 'Remove favorite' : 'Add favorite',
          onPressed: () => widget.store.toggleFavorite(song.id),
          icon: Icon(
            song.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: song.isFavorite ? Theme.of(context).colorScheme.error : null,
          ),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SongDetailScreen(store: widget.store, song: song),
          ),
        ),
      ),
    );
  }

  Future<void> _importSong() async {
    try {
      final song = await OfflineFileService.importSong();
      if (song != null) {
        await widget.store.saveSong(song.copyWith(id: ''));
      }
    } on FormatException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('Unable to import that file.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class SongDetailScreen extends StatefulWidget {
  const SongDetailScreen({required this.store, required this.song, super.key});

  final LocalStore store;
  final Song song;

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  static const _minTranspose = -11;
  static const _maxTranspose = 11;
  static const _scrollSpeeds = [30.0, 50.0, 75.0, 100.0, 140.0];
  int _transpose = 0;
  int _scrollSpeedIndex = 2;
  double _zoom = 1;
  double _scaleStartZoom = 1;
  bool _controlsExpanded = false;
  bool _showQuickControls = false;
  Timer? _autoScrollTimer;
  late final ScrollController _songScrollController;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _songScrollController = ScrollController();
    _songScrollController.addListener(_handleSongScroll);
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _songScrollController.removeListener(_handleSongScroll);
    _songScrollController.dispose();
    super.dispose();
  }

  void _handleSongScroll() {
    final shouldShow = _songScrollController.offset > 120;
    if (shouldShow != _showQuickControls && mounted) {
      setState(() {
        _showQuickControls = shouldShow;
        if (!shouldShow) _controlsExpanded = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.store.songById(widget.song.id) ?? widget.song;
    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          IconButton(
            tooltip: song.isFavorite ? 'Remove favorite' : 'Add favorite',
            onPressed: () async {
              await widget.store.toggleFavorite(song.id);
              if (mounted) setState(() {});
            },
            icon: Icon(
              song.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: song.isFavorite
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
          ),
          IconButton(
            tooltip: 'Edit song',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SongEditorScreen(store: widget.store, song: song),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') OfflineFileService.exportSong(song);
              if (value == 'print') OfflineFileService.printSong(song);
              if (value == 'delete') _delete(song);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export song')),
              PopupMenuItem(value: 'print', child: Text('Print song')),
              PopupMenuItem(value: 'delete', child: Text('Delete song')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            controller: _songScrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Text(song.artist, style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Key: ${transposeKey(song.key, _transpose)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  const Text('Transpose'),
                  IconButton(
                    tooltip: 'Transpose down',
                    onPressed: () => setState(
                      () => _transpose = _transpose == _minTranspose
                          ? 0
                          : _transpose - 1,
                    ),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${_transpose >= 0 ? '+' : ''}$_transpose'),
                  IconButton(
                    tooltip: 'Transpose up',
                    onPressed: () => setState(
                      () => _transpose = _transpose == _maxTranspose
                          ? 0
                          : _transpose + 1,
                    ),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const Divider(),
              GestureDetector(
                onScaleStart: (_) => _scaleStartZoom = _zoom,
                onScaleUpdate: (details) {
                  if (details.scale == 1) return;
                  setState(() {
                    _zoom = (_scaleStartZoom * details.scale).clamp(0.75, 1.8);
                  });
                },
                child: _ChordLyrics(
                  lyrics: transposeLyrics(song.lyrics, _transpose),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize:
                        (Theme.of(context).textTheme.bodyLarge?.fontSize ??
                            16) *
                        _zoom,
                  ),
                  onChordTap: (chord) => showChordSheet(context, chord),
                ),
              ),
              if (song.youtubeUrl.isNotEmpty) ...[
                const SizedBox(height: 20),
                SelectableText(song.youtubeUrl),
              ],
            ],
          ),
          if (_showQuickControls)
            Positioned(
              right: 16,
              bottom: 16,
              child: _SongQuickControls(
                isExpanded: _controlsExpanded,
                isScrolling: _isAutoScrolling,
                transpose: _transpose,
                zoom: _zoom,
                speedIndex: _scrollSpeedIndex,
                speedCount: _scrollSpeeds.length,
                onToggleExpanded: () =>
                    setState(() => _controlsExpanded = !_controlsExpanded),
                onTransposeChanged: (value) =>
                    setState(() => _transpose = value),
                onZoomChanged: (value) => setState(() => _zoom = value),
                onToggleAutoScroll: _toggleAutoScroll,
                onSpeedChanged: (index) =>
                    setState(() => _scrollSpeedIndex = index),
                onShowChords: () =>
                    _showAllChords(transposeLyrics(song.lyrics, _transpose)),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleAutoScroll() {
    if (_isAutoScrolling) {
      _autoScrollTimer?.cancel();
      setState(() {
        _isAutoScrolling = false;
      });
      return;
    }

    if (!_songScrollController.hasClients ||
        _songScrollController.position.maxScrollExtent <= 0) {
      return;
    }

    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_songScrollController.hasClients) {
        _toggleAutoScroll();
        return;
      }

      final position = _songScrollController.position;
      final nextOffset =
          position.pixels + (_scrollSpeeds[_scrollSpeedIndex] * 0.05);
      if (nextOffset >= position.maxScrollExtent) {
        _songScrollController.jumpTo(position.maxScrollExtent);
        _toggleAutoScroll();
        return;
      }
      _songScrollController.jumpTo(nextOffset);
    });
    setState(() {
      _isAutoScrolling = true;
    });
  }

  Future<void> _delete(Song song) async {
    await widget.store.deleteSong(song.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _showAllChords(String lyrics) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.42,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Chords in this song',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            _ChordReferenceSection(
              lyrics: lyrics,
              onChordTap: (chord) => showChordSheet(context, chord),
              initiallyExpanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SongQuickControls extends StatelessWidget {
  const _SongQuickControls({
    required this.isExpanded,
    required this.isScrolling,
    required this.transpose,
    required this.zoom,
    required this.speedIndex,
    required this.speedCount,
    required this.onToggleExpanded,
    required this.onTransposeChanged,
    required this.onZoomChanged,
    required this.onToggleAutoScroll,
    required this.onSpeedChanged,
    required this.onShowChords,
  });

  final bool isExpanded;
  final bool isScrolling;
  final int transpose;
  final double zoom;
  final int speedIndex;
  final int speedCount;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onTransposeChanged;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onToggleAutoScroll;
  final ValueChanged<int> onSpeedChanged;
  final VoidCallback onShowChords;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isExpanded ? 350 : 56,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
      ),
      child: Row(
        children: [
          if (isExpanded)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Transpose down',
                      onPressed: () => onTransposeChanged(
                        transpose <= -11 ? 0 : transpose - 1,
                      ),
                      icon: const Icon(Icons.remove),
                    ),
                    Text(
                      '${transpose >= 0 ? '+' : ''}$transpose',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    IconButton(
                      tooltip: 'Transpose up',
                      onPressed: () => onTransposeChanged(
                        transpose >= 11 ? 0 : transpose + 1,
                      ),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: isScrolling
                          ? 'Pause autoscroll'
                          : 'Start autoscroll',
                      onPressed: onToggleAutoScroll,
                      icon: Icon(isScrolling ? Icons.pause : Icons.play_arrow),
                    ),
                    PopupMenuButton<int>(
                      tooltip: 'Autoscroll speed',
                      initialValue: speedIndex,
                      onSelected: onSpeedChanged,
                      itemBuilder: (_) => [
                        for (var index = 0; index < speedCount; index++)
                          PopupMenuItem(
                            value: index,
                            child: Text('Speed ${index + 1}'),
                          ),
                      ],
                      child: const Icon(Icons.speed),
                    ),
                    IconButton(
                      tooltip: 'Show chord diagrams',
                      onPressed: onShowChords,
                      icon: const Icon(Icons.music_note),
                    ),
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () =>
                          onZoomChanged((zoom - 0.1).clamp(0.75, 1.8)),
                      icon: const Icon(Icons.zoom_out),
                    ),
                    Text('${(zoom * 100).round()}%'),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () =>
                          onZoomChanged((zoom + 0.1).clamp(0.75, 1.8)),
                      icon: const Icon(Icons.zoom_in),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            tooltip: isExpanded ? 'Collapse controls' : 'Expand controls',
            onPressed: onToggleExpanded,
            icon: Icon(isExpanded ? Icons.chevron_right : Icons.chevron_left),
          ),
        ],
      ),
    );
  }
}

class _ChordLyrics extends StatelessWidget {
  const _ChordLyrics({
    required this.lyrics,
    required this.style,
    required this.onChordTap,
  });

  final String lyrics;
  final TextStyle? style;
  final ValueChanged<String> onChordTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chordStyle = style?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );
    final spans = <TextSpan>[];
    var cursor = 0;
    final chordPattern = RegExp(
      r'\[([A-Ga-g][#b]?(?:m|maj|min|dim|aug|sus|add)?[0-9]*)\]',
    );

    for (final match in chordPattern.allMatches(lyrics)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: lyrics.substring(cursor, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: chordStyle,
          recognizer: TapGestureRecognizer()
            ..onTap = () => onChordTap(match.group(1)!),
        ),
      );
      cursor = match.end;
    }
    if (cursor < lyrics.length) {
      spans.add(TextSpan(text: lyrics.substring(cursor)));
    }

    return SelectableText.rich(
      TextSpan(style: style?.copyWith(height: 1.6), children: spans),
    );
  }
}

class _ChordReferenceSection extends StatelessWidget {
  const _ChordReferenceSection({
    required this.lyrics,
    required this.onChordTap,
    this.initiallyExpanded = false,
  });

  final String lyrics;
  final ValueChanged<String> onChordTap;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final chords = <String>[];
    final pattern = RegExp(
      r'\[([A-Ga-g][#b]?(?:m|maj|min|dim|aug|sus|add)?[0-9]*)\]',
    );
    for (final match in pattern.allMatches(lyrics)) {
      final chord = match.group(1)!;
      if (!chords.contains(chord)) chords.add(chord);
    }
    if (chords.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      tilePadding: EdgeInsets.zero,
      title: const Text('Chords in this song'),
      subtitle: Text(
        '${chords.length} unique chord${chords.length == 1 ? '' : 's'}',
      ),
      children: [
        SizedBox(
          height: 218,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chords.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final chord = chords[index];
              final shape = chordShapeFor(chord);
              return SizedBox(
                width: 164,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChordTap(chord),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chord,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (shape == null)
                          Text(
                            'No diagram',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          )
                        else
                          SizedBox(
                            height: 176,
                            child: ChordDiagram(shape: shape),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
