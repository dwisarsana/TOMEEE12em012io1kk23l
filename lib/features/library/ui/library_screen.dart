import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: const Center(child: Text('Recent Presentations')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // GoRouter.of(context).push('/wizard');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
