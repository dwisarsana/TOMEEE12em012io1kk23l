import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/providers.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/components/glass_card.dart';
import '../../../core/design/typography.dart';

class RoleScreen extends ConsumerWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: TomeColors.washWhite,
      appBar: AppBar(
        title: Text("Who are you?", style: TomeTypography.heading2),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: TomeColors.slateGrey),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "This helps us tailor your first tome.",
                style: TomeTypography.bodyLarge.copyWith(color: TomeColors.slateGrey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              _RoleCard(
                title: "Professional",
                description: "Pitch decks, reports, and business plans.",
                icon: Icons.business_center_rounded,
                onTap: () => _selectRole(context, ref, "Professional"),
              ).animate().fadeIn(delay: 200.ms).slideX(),

              const SizedBox(height: 16),

              _RoleCard(
                title: "Student",
                description: "Assignments, research, and study aids.",
                icon: Icons.school_rounded,
                onTap: () => _selectRole(context, ref, "Student"),
              ).animate().fadeIn(delay: 400.ms).slideX(),

              const SizedBox(height: 16),

              _RoleCard(
                title: "Creative",
                description: "Storyboards, mood boards, and portfolios.",
                icon: Icons.palette_rounded,
                onTap: () => _selectRole(context, ref, "Creative"),
              ).animate().fadeIn(delay: 600.ms).slideX(),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, WidgetRef ref, String role) {
    ref.read(userProvider.notifier).completeOnboarding(role);
    context.go('/library'); // Router redirect should handle this, but explicit go is safe
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TomeColors.mysticIndigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: TomeColors.mysticIndigo, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TomeTypography.heading3),
                const SizedBox(height: 4),
                Text(description, style: TomeTypography.caption.copyWith(fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: TomeColors.slateGrey),
        ],
      ),
    );
  }
}
