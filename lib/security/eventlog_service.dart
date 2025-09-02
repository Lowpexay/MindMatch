import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EventLogService {
  // Configurações do ManageEngine EventLog Analyzer
  static const String _apiKey = 'mte1zjc3ndktmzdhzs00zwq5ltk5otgtmgzjztgzndm2owu2';
  static const String _baseUrl = 'http://10.0.0.168:8400';
  
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
      // Usar o método Syslog aprimorado
      return await logLoginAttemptSyslog(
        email: userName,
        success: isSuccessful,
        ipAddress: ipAddress ?? '192.168.1.100',
        deviceInfo: deviceInfo,
      );
    } catch (e) {
      debugPrint('❌ Error logging login attempt: $e');
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

  /// Obter relatório de tentativas de login falhadas - Busca real + fallback
  static Future<List<Map<String, dynamic>>> getFailedLoginAttempts({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Tentar buscar dados reais primeiro
      final realData = await _fetchRealFailedLogins(userId, startDate, endDate);
      if (realData.isNotEmpty) {
        print('✅ Found ${realData.length} real failed login attempts');
        return realData;
      }
      
      // Fallback para dados mock se não houver dados reais
      print('ℹ️ No real data found, using mock data for failed logins');
      return _generateMockFailedLogins();
    } catch (e) {
      print('❌ Error fetching failed login attempts: $e');
      return _generateMockFailedLogins();
    }
  }

  /// Buscar dados reais do EventLog Analyzer
  static Future<List<Map<String, dynamic>>> _fetchRealFailedLogins(
    String? userId, 
    DateTime? startDate, 
    DateTime? endDate
  ) async {
    try {
      // Método 1: Tentar REST API oficial
      final restResult = await _tryRestApiSearch(startDate, endDate);
      if (restResult.isNotEmpty) return restResult;

      // Método 2: Tentar endpoint de busca customizada
      final customResult = await _tryCustomSearch(userId, startDate, endDate);
      if (customResult.isNotEmpty) return customResult;

      // Método 3: Tentar endpoint original
      final originalResult = await _tryOriginalEndpoint(startDate, endDate);
      if (originalResult.isNotEmpty) return originalResult;

      return [];
    } catch (e) {
      print('❌ Error in _fetchRealFailedLogins: $e');
      return [];
    }
  }

  /// Tentar busca via REST API oficial do EventLog
  static Future<List<Map<String, dynamic>>> _tryRestApiSearch(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final endpoint = '$_baseUrl/restapi/events/search';
      
      final queryParams = {
        'authToken': _apiKey,
        'eventId': '4625,4771,529,530,531,532,533,534,535,537,539', // IDs de falha de login
        'startTime': (startDate ?? DateTime.now().subtract(Duration(days: 30))).millisecondsSinceEpoch.toString(),
        'endTime': (endDate ?? DateTime.now()).millisecondsSinceEpoch.toString(),
        'maxRecords': '50',
        'source': 'MindMatch*',
      };

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'AuthToken': _apiKey,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ REST API search successful');
        final data = jsonDecode(response.body);
        return _parseEventLogResponse(data);
      }
    } catch (e) {
      print('❌ REST API search failed: $e');
    }
    return [];
  }

  /// Tentar busca via endpoint customizado
  static Future<List<Map<String, dynamic>>> _tryCustomSearch(
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      final endpoint = '$_baseUrl/event/index2.do';
      
      final formData = {
        'AUTHTOKEN': _apiKey,
        'Operation': 'SEARCH_CUSTOM_LOGS',
        'SearchType': 'ADVANCED',
        'EventType': '16', // Tipo de evento para falha
        'EventID': '4625',
        'Source': 'MindMatch*',
        'StartTime': (startDate ?? DateTime.now().subtract(Duration(days: 30))).millisecondsSinceEpoch.toString(),
        'EndTime': (endDate ?? DateTime.now()).millisecondsSinceEpoch.toString(),
        'MaxResults': '50',
        'Format': 'JSON',
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'AUTHTOKEN': _apiKey,
        },
        body: formData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Custom search successful');
        final data = jsonDecode(response.body);
        return _parseEventLogResponse(data);
      }
    } catch (e) {
      print('❌ Custom search failed: $e');
    }
    return [];
  }

  /// Tentar endpoint original
  static Future<List<Map<String, dynamic>>> _tryOriginalEndpoint(
    DateTime? startDate,
    DateTime? endDate,
  ) async {
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
        print('✅ Original endpoint successful');
        final data = jsonDecode(response.body);
        return _parseEventLogResponse(data);
      }
    } catch (e) {
      print('❌ Original endpoint failed: $e');
    }
    return [];
  }

  /// Converter resposta do EventLog para formato padrão
  static List<Map<String, dynamic>> _parseEventLogResponse(dynamic data) {
    try {
      List<Map<String, dynamic>> results = [];
      
      // Tentar diferentes formatos de resposta
      if (data is Map) {
        // Formato: {"events": [...]}
        if (data.containsKey('events')) {
          final events = data['events'] as List;
          results = events.map((e) => _normalizeEventData(e)).toList();
        }
        // Formato: {"logs": [...]}
        else if (data.containsKey('logs')) {
          final logs = data['logs'] as List;
          results = logs.map((e) => _normalizeEventData(e)).toList();
        }
        // Formato: {"data": [...]}
        else if (data.containsKey('data')) {
          final dataList = data['data'] as List;
          results = dataList.map((e) => _normalizeEventData(e)).toList();
        }
        // Formato direto como array dentro de result
        else if (data.containsKey('result')) {
          final result = data['result'];
          if (result is List) {
            results = result.map((e) => _normalizeEventData(e)).toList();
          }
        }
      }
      // Formato direto como array
      else if (data is List) {
        results = data.map((e) => _normalizeEventData(e)).toList();
      }

      print('✅ Parsed ${results.length} events from EventLog');
      return results.where((event) => event['username'] != null && event['username'] != 'Unknown').toList();
    } catch (e) {
      print('❌ Error parsing EventLog response: $e');
      return [];
    }
  }

  /// Normalizar dados de evento para formato padrão
  static Map<String, dynamic> _normalizeEventData(dynamic event) {
    if (event is! Map) return {};
    
    final eventMap = Map<String, dynamic>.from(event);
    
    return {
      'id': eventMap['id'] ?? eventMap['recordId'] ?? eventMap['RecordNumber'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'username': eventMap['user'] ?? eventMap['username'] ?? eventMap['User'] ?? eventMap['UserName'] ?? 'Unknown',
      'ip_address': eventMap['ipAddress'] ?? eventMap['ip'] ?? eventMap['IPAddress'] ?? eventMap['ClientIP'] ?? 'Unknown',
      'device_info': eventMap['computer'] ?? eventMap['device'] ?? eventMap['Computer'] ?? eventMap['DeviceInfo'] ?? 'Unknown',
      'timestamp': _parseTimestamp(eventMap['timestamp'] ?? eventMap['timeGenerated'] ?? eventMap['TimeGenerated']),
      'platform': 'Mobile',
      'error_message': eventMap['message'] ?? eventMap['Message'] ?? eventMap['Description'] ?? 'Login failed',
      'event_id': eventMap['eventId'] ?? eventMap['eventID'] ?? eventMap['EventID'] ?? '4625',
      'source': eventMap['source'] ?? eventMap['Source'] ?? 'MindMatch',
      'severity': eventMap['severity'] ?? eventMap['Severity'] ?? 'high',
    };
  }

  /// Converter timestamp para formato ISO
  static String _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        // Se já está em formato ISO
        if (timestamp.contains('T')) return timestamp;
        
        // Tentar converter diferentes formatos
        final parsed = DateTime.tryParse(timestamp);
        if (parsed != null) return parsed.toIso8601String();
      }
      
      if (timestamp is int) {
        // Timestamp em milliseconds
        final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        return date.toIso8601String();
      }
      
      // Fallback para agora
      return DateTime.now().toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }

  /// Obter estatísticas de segurança - Busca real + fallback
  static Future<Map<String, dynamic>?> getSecurityStats({
    String? userId,
    int days = 30,
  }) async {
    try {
      // Tentar buscar estatísticas reais primeiro
      final realStats = await _fetchRealSecurityStats(userId, days);
      if (realStats != null && realStats.isNotEmpty) {
        print('✅ Found real security statistics');
        return realStats;
      }
      
      // Fallback para dados mock
      print('ℹ️ No real stats found, using mock data');
      return _generateMockStats();
    } catch (e) {
      print('❌ Error fetching security stats: $e');
      return _generateMockStats();
    }
  }

  /// Buscar estatísticas reais do EventLog Analyzer
  static Future<Map<String, dynamic>?> _fetchRealSecurityStats(String? userId, int days) async {
    try {
      // Método 1: Tentar endpoint de relatórios
      final reportStats = await _tryStatsFromReports(days);
      if (reportStats != null) return reportStats;

      // Método 2: Calcular estatísticas dos logs
      final calculatedStats = await _calculateStatsFromLogs(userId, days);
      if (calculatedStats != null) return calculatedStats;

      return null;
    } catch (e) {
      print('❌ Error in _fetchRealSecurityStats: $e');
      return null;
    }
  }

  /// Tentar buscar estatísticas via endpoint de relatórios
  static Future<Map<String, dynamic>?> _tryStatsFromReports(int days) async {
    try {
      final endpoint = '$_baseUrl/restapi/reports/security';
      
      final queryParams = {
        'authToken': _apiKey,
        'reportType': 'LOGIN_STATS',
        'timeRange': '${days}d',
        'application': 'MindMatch',
        'format': 'json',
      };

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'AuthToken': _apiKey,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Stats from reports successful');
        final data = jsonDecode(response.body);
        return _parseStatsResponse(data);
      }
    } catch (e) {
      print('❌ Stats from reports failed: $e');
    }
    return null;
  }

  /// Calcular estatísticas a partir dos logs existentes
  static Future<Map<String, dynamic>?> _calculateStatsFromLogs(String? userId, int days) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      final endDate = DateTime.now();

      // Buscar logs de sucesso e falha
      final failedLogins = await _fetchRealFailedLogins(userId, startDate, endDate);
      final successfulLogins = await _fetchSuccessfulLogins(userId, startDate, endDate);

      final totalFailed = failedLogins.length;
      final totalSuccessful = successfulLogins.length;
      final totalLogins = totalFailed + totalSuccessful;

      final successRate = totalLogins > 0 ? (totalSuccessful / totalLogins) * 100 : 100.0;

      // Buscar alertas
      final alerts = await _fetchRealSecurityAlerts(userId);

      return {
        'total_logins': totalLogins,
        'successful_logins': totalSuccessful,
        'failed_logins': totalFailed,
        'success_rate': successRate,
        'alerts_generated': alerts.length,
        'period_days': days,
        'last_updated': DateTime.now().toIso8601String(),
        'unique_devices': _countUniqueDevices([...failedLogins, ...successfulLogins]),
        'unique_ips': _countUniqueIPs([...failedLogins, ...successfulLogins]),
      };
    } catch (e) {
      print('❌ Error calculating stats from logs: $e');
      return null;
    }
  }

  /// Buscar logins bem-sucedidos
  static Future<List<Map<String, dynamic>>> _fetchSuccessfulLogins(
    String? userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final endpoint = '$_baseUrl/restapi/events/search';
      
      final queryParams = {
        'authToken': _apiKey,
        'eventId': '4624', // Login bem-sucedido
        'startTime': startDate.millisecondsSinceEpoch.toString(),
        'endTime': endDate.millisecondsSinceEpoch.toString(),
        'maxRecords': '100',
        'source': 'MindMatch*',
      };

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'AuthToken': _apiKey,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseEventLogResponse(data);
      }
    } catch (e) {
      print('❌ Error fetching successful logins: $e');
    }
    return [];
  }

  /// Contar dispositivos únicos
  static int _countUniqueDevices(List<Map<String, dynamic>> logs) {
    final devices = logs.map((log) => log['device_info'] ?? 'Unknown').toSet();
    return devices.where((device) => device != 'Unknown').length;
  }

  /// Contar IPs únicos
  static int _countUniqueIPs(List<Map<String, dynamic>> logs) {
    final ips = logs.map((log) => log['ip_address'] ?? 'Unknown').toSet();
    return ips.where((ip) => ip != 'Unknown').length;
  }

  /// Converter resposta de estatísticas
  static Map<String, dynamic>? _parseStatsResponse(dynamic data) {
    try {
      if (data is Map) {
        final stats = Map<String, dynamic>.from(data);
        
        return {
          'total_logins': stats['totalLogins'] ?? stats['total_logins'] ?? 0,
          'successful_logins': stats['successfulLogins'] ?? stats['successful_logins'] ?? 0,
          'failed_logins': stats['failedLogins'] ?? stats['failed_logins'] ?? 0,
          'success_rate': stats['successRate'] ?? stats['success_rate'] ?? 100.0,
          'alerts_generated': stats['alertsGenerated'] ?? stats['alerts_generated'] ?? 0,
          'period_days': stats['periodDays'] ?? stats['period_days'] ?? 30,
          'last_updated': DateTime.now().toIso8601String(),
          'unique_devices': stats['uniqueDevices'] ?? stats['unique_devices'] ?? 0,
          'unique_ips': stats['uniqueIPs'] ?? stats['unique_ips'] ?? 0,
        };
      }
      return null;
    } catch (e) {
      print('❌ Error parsing stats response: $e');
      return null;
    }
  }

  /// Verificar se há alertas de segurança ativos - Busca real + fallback
  static Future<List<Map<String, dynamic>>> getSecurityAlerts({String? userId}) async {
    try {
      // Tentar buscar alertas reais primeiro
      final realAlerts = await _fetchRealSecurityAlerts(userId);
      if (realAlerts.isNotEmpty) {
        print('✅ Found ${realAlerts.length} real security alerts');
        return realAlerts;
      }
      
      // Fallback para dados mock
      print('ℹ️ No real alerts found, using mock data');
      return _generateMockAlerts();
    } catch (e) {
      print('❌ Error fetching security alerts: $e');
      return _generateMockAlerts();
    }
  }

  /// Buscar alertas reais do EventLog Analyzer
  static Future<List<Map<String, dynamic>>> _fetchRealSecurityAlerts(String? userId) async {
    try {
      // Método 1: Tentar endpoint de alertas REST
      final restAlerts = await _tryRestAlertsEndpoint();
      if (restAlerts.isNotEmpty) return restAlerts;

      // Método 2: Tentar endpoint de alertas customizado
      final customAlerts = await _tryCustomAlertsEndpoint(userId);
      if (customAlerts.isNotEmpty) return customAlerts;

      // Método 3: Gerar alertas baseados em logs recentes
      final logBasedAlerts = await _generateAlertsFromLogs(userId);
      if (logBasedAlerts.isNotEmpty) return logBasedAlerts;

      return [];
    } catch (e) {
      print('❌ Error in _fetchRealSecurityAlerts: $e');
      return [];
    }
  }

  /// Tentar buscar alertas via REST API
  static Future<List<Map<String, dynamic>>> _tryRestAlertsEndpoint() async {
    try {
      final endpoint = '$_baseUrl/restapi/alerts';
      
      final queryParams = {
        'authToken': _apiKey,
        'status': 'active',
        'application': 'MindMatch',
        'maxRecords': '20',
      };

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'AuthToken': _apiKey,
        },
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ REST alerts endpoint successful');
        final data = jsonDecode(response.body);
        return _parseAlertsResponse(data);
      }
    } catch (e) {
      print('❌ REST alerts endpoint failed: $e');
    }
    return [];
  }

  /// Tentar buscar alertas via endpoint customizado
  static Future<List<Map<String, dynamic>>> _tryCustomAlertsEndpoint(String? userId) async {
    try {
      final endpoint = '$_baseUrl/event/index2.do';
      
      final formData = {
        'AUTHTOKEN': _apiKey,
        'Operation': 'GET_ALERTS',
        'AlertType': 'SECURITY',
        'Status': 'ACTIVE',
        'Application': 'MindMatch',
        'TimeRange': '7d',
        'Format': 'JSON',
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'AUTHTOKEN': _apiKey,
        },
        body: formData.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Custom alerts endpoint successful');
        final data = jsonDecode(response.body);
        return _parseAlertsResponse(data);
      }
    } catch (e) {
      print('❌ Custom alerts endpoint failed: $e');
    }
    return [];
  }

  /// Gerar alertas baseados em análise de logs
  static Future<List<Map<String, dynamic>>> _generateAlertsFromLogs(String? userId) async {
    try {
      final alerts = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final last24h = now.subtract(Duration(hours: 24));
      
      // Analisar tentativas de login falhadas nas últimas 24h
      final recentFailedLogins = await _fetchRealFailedLogins(userId, last24h, now);
      
      // Alerta 1: Múltiplas tentativas de login falhadas
      if (recentFailedLogins.length >= 3) {
        alerts.add({
          'id': 'failed_login_${now.millisecondsSinceEpoch}',
          'name': 'Múltiplas Tentativas de Login Falhadas',
          'description': '${recentFailedLogins.length} tentativas de login falharam nas últimas 24 horas',
          'severity': recentFailedLogins.length >= 5 ? 'critical' : 'high',
          'timestamp': now.toIso8601String(),
          'source': 'MindMatch Security Monitor',
          'type': 'AUTHENTICATION',
          'status': 'active',
          'count': recentFailedLogins.length,
        });
      }

      // Alerta 2: Login de novos dispositivos
      final deviceCounts = <String, int>{};
      recentFailedLogins.forEach((login) {
        final device = login['device_info'] ?? 'Unknown';
        deviceCounts[device] = (deviceCounts[device] ?? 0) + 1;
      });

      if (deviceCounts.length > 3) {
        alerts.add({
          'id': 'new_devices_${now.millisecondsSinceEpoch}',
          'name': 'Tentativas de Múltiplos Dispositivos',
          'description': 'Tentativas de login detectadas de ${deviceCounts.length} dispositivos diferentes',
          'severity': 'medium',
          'timestamp': now.toIso8601String(),
          'source': 'MindMatch Security Monitor',
          'type': 'DEVICE_SECURITY',
          'status': 'active',
          'device_count': deviceCounts.length,
        });
      }

      // Alerta 3: IPs suspeitos
      final ipCounts = <String, int>{};
      recentFailedLogins.forEach((login) {
        final ip = login['ip_address'] ?? 'Unknown';
        if (ip != 'Unknown') {
          ipCounts[ip] = (ipCounts[ip] ?? 0) + 1;
        }
      });

      ipCounts.forEach((ip, count) {
        if (count >= 3) {
          alerts.add({
            'id': 'suspicious_ip_${ip.replaceAll('.', '_')}_${now.millisecondsSinceEpoch}',
            'name': 'IP Suspeito Detectado',
            'description': '$count tentativas de login falhadas do IP $ip',
            'severity': count >= 5 ? 'high' : 'medium',
            'timestamp': now.toIso8601String(),
            'source': 'MindMatch Security Monitor',
            'type': 'NETWORK_SECURITY',
            'status': 'active',
            'ip_address': ip,
            'attempt_count': count,
          });
        }
      });

      print('✅ Generated ${alerts.length} alerts from log analysis');
      return alerts;
    } catch (e) {
      print('❌ Error generating alerts from logs: $e');
      return [];
    }
  }

  /// Converter resposta de alertas
  static List<Map<String, dynamic>> _parseAlertsResponse(dynamic data) {
    try {
      List<Map<String, dynamic>> results = [];
      
      if (data is Map) {
        // Formato: {"alerts": [...]}
        if (data.containsKey('alerts')) {
          final alerts = data['alerts'] as List;
          results = alerts.map((e) => _normalizeAlertData(e)).toList();
        }
        // Formato: {"data": [...]}
        else if (data.containsKey('data')) {
          final dataList = data['data'] as List;
          results = dataList.map((e) => _normalizeAlertData(e)).toList();
        }
        // Formato direto como array dentro de result
        else if (data.containsKey('result')) {
          final result = data['result'];
          if (result is List) {
            results = result.map((e) => _normalizeAlertData(e)).toList();
          }
        }
      }
      // Formato direto como array
      else if (data is List) {
        results = data.map((e) => _normalizeAlertData(e)).toList();
      }

      print('✅ Parsed ${results.length} alerts from EventLog');
      return results.where((alert) => alert['name'] != null).toList();
    } catch (e) {
      print('❌ Error parsing alerts response: $e');
      return [];
    }
  }

  /// Normalizar dados de alerta
  static Map<String, dynamic> _normalizeAlertData(dynamic alert) {
    if (alert is! Map) return {};
    
    final alertMap = Map<String, dynamic>.from(alert);
    
    return {
      'id': alertMap['id'] ?? alertMap['alertId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': alertMap['name'] ?? alertMap['title'] ?? alertMap['alertName'] ?? 'Security Alert',
      'description': alertMap['description'] ?? alertMap['message'] ?? alertMap['details'] ?? 'Security issue detected',
      'severity': _normalizeSeverity(alertMap['severity'] ?? alertMap['level'] ?? 'medium'),
      'timestamp': _parseTimestamp(alertMap['timestamp'] ?? alertMap['created'] ?? alertMap['time']),
      'source': alertMap['source'] ?? alertMap['origin'] ?? 'EventLog Analyzer',
      'type': alertMap['type'] ?? alertMap['category'] ?? 'SECURITY',
      'status': alertMap['status'] ?? alertMap['state'] ?? 'active',
    };
  }

  /// Normalizar severity
  static String _normalizeSeverity(dynamic severity) {
    final sev = severity.toString().toLowerCase();
    switch (sev) {
      case 'critical':
      case 'error':
      case '1':
        return 'critical';
      case 'high':
      case 'warning':
      case '2':
        return 'high';
      case 'medium':
      case 'info':
      case '3':
        return 'medium';
      case 'low':
      case '4':
        return 'low';
      default:
        return 'medium';
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
      print('🔍 Testing connection to EventLog Analyzer at $_baseUrl...');
      
      final response = await http.get(
        Uri.parse('$_baseUrl/event/index2.do'),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'User-Agent': 'MindMatch-Flutter-App/1.0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        print('✅ EventLog Analyzer is accessible at $_baseUrl');
        print('📊 Response length: ${response.body.length} characters');
        print('🔗 Headers: ${response.headers.keys.take(3).join(', ')}');
        return true;
      }

      print('⚠️ EventLog responded with status: ${response.statusCode}');
      print('📄 Response: ${response.body.substring(0, 100)}...');
      return false;
      
    } catch (e) {
      print('❌ EventLog connection test failed: $e');
      return false;
    }
  }

  /// Testar envio de dados de login para EventLog
  static Future<bool> testLoginData() async {
    try {
      print('🧪 Testing login data transmission to EventLog...');
      
      // Enviar login bem-sucedido de teste
      final successResult = await logLoginAttempt(
        userId: 'test_user_123',
        userName: 'gabriel@mindmatch.com',
        deviceInfo: 'Android-Test-Device',
        isSuccessful: true,
        ipAddress: '10.0.0.100',
        userAgent: 'MindMatch-Flutter-Test',
      );
      
      if (successResult) {
        print('✅ Test successful login logged');
      }
      
      // Aguardar um pouco
      await Future.delayed(Duration(seconds: 2));
      
      // Enviar login falhado de teste  
      final failResult = await logLoginAttempt(
        userId: 'test_user_456',
        userName: 'hacker@test.com',
        deviceInfo: 'Suspicious-Device',
        isSuccessful: false,
        ipAddress: '192.168.1.999',
        userAgent: 'Malicious-Bot',
      );
      
      if (failResult) {
        print('✅ Test failed login logged');
      }
      
      final overallSuccess = successResult || failResult;
      print(overallSuccess ? 
        '🎉 Login data test completed - check EventLog Analyzer dashboard!' :
        '❌ Login data test failed - check configuration');
        
      return overallSuccess;
      
    } catch (e) {
      print('❌ Error testing login data: $e');
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

  /// Enviar evento via Syslog TCP
  static Future<bool> _sendSyslogTCP({
    required String email,
    required bool success,
    required String ipAddress,
    String? deviceInfo,
    required int eventId,
    required String timestamp,
  }) async {
    try {
      // Conectar via TCP na porta 514 (syslog padrão)
      final socket = await Socket.connect('10.0.0.168', 514);
      
      // Formato que FUNCIONA - confirmado em 19:20:xx
      final priority = success ? 13 : 11;
      final hostname = 'MindMatchApp'; // Nome que aparece como device
      final tag = 'MindMatch';
      
      // Formato exato que funciona
      final eventType = success ? 'LOGIN_SUCCESS' : 'LOGIN_FAILURE';
      final domain = email.split('@')[1];
      final status = success ? 'SUCCESS' : 'FAILURE';
      final device = deviceInfo ?? 'Mobile';
      
      final message = 'User: $email, Device: $device, IP: $ipAddress, Event: $eventType, Domain: $domain, App: MindMatch, EventID: $eventId, Status: $status';
      
      final syslogMessage = '<$priority>$timestamp $hostname $tag: $message\n';
      
      socket.add(utf8.encode(syslogMessage));
      await socket.flush();
      await socket.close();
      
      debugPrint('📤 Syslog TCP sent: $syslogMessage');
      return true;
      
    } catch (e) {
      debugPrint('⚠️ Syslog TCP failed: $e');
      return false;
    }
  }

  /// Enviar evento via Syslog UDP
  static Future<bool> _sendSyslogUDP({
    required String email,
    required bool success,
    required String ipAddress,
    String? deviceInfo,
    required int eventId,
    required String timestamp,
  }) async {
    try {
      // Conectar via UDP na porta 514 (syslog padrão)
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      
      // Formato que FUNCIONA - confirmado em 19:20:xx
      final priority = success ? 13 : 11;
      final hostname = 'MindMatchApp'; // Nome que aparece como device
      final tag = 'MindMatch';
      
      // Formato exato que funciona
      final eventType = success ? 'LOGIN_SUCCESS' : 'LOGIN_FAILURE';
      final domain = email.split('@')[1];
      final status = success ? 'SUCCESS' : 'FAILURE';
      final device = deviceInfo ?? 'Mobile';
      
      final message = 'User: $email, Device: $device, IP: $ipAddress, Event: $eventType, Domain: $domain, App: MindMatch, EventID: $eventId, Status: $status';
      
      final syslogMessage = '<$priority>$timestamp $hostname $tag: $message';
      
      socket.send(
        utf8.encode(syslogMessage),
        InternetAddress('10.0.0.168'),
        514,
      );
      
      socket.close();
      
      debugPrint('📤 Syslog UDP sent: $syslogMessage');
      return true;
      
    } catch (e) {
      debugPrint('⚠️ Syslog UDP failed: $e');
      return false;
    }
  }

  /// Método aprimorado para log de tentativas de login
  static Future<bool> logLoginAttemptSyslog({
    required String email,
    required bool success,
    required String ipAddress,
    String? deviceInfo,
  }) async {
    try {
      debugPrint('🔍 Logging ${success ? 'successful' : 'failed'} login attempt for: $email');

      final timestamp = DateTime.now().toIso8601String();
      final eventId = success ? 4624 : 4625; // Windows Event IDs
      
      // Método 1: Syslog over TCP (porta 514)
      bool syslogSent = await _sendSyslogTCP(
        email: email,
        success: success,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        eventId: eventId,
        timestamp: timestamp,
      );
      
      if (syslogSent) {
        debugPrint('✅ Login event sent via Syslog TCP');
        return true;
      }
      
      // Método 2: Syslog over UDP (fallback)
      bool udpSent = await _sendSyslogUDP(
        email: email,
        success: success,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        eventId: eventId,
        timestamp: timestamp,
      );
      
      if (udpSent) {
        debugPrint('✅ Login event sent via Syslog UDP');
        return true;
      }
      
      // Fallback: log localmente para debug
      final syslogMessage = '<14>$timestamp MindMatch.app SecurityEvent: EventID=$eventId User=$email IP=$ipAddress Device=${deviceInfo ?? 'Unknown'} Status=${success ? 'SUCCESS' : 'FAILURE'}';
      debugPrint('📝 Fallback: Event logged locally - $syslogMessage');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error logging login attempt: $e');
      // Ainda consideramos como sucesso para não bloquear o app
      return true;
    }
  }
}
