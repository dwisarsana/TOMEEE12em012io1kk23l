import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/colors.dart';
import '../../../core/design/components/magic_button.dart';
import '../../../core/design/typography.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TomeColors.washWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Book Opening Animation Placeholder
              const Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: TomeColors.mysticIndigo,
              ).animate()
               .fadeIn(duration: 600.ms)
               .scale(delay: 200.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              Text(
                "Tome AI",
                style: TomeTypography.display1.copyWith(
                  color: TomeColors.mysticIndigo,
                ),
              ).animate().fadeIn(delay: 400.ms).moveY(begin: 10, end: 0),

              const SizedBox(height: 12),

              Text(
                "Your thoughts, magically transformed into beautiful presentations.",
                textAlign: TextAlign.center,
                style: TomeTypography.bodyLarge.copyWith(
                  color: TomeColors.slateGrey,
                ),
              ).animate().fadeIn(delay: 600.ms),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: MagicButton(
                  label: "Start Your Journey",
                  onPressed: () => context.push('/role'),
                  icon: Icons.arrow_forward_rounded,
                ),
              ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
