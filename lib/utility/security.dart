import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyUserEmail = 'user_email';
  static const _keyIsPremium = 'is_premium';

  /// Save logged in state
  static Future<void> setLoggedIn(bool value) async {
    await _storage.write(key: _keyIsLoggedIn, value: value.toString());
  }

  /// Check if logged in
  static Future<bool> isLoggedIn() async {
    final val = await _storage.read(key: _keyIsLoggedIn);
    return val == 'true';
  }

  /// Save user email
  static Future<void> setUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Save premium status (cached)
  /// Note: Always verify against RevenueCat/Backend in production.
  static Future<void> setPremium(bool value) async {
    await _storage.write(key: _keyIsPremium, value: value.toString());
  }

  /// Check premium status
  static Future<bool> isPremium() async {
    final val = await _storage.read(key: _keyIsPremium);
    return val == 'true';
  }

  /// Clear all auth data (Logout)
  static Future<void> clearAuth() async {
    await _storage.delete(key: _keyIsLoggedIn);
    await _storage.delete(key: _keyUserEmail);
    // Optional: Decide if premium cache should be cleared or kept
    await _storage.delete(key: _keyIsPremium);
  }
}
