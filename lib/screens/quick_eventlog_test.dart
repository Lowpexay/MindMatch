import 'package:flutter/material.dart';
import '../security/eventlog_service.dart';

class QuickEventLogTest extends StatefulWidget {
  const QuickEventLogTest({super.key});

  @override
  State<QuickEventLogTest> createState() => _QuickEventLogTestState();
}

class _QuickEventLogTestState extends State<QuickEventLogTest> {
  String _testResult = '';
  bool _isLoading = false;

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

        // Teste 2: Enviar log de teste
        final logSent = await EventLogService.logLoginAttempt(
          userId: 'test_user_123',
          userName: 'test@mindmatch.com',
          deviceInfo: 'flutter_test_device',
          isSuccessful: true,
          ipAddress: '192.168.15.3',
          userAgent: 'MindMatch/1.0.0 Flutter Test',
        );

        if (logSent) {
          setState(() {
            _testResult += '\n✅ Log enviado com sucesso!';
            _testResult += '\n📤 Verifique no EventLog Analyzer';
          });
        } else {
          setState(() {
            _testResult += '\n❌ Falha ao enviar log';
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
      final results = await EventLogService.debugConnection();
      
      setState(() {
        _testResult = 'Resultados dos testes:\n';
        results.forEach((endpoint, result) {
          final status = result['status'];
          final success = result['success'] ?? false;
          final icon = success ? '✅' : '❌';
          _testResult += '\n$icon $endpoint -> $status';
        });
      });
    } catch (e) {
      setState(() {
        _testResult = 'Erro no debug: $e';
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
        title: const Text('Teste EventLog Analyzer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuração EventLog',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Servidor: desktop-ne646bh:8400'),
                    Text('API Key: mte1***...'),
                    Text('Status: Pronto para teste'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: const Icon(Icons.wifi_protected_setup),
              label: const Text('Testar Conexão + Enviar Log'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _debugEndpoints,
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug Endpoints'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resultado do Teste',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              _testResult.isEmpty 
                                ? 'Clique em um botão para testar'
                                : _testResult,
                              style: const TextStyle(fontFamily: 'monospace'),
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
