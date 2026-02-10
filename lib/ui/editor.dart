import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui; // for blur

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../utility/models.dart';   // Presentation, Slide
import '../utility/storage.dart';  // Storage.load/save

class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  Presentation? _presentation;
  int _selectedIndex = 0;
  String _source = 'blank';

  // UI state
  bool _busy = false;

  // Theme color (background behind the white slide card)
  Color _themeColor = const Color(0xFFEEF2FF); // indigo-50
  final List<Color> _palette = const [
    Color(0xFFEEF2FF), // indigo-50
    Color(0xFFF0F9FF), // sky-50
    Color(0xFFFFF7ED), // orange-50
    Color(0xFFFDF2F8), // pink-50
    Color(0xFFF1F5F9), // slate-50
    Color(0xFFFFFBEB), // amber-50
  ];

  // Per-slide images (kept in memory; optional)
  final Map<String, Uint8List> _slideImages = {};

  @override
  void initState() {
    super.initState();
    // after build so ModalRoute is available
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromArgs());
  }

  Future<void> _initFromArgs() async {
    final args = ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;

    _source = (args?['source'] as String?) ?? 'blank';
    final argTitle = (args?['title'] as String?) ?? 'Untitled Presentation';
    final argId = args?['id'] as String?;

    if (argId != null) {
      final loaded = await Storage.loadPresentation(argId);
      if (loaded != null) {
        setState(() => _presentation = loaded);
        return;
      }
    }

    final pres = Presentation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: argTitle,
      slides: _initialSlidesForSource(_source, argTitle),
      updatedAt: DateTime.now(),
    );
    setState(() => _presentation = pres);

    if (_source == 'outline') {
      await Future.delayed(const Duration(milliseconds: 200));
      _showOutlineDialog();
    }
  }

  List<Slide> _initialSlidesForSource(String source, String title) {
    if (source == 'template') {
      return [
        Slide.newSlide(title),
        Slide.newSlide("Overview"),
        Slide.newSlide("Key Points"),
        Slide.newSlide("Data & Charts"),
        Slide.newSlide("Roadmap"),
        Slide.newSlide("Conclusion"),
      ];
    }
    return [Slide.newSlide(title)];
  }

  Future<void> _save() async {
    if (_presentation == null) return;
    await Storage.savePresentation(_presentation!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Saved", style: GoogleFonts.poppins()),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _renamePresentation() async {
    final controller = TextEditingController(text: _presentation?.title ?? "");
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Presentation"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: "Enter title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Save")),
        ],
      ),
    );
    if (newTitle == null || newTitle.isEmpty) return;
    setState(() => _presentation = _presentation!..title = newTitle);
    await _save();
  }

  Future<void> _renameSlide(int i) async {
    final controller = TextEditingController(text: _presentation?.slides[i].title ?? "");
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rename Slide"),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: "Enter slide title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text("Save")),
        ],
      ),
    );
    if (newTitle == null || newTitle.isEmpty) return;
    setState(() => _presentation!.slides[i].title = newTitle);
    await _save();
  }

  Future<void> _showOutlineDialog() async {
    final controller = TextEditingController(text: "Intro\nProblem\nSolution\nBenefits\nConclusion");
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Paste Outline (1 line = 1 slide)"),
        content: SizedBox(
          width: 500,
          child: TextField(
            controller: controller,
            maxLines: 10,
            autofocus: true,
            decoration: const InputDecoration(hintText: "One line per slide"),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Generate")),
        ],
      ),
    );
    if (text == null) return;
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (lines.isEmpty) return;
    setState(() {
      _presentation!.slides = lines.map((e) => Slide.newSlide(e)).toList();
      _selectedIndex = 0;
    });
    await _save();
  }

  void _addSlide() async {
    setState(() => _presentation!.slides.add(Slide.newSlide("Slide ${_presentation!.slideCount + 1}")));
    _selectedIndex = _presentation!.slideCount - 1;
    await _save();
  }

  void _deleteSlide(int i) async {
    if (_presentation!.slides.length <= 1) return;
    setState(() {
      _presentation!.slides.removeAt(i);
      if (_selectedIndex >= _presentation!.slides.length) {
        _selectedIndex = _presentation!.slides.length - 1;
      }
    });
    await _save();
  }

  // ===== Image helpers
  Future<void> _pickImageForSlide(Slide s) async {
    try {
      setState(() => _busy = true);
      final picker = ImagePicker();
      final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => _slideImages[s.id] = bytes);
      await _save();
      _snack('Image added to slide');
    } catch (e) {
      _snack('Failed to pick image: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeImageForSlide(Slide s) async {
    setState(() => _slideImages.remove(s.id));
    await _save();
    _snack('Image removed');
  }

  // ===== Preview (PPT Show) =====
  void _openPreview() {
    final p = _presentation;
    if (p == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PreviewScreen(
        presentation: p,
        images: _slideImages,
        themeColor: _themeColor,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = _presentation;
    if (p == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Stack(
      children: [
        WillPopScope(
          onWillPop: () async {
            await _save();
            return true;
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(p.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              actions: [
                Tooltip(
                  message: "Play",
                  child: IconButton.filled(
                    onPressed: _busy ? null : _openPreview,
                    icon: const Icon(Icons.play_arrow_rounded),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: "Rename",
                  child: IconButton.outlined(
                    onPressed: _busy ? null : _renamePresentation,
                    icon: const Icon(Icons.drive_file_rename_outline_rounded),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: "Save",
                  child: IconButton.outlined(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.save_alt_rounded),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Row(
              children: [
                // Sidebar (no cramped Rows → avoids RenderFlex issues)
                SizedBox(
                  width: 132,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : _addSlide,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text("Add"),
                          ),
                        ),
                      ),
                      // Theme color picker
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Theme", style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: _palette.map((c) {
                            final sel = c.value == _themeColor.value;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: InkWell(
                                onTap: _busy ? null : () => setState(() => _themeColor = c),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: c,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: sel ? Colors.black54 : Colors.black12, width: sel ? 1.5 : 1),
                                  ),
                                  child: sel ? const Icon(Icons.check, size: 14) : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: p.slides.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final s = p.slides[i];
                            final selected = i == _selectedIndex;
                            return InkWell(
                              onTap: _busy ? null : () => setState(() => _selectedIndex = i),
                              onLongPress: _busy ? null : () => _renameSlide(i),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFFEFF1FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: selected ? const Color(0xFF5865F2) : const Color(0xFFE5E7EB)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Center(child: Icon(Icons.slideshow_rounded)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${i + 1}. ${s.title}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    // Compact actions (safe against overflow)
                                    OverflowBar(
                                      alignment: MainAxisAlignment.start,
                                      spacing: 4,
                                      children: [
                                        IconButton(
                                          tooltip: "Rename",
                                          onPressed: _busy ? null : () => _renameSlide(i),
                                          icon: const Icon(Icons.edit, size: 16),
                                          padding: EdgeInsets.zero,
                                        ),
                                        IconButton(
                                          tooltip: "Delete",
                                          onPressed: _busy ? null : () => _deleteSlide(i),
                                          icon: const Icon(Icons.delete_outline, size: 16),
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Canvas
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _toolbar(),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _themeColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: _slideCanvas(p.slides[_selectedIndex]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Smooth glassy loader
        if (_busy) const _GlassLoader(message: "Processing…"),
      ],
    );
  }

  Widget _toolbar() {
    // Responsive, no overflow
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: [
          FilledButton.icon(
            onPressed: _busy ? null : _addSlide,
            icon: const Icon(Icons.add_rounded),
            label: const Text("Add Slide"),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _showOutlineDialog,
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text("Paste Outline"),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            onPressed: _busy ? null : _save,
            icon: const Icon(Icons.save_alt_rounded),
            label: const Text("Save"),
          ),
          // New: Play preview here too (second access)
          FilledButton.icon(
            onPressed: _busy ? null : _openPreview,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text("Play"),
          ),
        ],
      ),
    );
  }

  Widget _slideCanvas(Slide s) {
    final controllerTitle = TextEditingController(text: s.title);
    final controllerBody = TextEditingController(text: s.body ?? "");
    final slideImg = _slideImages[s.id];

    // White inner card for contrast
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title
            TextField(
              controller: controllerTitle,
              decoration: const InputDecoration(
                labelText: "Slide Title",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => s.title = v,
              onEditingComplete: _save,
            ),
            const SizedBox(height: 12),

            // Body
            Expanded(
              child: TextField(
                controller: controllerBody,
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: const InputDecoration(
                  labelText: "Slide Body",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => s.body = v,
                onEditingComplete: _save,
              ),
            ),
            const SizedBox(height: 12),

            // Image block (overflow-safe controls)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Slide Image (optional)", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  if (slideImg != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        slideImg,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    spacing: 8,
                    overflowSpacing: 8,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _busy ? null : () => _pickImageForSlide(s),
                            icon: const Icon(Icons.image_outlined),
                            label: Text(slideImg == null ? "Add Image" : "Replace Image"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      if (slideImg != null)
                        TextButton.icon(
                          onPressed: _busy ? null : () => _removeImageForSlide(s),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Remove"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.poppins())),
    );
  }
}

/// Smooth glassy loader (matches the AI screen’s style)
class _GlassLoader extends StatelessWidget {
  final String message;
  const _GlassLoader({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Stack(
        key: ValueKey(message),
        children: [
          ModalBarrier(color: Colors.black.withOpacity(0.15), dismissible: false),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.04)),
            ),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              tween: Tween(begin: 0.9, end: 1.0),
              builder: (context, scale, child) => Transform.scale(
                scale: scale,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 260),
                  opacity: 1,
                  child: child,
                ),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 14, offset: Offset(0, 6)),
                      BoxShadow(color: Color(0x11000000), blurRadius: 4, offset: Offset(0, 1)),
                    ],
                    border: Border.all(color: const Color(0x11000000)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      SizedBox(width: 6),
                      SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.8)),
                      SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          "Processing…",
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: TextStyle(fontSize: 12.5, height: 1.2, fontWeight: FontWeight.w500, color: Color(0xFF0F172A), letterSpacing: 0.1),
                        ),
                      ),
                      SizedBox(width: 6),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Preview Screen
/// =======================
class _PreviewScreen extends StatefulWidget {
  final Presentation presentation;
  final Map<String, Uint8List> images;
  final Color themeColor;

  const _PreviewScreen({
    required this.presentation,
    required this.images,
    required this.themeColor,
  });

  @override
  State<_PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<_PreviewScreen> {
  late final PageController _page;
  int _index = 0;
  bool _auto = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _page = PageController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _toggleAuto() {
    setState(() => _auto = !_auto);
    _timer?.cancel();
    if (_auto) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) => _next());
    }
  }

  void _next() {
    final last = widget.presentation.slideCount - 1;
    if (_index >= last) {
      _page.animateToPage(0, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  void _prev() {
    if (_index <= 0) {
      final last = widget.presentation.slideCount - 1;
      _page.animateToPage(last, duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      _page.previousPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slides = widget.presentation.slides;

    return Scaffold(
      backgroundColor: widget.themeColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Slides
            PageView.builder(
              controller: _page,
              itemCount: slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final s = slides[i];
                final img = widget.images[s.id];
                return _DeckSlide(
                  title: s.title,
                  body: (s.body ?? ''),
                  imageBytes: img,
                  themeColor: widget.themeColor,
                );
              },
            ),

            // Top controls
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: _prev,
                    tooltip: 'Previous',
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: _next,
                    tooltip: 'Next',
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _toggleAuto,
                    tooltip: _auto ? 'Pause autoplay' : 'Autoplay',
                    icon: Icon(_auto ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Text(
                      '${_index + 1} / ${slides.length}',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 250),
                tween: Tween(begin: 0, end: (_index + 1) / slides.length),
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v,
                  minHeight: 4,
                  backgroundColor: Colors.white.withOpacity(.4),
                  color: const Color(0xFF5865F2),
                ),
              ),
            ),

            // Dots
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (i) {
                  final sel = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: sel ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF111827) : const Color(0x66111827),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),


          ],
        ),
      ),
    );
  }
}

class _DeckSlide extends StatelessWidget {
  final String title;
  final String body;
  final Uint8List? imageBytes;
  final Color themeColor;

  const _DeckSlide({
    required this.title,
    required this.body,
    required this.imageBytes,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final bullets = body
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return LayoutBuilder(
      builder: (_, c) {
        final wide = c.maxWidth >= 900;
        final card = Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 10)),
              BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
            border: Border.all(color: const Color(0x11000000)),
          ),
          child: wide
              ? Row(
            children: [
              // Text
              Expanded(
                flex: 7,
                child: _SlideText(title: title, bullets: bullets),
              ),
              const SizedBox(width: 18),
              // Image
              Expanded(
                flex: 5,
                child: _SlideImage(imageBytes: imageBytes),
              ),
            ],
          )
              : Column(
            children: [
              _SlideImage(imageBytes: imageBytes, height: 240),
              const SizedBox(height: 14),
              _SlideText(title: title, bullets: bullets),
            ],
          ),
        );

        // subtle background gradient from themeColor
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeColor,
                Color.alphaBlend(Colors.white.withOpacity(.8), themeColor),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(child: card),
        );
      },
    );
  }
}

class _SlideText extends StatelessWidget {
  final String title;
  final List<String> bullets;
  const _SlideText({required this.title, required this.bullets});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.isEmpty ? 'Untitled' : title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 28,
            height: 1.1,
            fontWeight: FontWeight.w700,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(height: 12),
        ...bullets.take(12).map((b) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  ', style: TextStyle(fontSize: 16, height: 1.35)),
              Expanded(
                child: Text(
                  b,
                  style: GoogleFonts.poppins(fontSize: 16, height: 1.35, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _SlideImage extends StatelessWidget {
  final Uint8List? imageBytes;
  final double? height;

  const _SlideImage({required this.imageBytes, this.height});

  @override
  Widget build(BuildContext context) {
    if (imageBytes == null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x11000000)),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 56, color: Color(0xFF9CA3AF)),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.memory(
        imageBytes!,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
