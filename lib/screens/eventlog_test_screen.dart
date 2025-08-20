import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventLogTestWidget extends StatefulWidget {
  @override
  _EventLogTestWidgetState createState() => _EventLogTestWidgetState();
}

class _EventLogTestWidgetState extends State<EventLogTestWidget> {
  String _testResult = 'Clique em "Testar Conexão" para começar';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testando conexão...';
    });

    final baseUrl = 'http://desktop-ne646bh:8400';
    final apiKey = 'mte1zjc3ndktmzdhzs00zwq5ltk5otgtmgzjztgzndm2owu2';

    final headers = {
      'Content-Type': 'application/json',
      'AuthToken': apiKey,
      'Accept': 'application/json',
    };

    final testEndpoints = [
      baseUrl,
      '$baseUrl/event',
      '$baseUrl/event/index2.do',
      '$baseUrl/event/restapi/health',
    ];

    String result = '🔍 TESTE DE CONECTIVIDADE\n\n';

    for (final endpoint in testEndpoints) {
      try {
        result += '📡 Testando: $endpoint\n';
        
        final response = await http.get(
          Uri.parse(endpoint),
          headers: headers,
        ).timeout(const Duration(seconds: 5));

        result += '✅ Status: ${response.statusCode}\n';
        result += '📏 Body: ${response.body.length} chars\n';
        
        if (response.statusCode == 200) {
          result += '🎉 SUCESSO!\n';
        }
        
        result += '\n';
      } catch (e) {
        result += '❌ ERRO: $e\n\n';
      }
    }

    // Teste de log simples
    try {
      result += '📝 Testando envio de log...\n';
      
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'application': 'MindMatch',
        'event_type': 'test_connection',
        'user_id': 'test_user',
        'username': 'test@example.com',
        'success': true,
        'device_info': 'test_device',
        'eventid': 9999,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/event/restapi/logdata'),
        headers: headers,
        body: jsonEncode(logData),
      ).timeout(const Duration(seconds: 10));

      result += '📤 Log Status: ${response.statusCode}\n';
      result += '📥 Response: ${response.body}\n';

    } catch (e) {
      result += '❌ Log Error: $e\n';
    }

    result += '\n💡 PRÓXIMOS PASSOS:\n';
    result += '• Se todos falharam: Verificar se EventLog está rodando\n';
    result += '• Se 200 OK: Configuração está correta!\n';
    result += '• Se timeout: Problema de firewall/rede\n';

    setState(() {
      _testResult = result;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste EventLog Analyzer'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading 
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.wifi_find),
              label: Text(_isLoading ? 'Testando...' : 'Testar Conexão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
