import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

class CrpValidationResult {
  final String registration;
  final String status;
  final String? name;
  final String? regional;

  const CrpValidationResult({
    required this.registration,
    required this.status,
    this.name,
    this.regional,
  });

  bool get isActive => status.toUpperCase().trim() == 'ATIVO';
}

class CrpValidationException implements Exception {
  final String message;
  const CrpValidationException(this.message);

  @override
  String toString() => message;
}

/// Consulta diretamente o endpoint público usado pelo Cadastro Nacional do CFP.
///
/// Esta opção não exige token nem backend pago. Como o endpoint público pode
/// mudar ou aplicar CAPTCHA/bloqueios, a URL permanece configurável.
class CrpValidationService {
  static const _mode = String.fromEnvironment(
    'CFP_VALIDATION_MODE',
    defaultValue: 'direct',
  );

  static const _cfpApiUrl = String.fromEnvironment(
    'CFP_API_URL',
    defaultValue: 'https://cn-api.cfp.org.br/psi/busca',
  );
  static const _localScraperUrl = String.fromEnvironment(
    'CRP_LOCAL_SCRAPER_URL',
    defaultValue: 'http://127.0.0.1:3000/validate-crp',
  );

  Future<CrpValidationResult> validate(String rawCrp) async {
    final crp = _normalize(rawCrp);
    if (crp == null) {
      throw const CrpValidationException(
        'Informe um CRP válido no formato NN/1234, NN/12345 ou NN/123456.',
      );
    }

    if (_mode == 'mock') {
      developer.log('Modo mock; CRP de teste recebido.', name: 'CrpValidation');
      return _mockValidate(crp);
    }

    if (_mode == 'local_scrape') return _validateWithLocalScraper(crp);

    developer.log(
      'Iniciando consulta direta ao CFP para a regional ${crp.substring(0, 2)}.',
      name: 'CrpValidation',
    );

    late final http.Response response;
    try {
      response = await http
          .get(Uri.parse(_cfpApiUrl).replace(queryParameters: {
            'nome': '',
            'regiao': int.parse(crp.substring(0, 2)).toString(),
            'registro': crp.substring(3),
            'cpf': '',
            'recaptchaToken': '',
          }))
          .timeout(const Duration(seconds: 12));
    } on TimeoutException catch (error, stackTrace) {
      developer.log('Timeout na consulta ao CFP.', name: 'CrpValidation', error: error, stackTrace: stackTrace);
      throw const CrpValidationException(
        'O CFP demorou para responder. Tente novamente.',
      );
    } on http.ClientException catch (error, stackTrace) {
      developer.log('Falha de conexão com o CFP.', name: 'CrpValidation', error: error, stackTrace: stackTrace);
      throw const CrpValidationException(
        'Não foi possível conectar ao cadastro do CFP agora.',
      );
    }

    developer.log(
      'Resposta do CFP: HTTP ${response.statusCode}, ${response.body.length} bytes.',
      name: 'CrpValidation',
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 422) {
        throw const CrpValidationException(
          'O CFP rejeitou os parâmetros da consulta (o cadastro público pode exigir CAPTCHA).',
        );
      }
      if (response.statusCode == 400 || response.statusCode == 403) {
        throw const CrpValidationException(
          'O CFP recusou a consulta (possível CAPTCHA ou bloqueio temporário).',
        );
      }
      throw CrpValidationException(
        'Não foi possível consultar o cadastro do CFP agora (HTTP ${response.statusCode}). Tente novamente.',
      );
    }

    final body = jsonDecode(response.body);
    final result = _findMatchingResult(body, crp);
    if (result == null) {
      throw const CrpValidationException(
        'CRP não encontrado ou não está ativo no cadastro do CFP.',
      );
    }

    final status = _readString(result, const ['situacao', 'status']) ?? '';
    if (status.toUpperCase() != 'ATIVO') {
      throw CrpValidationException(
        'O CRP informado está com situação "$status" no CFP.',
      );
    }

    return CrpValidationResult(
      registration: _readString(result, const [
            'registro',
            'registration',
            'numeroRegistro',
            'numero_registro',
          ]) ??
          crp,
      status: status,
      name: _readString(result, const ['nome', 'name']),
      regional: _readString(result, const ['nome_regional', 'regional']),
    );
  }

  Future<CrpValidationResult> _validateWithLocalScraper(String crp) async {
    developer.log('Consultando scraper local.', name: 'CrpValidation');
    try {
      final response = await http
          .post(
            Uri.parse(_localScraperUrl),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'crp': crp}),
          )
          .timeout(const Duration(seconds: 90));
      final body = jsonDecode(response.body);
      if (response.statusCode == 409 && body is Map) {
        throw CrpValidationException(body['message']?.toString() ?? 'CAPTCHA necessário no navegador local.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300 || body is! Map || body['exists'] != true) {
        throw const CrpValidationException('CRP não encontrado no cadastro do CFP.');
      }
      return CrpValidationResult(
        registration: body['registration']?.toString() ?? crp,
        status: body['status']?.toString() ?? 'ATIVO',
        name: body['name']?.toString(),
        regional: body['regional']?.toString(),
      );
    } on TimeoutException {
      throw const CrpValidationException('A consulta local demorou. Verifique o navegador do CFP.');
    } on http.ClientException {
      throw const CrpValidationException('Não foi possível conectar ao scraper local.');
    }
  }

  CrpValidationResult _mockValidate(String crp) {
    // Fixture local para demonstração acadêmica. Não representa uma consulta
    // online e não deve ser usado para liberar profissionais em produção.
    if (crp != '05/80177') {
      throw const CrpValidationException(
        'CRP de teste não encontrado. Use 05/80177 no modo simulação.',
      );
    }

    return const CrpValidationResult(
      registration: '05/80177',
      status: 'ATIVO',
      name: 'Profissional de teste',
      regional: 'CRP 05 - Rio de Janeiro',
    );
  }

  Map<String, dynamic>? _findMatchingResult(dynamic value, String crp) {
    if (value is Map<String, dynamic>) {
      final registration = _readString(value, const [
        'registro',
        'registration',
        'numeroRegistro',
        'numero_registro',
      ]);
      if (registration != null && _normalize(registration) == crp) return value;
      for (final child in value.values) {
        final match = _findMatchingResult(child, crp);
        if (match != null) return match;
      }
    } else if (value is List) {
      for (final child in value) {
        final match = _findMatchingResult(child, crp);
        if (match != null) return match;
      }
    }
    return null;
  }

  String? _readString(Map<String, dynamic> value, List<String> keys) {
    for (final key in keys) {
      final item = value[key]?.toString().trim();
      if (item != null && item.isNotEmpty) return item;
    }
    return null;
  }

  String? _normalize(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    // O tamanho do registro varia entre as regionais: há números com quatro,
    // cinco ou seis dígitos depois do código regional.
    if (!RegExp(r'^\d{6,8}$').hasMatch(digits)) return null;
    return '${digits.substring(0, 2)}/${digits.substring(2)}';
  }
}
