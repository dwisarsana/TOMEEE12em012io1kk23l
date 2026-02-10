import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Load keys from .env
final googleApiKey = dotenv.get('REVENUECAT_GOOGLE_KEY', fallback: '');
final amazonApiKey = dotenv.get('REVENUECAT_AMAZON_KEY', fallback: '');
final appleApiKey = dotenv.get('REVENUECAT_APPLE_KEY', fallback: '');
final appId = dotenv.get('REVENUECAT_APP_ID', fallback: 'app6dd1e43ac7');

const entitlementKey = 'slides';

void checkPremiumStatus(CustomerInfo customerInfo) {
  try {
    // Mendefinisikan kunci entitlements premium yang Anda miliki
    const premiumEntitlements = [
      'slides',
    ];

    // Cek apakah user memiliki salah satu entitlements premium
    bool isPremium = premiumEntitlements.any((entitlement) =>
        customerInfo.entitlements.all[entitlement] != null &&
        customerInfo.entitlements.all[entitlement]!.isActive);

    if (!isPremium) {
      // Jika pengguna tidak premium, tampilkan iklan dan paywall dengan jeda 2 detik
      Future.delayed(const Duration(seconds: 2), () {
        presentPaywall();
      });
    } else {
      // Logika jika pengguna premium (misalnya, tampilkan fitur premium)
      // ...
    }
  } catch (e) {
    debugPrint("Error checking premium status: $e");
  }
}

Future<void> cekPremium() async {
  try {
    // Misalnya, Anda mendapatkan `CustomerInfo` dari SDK saat aplikasi dimulai
    CustomerInfo customerInfo = await fetchCustomerInfo();

    // Memanggil fungsi checkPremiumStatus dengan `CustomerInfo` yang didapatkan
    checkPremiumStatus(customerInfo);
  } catch (e) {
    debugPrint("Error fetching customer info: $e");
  }
}

Future<CustomerInfo> fetchCustomerInfo() async {
  // Kode untuk mengambil informasi customer dari SDK atau server Anda
  // Misalnya menggunakan SDK RevenueCat
  return await Purchases.getCustomerInfo();
}

Future<void> presentPaywall() async {
  try {
    await RevenueCatUI.presentPaywall();
  } catch (e) {
    debugPrint("Error presenting paywall: $e");
  }
}
