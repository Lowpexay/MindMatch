import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class TelegramService {
  TelegramService._();
  static final instance = TelegramService._();

  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = await user?.getIdToken();
    if (token == null) throw Exception('Usuário não autenticado.');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      // Needed when the local backend is exposed through ngrok Free.
      'ngrok-skip-browser-warning': 'true',
    };
  }

  Future<bool> isConnected() async {
    final response = await http.get(
      Uri.parse('$backendUrl/telegram/status'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception(_error(response));
    return jsonDecode(response.body)['connected'] == true;
  }

  Future<void> connect() async {
    final response = await http.post(
      Uri.parse('$backendUrl/telegram/link-token'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception(_error(response));

    final url = Uri.parse(jsonDecode(response.body)['url'].toString());
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o Telegram.');
    }
  }

  Future<void> disconnect() async {
    final response = await http.post(
      Uri.parse('$backendUrl/telegram/disconnect'),
      headers: await _headers(),
    );
    if (response.statusCode != 200) throw Exception(_error(response));
  }

  Future<void> notifyConsultationCreated({
    required String consultationId,
    required String patientId,
    required String psychologistId,
    required String patientName,
    required int date,
    required String hour,
    required String modality,
  }) async {
    final response = await http.post(
      Uri.parse('$backendUrl/telegram/consultation-created'),
      headers: await _headers(),
      body: jsonEncode({
        'consultationId': consultationId,
        'idPatient': patientId,
        'idPsychologist': psychologistId,
        'patientName': patientName,
        'date': date,
        'hour': hour,
        'modality': modality,
      }),
    );
    if (response.statusCode != 200) throw Exception(_error(response));
  }

  String _error(http.Response response) {
    try {
      return jsonDecode(response.body)['error']?.toString() ?? 'Erro no backend.';
    } catch (_) {
      return 'Erro no backend (${response.statusCode}).';
    }
  }
}
