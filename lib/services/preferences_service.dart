import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para gerenciar preferências do usuário
class PreferencesService {
  static const String _lumaConfiguredKey = 'luma_configured';
  static const String _lumaInteractionModeKey = 'luma_interaction_mode';
  
  // Modos de interação
  static const String interactionModeText = 'text';
  static const String interactionModeVoice = 'voice';
  
  /// Verifica se a Luma já foi configurada
  static Future<bool> hasConfiguredLuma() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_lumaConfiguredKey) ?? false;
  }
  
  /// Marca a Luma como configurada
  static Future<void> setLumaConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lumaConfiguredKey, true);
  }
  
  /// Obtém o modo de interação atual
  static Future<String> getLumaInteractionMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lumaInteractionModeKey) ?? interactionModeText;
  }
  
  /// Define o modo de interação
  static Future<void> setLumaInteractionMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lumaInteractionModeKey, mode);
  }
  
  /// Verifica se está no modo voz
  static Future<bool> isVoiceMode() async {
    final mode = await getLumaInteractionMode();
    return mode == interactionModeVoice;
  }
}
