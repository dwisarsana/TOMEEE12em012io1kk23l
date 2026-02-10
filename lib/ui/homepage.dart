import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utility/models.dart';
import '../utility/storage.dart';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:dart_pptx/dart_pptx.dart' as pptx; // kalau share PPTX
enum ShareFormat { pdf, pptx }

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // --- Templates sorting state ---
  int _selectedChip = 0; // 0:A–Z, 1:Z–A, 2:Most, 3:Fewest
  final List<String> _chips = const ["A–Z","Z–A","Most slides","Fewest slides"];
  final List<_Template> _templates = const [
    _Template("Gradient Pitch", "12 slides", "assets/1.jpg"),
    _Template("Minimal Report", "10 slides", "assets/2.jpg"),
    _Template("Modern Profile", "14 slides", "assets/3.jpg"),
    _Template("Edu Lecture", "9 slides", "assets/4.jpg"),
    _Template("Sales Kit", "11 slides", "assets/5.jpg"),
    _Template("Portfolio Pro", "8 slides", "assets/6.jpg"),
  ];

  List<_Template> _sortedTemplates = []; // hasil sort yang ditampilkan



  String _slug(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');

  Map<String, dynamic> _presentationToJson(Presentation p) => {
    'id': p.id,
    'title': p.title,
    'updatedAt': p.updatedAt.toIso8601String(),
    'slideCount': p.slideCount,
    'slides': p.slides.map((s) => {
      'id': s.id,
      'title': s.title,
      'body': s.body,
    }).toList(),
  };

  // --- Recents + See-all state ---
  List<RecentPresentation> _recents = [];
  bool _showAllRecent = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final t in _templates) {
      precacheImage(AssetImage(t.imagePath), context);
    }
  }
// ===== helper: wajib login sebelum share =====
  Future<bool> _ensureLoggedInForShare(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    if (loggedIn) return true;

    // Tampilkan dialog wajib login
    final go = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Login required'),
        content: const Text(
          'You need to sign in before sharing presentations.\n'
              'Go to Settings to sign in with Apple.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Go to Settings')),
        ],
      ),
    );

    if (go == true && context.mounted) {
      // Arahkan ke Settings untuk login, lalu user bisa tekan Share lagi setelah kembali
      await Navigator.pushNamed(context, '/settings');
    }
    return false; // hentikan share untuk sekarang
  }
  @override
  void initState() {
    super.initState();
    _loadRecents();
    _applySort(); // inisialisasi tampilan grid sesuai chip default (A–Z)
  }

  Future<void> _shareRecent(RecentPresentation r, {ShareFormat? as}) async {
    // ===== WAJIB LOGIN DULU =====
    final ok = await _ensureLoggedInForShare(context);
    if (!ok) return;

    try {
      // Ambil presentasi lengkap
      final p = await Storage.loadPresentation(r.id);

      // fallback text kalau gagal load
      if (p == null) {
        final text = 'Presentation: ${r.title}\nSlides: ${r.slideCount}\nLast edit: ${r.updatedAt}';
        await Share.share(text);
        return;
      }

      final format = as ?? ShareFormat.pdf; // default paling aman: PDF
      switch (format) {
        case ShareFormat.pdf:
        // Pastikan kamu punya implementasi _buildPdfFile(Presentation p)
        // yang membuat File PDF (mis. pakai package `pdf`).
          final file = await _buildPdfFile(p);
          await Share.shareXFiles(
            [XFile(file.path, mimeType: 'application/pdf', name: file.uri.pathSegments.last)],
            text: 'Sharing “${p.title}” as PDF',
          );
          break;

        case ShareFormat.pptx:
        // Pastikan kamu punya implementasi _buildPptxBytes(Presentation p)
        // (minimal title + bullets; image kalau lib mendukung).
          final bytes = await _buildPptxBytes(p);
          final tmpDir = await getTemporaryDirectory();
          final out = File('${tmpDir.path}/${_slug(p.title)}.pptx');
          await out.writeAsBytes(bytes, flush: true);
          await Share.shareXFiles(
            [XFile(
              out.path,
              mimeType: 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
              name: out.uri.pathSegments.last,
            )],
            text: 'Sharing “${p.title}” as PPTX',
          );
          break;
      }
    } catch (e) {
      // fallback share text
      final text = 'Presentation: ${r.title}\nSlides: ${r.slideCount}\n(Share failed: $e)';
      await Share.share(text);
    }
  }

  Future<File> _buildPdfFile(Presentation p) async {
    final doc = pw.Document();

    // warna lembut utk background halaman (opsional)
    final PdfColor pageBg = PdfColor.fromInt(0xFFF6F7FB);
    final PdfColor cardBg = PdfColor.fromInt(0xFFFFFFFF);
    final titleStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold);
    final bodyStyle  = pw.TextStyle(fontSize: 12.5, lineSpacing: 2);

    // Cover
    doc.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: pageBg),
          ),
        ),
        build: (_) => pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              color: cardBg,
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(p.title, style: titleStyle),
                pw.SizedBox(height: 8),
                pw.Text('Generated/Edited with Presentation AI',
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
          ),
        ),
      ),
    );

    // Slides (text only; setiap baris body -> bullet)
    for (final s in p.slides) {
      final bullets = (s.body ?? '')
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      doc.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.all(24),
            buildBackground: (context) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Container(color: pageBg),
            ),
          ),
          build: (_) => pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: cardBg,
              borderRadius: pw.BorderRadius.circular(16),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(s.title, style: titleStyle),
                pw.SizedBox(height: 12),
                if (bullets.isEmpty)
                  pw.Text(' ', style: bodyStyle)
                else
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: bullets.map((b) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 3),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('•  ', style: bodyStyle),
                            pw.Expanded(child: pw.Text(b, style: bodyStyle)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/${_slug(p.title)}.pdf');
    await file.writeAsBytes(await doc.save(), flush: true);
    return file;
  }

  Future<Uint8List> _buildPptxBytes(Presentation p) async {
    final pres = pptx.PowerPoint();
    pres.title = p.title;
    pres.author = 'Presentation AI';
    pres.company = 'Your Company';
    pres.showSlideNumbers = true;

    // helper tipe tepat untuk dart_pptx 0.1.3
    pptx.TextValue tv(String s) =>
        pptx.TextValue.singleLine(<pptx.TextItem>[pptx.TextItem(s)]);
    List<pptx.TextValue> tvList(List<String> lines) =>
        lines.map((e) => pptx.TextValue.singleLine(<pptx.TextItem>[pptx.TextItem(e)])).toList();

    // cover
    pres.addTitleSlide(title: tv(p.title), author: tv(''));

    // slides
    for (final s in p.slides) {
      final bullets = (s.body ?? '')
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      pres.addTitleAndBulletsSlide(
        title: tv(s.title),
        bullets: tvList(bullets),
      );
    }

    final bytes = await pres.save(); // Uint8List?
    if (bytes == null || bytes.isEmpty) {
      throw 'Failed to build PPTX (no bytes).';
    }
    return bytes;
  }

  Future<void> _loadRecents() async {
    final list = await Storage.loadRecents();
    if (mounted) setState(() => _recents = list);
  }

  // --- Helper: ambil angka slide dari subtitle "12 slides" ---
  int _slidesOf(_Template t) {
    final m = RegExp(r'\d+').firstMatch(t.subtitle);
    return int.tryParse(m?.group(0) ?? '') ?? 0;
  }

  // --- Terapkan sorting sesuai chip yang dipilih ---
  void _applySort() {
    final list = [..._templates];
    switch (_selectedChip) {
      case 0: // A–Z
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 1: // Z–A
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 2: // Most slides
        list.sort((a, b) => _slidesOf(b).compareTo(_slidesOf(a)));
        break;
      case 3: // Fewest slides
        list.sort((a, b) => _slidesOf(a).compareTo(_slidesOf(b)));
        break;
    }
    setState(() => _sortedTemplates = list);
  }

  @override
  Widget build(BuildContext context) {
    final Color bg = const Color(0xFFF6F7FB);
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        leading: _circleIcon(
          icon: Icons.dashboard_rounded,
          bg: Colors.white,
          onTap: () => Navigator.pushNamed(context, '/templates'),
        ),
        title: Text(
          "Presentation AI",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/settings'),
            child: _pillPremium(),
          ),
          const SizedBox(width: 12),
          _circleIcon(
            icon: Icons.settings_rounded, bg: Colors.white,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRecents,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headline(),
                      const SizedBox(height: 16),
                      _searchBar(),
                      const SizedBox(height: 16),
                      _quickActions(),
                      const SizedBox(height: 20),

                      // Templates
                      _sectionHeader(
                        title: "Popular Templates",
                        actionText: "See all",
                        onAction: () => Navigator.pushNamed(context, '/templates'),
                      ),
                      const SizedBox(height: 12),
                      _templateChips(),
                      const SizedBox(height: 12),
                      _templateGrid(),

                      const SizedBox(height: 20),

                      // Recents
                      _sectionHeader(
                        title: "Recent Presentations",
                        actionText: (_recents.length > 5)
                            ? (_showAllRecent ? "Collapse" : "See all")
                            : "See all",
                        onAction: (_recents.length > 5)
                            ? () => setState(() => _showAllRecent = !_showAllRecent)
                            : () {}, // <=5: tombol tetap ada tapi no-op
                      ),
                      const SizedBox(height: 12),
                      if (_recents.isEmpty) _emptyRecentsCard() else _recentList(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  // ---------- Widgets ----------
  Widget _circleIcon({required IconData icon, required Color bg, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.black87)),
    );
  }

  Widget _pillPremium() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(999)),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.amber),
          const SizedBox(width: 6),
          Text(
            "Go Premium",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _headline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Design, Revamp & Present", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          "Generate beautiful slides with AI — faster than ever.",
          style: GoogleFonts.poppins(fontSize: 13.5, color: Colors.black54, height: 1.3),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return TextField(
      readOnly: true, // biar kelihatan input tapi dibuka via SearchDelegate
      onTap: _openSearch,
      decoration: InputDecoration(
        hintText: "Search templates or presentations",
        hintStyle: GoogleFonts.poppins(color: Colors.black45, fontSize: 13.5),
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

// Tambahkan ke dalam _HomePageState:
  Future<void> _openSearch() async {
    // kirim data templates & recents ke delegate
    await showSearch(
      context: context,
      delegate: _HomeSearchDelegate(
        templates: _templates,            // list template statis
        recents: _recents,                // hasil dari Storage.loadRecents()
        onOpenTemplate: (t) async {
          await Navigator.pushNamed(context, '/editor', arguments: {
            'source': 'template',
            'title': t.title,
          });
        },
        onOpenRecent: (r) async {
          await Navigator.pushNamed(context, '/editor', arguments: {
            'source': 'recent',
            'id': r.id,
          });
        },
      ),
    );

    // refresh recents setelah kembali dari editor
    _loadRecents();
  }
  Widget _quickActions() {
    return Row(
      children: [
        Expanded(
          child: _bigActionCard(
            title: "New Presentation",
            subtitle: "Blank canvas",
            icon: Icons.add_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF5865F2), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () async {
              await Navigator.pushNamed(context, '/editor', arguments: {
                'source': 'blank',
                'title': 'Untitled Presentation',
              });
              _loadRecents();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bigActionCard(
            title: "From Outline",
            subtitle: "Paste your idea",
            icon: Icons.text_snippet_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFF00C2FF), Color(0xFF4ADE80)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onTap: () async {
              await Navigator.pushNamed(context, '/editor', arguments: {
                'source': 'outline',
                'title': 'From Outline',
              });
              _loadRecents();
            },
          ),
        ),
      ],
    );
  }

  Widget _bigActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: 120,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.9), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header reusable & anti overflow
  Widget _sectionHeader({required String title, required String actionText, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 16.5, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: onAction,
            icon: Icon(
              (_recents.length > 5 && _showAllRecent) ? Icons.expand_less_rounded : Icons.chevron_right_rounded,
              size: 18,
            ),
            label: Text(
              actionText,
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // === SORT CHIPS ===
  Widget _templateChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final selected = _selectedChip == index;
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {
              _selectedChip = index;
              _applySort(); // jalankan sortir & setState di dalamnya
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFEEF2FF) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? const Color(0xFF5865F2) : const Color(0xFFE5E7EB),
                  width: selected ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    index.isEven ? Icons.auto_awesome_rounded : Icons.layers_rounded,
                    size: 16,
                    color: selected ? const Color(0xFF5865F2) : Colors.black87,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _chips[index],
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? const Color(0xFF5865F2) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // === GRID TEMPLATE: gunakan _sortedTemplates ===
  Widget _templateGrid() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _sortedTemplates.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 170,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final t = _sortedTemplates[i];
        return InkWell(
          onTap: () async {
            await Navigator.pushNamed(context, '/editor', arguments: {
              'source': 'template',
              'title': t.title,
            });
            _loadRecents();
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            t.imagePath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF3F4F6),
                              child: const Center(
                                child: Icon(Icons.broken_image_rounded, color: Color(0xFF9CA3AF)),
                              ),
                            ),
                          ),
                          // Overlay halus biar teks & ikon tetap kebaca
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.10),
                                  Colors.black.withOpacity(0.20),
                                ],
                              ),
                            ),
                          ),
                          // Ikon kecil di kanan-atas (optional, mirip sebelumnya)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.dashboard_customize_sharp, size: 18, color: Color(0xFF6B7280)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t.subtitle,
                      style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _emptyRecentsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(
        "No recent presentations yet. Start with New Presentation or pick a template.",
        style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.black54),
      ),
    );
  }

  Widget _recentList() {
    final visible = _showAllRecent ? _recents : _recents.take(5).toList();
    return Column(
      children: List.generate(visible.length, (i) {
        final r = visible[i];
        final subtitle = "Edited ${_timeAgo(r.updatedAt)} • ${r.slideCount} slides";
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ListTile(
            onTap: () async {
              await Navigator.pushNamed(context, '/editor', arguments: {'source': 'recent', 'id': r.id});
              _loadRecents();
            },
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF6B7280)),
            ),
            title: Text(r.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
            trailing: PopupMenuButton<String>(
              onSelected: (key) async {
                if (key == 'pdf') {
                  await _shareRecent(r, as: ShareFormat.pdf);
                } else if (key == 'pptx') {
                  await _shareRecent(r, as: ShareFormat.pptx);
                } else if (key == 'delete') {
                  await Storage.deletePresentation(r.id);
                  _loadRecents();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pdf',   child: ListTile(
                    dense: true, leading: Icon(Icons.picture_as_pdf_rounded), title: Text('Share as PDF'))),
                const PopupMenuItem(value: 'pptx',  child: ListTile(
                    dense: true, leading: Icon(Icons.slideshow_rounded),      title: Text('Share as PPTX'))),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'delete', child: ListTile(
                    dense: true, leading: Icon(Icons.delete_outline_rounded), title: Text('Delete'))),
              ],
            ),


          ),
        );
      }),
    );
  }

  Widget _bottomBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) async {
        setState(() => _currentIndex = i);
        if (i == 1) {
          await Navigator.pushNamed(context, '/ai');
        } else if (i == 2) {
          await Navigator.pushNamed(context, '/templates');
        } else if (i == 3) {
          await Navigator.pushNamed(context, '/settings');
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF5865F2),
      unselectedItemColor: Colors.black45,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: "AI"),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Templates"),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: "Profile"),
      ],
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return "just now";
    if (d.inMinutes < 60) return "${d.inMinutes}m ago";
    if (d.inHours < 24) return "${d.inHours}h ago";
    if (d.inDays < 7) return "${d.inDays}d ago";
    final weeks = (d.inDays / 7).floor();
    return "${weeks}w ago";
  }
}

class _Template {
  final String title;
  final String subtitle;
  final String imagePath; // NEW

  const _Template(this.title, this.subtitle, this.imagePath);
}

// ===== SearchDelegate =====
class _HomeSearchDelegate extends SearchDelegate<String?> {
  final List<_Template> templates;
  final List<RecentPresentation> recents;
  final Future<void> Function(_Template t) onOpenTemplate;
  final Future<void> Function(RecentPresentation r) onOpenRecent;

  _HomeSearchDelegate({
    required this.templates,
    required this.recents,
    required this.onOpenTemplate,
    required this.onOpenRecent,
  });

  // Style AppBar pencarian biar serasi
  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        hintStyle: GoogleFonts.poppins(color: Colors.black54),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
    );
  }

  @override
  String get searchFieldLabel => 'Type to search…';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          onPressed: () => query = '',
          icon: const Icon(Icons.close_rounded),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // saat query kosong, tampilkan saran cepat
    if (query.trim().isEmpty) {
      final topRecents = recents.take(5).toList();
      final topTemplates = templates.take(6).toList();
      return _SuggestionsView(
        title1: 'Recent',
        items1: topRecents.map((r) => _SuggestionItem.recent(r)).toList(),
        title2: 'Templates',
        items2: topTemplates.map((t) => _SuggestionItem.template(t)).toList(),
        onTapItem: (item) async {
          if (item.isTemplate) {
            await onOpenTemplate(item.template!);
          } else {
            await onOpenRecent(item.recent!);
          }
          close(context, null);
        },
      );
    }
    // jika ada query → tampilkan hasil filter ringan
    return buildResults(context);
  }

  @override
  Widget buildResults(BuildContext context) {
    final q = query.toLowerCase().trim();

    final filteredTemplates = templates
        .where((t) => t.title.toLowerCase().contains(q))
        .toList();

    final filteredRecents = recents
        .where((r) => r.title.toLowerCase().contains(q))
        .toList();

    if (filteredTemplates.isEmpty && filteredRecents.isEmpty) {
      return Center(
        child: Text(
          'No results for “$query”.',
          style: GoogleFonts.poppins(color: Colors.black54),
        ),
      );
    }

    return ListView(
      children: [
        if (filteredRecents.isNotEmpty)
          _ResultSection(
            title: 'Presentations',
            children: filteredRecents.map((r) {
              final subtitle = 'Edited ${_timeAgoStatic(r.updatedAt)} • ${r.slideCount} slides';
              return ListTile(
                leading: const Icon(Icons.insert_drive_file_rounded),
                title: Text(r.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                onTap: () async {
                  await onOpenRecent(r);
                  close(context, null);
                },
              );
            }).toList(),
          ),
        if (filteredTemplates.isNotEmpty)
          _ResultSection(
            title: 'Templates',
            children: filteredTemplates.map((t) {
              return ListTile(
                leading: const Icon(Icons.slideshow_rounded),
                title: Text(t.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                subtitle: Text(t.subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
                onTap: () async {
                  await onOpenTemplate(t);
                  close(context, null);
                },
              );
            }).toList(),
          ),
      ],
    );
  }

  // helper untuk timeAgo tanpa akses state
  static String _timeAgoStatic(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return "just now";
    if (d.inMinutes < 60) return "${d.inMinutes}m ago";
    if (d.inHours < 24) return "${d.inHours}h ago";
    if (d.inDays < 7) return "${d.inDays}d ago";
    final weeks = (d.inDays / 7).floor();
    return "${weeks}w ago";
  }
}

// ===== Widget kecil untuk grouping hasil =====
class _ResultSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _ResultSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black54),
            ),
          ),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ===== Suggestions view (saat query kosong) =====
class _SuggestionsView extends StatelessWidget {
  final String title1;
  final List<_SuggestionItem> items1;
  final String title2;
  final List<_SuggestionItem> items2;
  final ValueChanged<_SuggestionItem> onTapItem;

  const _SuggestionsView({
    required this.title1,
    required this.items1,
    required this.title2,
    required this.items2,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (items1.isNotEmpty)
          _ResultSection(
            title: title1,
            children: items1.map((e) => _suggestionTile(e, context)).toList(),
          ),
        if (items2.isNotEmpty)
          _ResultSection(
            title: title2,
            children: items2.map((e) => _suggestionTile(e, context)).toList(),
          ),
      ],
    );
  }

  Widget _suggestionTile(_SuggestionItem item, BuildContext context) {
    return ListTile(
      leading: Icon(item.isTemplate ? Icons.slideshow_rounded : Icons.history_rounded),
      title: Text(item.title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      subtitle: item.subtitle == null
          ? null
          : Text(item.subtitle!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
      onTap: () => onTapItem(item),
    );
  }
}

class _SuggestionItem {
  final _Template? template;
  final RecentPresentation? recent;
  String get title => template?.title ?? recent!.title;
  String? get subtitle => template?.subtitle ?? "Edited ${_HomeSearchDelegate._timeAgoStatic(recent!.updatedAt)}";
  bool get isTemplate => template != null;

  _SuggestionItem.template(this.template) : recent = null;
  _SuggestionItem.recent(this.recent) : template = null;
}
