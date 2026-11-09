import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/chord_transposer.dart';
import '../../core/local_store.dart';
import '../../core/offline_file_service.dart';
import '../../core/offline_models.dart';

class AddSongScreen extends StatelessWidget {
  const AddSongScreen({required this.store, this.onSaved, super.key});

  final LocalStore store;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context) {
    return SongEditorScreen(store: store, onSaved: onSaved);
  }
}

class SongEditorScreen extends StatefulWidget {
  const SongEditorScreen({
    required this.store,
    this.song,
    this.onSaved,
    super.key,
  });

  final LocalStore store;
  final Song? song;
  final VoidCallback? onSaved;

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _keyController;
  late final TextEditingController _youtubeController;
  late final TextEditingController _lyricsController;

  @override
  void initState() {
    super.initState();
    final song = widget.song;
    _titleController = TextEditingController(text: song?.title);
    _artistController = TextEditingController(text: song?.artist);
    _keyController = TextEditingController(text: song?.key);
    _youtubeController = TextEditingController(text: song?.youtubeUrl);
    _lyricsController = TextEditingController(text: song?.lyrics);
  }

  @override
  void dispose() {
    for (final controller in [
      _titleController,
      _artistController,
      _keyController,
      _youtubeController,
      _lyricsController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.song != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit song' : 'Add song')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Song title'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _artistController,
              decoration: const InputDecoration(labelText: 'Artist'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _keyController,
              decoration: const InputDecoration(
                labelText: 'Original key',
                hintText: 'For example, G',
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _youtubeController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'YouTube URL (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lyricsController,
              minLines: 12,
              maxLines: 20,
              decoration: const InputDecoration(
                labelText: 'Lyrics and chords',
                hintText:
                    'G        D        Em\nAmazing grace, how sweet the sound',
                helperText:
                    'Chord lines can use G  D  Em, [G], or <G>. '
                    'They are formatted automatically when saved.',
                alignLabelWithHint: true,
              ),
              validator: _required,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Save changes' : 'Save song'),
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => OfflineFileService.exportSong(widget.song!),
                icon: const Icon(Icons.ios_share),
                label: const Text('Export song file'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.song;
    await widget.store.saveSong(
      Song(
        id: existing?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        key: _keyController.text.trim(),
        lyrics: addChordBrackets(_lyricsController.text),
        youtubeUrl: _youtubeController.text.trim(),
        isFavorite: existing?.isFavorite ?? false,
      ),
    );
    if (!mounted) return;
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.of(context).pop();
    }
  }
}
