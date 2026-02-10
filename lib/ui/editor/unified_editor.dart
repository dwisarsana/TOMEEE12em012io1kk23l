import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tome_ai/utility/models.dart';
import 'package:tome_ai/utility/image_store.dart';
import 'package:tome_ai/utility/storage.dart';

class UnifiedEditor extends StatefulWidget {
  final Presentation? initialPresentation;
  final String? source;
  final String? initialTitle;

  const UnifiedEditor({
    super.key,
    this.initialPresentation,
    this.source,
    this.initialTitle,
  });

  @override
  State<UnifiedEditor> createState() => _UnifiedEditorState();
}

class _UnifiedEditorState extends State<UnifiedEditor> {
  // Logic placeholders - will be populated in next phase
  Presentation? _presentation;
  int _selectedIndex = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // TODO: Init logic
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_presentation?.title ?? "Editor", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.play_arrow_rounded)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.save_outlined)),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 140,
            color: const Color(0xFFF3F4F6),
            child: const Center(child: Text("Slides")),
          ),
          // Canvas
          Expanded(
            child: Container(
              color: Colors.white,
              child: const Center(child: Text("Canvas")),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // AI Overlay
        },
        child: const Icon(Icons.auto_awesome_rounded),
      ),
    );
  }
}
