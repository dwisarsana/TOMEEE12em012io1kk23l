// lib/ui/ai_generate.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dart_pptx/dart_pptx.dart' as pptx;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../src/constant.dart';
import '../utility/apikey.dart'; // AIConfig (hardcoded key + model + headers)
import '../utility/models.dart' as app;
import '../utility/storage.dart';

/// =======================================================
/// Flags & logging
/// =======================================================
const bool kNetworkLog = true;

/// =======================================================
/// Utilities
/// =======================================================
String _pretty(Object? data) {
  try {
    if (data is String) {
      final obj = jsonDecode(data);
      return const JsonEncoder.withIndent('  ').convert(obj);
    }
    return const JsonEncoder.withIndent('  ').convert(data);
  } catch (_) {
    return data.toString();
  }
}

void _logRequest({
  required String method,
  required Uri url,
  required Map<String, String> headers,
  required Object? body,
}) {
  if (!kNetworkLog) return;
  final redacted = Map<String, String>.from(headers);
  if (redacted.containsKey('Authorization')) {
    redacted['Authorization'] = 'Bearer ***';
  }
  debugPrint('==== HTTP $method ${url.toString()}');
  debugPrint('Headers: ${_pretty(redacted)}');
  if (body != null) debugPrint('Body   : ${_pretty(body)}');
}

void _logResponse(http.Response resp) {
  if (!kNetworkLog) return;
  debugPrint('---- Response ${resp.statusCode}');
  debugPrint(_pretty(resp.body));
  debugPrint('===============================================');
}

String _extractOpenAIErrorBody(String body) {
  try {
    final m = jsonDecode(body);
    final err = (m['error'] ?? m['message']) ?? m;
    if (err is Map && err['message'] != null) {
      final msg = err['message'];
      final type = err['type'];
      final code = err['code'];
      return '$msg${type != null ? ' (type: $type)' : ''}${code != null ? ' [code: $code]' : ''}';
    }
    return err.toString();
  } catch (_) {
    return body;
  }
}

String _slug(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

/// =======================================================

class AIGeneratePage extends StatefulWidget {
  const AIGeneratePage({super.key});

  @override
  State<AIGeneratePage> createState() => _AIGeneratePageState();
}

class _AIGeneratePageState extends State<AIGeneratePage> {
  app.Presentation? _presentation;
  int _selectedIndex = 0;
  String _source = 'blank';

  // Images (cover + per-slide)
  Uint8List? _coverImage;
  final Map<String, Uint8List> _slideImages = {};

  // UI State
  bool _exporting = false;
  bool _busy = false;

  // Debounced autosave
  Timer? _saveDebounce;

  void _autosaveSoon() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 600), _save);
  }

  // Controllers cache (avoid rebuilding every frame)
  final Map<String, TextEditingController> _titleCtrls = {};
  final Map<String, TextEditingController> _bodyCtrls = {};

  TextEditingController _titleCtrlFor(app.Slide s) =>
      _titleCtrls.putIfAbsent(s.id, () => TextEditingController(text: s.title));

  TextEditingController _bodyCtrlFor(app.Slide s) =>
      _bodyCtrls.putIfAbsent(
          s.id, () => TextEditingController(text: s.body ?? ''));

  // Theme color for editor & presenter
  Color _themeColor = const Color(0xFFEEF2FF); // indigo-50
  final List<Color> _palette = const [
    Color(0xFFEEF2FF), // indigo-50
    Color(0xFFF0F9FF), // sky-50
    Color(0xFFFFF7ED), // orange-50
    Color(0xFFFDF2F8), // pink-50
    Color(0xFFF1F5F9), // slate-50
    Color(0xFFFFFBEB), // amber-50
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromArgs());
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    for (final c in _titleCtrls.values)
      c.dispose();
    for (final c in _bodyCtrls.values)
      c.dispose();
    super.dispose();
  }

  Future<void> _initFromArgs() async {
    final args = ModalRoute
        .of(context)
        ?.settings
        .arguments as Map<dynamic, dynamic>?;

    _source = (args?['source'] as String?) ?? 'blank';
    final argTitle = (args?['title'] as String?) ?? 'Untitled Presentation';
    final argId = args?['id'] as String?;

    if (argId != null) {
      final loaded = await Storage.loadPresentation(argId);
      if (loaded != null) {
        setState(() => _presentation = loaded);
        // Warm image cache if model stores paths (optional upgrade in your model)
        for (final sl in loaded.slides) {
          final path = (sl as dynamic).imagePath as String?;
          if (path != null && path.isNotEmpty) {
            final f = File(path);
            if (await f.exists()) {
              _slideImages[sl.id] = await f.readAsBytes();
            }
          }
        }
        return;
      }
    }

    final pres = app.Presentation(
      id: DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
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

  List<app.Slide> _initialSlidesForSource(String source, String title) {
    if (source == 'template') {
      return [
        app.Slide.newSlide(title),
        app.Slide.newSlide("Overview"),
        app.Slide.newSlide("Key Points"),
        app.Slide.newSlide("Data & Charts"),
        app.Slide.newSlide("Roadmap"),
        app.Slide.newSlide("Conclusion"),
      ];
    }
    return [app.Slide.newSlide(title)];
  }

  Future<void> _save() async {
    if (_presentation == null) return;
    await Storage.savePresentation(_presentation!);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Saved", style: GoogleFonts.poppins()),
        duration: const Duration(milliseconds: 700),
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
      builder: (_) =>
          AlertDialog(
            title: const Text("Rename Presentation"),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: "Enter title"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              FilledButton(onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
                  child: const Text("Save")),
            ],
          ),
    );
    if (newTitle == null || newTitle.isEmpty) return;
    setState(() =>
    _presentation = _presentation!
      ..title = newTitle);
    await _save();
  }

  Future<void> _renameSlide(int i) async {
    final controller = TextEditingController(
        text: _presentation?.slides[i].title ?? "");
    final newTitle = await showDialog<String>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Rename Slide"),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: "Enter slide title"),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              FilledButton(onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
                  child: const Text("Save")),
            ],
          ),
    );
    if (newTitle == null || newTitle.isEmpty) return;
    setState(() => _presentation!.slides[i].title = newTitle);
    _autosaveSoon();
  }

  Future<void> _showOutlineDialog() async {
    final controller = TextEditingController(
        text: "Intro\nProblem\nSolution\nBenefits\nConclusion");
    final text = await showDialog<String>(
      context: context,
      builder: (_) =>
          AlertDialog(
            title: const Text("Paste Outline (1 line = 1 slide)"),
            content: SizedBox(
              width: 500,
              child: TextField(
                controller: controller,
                maxLines: 10,
                autofocus: true,
                decoration: const InputDecoration(
                    hintText: "One line per slide"),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel")),
              FilledButton(
                  onPressed: () => Navigator.pop(context, controller.text),
                  child: const Text("Generate")),
            ],
          ),
    );
    if (text == null) return;
    final lines = text.split('\n').map((e) => e.trim()).where((e) =>
    e.isNotEmpty).toList();
    if (lines.isEmpty) return;
    setState(() {
      _presentation!.slides = lines.map((e) => app.Slide.newSlide(e)).toList();
      _selectedIndex = 0;
    });
    _autosaveSoon();
  }

  void _addSlide() {
    setState(() =>
        _presentation!.slides.add(
        app.Slide.newSlide("Slide ${_presentation!.slideCount + 1}")));
    _selectedIndex = _presentation!.slideCount - 1;
    _autosaveSoon();
  }

  void _deleteSlide(int i) {
    if (_presentation!.slides.length <= 1) return;
    setState(() {
      _presentation!.slides.removeAt(i);
      if (_selectedIndex >= _presentation!.slides.length) {
        _selectedIndex = _presentation!.slides.length - 1;
      }
    });
    _autosaveSoon();
  }

  // ===================== AI GENERATOR (outline + images) =====================
  Future<void> _aiGenerateOutline() async {
    if (AIConfig.openAIKey.isEmpty) {
      _snack("OpenAI API key is empty in AIConfig.");
      return;
    }

    // ====== WAJIB PREMIUM ======
    final isPremium = await _readPremiumStatus();
    if (!isPremium) {
      _showUpgradeSnack();
      return; // stop di sini kalau non-premium
    }

    final topicCtrl = TextEditingController(
        text: _presentation?.title ?? "Presentation Topic");
    final styleCtrl = TextEditingController(text: "professional");
    double count = 8;


    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setD) =>
              AlertDialog(
                title: const Text("AI Outline"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: topicCtrl,
                        decoration: const InputDecoration(labelText: "Topic")),
                    const SizedBox(height: 8),
                    TextField(controller: styleCtrl,
                        decoration: const InputDecoration(labelText: "Style")),
                    const SizedBox(height: 8),
                    Text("Slides: ${count.toInt()}"),
                    Slider(
                      value: count,
                      min: 1,
                      max: 15,
                      divisions: 16,
                      onChanged: (v) => setD(() => count = v),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false),
                      child: const Text("Cancel")),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("Generate")),
                ],
              ),
        );
      },
    );

    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final outline = await _generateOutline(
        topic: topicCtrl.text.trim(),
        slides: count.toInt(),
        style: styleCtrl.text.trim(),
      );

      final slides = (outline['slides'] as List?);
      if (slides == null || slides.isEmpty) {
        throw "AI returned no slides.";
      }

      // Set title & slides
      setState(() {
        final aiTitle = (outline['title'] as String?)?.trim();
        if (aiTitle != null && aiTitle.isNotEmpty)
          _presentation!.title = aiTitle;

        _presentation!.slides = slides.map<app.Slide>((s) {
          final title = (s['title'] ?? '').toString();
          final bullets = ((s['bullets'] as List?) ?? const []).map((e) =>
              e.toString()).toList();
          return app.Slide(
            id: DateTime
                .now()
                .microsecondsSinceEpoch
                .toString(),
            title: title,
            body: bullets.join('\n'),
          );
        }).toList();
        _selectedIndex = 0;
      });

      // Generate images (best-effort, with retries)
      try {
        final coverPrompt = (outline['cover_image_prompt'] as String?)?.trim();
        if (coverPrompt != null && coverPrompt.isNotEmpty) {
          _coverImage =
          await _generateImageWithRetries(_themeAugmentedPrompt(coverPrompt));
        }
        final outlineSlides = (outline['slides'] as List);
        for (var i = 0; i < _presentation!.slides.length &&
            i < outlineSlides.length; i++) {
          final sPrompt = (outlineSlides[i]['image_prompt'] as String?)?.trim();
          if (sPrompt == null || sPrompt.isEmpty) continue;
          final bytes = await _generateImageWithRetries(
              _themeAugmentedPrompt(sPrompt));
          _slideImages[_presentation!.slides[i].id] = bytes;
        }
      } catch (e) {
        if (kNetworkLog) debugPrint('Image generation warn → $e');
      }

      await _save();
      _snack("Outline generated & saved");
    } catch (e) {
      _snack("AI failed: $e");
      if (kNetworkLog) debugPrint('AI Outline Error → $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }


  Future<bool> _readPremiumStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.all[entitlementKey]?.isActive ?? false;

      // cache ke SharedPreferences biar bisa fallback offline
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', active);
      return active;
    } catch (_) {
      // fallback ke cache
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_premium') ?? false;
    }
  }

  void _showUpgradeSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Upgrade to Premium to generate with AI",
          style: GoogleFonts.poppins(),
        ),
        action: SnackBarAction(
          label: 'Upgrade',
          onPressed: () {
            // arahkan ke Settings/Paywall
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ),
    );
  }

  String _themeDescriptor(Color c) {
    if (c.value == const Color(0xFFEEF2FF).value) return "soft indigo palette";
    if (c.value == const Color(0xFFF0F9FF).value)
      return "clean sky-blue palette";
    if (c.value == const Color(0xFFFFF7ED).value)
      return "warm cream-orange palette";
    if (c.value == const Color(0xFFFDF2F8).value) return "light pink palette";
    if (c.value == const Color(0xFFF1F5F9).value)
      return "neutral slate palette";
    if (c.value == const Color(0xFFFFFBEB).value) return "pale amber palette";
    return "minimal, brand-safe colors";
  }

  String _themeAugmentedPrompt(String prompt) =>
      "$prompt, ${_themeDescriptor(
          _themeColor)}, professional, minimal, clean branding, high resolution";

  Future<Map<String, dynamic>> _generateOutline({
    required String topic,
    required int slides,
    required String style,
  }) async {
    final urlUri = Uri.parse('https://api.openai.com/v1/responses');

    final input = [
      'Create a professional presentation outline about: "$topic".',
      'Number of slides: $slides. Style: $style.',
      'Include a cover (title + subtitle).',
      'For each slide, include bullets and a concise image_prompt describing a suitable visual (photo or clean illustration).',
      'Maximum 6 bullets per slide. Use English.',
      'Return strictly as JSON following the schema.'
    ].join('\n');

    final bodyMap = {
      "model": AIConfig.openAIModel, // <<< kembali ke config
      "input": input,
      "store": false,
      "text": {
        // "verbosity": "medium", // <<< opsional: boleh dihapus (recommended)
        "format": {
          "type": "json_schema",
          "name": "PresentationOutline",
          "strict": true,
          "schema": {
            "type": "object",
            "additionalProperties": false,
            "properties": {
              "title": {"type": "string"},
              "subtitle": {"type": "string"},
              "cover_image_prompt": {"type": "string"},
              "slides": {
                "type": "array",
                "minItems": 1,
                "maxItems": slides,
                "items": {
                  "type": "object",
                  "additionalProperties": false,
                  "properties": {
                    "title": {"type": "string"},
                    "subtitle": {"type": "string"},
                    "bullets": {
                      "type": "array",
                      "minItems": 1,
                      "maxItems": 6,
                      "items": {"type": "string"}
                    },
                    "image_prompt": {"type": "string"}
                  },
                  "required": ["title", "subtitle", "bullets", "image_prompt"]
                }
              }
            },
            "required": ["title", "subtitle", "slides", "cover_image_prompt"]
          }
        }
      }
    };

    _logRequest(method: 'POST',
        url: urlUri,
        headers: AIConfig.headers(),
        body: bodyMap);
    final resp = await http.post(
        urlUri, headers: AIConfig.headers(), body: jsonEncode(bodyMap))
        .timeout(const Duration(seconds: 45));
    _logResponse(resp);
    if (resp.statusCode != 200) {
      final msg = _extractOpenAIErrorBody(resp.body);
      throw "HTTP ${resp.statusCode}: $msg";
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;

    String? text;
    if (data['output_text'] is String) {
      text = data['output_text'] as String;
    } else if (data['output'] is List) {
      final out = data['output'] as List;
      final buff = StringBuffer();
      for (final item in out) {
        if (item is Map && item['content'] is List) {
          for (final c in (item['content'] as List)) {
            if (c is Map && c['text'] is String) buff.write(c['text']);
          }
        }
      }
      text = buff.isEmpty ? null : buff.toString();
    } else if (data['choices'] is List) {
      final ch0 = (data['choices'] as List).first;
      text = (ch0['message']?['content'] ?? '').toString();
    }

    if (text == null || text.isEmpty) {
      throw "Could not read output_text from Responses API";
    }
    final outline = jsonDecode(text) as Map<String, dynamic>;
    if (outline['slides'] is! List) {
      throw "Outline structure is invalid";
    }
    return outline;
  }

  /// Image generation with retry & backoff
  Future<Uint8List> _generateImageWithRetries(String prompt) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _downloadImageFromPrompt(prompt);
      } catch (e) {
        // 3x percobaan dengan backoff eksponensial
        if (attempt >= 3) rethrow;
        final ms = 700 * attempt + Random().nextInt(400);
        if (kNetworkLog) debugPrint(
            'Image gen retry #$attempt in ${ms}ms → $e');
        await Future.delayed(Duration(milliseconds: ms));
      }
    }
  }

  Future<Uint8List> _downloadImageFromPrompt(String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/images/generations');
    final body = {
      "model": "gpt-image-1",
      "prompt": prompt,
      "size": "1024x1024",
      "n": 1,
      // NOTE: jangan kirim "response_format"
      // "style": "vivid",     // opsional
      // "quality": "high",    // opsional (jika akun mendukung)
    };

    final headers = {
      ...AIConfig.headers(),
      "Accept": "application/json",
      "Content-Type": "application/json",
    };

    _logRequest(method: 'POST', url: url, headers: headers, body: body);

    late http.Response resp;
    try {
      resp = await http
          .post(url, headers: headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw 'Image request timed out';
    } catch (e) {
      throw 'Network error: $e';
    }

    _logResponse(resp);

    if (resp.statusCode != 200) {
      final msg = _extractOpenAIErrorBody(resp.body);
      throw 'HTTP ${resp.statusCode}: $msg';
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final items = data['data'] as List?;
    if (items == null || items.isEmpty) {
      throw 'No image items returned';
    }

    // 1) Prefer b64_json jika tersedia
    final b64 = items.first['b64_json'];
    if (b64 is String && b64.isNotEmpty) {
      return base64Decode(b64);
    }

    // 2) Fallback ke URL
    final urlStr = items.first['url'];
    if (urlStr is String && urlStr.isNotEmpty) {
      final imgResp = await http.get(Uri.parse(urlStr)).timeout(const Duration(seconds: 60));
      if (imgResp.statusCode != 200) {
        throw 'Image URL fetch failed: HTTP ${imgResp.statusCode}';
      }
      return imgResp.bodyBytes;
    }

    throw 'No image data field (b64_json/url) in response';
  }


  Future<String> _saveTempPng(Uint8List bytes, String name) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${name}_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// ====== Image helpers per slide ======
  Future<String?> _askPrompt({
    String title = 'Image Prompt',
    String hint = 'Describe the image…',
    String initial = '',
  }) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _aiImageForSlide(app.Slide s) async {
    try {
      if (AIConfig.openAIKey.isEmpty) {
        _snack("OpenAI API key is empty in AIConfig.");
        return;
      }

      // ====== WAJIB PREMIUM ======
      final isPremium = await _readPremiumStatus();
      if (!isPremium) {
        _showUpgradeSnack(); // munculkan snackbar + tombol Upgrade
        return;              // stop kalau non-premium
      }

      final prompt = await _askPrompt(
        title: 'AI Image Prompt',
        hint: 'e.g. Clean photo/illustration related to "${s.title}"',
        initial: 'Clean, professional, high-resolution illustration of ${s.title}',
      );
      if (prompt == null || prompt.isEmpty) return;

      setState(() => _busy = true);

      final themedPrompt = _themeAugmentedPrompt(prompt);
      final bytes = await _generateImageWithRetries(themedPrompt);

      setState(() => _slideImages[s.id] = bytes);

      // simpan (pakai autosave milikmu; kalau tidak ada, ganti ke await _save();)
      _autosaveSoon();

      _snack('AI image added to slide');
    } catch (e) {
      _snack('Failed to generate image: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }



  Future<void> _pickImageForSlide(app.Slide s) async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        imageQuality: 88,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() => _slideImages[s.id] = bytes);
      _autosaveSoon();
      _snack('Image added to slide');
    } catch (e) {
      _snack('Failed to pick image: $e');
    }
  }

  Future<void> _removeImageForSlide(app.Slide s) async {
    setState(() => _slideImages.remove(s.id));
    _autosaveSoon();
    _snack('Image removed');
  }

  /// ====== Export via dart_pptx (text-only; image/background not supported by helpers) ======
  Future<void> _exportToPptx() async {
    if (_presentation == null || _exporting) return;
    setState(() => _exporting = true);

    try {
      final p = _presentation!;
      final pres = pptx.PowerPoint();

      // Metadata
      pres.title = p.title;
      pres.author = 'Presentation AI';
      pres.company = 'Your Company';
      pres.showSlideNumbers = true;
      // If your dart_pptx version supports layout, uncomment:
      // pres.layout = pptx.Layout.screen16x9();

      // Local helpers to match dart_pptx signatures
      pptx.TextValue _tv(String s) =>
          pptx.TextValue.singleLine(<pptx.TextItem>[pptx.TextItem(s)]);
      List<pptx.TextValue> _tvList(List<String> lines) =>
          lines.map((e) => pptx.TextValue.singleLine(<pptx.TextItem>[pptx.TextItem(e)])).toList();

      // Cover (text only)
      const coverSubtitle = 'Generated with AI';
      pres.addTitleSlide(
        title: _tv(p.title),
        author: _tv(coverSubtitle),
      );

      // Content (title + bullets)
      for (final s in p.slides) {
        final bullets = (s.body ?? '')
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        pres.addTitleAndBulletsSlide(
          title: _tv(s.title),
          bullets: _tvList(bullets),
        );
        // NOTE: dart_pptx (0.1.3) does not expose image/background on these helpers.
        // When you move to a lib that supports images/backgrounds per slide,
        // add the image here using the saved _slideImages or disk paths.
      }

      final bytesOut = await pres.save();
      if (bytesOut == null || bytesOut.isEmpty) {
        throw 'Failed to build PPTX (no bytes returned by dart_pptx).';
      }

      final outDir = await getApplicationDocumentsDirectory();
      final outFile = File('${outDir.path}/${_slug(p.title)}.pptx');
      await outFile.writeAsBytes(bytesOut, flush: true);

      _snack("Saved: ${outFile.path.split('/').last}");
      await OpenFilex.open(outFile.path);
    } catch (e) {
      _snack('Export failed: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  // =================== UI ===================

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
                  message: "Present",
                  child: IconButton.filledTonal(
                    onPressed: _busy ? null : () => _openPresenter(p),
                    icon: const Icon(Icons.play_circle_fill_rounded),
                  ),
                ),
                const SizedBox(width: 6),
                Tooltip(
                  message: "AI Outline",
                  child: IconButton.filledTonal(
                    onPressed: _busy ? null : _aiGenerateOutline,
                    icon: const Icon(Icons.auto_awesome_rounded),
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

              ],
            ),
            body: Row(
              children: [
                // Sidebar
                SizedBox(
                  width: 136,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _addSlide,
                            icon: const Icon(Icons.add_rounded),
                            label: const Text("New"),
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
                            final hasImage = _slideImages[s.id] != null;
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
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Stack(
                                        children: [
                                          const Center(child: Icon(Icons.slideshow_rounded)),
                                          if (hasImage)
                                            Positioned(
                                              right: 6, bottom: 6,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.6),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.image, size: 12, color: Colors.white),
                                                    SizedBox(width: 4),
                                                    Text('img', style: TextStyle(color: Colors.white, fontSize: 10)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "${i + 1}. ${s.title}",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    // Compact action bar (no overflow)
                                    Row(
                                      children: [
                                        IconButton(
                                          tooltip: "Rename",
                                          onPressed: _busy ? null : () => _renameSlide(i),
                                          icon: const Icon(Icons.edit, size: 16),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        const SizedBox(width: 2),
                                        IconButton(
                                          tooltip: "Delete",
                                          onPressed: _busy ? null : () => _deleteSlide(i),
                                          icon: const Icon(Icons.delete_outline, size: 16),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
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

        // === Smooth global loading overlay ===
        if (_busy || _exporting)
          _GlassLoader(message: _busy ? "Generating with AI..." : "Exporting PPTX..."),
      ],
    );
  }

  Widget _toolbar() {
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
        ],
      ),
    );
  }

  Widget _slideCanvas(app.Slide s) {
    final titleCtrl = _titleCtrlFor(s);
    final bodyCtrl = _bodyCtrlFor(s);
    final slideImg = _slideImages[s.id];

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
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: "Slide Title",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) { s.title = v; _autosaveSoon(); },
            ),
            const SizedBox(height: 12),

            Expanded(
              child: TextField(
                controller: bodyCtrl,
                expands: true,
                maxLines: null,
                minLines: null,
                decoration: const InputDecoration(
                  labelText: "Slide Body",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) { s.body = v; _autosaveSoon(); },
              ),
            ),
            const SizedBox(height: 12),

            // Image section
            // Controls – tidy, responsive, no RenderFlex overflow
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 420;

                final leftGroup = Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _aiImageForSlide(s),
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(slideImg == null ? "AI" : "Regen AI"),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pickImageForSlide(s),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text("Add Image"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                );

                final removeBtn = (slideImg != null)
                    ? TextButton.icon(
                  onPressed: _busy ? null : () => _removeImageForSlide(s),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Remove"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    visualDensity: VisualDensity.compact,
                  ),
                )
                    : const SizedBox.shrink();

                if (isNarrow) {
                  // Stack vertically on small widths
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftGroup,
                      if (slideImg != null) ...[
                        const SizedBox(height: 8),
                        Align(alignment: Alignment.centerLeft, child: removeBtn),
                      ],
                    ],
                  );
                }

                // Wide: keep in one line safely
                return Row(
                  children: [
                    Expanded(child: leftGroup),
                    if (slideImg != null) removeBtn,
                  ],
                );
              },
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

  /// Open in-app presenter — images appear here while presenting
  Future<void> _openPresenter(app.Presentation p) async {
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _PresenterView(
        presentation: p,
        images: _slideImages,
        themeColor: _themeColor,
      ),
    ));
  }
}

/// Smooth, elegant loader (blur + fade + scale)
class _GlassLoader extends StatelessWidget {
  final String message;
  /// Optional: pass an asset path for your logo (e.g. 'assets/logo.png').
  final String? logoAsset;
  /// Or pass a custom logo widget.
  final Widget? logo;

  const _GlassLoader({
    required this.message,
    this.logoAsset,
    this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Stack(
        key: ValueKey(message),
        children: [
          // Frosted backdrop
          ModalBarrier(color: Colors.black.withOpacity(0.15), dismissible: false),
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withOpacity(0.04)),
            ),
          ),

          // Card with “opening” scale + fade
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
                    children: [
                      const SizedBox(width: 4),
                      _LogoSpinner(
                        asset: logoAsset,
                        logo: logo,
                      ),
                      const SizedBox(width: 12),
                      // Smaller, elegant text
                      Flexible(
                        child: Text(
                          message,
                          softWrap: true,
                          overflow: TextOverflow.fade,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF0F172A),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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

class _LogoSpinner extends StatefulWidget {
  final String? asset;
  final Widget? logo;
  const _LogoSpinner({this.asset, this.logo});

  @override
  State<_LogoSpinner> createState() => _LogoSpinnerState();
}

class _LogoSpinnerState extends State<_LogoSpinner> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final innerLogo = widget.logo ??
        (widget.asset != null
            ? ClipOval(child: Image.asset(widget.asset!, width: 36, height: 36, fit: BoxFit.cover))
            : const Icon(Icons.auto_awesome_rounded, size: 22));

    return SizedBox(
      width: 64,
      height: 64,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return CustomPaint(
            painter: _RingPainter(progress: _c.value),
            child: Center(
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Center(child: innerLogo),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  const _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.0;
    final rect = Offset.zero & size;

    // Soft background ring
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x22000000);
    canvas.drawArc(rect.deflate(stroke / 2), 0, 6.28318, false, bg);

    // Neon sweep arc that rotates
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: const [
          Color(0xFF6366F1), // indigo
          Color(0xFF22D3EE), // cyan
          Color(0xFF6366F1),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(6.28318 * progress),
      ).createShader(rect.deflate(stroke / 2));

    // Arc length ~ 1.25π for a dynamic look
    canvas.drawArc(rect.deflate(stroke / 2), -1.5708, 3.92699, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

/// In-app presenter (images appear during play)
class _PresenterView extends StatefulWidget {
  final app.Presentation presentation;
  final Map<String, Uint8List> images;
  final Color themeColor;
  const _PresenterView({
    required this.presentation,
    required this.images,
    required this.themeColor,
  });

  @override
  State<_PresenterView> createState() => _PresenterViewState();
}

class _PresenterViewState extends State<_PresenterView> {
  late final PageController _pc = PageController();

  @override
  Widget build(BuildContext context) {
    final slides = widget.presentation.slides;

    return Scaffold(
      backgroundColor: widget.themeColor,
      appBar: AppBar(
        title: Text(widget.presentation.title),
        actions: [
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          final next = _pc.page!.round() + 1;
          if (next < slides.length) _pc.animateToPage(next, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
        },
        onDoubleTap: () {
          final prev = _pc.page!.round() - 1;
          if (prev >= 0) _pc.animateToPage(prev, duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
        },
        child: PageView.builder(
          controller: _pc,
          itemCount: slides.length,
          itemBuilder: (_, i) {
            final s = slides[i];
            final img = widget.images[s.id];

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 6))],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    if ((s.body ?? '').trim().isNotEmpty)
                      ...((s.body ?? '').split('\n').where((e) => e.trim().isNotEmpty).map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  ', style: TextStyle(fontSize: 18, height: 1.4)),
                            Expanded(child: Text(b, style: GoogleFonts.poppins(fontSize: 18, height: 1.4))),
                          ],
                        ),
                      ))),
                    const SizedBox(height: 16),
                    if (img != null)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(img, width: double.infinity, fit: BoxFit.cover),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text('${i + 1} / ${slides.length}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
