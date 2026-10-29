import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite,
              size: 72,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16),
            Text('Your favorite songs will appear here.'),
          ],
        ),
      ),
    );
  }
}
