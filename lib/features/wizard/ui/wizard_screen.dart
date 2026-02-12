import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/state/providers.dart';
import '../../../core/design/colors.dart';
import '../../../core/design/components/glass_card.dart';
import '../../../core/design/components/magic_button.dart';
import '../../../core/design/typography.dart';
import '../../../core/engine/ai_engine.dart';
import '../../../core/models/presentation_models.dart';
import '../../../core/monetization/revenue_cat_service.dart';
import '../../../core/storage/local_storage.dart';
import 'dart:math';

// --- Wizard State ---
class WizardState {
  final String style;
  final String topic;
  final int slideCount;
  final int step;
  final bool isGenerating;

  const WizardState({
    this.style = 'persuasive business',
    this.topic = '',
    this.slideCount = 10,
    this.step = 0,
    this.isGenerating = false,
  });

  WizardState copyWith({
    String? style,
    String? topic,
    int? slideCount,
    int? step,
    bool? isGenerating,
  }) {
    return WizardState(
      style: style ?? this.style,
      topic: topic ?? this.topic,
      slideCount: slideCount ?? this.slideCount,
      step: step ?? this.step,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }
}

class WizardNotifier extends Notifier<WizardState> {
  @override
  WizardState build() => const WizardState();

  void setStyle(String s) => state = state.copyWith(style: s);
  void setTopic(String t) => state = state.copyWith(topic: t);
  void setSlideCount(int c) => state = state.copyWith(slideCount: c);
  void nextStep() => state = state.copyWith(step: state.step + 1);
  void prevStep() => state = state.copyWith(step: state.step - 1);
  void setGenerating(bool g) => state = state.copyWith(isGenerating: g);
}

final wizardProvider = NotifierProvider<WizardNotifier, WizardState>(WizardNotifier.new);

// --- Wizard UI ---
class WizardScreen extends ConsumerWidget {
  const WizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final notifier = ref.read(wizardProvider.notifier);

    return Scaffold(
      backgroundColor: TomeColors.washWhite,
      appBar: AppBar(
        title: Text("Conjure Tome", style: TomeTypography.heading3),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: TomeColors.slateGrey),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (wizard.step + 1) / 4,
              backgroundColor: TomeColors.slateGrey.withOpacity(0.1),
              color: TomeColors.mysticIndigo,
            ).animate().slideX(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOut),

            Expanded(
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: PageController(initialPage: wizard.step),
                children: [
                  if (wizard.step == 0) _IntentStep(
                    selectedStyle: wizard.style,
                    onSelect: (s) {
                      notifier.setStyle(s);
                      notifier.nextStep();
                    },
                  ),
                  if (wizard.step == 1) _SubjectStep(
                    initialTopic: wizard.topic,
                    onNext: (t) {
                      notifier.setTopic(t);
                      notifier.nextStep();
                    },
                    onBack: notifier.prevStep,
                  ),
                  if (wizard.step == 2) _DepthStep(
                    count: wizard.slideCount,
                    onChanged: notifier.setSlideCount,
                    onNext: notifier.nextStep,
                    onBack: notifier.prevStep,
                  ),
                  if (wizard.step == 3) _GateStep(
                    onBack: notifier.prevStep,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Steps ---

class _IntentStep extends StatelessWidget {
  final String selectedStyle;
  final ValueChanged<String> onSelect;

  const _IntentStep({required this.selectedStyle, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("What is the intent?", style: TomeTypography.heading2),
          const SizedBox(height: 32),
          _StyleCard("Pitch Deck", "Persuade investors or stakeholders.", "persuasive business", Icons.business_center, onSelect),
          const SizedBox(height: 16),
          _StyleCard("Lecture", "Educate an audience clearly.", "educational and clear", Icons.school, onSelect),
          const SizedBox(height: 16),
          _StyleCard("Story", "Narrate a compelling journey.", "vivid narrative", Icons.auto_stories, onSelect),
        ],
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  final String title;
  final String desc;
  final String value;
  final IconData icon;
  final ValueChanged<String> onTap;

  const _StyleCard(this.title, this.desc, this.value, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => onTap(value),
      child: Row(
        children: [
          Icon(icon, size: 32, color: TomeColors.mysticIndigo),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TomeTypography.heading3),
                const SizedBox(height: 4),
                Text(desc, style: TomeTypography.caption),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class _SubjectStep extends StatefulWidget {
  final String initialTopic;
  final ValueChanged<String> onNext;
  final VoidCallback onBack;

  const _SubjectStep({required this.initialTopic, required this.onNext, required this.onBack});

  @override
  State<_SubjectStep> createState() => _SubjectStepState();
}

class _SubjectStepState extends State<_SubjectStep> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialTopic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("What is the subject?", style: TomeTypography.heading2),
          const SizedBox(height: 32),
          TextField(
            controller: _ctrl,
            style: TomeTypography.display1.copyWith(fontSize: 24),
            decoration: InputDecoration(
              hintText: "e.g. The Future of AI",
              hintStyle: TextStyle(color: TomeColors.slateGrey.withOpacity(0.4)),
              border: InputBorder.none,
            ),
            maxLines: 3,
            autofocus: true,
          ),
          const Spacer(),
          Row(
            children: [
              MagicButton(label: "Back", isGhost: true, onPressed: widget.onBack),
              const Spacer(),
              MagicButton(
                label: "Next",
                icon: Icons.arrow_forward,
                onPressed: () {
                  if (_ctrl.text.trim().length < 3) return;
                  widget.onNext(_ctrl.text.trim());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DepthStep extends StatelessWidget {
  final int count;
  final ValueChanged<int> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _DepthStep({required this.count, required this.onChanged, required this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("How deep shall we go?", style: TomeTypography.heading2),
          const SizedBox(height: 48),

          Text("${count.toInt()} Slides", style: TomeTypography.display1.copyWith(color: TomeColors.mysticIndigo), textAlign: TextAlign.center),

          Slider(
            value: count.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            activeColor: TomeColors.mysticIndigo,
            onChanged: (v) => onChanged(v.toInt()),
          ),

          const Spacer(),
          Row(
            children: [
              MagicButton(label: "Back", isGhost: true, onPressed: onBack),
              const Spacer(),
              MagicButton(label: "Next", icon: Icons.arrow_forward, onPressed: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

class _GateStep extends ConsumerWidget {
  final VoidCallback onBack;

  const _GateStep({required this.onBack});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(wizardProvider);
    final userState = ref.watch(userProvider);
    final isPremium = userState.valueOrNull?.isPremium ?? false;

    if (wizard.isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: TomeColors.mysticIndigo),
            const SizedBox(height: 24),
            Text("Weaving your tome...", style: TomeTypography.heading3),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: TomeColors.mysticIndigo),
          const SizedBox(height: 24),
          Text("Ready to Reveal?", style: TomeTypography.heading2),
          const SizedBox(height: 12),
          Text(
            "We will generate an outline for '${wizard.topic}' with ${wizard.slideCount} slides.",
            textAlign: TextAlign.center,
            style: TomeTypography.bodyLarge.copyWith(color: TomeColors.slateGrey),
          ),
          const SizedBox(height: 48),

          MagicButton(
            label: isPremium ? "Reveal Outline" : "Unlock & Reveal",
            icon: isPremium ? Icons.auto_awesome : Icons.lock_open,
            onPressed: () => _generate(context, ref, isPremium),
          ),
          const SizedBox(height: 16),
          MagicButton(label: "Back", isGhost: true, onPressed: onBack),
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context, WidgetRef ref, bool isPremium) async {
    final notifier = ref.read(wizardProvider.notifier);
    final wizard = ref.read(wizardProvider);

    // 1. Check Premium
    if (!isPremium) {
      // Show Paywall
      await RevenueCatService.presentPaywall();
      // Refresh User State to check if purchase happened
      await ref.read(userProvider.notifier).refreshPremium();
      // Re-check
      final updatedUser = ref.read(userProvider).value;
      if (updatedUser == null || !updatedUser.isPremium) return; // Still free
    }

    // 2. Generate
    notifier.setGenerating(true);
    try {
      final outlineMap = await AIEngine.generateOutline(
        topic: wizard.topic,
        slides: wizard.slideCount,
        style: wizard.style,
      );

      // 3. Convert to Presentation (Mapping JSON to Model)
      final slidesList = (outlineMap['slides'] as List).map((s) {
         final title = (s['title'] ?? '').toString();
         final bullets = ((s['bullets'] as List?) ?? const []).map((e) => e.toString()).toList();
         final imgPrompt = (s['image_prompt'] ?? '').toString();
         // Note: Slide model doesn't explicitly store imagePrompt in original model,
         // but ENGINE_CONTRACT says "Each slide contains... image_prompt".
         // We might need to store it if we want to use it later,
         // but the original `Slide` model only had `body`.
         // We will append it to body or rely on regeneration logic if needed.
         // For strict engine contract, we populate what fits.

         return Slide(
          id: DateTime.now().microsecondsSinceEpoch.toString() + Random().nextInt(1000).toString(),
          title: title,
          body: bullets.join('\n'),
        );
      }).toList();

      final title = (outlineMap['title'] as String?) ?? wizard.topic;

      final presentation = Presentation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        slides: slidesList,
        updatedAt: DateTime.now(),
      );

      // 4. Save via Storage directly (Library provider will refresh)
      await Storage.savePresentation(presentation);
      ref.read(libraryProvider.notifier).refresh(); // Explicit refresh

      // 5. Navigate
      if (context.mounted) {
        context.pushReplacement('/library/editor/${presentation.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      notifier.setGenerating(false);
    }
  }
}
