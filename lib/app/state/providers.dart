import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/presentation_models.dart';
import '../../core/storage/local_storage.dart';
import '../../core/monetization/revenue_cat_service.dart';

// --- User Provider ---
class UserState {
  final bool isPremium;
  final bool onboardingDone;
  final String? role;

  const UserState({
    this.isPremium = false,
    this.onboardingDone = false,
    this.role,
  });

  UserState copyWith({
    bool? isPremium,
    bool? onboardingDone,
    String? role,
  }) {
    return UserState(
      isPremium: isPremium ?? this.isPremium,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      role: role ?? this.role,
    );
  }
}

class UserNotifier extends AsyncNotifier<UserState> {
  @override
  Future<UserState> build() async {
    // 1. Check Premium
    final isPremium = await RevenueCatService.isPremium();

    // 2. Check Onboarding
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;
    final role = prefs.getString('user_role');

    return UserState(
      isPremium: isPremium,
      onboardingDone: onboardingDone,
      role: role,
    );
  }

  Future<void> completeOnboarding(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    await prefs.setString('user_role', role);

    state = AsyncValue.data(state.value!.copyWith(
      onboardingDone: true,
      role: role,
    ));
  }

  Future<void> refreshPremium() async {
    final isPremium = await RevenueCatService.isPremium();
    if (state.value != null) {
      state = AsyncValue.data(state.value!.copyWith(isPremium: isPremium));
    }
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, UserState>(UserNotifier.new);

// --- Library Provider ---
class LibraryNotifier extends AsyncNotifier<List<RecentPresentation>> {
  @override
  Future<List<RecentPresentation>> build() async {
    return await Storage.loadRecents();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => Storage.loadRecents());
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<RecentPresentation>>(LibraryNotifier.new);

// --- Theme Provider ---
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    return ThemeMode.system; // Can load from prefs
  }

  void toggle() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
