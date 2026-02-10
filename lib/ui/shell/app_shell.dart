import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tome_ai/ui/homepage.dart';
import 'package:tome_ai/ui/template.dart';
import 'package:tome_ai/ui/setting.dart';
import 'package:tome_ai/ui/ai_generate.dart'; // Will be integrated/replaced, but needed for now.

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  // Pages for persistent navigation
  // Note: We'll eventually merge AI into Editor or Home, but for now we keep the tabs.
  // Ideally 'AI' should be a modal or part of creation flow, not a permanent tab in Tome AI.
  // However, based on current structure, we map them here.
  // The 'AI' tab in legacy was 'AIGeneratePage'. In Tome AI, AI is a tool.
  // For this transition, we might want to keep it or replace it with something else.
  // Let's stick to the analysis: "Home, AI, Templates, Settings" were the tabs.
  // FLOWS.md says: "Bottom Nav: Removed. Replaced by a floating Command Bar or simple top-level navigation".
  // But checking `HomePage` in legacy code, it had bottom nav.
  // DESIGN.md says: "Bottom Nav: Removed. Replaced by a floating Command Bar..."
  // Wait, if I remove Bottom Nav, how do I navigate?
  // DESIGN.md says "Recent Work", "Templates", "Quick Action".
  // Let's follow DESIGN.md: "Home (Dashboard)" is the main view.
  // "Settings" is accessible via Avatar.
  // "Templates" is a section in Home.
  // So `AppShell` might actually just be the Home with a scaffold, and other screens are pushed?
  // BUT `FLOWS.md` said: "Stateful Shell Route ... Using a persistent Scaffold or Shell Route keeps the bottom nav and tab state alive."
  // This contradicts "Bottom Nav: Removed" in DESIGN.md.
  // The User approved FLOWS.md ("Stateful Shell Route").
  // So I will implement a Shell with Bottom Nav for now to ensure stability, or minimal version.
  // Let's implement a standard 4-tab shell for now to match the legacy functionality BUT with persistence.

  final List<Widget> _pages = const [
    HomePage(),
    AIGeneratePage(), // Placeholder for "AI" tab if we keep it, or maybe "My Library"?
    TemplatesPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        indicatorColor: const Color(0xFFEEF2FF),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF5865F2)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded, color: Color(0xFF5865F2)),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF5865F2)),
            label: 'Templates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF5865F2)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
