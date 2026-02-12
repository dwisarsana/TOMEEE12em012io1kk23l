import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            // Functional tab - opens Wizard modal
            context.push('/wizard');
          } else {
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle, size: 32),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.archive),
            label: 'Archive',
          ),
        ],
      ),
    );
  }
}
