import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/local_store.dart';
import '../../core/offline_file_service.dart';
import '../../core/offline_models.dart';
import '../search/songs_list_screen.dart';

class SetlistsScreen extends StatelessWidget {
  const SetlistsScreen({required this.store, super.key});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Setlists'),
          actions: [
            IconButton(
              tooltip: 'Import setlist',
              onPressed: () => _import(context),
              icon: const Icon(Icons.file_open_outlined),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SetlistEditorScreen(store: store),
            ),
          ),
          child: const Icon(Icons.add),
        ),
        body: store.setlists.isEmpty
            ? const Center(child: Text('Create a setlist for your next show.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: store.setlists.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, index) {
                  final setlist = store.setlists[index];
                  return Card(
                    child: ListTile(
                      title: Text(setlist.title),
                      subtitle: Text(
                        '${setlist.songIds.length} '
                        '${setlist.songIds.length == 1 ? 'song' : 'songs'}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SetlistDetailScreen(
                            store: store,
                            setlist: setlist,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    try {
      final imported = await OfflineFileService.importSetlist();
      if (imported == null) return;
      for (final song in imported.songs) {
        await store.saveSong(song.copyWith(id: ''));
      }
      final ids = imported.songs
          .map(
            (song) => store.songs
                .lastWhere(
                  (saved) =>
                      saved.title == song.title && saved.artist == song.artist,
                )
                .id,
          )
          .toList();
      await store.saveSetlist(imported.setlist.copyWith(id: '', songIds: ids));
    } on FormatException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to import that setlist.')),
        );
      }
    }
  }
}

class SetlistEditorScreen extends StatefulWidget {
  const SetlistEditorScreen({required this.store, this.setlist, super.key});

  final LocalStore store;
  final Setlist? setlist;

  @override
  State<SetlistEditorScreen> createState() => _SetlistEditorScreenState();
}

class _SetlistEditorScreenState extends State<SetlistEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final Set<String> _selectedSongIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.setlist?.title);
    _descriptionController = TextEditingController(
      text: widget.setlist?.description,
    );
    _selectedSongIds = {...?widget.setlist?.songIds};
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.store.songs;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setlist == null ? 'New setlist' : 'Edit setlist'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Setlist title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          Text('Songs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (songs.isEmpty)
            const Text('Create a song first, then add it to this setlist.')
          else
            for (final song in songs)
              CheckboxListTile(
                value: _selectedSongIds.contains(song.id),
                title: Text(song.title),
                subtitle: Text(song.artist),
                onChanged: (selected) => setState(() {
                  if (selected == true) {
                    _selectedSongIds.add(song.id);
                  } else {
                    _selectedSongIds.remove(song.id);
                  }
                }),
              ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    await widget.store.saveSetlist(
      Setlist(
        id: widget.setlist?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        songIds: _selectedSongIds.toList(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }
}

class SetlistDetailScreen extends StatelessWidget {
  const SetlistDetailScreen({
    required this.store,
    required this.setlist,
    super.key,
  });

  final LocalStore store;
  final Setlist setlist;

  @override
  Widget build(BuildContext context) {
    final songs = store.songsForSetlist(setlist);
    return Scaffold(
      appBar: AppBar(
        title: Text(setlist.title),
        actions: [
          IconButton(
            tooltip: 'Edit setlist',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    SetlistEditorScreen(store: store, setlist: setlist),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'export') {
                OfflineFileService.exportSetlist(setlist, store);
              }
              if (value == 'print') {
                OfflineFileService.printSetlist(setlist, store);
              }
              if (value == 'delete') {
                _delete(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export setlist')),
              PopupMenuItem(value: 'print', child: Text('Print setlist')),
              PopupMenuItem(value: 'delete', child: Text('Delete setlist')),
            ],
          ),
        ],
      ),
      body: songs.isEmpty
          ? const Center(child: Text('This setlist has no songs yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) {
                final song = songs[index];
                return Card(
                  child: ListTile(
                    title: Text(song.title),
                    subtitle: Text('${song.artist} • ${song.key}'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SongDetailScreen(store: store, song: song),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _delete(BuildContext context) async {
    await store.deleteSetlist(setlist.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
