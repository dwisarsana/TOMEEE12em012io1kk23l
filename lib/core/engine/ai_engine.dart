import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_pptx/dart_pptx.dart' as pptx;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_keys.dart';
import '../models/presentation_models.dart';

const bool kNetworkLog = true;

class AIEngine {
  static String _pretty(Object? data) {
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

  static void _logRequest({
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

  static void _logResponse(http.Response resp) {
    if (!kNetworkLog) return;
    debugPrint('---- Response ${resp.statusCode}');
    debugPrint(_pretty(resp.body));
    debugPrint('===============================================');
  }

  static String _extractOpenAIErrorBody(String body) {
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

  static String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  // ===================== AI GENERATOR (outline) =====================

  static Future<Map<String, dynamic>> generateOutline({
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
      "model": AIConfig.openAIModel,
      "input": input,
      "store": false,
      "text": {
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

    _logRequest(method: 'POST', url: urlUri, headers: AIConfig.headers(), body: bodyMap);
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

  // ===================== IMAGE GENERATOR =====================

  static String themeDescriptor(int colorValue) {
    // Basic mapping, expanded in real app
    // Color _themeColor = const Color(0xFFEEF2FF); // indigo-50
    if (colorValue == 0xFFEEF2FF) return "soft indigo palette";
    if (colorValue == 0xFFF0F9FF) return "clean sky-blue palette";
    if (colorValue == 0xFFFFF7ED) return "warm cream-orange palette";
    if (colorValue == 0xFFFDF2F8) return "light pink palette";
    if (colorValue == 0xFFF1F5F9) return "neutral slate palette";
    if (colorValue == 0xFFFFFBEB) return "pale amber palette";
    return "minimal, brand-safe colors";
  }

  static String themeAugmentedPrompt(String prompt, int themeColorValue) =>
      "$prompt, ${themeDescriptor(themeColorValue)}, professional, minimal, clean branding, high resolution";

  static Future<Uint8List> generateImageWithRetries(String prompt) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await _downloadImageFromPrompt(prompt);
      } catch (e) {
        if (attempt >= 3) rethrow;
        final ms = 700 * attempt + Random().nextInt(400);
        if (kNetworkLog) debugPrint('Image gen retry #$attempt in ${ms}ms → $e');
        await Future.delayed(Duration(milliseconds: ms));
      }
    }
  }

  static Future<Uint8List> _downloadImageFromPrompt(String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/images/generations');
    final body = {
      "model": "gpt-image-1",
      "prompt": prompt,
      "size": "1024x1024",
      "n": 1,
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

    final b64 = items.first['b64_json'];
    if (b64 is String && b64.isNotEmpty) {
      return base64Decode(b64);
    }

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

  // ===================== EXPORT =====================

  static Future<void> exportToPptx(Presentation p, Map<String, Uint8List> slideImages) async {
    try {
      final pres = pptx.PowerPoint();

      pres.title = p.title;
      pres.author = 'Presentation AI';
      pres.company = 'Your Company';
      pres.showSlideNumbers = true;

      pptx.TextValue _tv(String s) =>
          pptx.TextValue.singleLine(<pptx.TextItem>[pptx.TextItem(s)]);
      List<pptx.TextValue> _tvList(List<String> lines) =>
          lines.map((e) => pptx.TextValue.singleLine(<pptx.TextItem>[pptx.TextItem(e)])).toList();

      const coverSubtitle = 'Generated with AI';
      pres.addTitleSlide(
        title: _tv(p.title),
        author: _tv(coverSubtitle),
      );

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
      }

      final bytesOut = await pres.save();
      if (bytesOut == null || bytesOut.isEmpty) {
        throw 'Failed to build PPTX (no bytes returned by dart_pptx).';
      }

      final outDir = await getApplicationDocumentsDirectory();
      final outFile = File('${outDir.path}/${_slug(p.title)}.pptx');
      await outFile.writeAsBytes(bytesOut, flush: true);

      await OpenFilex.open(outFile.path);
    } catch (e) {
      rethrow;
    }
  }
}
