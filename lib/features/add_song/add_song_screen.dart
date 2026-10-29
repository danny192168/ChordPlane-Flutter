import 'package:flutter/material.dart';

class AddSongScreen extends StatelessWidget {
  const AddSongScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add song'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: const [
            TextField(
              decoration: InputDecoration(labelText: 'Song title'),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'Artist'),
            ),
            SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(labelText: 'Key'),
            ),
            SizedBox(height: 12),
            TextField(
              maxLines: 8,
              decoration: InputDecoration(
                labelText: 'Lyrics and chords',
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 20),
            FilledButton(
              onPressed: null,
              child: Text('Save song'),
            ),
          ],
        ),
      ),
    );
  }
}
