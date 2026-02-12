import 'package:flutter/material.dart';

class WizardScreen extends StatelessWidget {
  const WizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Tome')),
      body: const Center(child: Text('Wizard Steps (Intent, Subject, Depth)')),
    );
  }
}
