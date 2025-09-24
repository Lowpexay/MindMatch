import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import '../utils/scaffold_utils.dart';
import 'gemini_service.dart';

/// Serviço real de captura de áudio + transcrição com Gemini
class SpeechRecognitionService {
  static final SpeechRecognitionService _instance = SpeechRecognitionService._internal();
  factory SpeechRecognitionService() => _instance;
  SpeechRecognitionService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastWords = '';
  Timer? _recordingTimer;

  // Callbacks
  Function(String)? onResult;
  Function(String)? onPartialResult; // Não suportado por gravação pura
  Function(String)? onError;
  Function()? onListeningStart;
  Function()? onListeningStop;

  // Serviços
  final GeminiService _gemini = GeminiService();

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        ScaffoldUtils.showErrorSnackBar('Permissão de microfone negada');
        return false;
      }
      _isInitialized = true;
      return true;
    } catch (e) {
      onError?.call('Erro ao inicializar áudio: $e');
      return false;
    }
  }

  Future<bool> startListening({
    String localeId = 'pt_BR',
    Duration? listenFor,
    Duration? pauseFor,
  }) async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) return false;
    }
    if (_isListening) return false;

    try {
      _isListening = true;
      onListeningStart?.call();

      // Gravar em arquivo temporário no formato WAV (maior compatibilidade)
      final tempDir = Directory.systemTemp;
      final filePath = '${tempDir.path}/mindmatch_rec_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          bitRate: 256000,
        ),
        path: filePath,
      );

      // Parar automaticamente após listenFor
      if (listenFor != null) {
        _recordingTimer = Timer(listenFor, () => stopListening());
      }

      return true;
    } catch (e) {
      onError?.call('Erro ao iniciar gravação: $e');
      _isListening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    try {
      final path = await _recorder.stop();
      _recordingTimer?.cancel();
      _isListening = false;
      onListeningStop?.call();

      if (path == null) {
        onError?.call('Nenhum arquivo gerado');
        return;
      }

      final file = File(path);
      final bytes = await file.readAsBytes();

      // Enviar para Gemini transcrever
      final transcript = await _gemini.transcribeAudio(
        audioBytes: bytes,
        mimeType: 'audio/wav',
      );

      _lastWords = transcript;
      onResult?.call(transcript);

      // Limpar arquivo temp
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      onError?.call('Erro ao finalizar gravação: $e');
    }
  }

  Future<void> cancelListening() async {
    if (!_isListening) return;
    try {
      await _recorder.cancel();
      _recordingTimer?.cancel();
      _isListening = false;
      onListeningStop?.call();
    } catch (e) {
      onError?.call('Erro ao cancelar gravação: $e');
    }
  }

  static Future<bool> isAvailable() async {
    try {
      final r = AudioRecorder();
      return await r.hasPermission();
    } catch (_) {
      return false;
    }
  }

  String getDefaultLocale() => 'pt_BR';

  void dispose() {
    _recordingTimer?.cancel();
    _isInitialized = false;
    _isListening = false;
    onResult = null;
    onPartialResult = null;
    onError = null;
    onListeningStart = null;
    onListeningStop = null;
  }
}