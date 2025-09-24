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
    // Chave primária já usada atualmente no projeto (migrar para este array)
    'AIzaSyDAEcBUmI4KOoxNxkaaXxeqWe3UkJoPmj8',
    // Chave secundária fornecida pelo usuário para fallback
    'AIzaSyCvtiI4SmV4UHtfPRTAnwZsv0fqQWNFNPs',
  ];

  static bool get isGeminiConfigured => geminiApiKeys.isNotEmpty && geminiApiKeys.first.isNotEmpty;
}
