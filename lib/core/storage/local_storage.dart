import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/presentation_models.dart';

const String kRecentsKey = 'recent_presentations';
String _presentationKey(String id) => 'presentation_$id';

class Storage {
  // ==== Presentation ====
  static Future<void> savePresentation(Presentation p) async {
    final prefs = await SharedPreferences.getInstance();
    p.updatedAt = DateTime.now();
    await prefs.setString(_presentationKey(p.id), p.toRawJson());
    await _upsertRecent(RecentPresentation(
      id: p.id,
      title: p.title,
      slideCount: p.slideCount,
      updatedAt: p.updatedAt,
    ));
  }

  static Future<Presentation?> loadPresentation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_presentationKey(id));
    if (raw == null) return null;
    return Presentation.fromRawJson(raw);
  }

  static Future<void> deletePresentation(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_presentationKey(id));
    await _removeRecent(id);
  }

  // ==== Recents (list of meta) ====
  static Future<List<RecentPresentation>> loadRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(kRecentsKey) ?? <String>[];
    final list = <RecentPresentation>[];
    for (final raw in rawList) {
      try {
        final obj = jsonDecode(raw) as Map<String, dynamic>;
        list.add(RecentPresentation.fromJson(obj));
      } catch (_) {}
    }
    // sort desc by updatedAt
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  static Future<void> _upsertRecent(RecentPresentation r) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadRecents();
    final filtered = list.where((e) => e.id != r.id).toList();
    filtered.insert(0, r);
    // batasi 30 item
    final trimmed = filtered.take(30).toList();
    final encoded = trimmed.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(kRecentsKey, encoded);
  }

  static Future<void> _removeRecent(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadRecents();
    final filtered = list.where((e) => e.id != id).toList();
    final encoded = filtered.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(kRecentsKey, encoded);
  }
}
