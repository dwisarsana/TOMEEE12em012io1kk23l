import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'store_config.dart';

const entitlementKey = 'slides';
const googleApiKey = 'googl_api_key';
const amazonApiKey = 'amazon_api_key';
const appleApiKey = 'appl_GiIpkYqcClVzAbuOJuFpWIoUJpG';


class RevenueCatService {
  static Future<void> configure(StoreConfig config) async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (config.store == Store.amazon) {
      configuration = AmazonConfiguration(config.apiKey);
    } else {
      configuration = PurchasesConfiguration(config.apiKey);
    }

    // configuration.entitlementVerificationMode = EntitlementVerificationMode.informational;

    await Purchases.configure(configuration);
    // await Purchases.enableAdServicesAttributionTokenCollection();
  }

  static Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      final active = info.entitlements.all[entitlementKey]?.isActive ?? false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', active);

      return active;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_premium') ?? false;
    }
  }

  static Future<void> presentPaywall() async {
    await RevenueCatUI.presentPaywall();
  }

  static Future<void> restorePurchases() async {
    try {
      await Purchases.restorePurchases();
    } catch (e) {
      debugPrint("Restore failed: $e");
    }
  }
}
