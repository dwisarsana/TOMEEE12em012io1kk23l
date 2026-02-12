import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/state/providers.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/components/glass_card.dart';
import '../../../core/design/typography.dart';
import '../../../core/models/presentation_models.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentations = ref.watch(libraryProvider);

    return Scaffold(
      backgroundColor: TomeColors.washWhite,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text("Your Tomes", style: TomeTypography.display1),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: false,
          ),

          presentations.when(
            data: (data) {
              if (data.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books_outlined, size: 64, color: TomeColors.slateGrey.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text("No tomes yet.", style: TomeTypography.heading3.copyWith(color: TomeColors.slateGrey)),
                        const SizedBox(height: 8),
                        Text("Tap + to conjure one.", style: TomeTypography.bodyLarge.copyWith(color: TomeColors.slateGrey)),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                sliver: SliverList.separated(
                  itemCount: data.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final tome = data[index];
                    return _TomeCard(tome: tome)
                        .animate()
                        .fadeIn(delay: (index * 50).ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                  },
                ),
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error: $err'))),
          ),
        ],
      ),
    );
  }
}

class _TomeCard extends StatelessWidget {
  final RecentPresentation tome;

  const _TomeCard({required this.tome});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat.yMMMd().format(tome.updatedAt);

    return GlassCard(
      onTap: () => context.push('/library/editor/${tome.id}'),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: TomeColors.etherealPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_motion_rounded, color: TomeColors.mysticIndigo, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tome.title, style: TomeTypography.heading3.copyWith(fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text("${tome.slideCount} slides • $dateStr", style: TomeTypography.caption),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: TomeColors.slateGrey),
        ],
      ),
    );
  }
}
