import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Load keys from .env
final googleApiKey = dotenv.get('REVENUECAT_GOOGLE_KEY', fallback: '');
final amazonApiKey = dotenv.get('REVENUECAT_AMAZON_KEY', fallback: '');
final appleApiKey = dotenv.get('REVENUECAT_APPLE_KEY', fallback: '');

const entitlementKey = 'slides';
const appId = 'app6dd1e43ac7'; // This looks like a public app ID, leaving as is but could be moved to .env

void checkPremiumStatus(CustomerInfo customerInfo) {
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
    Future.delayed(Duration(seconds: 2), () {
      presentPaywall();
    });
  } else {
    // Logika jika pengguna premium (misalnya, tampilkan fitur premium)
    // ...
  }
}

void cekPremium() async {
  // Misalnya, Anda mendapatkan `CustomerInfo` dari SDK saat aplikasi dimulai
  CustomerInfo customerInfo = await fetchCustomerInfo();

  // Memanggil fungsi checkPremiumStatus dengan `CustomerInfo` yang didapatkan
  checkPremiumStatus(customerInfo);
}

Future<CustomerInfo> fetchCustomerInfo() async {
  // Kode untuk mengambil informasi customer dari SDK atau server Anda
  // Misalnya menggunakan SDK RevenueCat
  return await Purchases.getCustomerInfo();
}

void presentPaywall() async {
    await RevenueCatUI.presentPaywall();

}