import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import '../services/fcm_service.dart';

class FcmDebugScreen extends StatefulWidget {
  const FcmDebugScreen({super.key});

  @override
  State<FcmDebugScreen> createState() => _FcmDebugScreenState();
}

class _FcmDebugScreenState extends State<FcmDebugScreen> {
  String? _token;
  String _log = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
    FirebaseMessaging.onMessage.listen((m) {
      setState(() {
        _log = '[FG] ${DateTime.now()}: ${m.messageId} data=${m.data} notifTitle=${m.notification?.title}\n' + _log;
      });
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) {
      setState(() {
        _log = '[OPEN] ${DateTime.now()}: ${m.messageId} data=${m.data}\n' + _log;
      });
    });
  }

  Future<void> _load() async {
    try {
      final t = await FirebaseMessaging.instance.getToken();
      setState(() => _token = t);
    } catch (e) {
      setState(() => _log = '[ERRO] getToken: $e\n' + _log);
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _loading = true);
    await FcmService.instance.saveCurrentToken();
    await _load();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _refreshToken,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('Token FCM:', style: Theme.of(context).textTheme.titleMedium),
            SelectableText(_token ?? 'Carregando...'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _token == null
                      ? null
                      : () {
                          if (_token != null) {
                            Clipboard.setData(ClipboardData(text: _token!));
                          }
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token copiado')));
                        },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar'),
                ),
                ElevatedButton.icon(
                  onPressed: _loading ? null : _refreshToken,
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar novamente'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final settings = await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
                    setState(() {
                      _log = '[PERMISSION] status=${settings.authorizationStatus}\n' + _log;
                    });
                  },
                  icon: const Icon(Icons.security),
                  label: const Text('Pedir permissão'),
                ),
              ],
            ),
            const Divider(height: 32),
            Text('Logs de mensagens:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                _log.isEmpty ? 'Nenhuma mensagem recebida ainda.' : _log,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            const SizedBox(height: 24),
            Text('Como testar rápido:', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('1. Copie o token.\n2. No console > Cloud Messaging > Enviar mensagem > Teste > Cole o token.\n3. Envie notificações de título e texto simples.\n4. Veja se aparece aqui log [FG] ou no sistema.'),
          ],
        ),
      ),
    );
  }
}
