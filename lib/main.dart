import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'app/navigation/app_router.dart';
import 'core/monetization/revenue_cat_service.dart';
import 'core/monetization/store_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // RevenueCat Store Config Logic
  try {
    if (Platform.isIOS || Platform.isMacOS) {
      StoreConfig(store: Store.appStore, apiKey: appleApiKey);
    } else if (Platform.isAndroid) {
      const useAmazon = bool.fromEnvironment("amazon");
      StoreConfig(
        store: useAmazon ? Store.amazon : Store.playStore,
        apiKey: useAmazon ? amazonApiKey : googleApiKey,
      );
    }

    // Initialize RevenueCat via Service
    // Note: StoreConfig factory ensures _instance is set if platform logic matched
    await RevenueCatService.configure(StoreConfig.instance);
  } catch (e) {
    debugPrint("Failed to initialize RevenueCat: $e");
  }

  runApp(const ProviderScope(child: TomeApp()));
}

class TomeApp extends ConsumerWidget {
  const TomeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Tome AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Mystic Indigo from Design System
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(), // Using Sans as per Design System
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Wash White
      ),
      routerConfig: router,
    );
  }
}
