import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const _scrollSpeeds = [4.0, 7.0, 10.0, 13.0, 16.0, 18.0, 20.0];
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
    final shouldShow = _songScrollController.offset > 64;
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
                  _AdjustmentControl(
                    label: 'Transpose',
                    value: '${_transpose >= 0 ? '+' : ''}$_transpose',
                    onDecrement: () => setState(
                      () => _transpose = _transpose == _minTranspose
                          ? 0
                          : _transpose - 1,
                    ),
                    onIncrement: () => setState(
                      () => _transpose = _transpose == _maxTranspose
                          ? 0
                          : _transpose + 1,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: _isAutoScrolling
                        ? 'Pause autoscroll'
                        : 'Start autoscroll',
                    onPressed: _toggleAutoScroll,
                    icon: Icon(
                      _isAutoScrolling ? Icons.pause : Icons.play_arrow,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Show chord diagrams',
                    onPressed: () => _showAllChords(
                      transposeLyrics(song.lyrics, _transpose),
                    ),
                    icon: const Icon(Icons.grid_view_rounded),
                  ),
                ],
              ),
              if (song.youtubeUrl.isNotEmpty)
                _YouTubeSongCard(url: song.youtubeUrl),
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
            ],
          ),
          Positioned(
            right: 16,
            bottom: 152,
            child: IgnorePointer(
              ignoring: !_showQuickControls,
              child: AnimatedOpacity(
                opacity: _showQuickControls ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: _SongQuickControls(
                  isExpanded: _controlsExpanded,
                  isScrolling: _isAutoScrolling,
                  transpose: _transpose,
                  zoom: _zoom,
                  onToggleExpanded: () =>
                      setState(() => _controlsExpanded = !_controlsExpanded),
                  onTransposeChanged: (value) =>
                      setState(() => _transpose = value),
                  onZoomChanged: (value) => setState(() => _zoom = value),
                  onToggleAutoScroll: _toggleAutoScroll,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 48,
            child: IgnorePointer(
              ignoring: !_showQuickControls || !_controlsExpanded,
              child: AnimatedOpacity(
                opacity: _showQuickControls && _controlsExpanded ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                child: SizedBox(
                  width: double.infinity,
                  child: _AutoscrollSpeedScrubber(
                    index: _scrollSpeedIndex,
                    onChanged: (index) =>
                        setState(() => _scrollSpeedIndex = index),
                    speedCount: _scrollSpeeds.length,
                  ),
                ),
              ),
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
    required this.onToggleExpanded,
    required this.onTransposeChanged,
    required this.onZoomChanged,
    required this.onToggleAutoScroll,
  });

  final bool isExpanded;
  final bool isScrolling;
  final int transpose;
  final double zoom;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onTransposeChanged;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onToggleAutoScroll;

  @override
  Widget build(BuildContext context) {
    final expandedWidth = (MediaQuery.sizeOf(context).width - 24).clamp(
      56.0,
      600.0,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: isExpanded ? expandedWidth : 56,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black26)],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (isExpanded)
                Positioned(
                  left: 4,
                  right: 104,
                  top: 4,
                  bottom: 4,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _AdjustmentControl(
                          label: 'Transpose',
                          value: '${transpose >= 0 ? '+' : ''}$transpose',
                          onDecrement: () => onTransposeChanged(
                            transpose <= -11 ? 0 : transpose - 1,
                          ),
                          onIncrement: () => onTransposeChanged(
                            transpose >= 11 ? 0 : transpose + 1,
                          ),
                        ),
                        _AdjustmentControl(
                          label: 'Zoom',
                          value: '${(zoom * 100).round()}%',
                          onDecrement: () =>
                              onZoomChanged((zoom - 0.1).clamp(0.75, 1.8)),
                          onIncrement: () =>
                              onZoomChanged((zoom + 0.1).clamp(0.75, 1.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isExpanded)
                Positioned(
                  right: 48,
                  top: 4,
                  child: IconButton(
                    tooltip: isScrolling
                        ? 'Pause autoscroll'
                        : 'Start autoscroll',
                    onPressed: onToggleAutoScroll,
                    icon: Icon(isScrolling ? Icons.pause : Icons.play_arrow),
                  ),
                ),
              if (isExpanded)
                Positioned(
                  right: 0,
                  top: 4,
                  child: _ControlToggleButton(
                    isExpanded: true,
                    onPressed: onToggleExpanded,
                  ),
                )
              else
                Center(
                  child: _ControlToggleButton(
                    isExpanded: false,
                    onPressed: onToggleExpanded,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdjustmentControl extends StatelessWidget {
  const _AdjustmentControl({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF141A28),
          border: Border.all(
            color: const Color(0xFF88A9CE).withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF95A0B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _SoftIconButton(
              tooltip: '$label down',
              icon: Icons.remove,
              onPressed: onDecrement,
            ),
            SizedBox(
              width: 52,
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF88A9CE),
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _SoftIconButton(
              tooltip: '$label up',
              icon: Icons.add,
              onPressed: onIncrement,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftIconButton extends StatefulWidget {
  const _SoftIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_SoftIconButton> createState() => _SoftIconButtonState();
}

class _SoftIconButtonState extends State<_SoftIconButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final background = _hovered
        ? const Color(0xFF88A9CE).withValues(alpha: 0.10)
        : const Color(0xFF0E1320);
    final border = _hovered
        ? const Color(0xFF567393)
        : const Color(0xFF88A9CE).withValues(alpha: 0.12);
    final foreground = _hovered
        ? const Color(0xFF88A9CE)
        : const Color(0xFF95A0B8);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              tooltip: widget.tooltip,
              onPressed: widget.onPressed,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 26, height: 26),
              color: foreground,
              splashColor: const Color(0xFF88A9CE).withValues(alpha: 0.16),
              icon: Text(
                widget.icon == Icons.add ? '+' : '-',
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutoscrollSpeedScrubber extends StatelessWidget {
  const _AutoscrollSpeedScrubber({
    required this.index,
    required this.onChanged,
    required this.speedCount,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int speedCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final speedLabel = (0.5 + (index / (speedCount - 1)) * 1.5).toStringAsFixed(
      1,
    );
    return AnimatedSlide(
      offset: const Offset(0, 0.2),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _ScrubberLabel(
                      text: 'AUTOSCROLL SPEED',
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  _ScrubberLabel(
                    text: '${speedLabel}x',
                    color: colors.primary,
                    monospace: true,
                  ),
                ],
              ),
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 26,
              activeTrackColor: colors.primary.withValues(alpha: 0.18),
              inactiveTrackColor: colors.surfaceContainerHighest,
              overlayColor: colors.primary.withValues(alpha: 0.12),
              thumbColor: colors.primary,
              showValueIndicator: ShowValueIndicator.never,
              trackShape: _SpeedTrackShape(),
              tickMarkShape: _SpeedTickMarkShape(
                color: colors.onSurfaceVariant.withValues(alpha: 0.45),
              ),
              thumbShape: const _SpeedThumbShape(),
            ),
            child: Slider(
              value: index.toDouble(),
              min: 0,
              max: (speedCount - 1).toDouble(),
              divisions: speedCount - 1,
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ScrubberLabel(
                  text: 'Slow',
                  color: colors.onSurfaceVariant.withValues(alpha: 0.72),
                ),
                _ScrubberLabel(
                  text: 'Normal',
                  color: colors.onSurfaceVariant.withValues(alpha: 0.72),
                ),
                _ScrubberLabel(
                  text: 'Fast',
                  color: colors.onSurfaceVariant.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrubberLabel extends StatelessWidget {
  const _ScrubberLabel({
    required this.text,
    required this.color,
    this.monospace = false,
  });

  final String text;
  final Color color;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontSize: 10,
            fontFamily: monospace ? 'monospace' : null,
            fontWeight: monospace ? FontWeight.bold : null,
          ),
        ),
      ),
    );
  }
}

class _SpeedTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final canvas = context.canvas;
    final radius = const Radius.circular(8);
    final background = Paint()..color = sliderTheme.inactiveTrackColor!;
    canvas.drawRRect(RRect.fromRectAndRadius(trackRect, radius), background);
    final activeRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    final fill = Paint()
      ..shader = LinearGradient(
        colors: [
          sliderTheme.activeTrackColor!,
          sliderTheme.activeTrackColor!.withValues(alpha: 0.45),
        ],
      ).createShader(trackRect);
    canvas.drawRRect(RRect.fromRectAndRadius(activeRect, radius), fill);
    final border = Paint()
      ..color = sliderTheme.activeTrackColor!.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(RRect.fromRectAndRadius(trackRect, radius), border);
  }
}

class _SpeedTickMarkShape extends SliderTickMarkShape {
  const _SpeedTickMarkShape({required this.color});

  final Color color;

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
  }) => const Size(1, 10);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    bool? isEnabled,
    required TextDirection textDirection,
  }) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    context.canvas.drawLine(
      Offset(center.dx, center.dy - 5),
      Offset(center.dx, center.dy + 5),
      paint,
    );
  }
}

class _SpeedThumbShape extends RoundSliderThumbShape {
  const _SpeedThumbShape();

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double textScaleFactor,
    required Size sizeWithOverflow,
    required double value,
  }) {
    final canvas = context.canvas;
    final interaction = activationAnimation.value;
    final ringPaint = Paint()
      ..color = sliderTheme.thumbColor!.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 12 + interaction * 2, ringPaint);
    final thumbPaint = Paint()..color = sliderTheme.thumbColor!;
    canvas.drawCircle(center, 9 + interaction * 1.5, thumbPaint);
  }
}

class _ControlToggleButton extends StatelessWidget {
  const _ControlToggleButton({
    required this.isExpanded,
    required this.onPressed,
  });

  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: IconButton(
        tooltip: isExpanded ? 'Collapse controls' : 'Expand controls',
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              RotationTransition(turns: animation, child: child),
          child: Icon(
            isExpanded ? Icons.close : Icons.chevron_left,
            key: ValueKey(isExpanded),
          ),
        ),
      ),
    );
  }
}

class _YouTubeSongCard extends StatelessWidget {
  const _YouTubeSongCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final videoId = _youtubeVideoId(url);
    final thumbnailUrl = videoId == null
        ? null
        : 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
    return Card(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        leading: SizedBox(
          width: 72,
          height: 48,
          child: thumbnailUrl == null
              ? const _MediaSkeleton()
              : Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const _MediaSkeleton(),
                ),
        ),
        title: const Text('YouTube video'),
        subtitle: Text(url, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: IconButton(
          tooltip: 'Open YouTube video',
          onPressed: () async {
            final uri = Uri.tryParse(url);
            if (uri == null || !await launchUrl(uri)) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to open this video.')),
                );
              }
            }
          },
          icon: const Icon(Icons.open_in_new),
        ),
      ),
    );
  }
}

class _MediaSkeleton extends StatelessWidget {
  const _MediaSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(child: Icon(Icons.ondemand_video_outlined)),
    );
  }
}

String? _youtubeVideoId(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
  }
  if (uri.host.contains('youtube.com')) return uri.queryParameters['v'];
  return null;
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
      shape: const Border(),
      collapsedShape: const Border(),
      title: const Text('Chords in this song'),
      subtitle: Text(
        '${chords.length} unique chord${chords.length == 1 ? '' : 's'}',
      ),
      children: [
        SizedBox(
          height: 232,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: chords.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final chord = chords[index];
              final shapes = chordShapesFor(chord);
              final shape = shapes.isEmpty ? null : shapes.first;
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                chord,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                child: Text(
                                  '${shapes.length}x',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (shape == null)
                          Text(
                            'No diagram',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelSmall,
                          )
                        else ...[
                          SizedBox(
                            height: 162,
                            child: ChordDiagram(shape: shape),
                          ),
                        ],
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
