// lib/utility/apikey.dart
class AIConfig {
  /// API key diambil dari --dart-define saat build/run.
  /// Contoh: flutter run --dart-define=OPENAI_API_KEY=sk-proj-xxx
  static const openAIKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '',
  );

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
        'OPENAI_API_KEY belum di-set.\n'
        'Jalankan: flutter run --dart-define=OPENAI_API_KEY=sk-proj-xxx',
      );
    }
  }
}
