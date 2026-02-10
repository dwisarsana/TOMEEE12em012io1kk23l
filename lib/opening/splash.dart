// splash.dart — Cupertino-first (Flutter 3.8+ safe)
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors; // hanya untuk Colors.*
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const SplashScreen({Key? key, required this.onFinish}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  // Brand palette (selaras dengan UI utama)
  static const _brandIndigo = Color(0xFF5865F2);
  static const _brandViolet = Color(0xFF8B5CF6);
  static const _bgTop       = Color(0xFFEEF2FF); // indigo-50
  static const _bgBottom    = Color(0xFFF6F7FB); // soft grey
  static const _ink         = Color(0xFF111827);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();

    // Delay splash 2.1s kemudian panggil onFinish
    Future.delayed(const Duration(milliseconds: 2100), widget.onFinish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        child: Container(
          // Latar gradient (brand)
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_bgTop, _bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo dengan efek scaling
                ScaleTransition(
                  scale: _scaleAnim,
                  child: SizedBox(
                    width: 160,
                    height: 160,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/splash.png', // pastikan ada di pubspec.yaml
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // Title — Tome AI
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeIn,
                  builder: (context, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: Text(
                    "Tome AI",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: _brandIndigo,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: .2,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitle — singkat & selaras dengan homepage
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeIn,
                  builder: (context, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: Text(
                    "Design, revamp & present — powered by AI",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: _ink.withOpacity(0.75),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      height: 1.35,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Brand loader (garis) + activity indicator kecil
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    final width = 140 * t;
                    return Column(
                      children: [
                        Container(
                          width: width,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: const LinearGradient(
                              colors: [_brandIndigo, _brandViolet],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const CupertinoActivityIndicator(radius: 9),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
