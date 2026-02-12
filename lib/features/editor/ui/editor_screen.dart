import 'package:flutter/material.dart';

class EditorScreen extends StatelessWidget {
  final String presentationId;
  const EditorScreen({super.key, required this.presentationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editor')),
      body: Center(child: Text('Editing: $presentationId')),
    );
  }
}
