/// Configurações de API Keys
/// ⚠️  IMPORTANTE: Nunca committar chaves reais para repositórios públicos
class ApiKeys {
  // ElevenLabs API Key
  // Para usar, substitua por sua chave real da ElevenLabs
  // Obtenha em: https://elevenlabs.io/
  static const String elevenLabsApiKey = 'sk_669d869dbe55c7e8a26a8f4552f77df3ac26ccbbd0100829';
  
  // URLs da API
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  
  // Configurações padrão
  static const String defaultVoiceId = '21m00Tcm4TlvDq8ikWAM'; // Rachel - Voz feminina natural
  
  // Verificar se as chaves estão configuradas
  static bool get isElevenLabsConfigured {
    return elevenLabsApiKey != 'YOUR_ELEVENLABS_API_KEY_HERE' && 
           elevenLabsApiKey.isNotEmpty;
  }

  // Gemini API Keys (suporta rotação)
  // Adicione aqui suas chaves; serão usadas em fallback/rotação em caso de 429/403/401
  static const List<String> geminiApiKeys = [
    'AIzaSyDTMequtzyC-3CkOOqT4wi-bbBYoyNqdp0',
    'AIzaSyDmeG8jmplwPlyl7aWPK7q1VugwdkQv4V4',
    'AIzaSyA0P1Y_u3rZjP-GSaOEUXtp1WimSx1G6nQ',
    'AIzaSyCpb5Mn6Iw-CccEzT6hvk5yFMAqDNCxkko',
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
