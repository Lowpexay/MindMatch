import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import '../config/api_keys.dart';

/// Serviço para integração com ElevenLabs Text-to-Speech
class ElevenLabsService {
  static const Duration _timeoutDuration = Duration(seconds: 30);
  bool _isSpeaking = false;
  
  // Player de áudio para reprodução
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Verificar se o serviço está configurado
  bool get isConfigured => ApiKeys.isElevenLabsConfigured;
  bool get isSpeaking => _isSpeaking;
  
  /// Converte texto em fala usando ElevenLabs API
  Future<void> speak(String text, {String? voiceId}) async {
    if (!isConfigured) {
      throw Exception('ElevenLabs API key não configurada');
    }
    
    if (_isSpeaking) return;
    
    final selectedVoiceId = voiceId ?? ApiKeys.defaultVoiceId;
    
    try {
      _isSpeaking = true;
      
      // Fazer requisição para a API do ElevenLabs
      final response = await http.post(
        Uri.parse('${ApiKeys.elevenLabsBaseUrl}/text-to-speech/$selectedVoiceId'),
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': ApiKeys.elevenLabsApiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.8,
            'style': 0.5,
            'use_speaker_boost': true,
          }
        }),
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        // Salvar áudio temporariamente
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/luma_voice_${DateTime.now().millisecondsSinceEpoch}.mp3');
        await tempFile.writeAsBytes(response.bodyBytes);
        
        // Reproduzir áudio (Windows)
        await _playAudio(tempFile.path);
        
        // Limpar arquivo temporário
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } else {
        throw Exception('Erro na API ElevenLabs: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ElevenLabs: $e');
      rethrow;
    } finally {
      _isSpeaking = false;
    }
  }
  
  /// Reproduz áudio usando AudioPlayer
  Future<void> _playAudio(String filePath) async {
    try {
      print('🔊 Reproduzindo áudio da Luma: ${filePath.split('/').last}');
      
      // Usar o AudioPlayer para reproduzir o arquivo de áudio
      await _audioPlayer.play(DeviceFileSource(filePath));
      
      // Aguardar até o áudio terminar
      await _audioPlayer.onPlayerComplete.first;
      
      print('✅ Áudio da Luma reproduzido com sucesso');
      
    } catch (e) {
      print('❌ Erro ao reproduzir áudio: $e');
      // Fallback: simular reprodução se houver erro
      await Future.delayed(const Duration(seconds: 2));
      throw Exception('Erro ao reproduzir áudio: $e');
    }
  }
  
  /// Para a reprodução atual
  void stop() {
    _isSpeaking = false;
    _audioPlayer.stop();
  }
  
  /// Obter vozes disponíveis
  Future<Map<String, String>> getAvailableVoices() async {
    if (!isConfigured) return {};
    
    try {
      final response = await http.get(
        Uri.parse('${ApiKeys.elevenLabsBaseUrl}/voices'),
        headers: {
          'xi-api-key': ApiKeys.elevenLabsApiKey,
        },
      ).timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final voices = <String, String>{};
        
        for (final voice in data['voices']) {
          voices[voice['name']] = voice['voice_id'];
        }
        
        return voices;
      }
      return {};
    } catch (e) {
      print('❌ Erro ao obter vozes: $e');
      return {};
    }
  }
}
