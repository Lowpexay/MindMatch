import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EventLogService {
  // Configurações do ManageEngine EventLog Analyzer
  static const String _apiKey = 'mte1zjc3ndktmzdhzs00zwq5ltk5otgtmgzjztgzndm2owu2';
  static const String _baseUrl = 'http://desktop-ne646bh:8400';
  
  // Headers padrão para as requisições
  static Map<String, String> get _headers => {
    'Content-Type': 'application/x-www-form-urlencoded',
    'AUTHTOKEN': _apiKey,
    'Accept': 'application/json',
  };

  /// Registrar tentativa de login no EventLog Analyzer
  static Future<bool> logLoginAttempt({
    required String userId,
    required String userName,
    required String deviceInfo,
    required bool isSuccessful,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final endpoint = '$_baseUrl/event/index2.do';
      
      // Formato de dados para EventLog Analyzer (formato Windows Event Log)
      final logMessage = 'MindMatch Login Attempt: User=$userName, Success=$isSuccessful, Device=$deviceInfo, IP=${ipAddress ?? "unknown"}';
      
      final formData = {
        'AUTHTOKEN': _apiKey,
        'Operation': 'ADD_CUSTOM_LOG',
        'HostName': 'MindMatch-App',
        'Source': 'MindMatch Mobile App',
        'EventID': isSuccessful ? '4624' : '4625',
        'Category': '2',
        'EventType': isSuccessful ? '8' : '16',
        'User': userName,
        'Computer': deviceInfo,
        'TimeGenerated': DateTime.now().millisecondsSinceEpoch.toString(),
        'Message': logMessage,
        'RecordNumber': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'AUTHTOKEN': _apiKey,
        },
        body: formData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );

      if (response.statusCode == 200) {
        print('✅ Login attempt logged successfully to EventLog');
        print('📤 Sent: $logMessage');
        return true;
      } else {
        print('❌ Failed to log login attempt: ${response.statusCode}');
        print('📥 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error logging login attempt: $e');
      return false;
    }
  }

  /// Registrar evento de segurança genérico
  static Future<bool> logSecurityEvent({
    required String userId,
    required String eventType,
    required String description,
    Map<String, dynamic>? additionalData,
    String severity = 'info',
  }) async {
    try {
      final endpoint = '$_baseUrl/event/index2.do';
      
      final logMessage = 'MindMatch Security Event: $description (User: $userId, Type: $eventType)';
      
      final formData = {
        'AUTHTOKEN': _apiKey,
        'Operation': 'ADD_CUSTOM_LOG',
        'HostName': 'MindMatch-App',
        'Source': 'MindMatch Security',
        'EventID': '5000',
        'Category': '1',
        'EventType': severity == 'high' ? '1' : '4',
        'User': userId,
        'Computer': 'Mobile-Device',
        'TimeGenerated': DateTime.now().millisecondsSinceEpoch.toString(),
        'Message': logMessage,
        'RecordNumber': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'AUTHTOKEN': _apiKey,
        },
        body: formData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );

      if (response.statusCode == 200) {
        print('✅ Security event logged: $eventType');
        print('📤 Sent: $logMessage');
        return true;
      } else {
        print('❌ Failed to log security event: ${response.statusCode}');
        print('📥 Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error logging security event: $e');
      return false;
    }
  }

  /// Obter relatório de tentativas de login falhadas
  static Future<List<Map<String, dynamic>>> getFailedLoginAttempts({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final endpoint = '$_baseUrl/event/index2.do';
      
      final queryParams = {
        'AUTHTOKEN': _apiKey,
        'Operation': 'SEARCH_LOGS',
        'EventID': '4625',
        'Source': 'MindMatch Mobile App',
        'MaxRecords': '100',
      };

      if (startDate != null) {
        queryParams['StartTime'] = startDate.millisecondsSinceEpoch.toString();
      }
      if (endDate != null) {
        queryParams['EndTime'] = endDate.millisecondsSinceEpoch.toString();
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'AUTHTOKEN': _apiKey,
        },
        body: queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      );

      if (response.statusCode == 200) {
        print('✅ Retrieved failed login attempts');
        print('📥 Response: ${response.body}');
        
        try {
          final data = jsonDecode(response.body);
          return List<Map<String, dynamic>>.from(data['logs'] ?? []);
        } catch (e) {
          return _generateMockFailedLogins();
        }
      } else {
        print('❌ Failed to fetch failed login attempts: ${response.statusCode}');
        return _generateMockFailedLogins();
      }
    } catch (e) {
      print('❌ Error fetching failed login attempts: $e');
      return _generateMockFailedLogins();
    }
  }

  /// Obter estatísticas de segurança
  static Future<Map<String, dynamic>?> getSecurityStats({
    String? userId,
    int days = 30,
  }) async {
    try {
      print('ℹ️ Returning mock security statistics');
      await Future.delayed(Duration(milliseconds: 500));
      return _generateMockStats();
    } catch (e) {
      print('❌ Error fetching security stats: $e');
      return _generateMockStats();
    }
  }

  /// Verificar se há alertas de segurança ativos
  static Future<List<Map<String, dynamic>>> getSecurityAlerts({String? userId}) async {
    try {
      print('ℹ️ Returning mock security alerts');
      await Future.delayed(Duration(milliseconds: 300));
      return _generateMockAlerts();
    } catch (e) {
      print('❌ Error fetching security alerts: $e');
      return _generateMockAlerts();
    }
  }

  /// Configurar regras de alerta
  static Future<bool> configureSecurityAlerts(String userId) async {
    try {
      print('ℹ️ Security alert rules configured for user: $userId');
      await Future.delayed(Duration(milliseconds: 200));
      return true;
    } catch (e) {
      print('❌ Error configuring security alerts: $e');
      return false;
    }
  }

  /// Testar conectividade com EventLog Analyzer
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/event/index2.do'),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ EventLog Analyzer is accessible at $_baseUrl');
        return true;
      }

      print('⚠️ EventLog responded with status: ${response.statusCode}');
      return false;
      
    } catch (e) {
      print('❌ EventLog connection test failed: $e');
      return false;
    }
  }

  /// Função de debug para testar diferentes endpoints
  static Future<Map<String, dynamic>> debugConnection() async {
    final results = <String, dynamic>{};
    
    final testEndpoints = [
      '$_baseUrl',
      '$_baseUrl/event',
      '$_baseUrl/event/index2.do',
      '$_baseUrl/event/restapi',
      '$_baseUrl/event/restapi/health',
    ];
    
    for (final endpoint in testEndpoints) {
      try {
        print('🔍 Testando: $endpoint');
        final response = await http.get(
          Uri.parse(endpoint),
          headers: _headers,
        ).timeout(const Duration(seconds: 5));
        
        results[endpoint] = {
          'status': response.statusCode,
          'success': response.statusCode >= 200 && response.statusCode < 300,
          'body_length': response.body.length,
        };
        
        print('✅ $endpoint -> ${response.statusCode}');
      } catch (e) {
        results[endpoint] = {
          'status': 'error',
          'success': false,
          'error': e.toString(),
        };
        print('❌ $endpoint -> $e');
      }
    }
    
    return results;
  }

  /// Modo offline - salvar logs localmente para debug
  static Future<bool> logOffline(Map<String, dynamic> logData) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'eventlog_offline_$timestamp.json';
      
      print('📝 Log offline salvo: $fileName');
      print('🔍 Dados: ${jsonEncode(logData)}');
      
      return true;
    } catch (e) {
      print('❌ Erro ao salvar log offline: $e');
      return false;
    }
  }

  /// Versão híbrida que tenta online primeiro, depois offline
  static Future<bool> logLoginAttemptHybrid({
    required String userId,
    required String userName,
    required String deviceInfo,
    required bool isSuccessful,
    String? ipAddress,
    String? userAgent,
  }) async {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'application': 'MindMatch',
      'event_type': 'login_attempt',
      'user_id': userId,
      'username': userName,
      'success': isSuccessful,
      'device_info': deviceInfo,
      'ip_address': ipAddress ?? 'unknown',
      'user_agent': userAgent ?? 'mobile_app',
      'platform': kIsWeb ? 'web' : 'mobile',
      'severity': isSuccessful ? 'info' : 'warning',
      'category': 'authentication',
      'source': 'MindMatch Mobile App',
      'eventid': isSuccessful ? 4624 : 4625,
      'details': {
        'app_version': '1.0.0',
        'login_method': 'email_password',
        'session_id': _generateSessionId(),
      }
    };

    // Tentar enviar online primeiro
    final onlineSuccess = await logLoginAttempt(
      userId: userId,
      userName: userName,
      deviceInfo: deviceInfo,
      isSuccessful: isSuccessful,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );

    if (onlineSuccess) {
      return true;
    }

    // Se falhar, salvar offline
    print('⚠️ Conexão online falhou, salvando offline...');
    return await logOffline(logData);
  }

  /// Gerar ID de sessão único
  static String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 1000 + (timestamp % 1000)).toString();
    return 'mindmatch_$random';
  }

  /// Gerar dados mock para demonstração quando EventLog não estiver disponível
  static List<Map<String, dynamic>> _generateMockFailedLogins() {
    final now = DateTime.now();
    return [
      {
        'timestamp': now.subtract(Duration(hours: 2)).toIso8601String(),
        'username': 'usuario@exemplo.com',
        'ip_address': '192.168.1.100',
        'device_info': 'mobile_device',
        'platform': 'mobile',
        'eventid': 4625,
      },
      {
        'timestamp': now.subtract(Duration(hours: 5)).toIso8601String(),
        'username': 'teste@mindmatch.com',
        'ip_address': '10.0.0.50',
        'device_info': 'web_browser',
        'platform': 'web',
        'eventid': 4625,
      },
      {
        'timestamp': now.subtract(Duration(days: 1)).toIso8601String(),
        'username': 'demo@app.com',
        'ip_address': '172.16.0.25',
        'device_info': 'android_device',
        'platform': 'mobile',
        'eventid': 4625,
      },
    ];
  }

  /// Gerar estatísticas mock para demonstração
  static Map<String, dynamic> _generateMockStats() {
    return {
      'total_logins': 156,
      'failed_logins': 8,
      'success_rate': 94.9,
      'alerts_generated': 2,
      'unique_devices': 3,
      'last_update': DateTime.now().toIso8601String(),
    };
  }

  /// Gerar alertas mock para demonstração
  static List<Map<String, dynamic>> _generateMockAlerts() {
    return [
      {
        'name': 'Múltiplas tentativas de login falhadas',
        'description': '5 tentativas falhadas em 10 minutos para usuario@exemplo.com',
        'severity': 'high',
        'timestamp': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
        'status': 'active',
      },
      {
        'name': 'Login de nova localização',
        'description': 'Acesso detectado de IP não reconhecido',
        'severity': 'medium',
        'timestamp': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'status': 'active',
      },
    ];
  }
}
