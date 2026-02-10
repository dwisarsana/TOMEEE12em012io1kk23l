import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_Template> templates = const [
      _Template("Gradient Pitch", 12, "assets/1.jpg"),
      _Template("Minimal Report", 10, "assets/2.jpg"),
      _Template("Modern Profile", 14, "assets/3.jpg"),
      _Template("Edu Lecture", 9, "assets/4.jpg"),
      _Template("Sales Kit", 11, "assets/5.jpg"),
      _Template("Portfolio Pro", 8, "assets/6.jpg"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("Templates", style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisExtent: 170,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) {
          final t = templates[i];
          return InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/editor',
              arguments: {'source': 'template', 'title': t.title},
            ),
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
                    // Thumbnail
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
                            // overlay halus
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
                            // badge icon kanan-atas
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.88),
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
                    // Title & slides
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
                        "${t.slides} slides",
                        style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Template {
  final String title;
  final int slides;
  final String imagePath;
  const _Template(this.title, this.slides, this.imagePath);
}
