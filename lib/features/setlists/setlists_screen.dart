import 'package:flutter/material.dart';

class SetlistsScreen extends StatelessWidget {
  const SetlistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlists'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music, size: 72),
            SizedBox(height: 16),
            Text('Create a setlist for your next performance.'),
          ],
        ),
      ),
    );
  }
}
