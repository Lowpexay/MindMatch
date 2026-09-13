/// Configurações de API Keys
/// ⚠️  IMPORTANTE: Nunca committar chaves reais para repositórios públicos
class ApiKeys {
  // Gemini API Keys (suporta rotação)
  // Configure com: flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE
  static const List<String> geminiApiKeys = [
    String.fromEnvironment('GEMINI_API_KEY', defaultValue: ''),
  ];

  static bool get isGeminiConfigured => geminiApiKeys.isNotEmpty && geminiApiKeys.first.isNotEmpty;

  // --- Controle simples de rotação ---
  static int _geminiKeyIndex = 0;

  static String get currentGeminiKey => geminiApiKeys[_geminiKeyIndex % geminiApiKeys.length];

  // Chamar quando receber 429 / 403 / 401 para tentar próximo fallback
  static String rotateGeminiKey() {
    _geminiKeyIndex = (_geminiKeyIndex + 1) % geminiApiKeys.length;
    return currentGeminiKey;
  }

  // Novo: pegar uma chave aleatória (sem alterar índice global de rotação)
  static String randomGeminiKey() {
    if (geminiApiKeys.isEmpty) return '';
    final now = DateTime.now().microsecondsSinceEpoch;
    final idx = now % geminiApiKeys.length; // leve pseudo-aleatório sem importar dart:math aqui
    return geminiApiKeys[idx];
  }

  // Helper para header padrão
  static Map<String, String> geminiHeaders({String? apiKey}) => {
    'Content-Type': 'application/json',
    'x-goog-api-key': apiKey ?? currentGeminiKey,
  };
}
