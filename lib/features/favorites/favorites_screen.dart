import 'package:flutter/material.dart';

import '../../core/local_store.dart';
import '../search/songs_list_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({required this.store, super.key});

  final LocalStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final songs = store.songs.where((song) => song.isFavorite).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Favorites')),
          body: songs.isEmpty
              ? const Center(child: Text('Favorite songs will appear here.'))
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
                        trailing: const Icon(Icons.chevron_right),
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
      },
    );
  }
}
