import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/state/providers.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/components/glass_card.dart';
import '../../../core/design/components/magic_button.dart';
import '../../../core/design/typography.dart';
import '../../../core/monetization/revenue_cat_service.dart';

class ArchiveScreen extends ConsumerWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: TomeColors.washWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text("Archive", style: TomeTypography.display1),
              const SizedBox(height: 32),

              userState.when(
                data: (user) => _SubscriptionCard(
                  isPremium: user.isPremium,
                  onUpgrade: () async {
                    await RevenueCatService.presentPaywall();
                    ref.read(userProvider.notifier).refreshPremium();
                  },
                  onRestore: () async {
                    await RevenueCatService.restorePurchases();
                    ref.read(userProvider.notifier).refreshPremium();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Purchases Restored")),
                      );
                    }
                  },
                ).animate().fadeIn().slideY(begin: 0.1),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text("Error: $e"),
              ),

              const SizedBox(height: 24),
              Text("Preferences", style: TomeTypography.heading2),
              const SizedBox(height: 16),
              const _PreferenceItem(icon: Icons.dark_mode_outlined, label: "Theme (System)"),
              const _PreferenceItem(icon: Icons.notifications_none_rounded, label: "Notifications"),
              const _PreferenceItem(icon: Icons.help_outline_rounded, label: "Support"),
              const Spacer(),
              Center(
                child: Text(
                  "Version 1.0.0",
                  style: TomeTypography.caption.copyWith(color: TomeColors.slateGrey.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final bool isPremium;
  final VoidCallback onUpgrade;
  final VoidCallback onRestore;

  const _SubscriptionCard({
    required this.isPremium,
    required this.onUpgrade,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.verified_rounded : Icons.lock_outline_rounded,
                color: isPremium ? TomeColors.success : TomeColors.mysticIndigo,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium ? "Premium Active" : "Free Plan",
                      style: TomeTypography.heading3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium ? "You have unlimited access." : "Unlock full AI power.",
                      style: TomeTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!isPremium)
            MagicButton(
              label: "Upgrade to Premium",
              icon: Icons.auto_awesome,
              onPressed: onUpgrade,
            ),
          if (!isPremium) const SizedBox(height: 12),
          MagicButton(
            label: "Restore Purchases",
            isGhost: true,
            onPressed: onRestore,
          ),
        ],
      ),
    );
  }
}

class _PreferenceItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreferenceItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: TomeColors.slateGrey),
            const SizedBox(width: 16),
            Text(label, style: TomeTypography.bodyMedium),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: TomeColors.slateGrey),
          ],
        ),
      ),
    );
  }
}
