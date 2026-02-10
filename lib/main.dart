import 'dart:io';

import 'package:tome_ai/src/constant.dart';
import 'package:tome_ai/src/store_config.dart';
import 'package:tome_ai/ui/ai_generate.dart';
import 'package:tome_ai/ui/editor.dart';
import 'package:tome_ai/ui/homepage.dart';
import 'package:tome_ai/ui/setting.dart';
import 'package:tome_ai/ui/template.dart';
import 'package:tome_ai/ui/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'opening/onboards.dart';
import 'opening/splash.dart';


Future<void> _configureSDK() async {
  await Purchases.setLogLevel(LogLevel.debug);

  PurchasesConfiguration configuration;
  if (StoreConfig.isForAmazonAppstore()) {
    configuration = AmazonConfiguration(StoreConfig.instance.apiKey);
  } else {
    configuration = PurchasesConfiguration(StoreConfig.instance.apiKey);
  }
  configuration.entitlementVerificationMode =
      EntitlementVerificationMode.informational;

  await Purchases.configure(configuration);
  await Purchases.enableAdServicesAttributionTokenCollection();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // RevenueCat Store Config
  if (Platform.isIOS || Platform.isMacOS) {
    StoreConfig(store: Store.appStore, apiKey: appleApiKey);
  } else if (Platform.isAndroid) {
    const useAmazon = bool.fromEnvironment("amazon");
    StoreConfig(
      store: useAmazon ? Store.amazon : Store.playStore,
      apiKey: useAmazon ? amazonApiKey : googleApiKey,
    );
  }

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Using empty environment.");
  }
  await _configureSDK();
  runApp(const TomeAIApp());
}


class TomeAIApp extends StatelessWidget {
  const TomeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tome AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5865F2)),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const _LaunchGate(),
      routes: {
        '/editor':     (_) => const EditorPage(),
        '/templates':  (_) => const TemplatesPage(),
        '/settings':   (_) => const MorePage(),
        '/ai':         (_) => const AIGeneratePage(),
      },
    );
  }
}

enum _Phase { splash, onboard, home }

class _LaunchGate extends StatefulWidget {
  const _LaunchGate({super.key});

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  _Phase _phase = _Phase.splash;

  Future<void> _decideNext() async {
    // baca flag setiap selesai splash (menghindari race)
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('onboarding_done') ?? false;
    if (!mounted) return;
    setState(() => _phase = done ? _Phase.home : _Phase.onboard);
  }

  Future<void> _onOnboardFinish() async {
    // Onboarding screen sendiri juga sudah set flag,
    // di sini cukup arahkan ke Home.
    setState(() => _phase = _Phase.home);
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.splash:
      // Setelah animasi splash selesai, tentukan next step
        return SplashScreen(onFinish: _decideNext);

      case _Phase.onboard:
      // Setelah onboarding selesai, masuk Home
        return OnboardingChatScreen(onFinish: _onOnboardFinish);

      case _Phase.home:
        return const AppShell();
    }
  }
}