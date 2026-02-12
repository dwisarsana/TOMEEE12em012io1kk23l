import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/state/providers.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/components/glass_card.dart';
import '../../../core/design/typography.dart';
import '../../../core/engine/ai_engine.dart';
import '../../../core/models/presentation_models.dart';
import '../../../core/monetization/revenue_cat_service.dart';
import '../../../core/storage/local_storage.dart';

// --- Editor Provider (Family Scoped) ---
final editorProvider = AsyncNotifierProviderFamily<EditorNotifier, Presentation, String>(EditorNotifier.new);

class EditorNotifier extends FamilyAsyncNotifier<Presentation, String> {
  Timer? _debounce;

  @override
  Future<Presentation> build(String arg) async {
    final p = await Storage.loadPresentation(arg);
    if (p == null) throw Exception("Presentation not found");
    return p;
  }

  void updateTitle(String title) {
    if (state.value == null) return;
    final p = state.value!;
    p.title = title;
    state = AsyncValue.data(p); // Trigger UI update
    _autosave();
  }

  void updateSlide(int index, String title, String body) {
    if (state.value == null) return;
    final p = state.value!;
    p.slides[index].title = title;
    p.slides[index].body = body;
    state = AsyncValue.data(p);
    _autosave();
  }

  Future<void> _autosave() async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      if (state.value != null) {
        await Storage.savePresentation(state.value!);
        ref.read(libraryProvider.notifier).refresh(); // Sync library
      }
    });
  }
}

// --- Editor UI ---
class EditorScreen extends ConsumerStatefulWidget {
  final String presentationId;
  const EditorScreen({super.key, required this.presentationId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final Map<String, Uint8List> _images = {}; // Local memory cache for session
  final Map<String, bool> _loadingImages = {};

  @override
  void initState() {
    super.initState();
    // In a real app, we'd load persisted images from disk here
  }

  @override
  Widget build(BuildContext context) {
    final presentationState = ref.watch(editorProvider(widget.presentationId));

    return Scaffold(
      backgroundColor: TomeColors.washWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: TomeColors.slateGrey),
          onPressed: () => context.pop(),
        ),
        title: presentationState.when(
          data: (p) => Text(p.title, style: TomeTypography.heading3),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const Text("Error"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: TomeColors.mysticIndigo),
            onPressed: () => _export(presentationState.valueOrNull),
          ),
        ],
      ),
      body: presentationState.when(
        data: (p) => ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: p.slides.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            final slide = p.slides[index];
            return _SlideEditorCard(
              slide: slide,
              index: index,
              imageBytes: _images[slide.id],
              isLoadingImage: _loadingImages[slide.id] ?? false,
              onTitleChanged: (val) => ref.read(editorProvider(widget.presentationId).notifier).updateSlide(index, val, slide.body ?? ''),
              onBodyChanged: (val) => ref.read(editorProvider(widget.presentationId).notifier).updateSlide(index, slide.title, val),
              onGenerateImage: () => _generateImage(slide),
            ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Failed to load: $err")),
      ),
    );
  }

  Future<void> _generateImage(Slide slide) async {
    final userState = ref.read(userProvider);
    final isPremium = userState.valueOrNull?.isPremium ?? false;

    if (!isPremium) {
      await RevenueCatService.presentPaywall();
      await ref.read(userProvider.notifier).refreshPremium();
      if (ref.read(userProvider).value?.isPremium != true) return;
    }

    setState(() => _loadingImages[slide.id] = true);

    try {
      // Prompt construction logic from legacy code
      // We don't have the color palette selection here, so we default to standard theme
      // or we could store theme in Presentation model (not in contract but useful).
      // Defaulting to "soft indigo palette" (0xFFEEF2FF)
      const defaultTheme = 0xFFEEF2FF;

      final prompt = "Clean, professional, high-resolution illustration of ${slide.title}";
      final augmentedPrompt = AIEngine.themeAugmentedPrompt(prompt, defaultTheme);

      final bytes = await AIEngine.generateImageWithRetries(augmentedPrompt);

      setState(() {
        _images[slide.id] = bytes;
        _loadingImages[slide.id] = false;
      });

      // Save image to disk (optional based on contract, but good practice)
      // Contract says: "Downloads image... and caches in memory" -> Autosaves progress.
      // Legacy code had `_saveTempPng`. We will keep memory for session as per legacy `_slideImages`.

    } catch (e) {
      setState(() => _loadingImages[slide.id] = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Image gen failed: $e")));
    }
  }

  Future<void> _export(Presentation? p) async {
    if (p == null) return;
    try {
      // Note: Export is text-only as per Engine Contract limitation
      await AIEngine.exportToPptx(p, _images);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
    }
  }
}

class _SlideEditorCard extends StatefulWidget {
  final Slide slide;
  final int index;
  final Uint8List? imageBytes;
  final bool isLoadingImage;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onBodyChanged;
  final VoidCallback onGenerateImage;

  const _SlideEditorCard({
    required this.slide,
    required this.index,
    required this.imageBytes,
    required this.isLoadingImage,
    required this.onTitleChanged,
    required this.onBodyChanged,
    required this.onGenerateImage,
  });

  @override
  State<_SlideEditorCard> createState() => _SlideEditorCardState();
}

class _SlideEditorCardState extends State<_SlideEditorCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.slide.title);
    _bodyCtrl = TextEditingController(text: widget.slide.body);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TomeColors.slateGrey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text("Slide ${widget.index + 1}", style: TomeTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.auto_awesome, color: TomeColors.mysticIndigo),
                tooltip: "Visualize",
                onPressed: widget.onGenerateImage,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            style: TomeTypography.heading3,
            decoration: const InputDecoration(
              hintText: "Slide Title",
              border: InputBorder.none,
            ),
            onChanged: widget.onTitleChanged,
          ),
          const Divider(height: 24),
          TextField(
            controller: _bodyCtrl,
            style: TomeTypography.bodyLarge,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: "Content...",
              border: InputBorder.none,
            ),
            onChanged: widget.onBodyChanged,
          ),
          const SizedBox(height: 16),
          if (widget.isLoadingImage)
            const Center(child: CircularProgressIndicator(color: TomeColors.mysticIndigo))
          else if (widget.imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(widget.imageBytes!, fit: BoxFit.cover, width: double.infinity, height: 200)
                  .animate().fadeIn(),
            ),
        ],
      ),
    );
  }
}
