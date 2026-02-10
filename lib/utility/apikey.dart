// lib/utility/apikey.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIConfig {
  /// Load from .env or environment variable
  static String get openAIKey => dotenv.get('OPENAI_API_KEY', fallback: '');

  /// Model default
  static const openAIModel = 'gpt-4o-mini';

  /// Header standar untuk OpenAI
  static Map<String, String> headers() => {
    'Authorization': 'Bearer $openAIKey',
    'Content-Type': 'application/json',
  };

  /// Guard: pastikan key sudah di-set sebelum memanggil API
  static void assertHasKey() {
    if (openAIKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is not set in .env file or environment variables.',
      );
    }
  }
}
