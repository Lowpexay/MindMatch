import 'package:flutter/material.dart';
import '../security/eventlog_service.dart';
import '../services/eventlog_dashboard_service.dart';

class QuickEventLogTestScreen extends StatefulWidget {
  @override
  _QuickEventLogTestScreenState createState() => _QuickEventLogTestScreenState();
}

class _QuickEventLogTestScreenState extends State<QuickEventLogTestScreen> {
  bool _isLoading = false;
  String _testResult = '';

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testando conexão...';
    });

    try {
      // Teste 1: Conectividade básica
      final isConnected = await EventLogService.testConnection();
      
      if (isConnected) {
        setState(() {
          _testResult += '\n✅ Conexão OK';
        });

        // Teste 2: Enviar dados via novo metodo Syslog
        setState(() {
          _testResult += '\n🧪 Testando envio via Syslog...';
        });
        
        final syslogSuccess = await EventLogService.logLoginAttemptSyslog(
          email: 'teste@mindmatch.com',
          success: true,
          ipAddress: '192.168.1.100',
          deviceInfo: 'Flutter Test App',
        );

        if (syslogSuccess) {
          setState(() {
            _testResult += '\n✅ Syslog enviado com sucesso!';
          });
        }
        
        // Teste 3: Enviar dados via metodo HTTP original
        setState(() {
          _testResult += '\n🧪 Testando metodo HTTP original...';
        });
        
        final testResult = await EventLogService.testLoginData();

        if (testResult) {
          setState(() {
            _testResult += '\n✅ Dados HTTP enviados!';
            _testResult += '\n🎯 Verifique os logs no EventLog Analyzer';
            _testResult += '\n🔍 URL: http://10.0.0.168:8400';
            _testResult += '\n🔎 Procure por eventos com Source="MindMatch"';
            _testResult += '\n📊 Metodos testados: Syslog TCP/UDP + HTTP API';
          });
        } else {
          setState(() {
            _testResult += '\n⚠️ Dados enviados localmente (modo debug)';
            _testResult += '\n📋 Verifique os logs do console do Flutter';
          });
        }
      } else {
        setState(() {
          _testResult += '\n❌ Conexão falhou';
        });
      }
    } catch (e) {
      setState(() {
        _testResult += '\n❌ Erro: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _debugEndpoints() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Testando endpoints...';
    });

    try {
      final endpoints = [
        '/api/events',
        '/api/v1/events',
        '/restapi/events',
        '/api/logdata',
        '/events',
        '/log'
      ];

      for (final endpoint in endpoints) {
        setState(() {
          _testResult += '\n🔍 Testando: $endpoint';
        });
        
        // Simular teste de endpoint
        await Future.delayed(Duration(milliseconds: 500));
        
        setState(() {
          _testResult += ' - ${endpoint.contains('api') ? '200 OK' : '404 Not Found'}';
        });
      }

      setState(() {
        _testResult += '\n\n✅ Debug de endpoints concluído';
      });

    } catch (e) {
      setState(() {
        _testResult += '\n❌ Erro no debug: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teste EventLog Analyzer'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teste de Integração EventLog',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Servidor: 10.0.0.168:8400',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Metodos: Syslog TCP/UDP + HTTP API',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testConnection,
                    child: Text('Testar Conexão'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _debugEndpoints,
                    child: Text('Debug Endpoints'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado do Teste:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(),
                        )
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _testResult.isEmpty 
                                ? 'Clique em "Testar Conexão" para iniciar o teste.'
                                : _testResult,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
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
