import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/telegram_service.dart';
import 'main_navigation.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool? _telegramConnected;
  bool _telegramLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTelegramStatus();
  }

  Future<void> _loadTelegramStatus() async {
    try {
      final connected = await TelegramService.instance.isConnected();
      if (mounted) setState(() => _telegramConnected = connected);
    } catch (_) {
      if (mounted) setState(() => _telegramConnected = false);
    }
  }

  Future<void> _connectTelegram() async {
    setState(() => _telegramLoading = true);
    try {
      await TelegramService.instance.connect();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abra o Telegram e toque em Iniciar no bot MindMatch.')),
        );
      }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _telegramLoading = false);
    }
  }

  Future<void> _disconnectTelegram() async {
    setState(() => _telegramLoading = true);
    try {
      await TelegramService.instance.disconnect();
      if (mounted) setState(() => _telegramConnected = false);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _telegramLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Voltar para a tela anterior usando Navigator ou MainNavigation
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Se não houver pilha, voltar para a aba de Perfil (índice 3)
              final mainNav = MainNavigation.mainNavigationKey.currentState;
              if (mainNav != null) {
                mainNav.switchToTab(3); // Aba do Perfil
              } else {
                context.go('/');
              }
            }
          },
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile.adaptive(
            title: const Text('Tema Escuro'),
            subtitle: const Text('Ativar/desativar tema escuro'),
            value: themeService.isDark,
            onChanged: (v) => themeService.setDark(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.send, color: Color(0xFF229ED9)),
            title: const Text('Notificações pelo Telegram'),
            subtitle: Text(_telegramConnected == true
                ? 'Telegram conectado para lembretes de consultas'
                : 'Conecte o Telegram para receber lembretes'),
            trailing: _telegramLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : _telegramConnected == true
                    ? TextButton(onPressed: _disconnectTelegram, child: const Text('Desconectar'))
                    : TextButton(onPressed: _connectTelegram, child: const Text('Conectar')),
            onTap: _telegramConnected == true ? null : _connectTelegram,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Deletar Conta'),
            subtitle: const Text('Remove sua conta e todos os dados'),
            textColor: Colors.red,
            onTap: () => _confirmDeleteAccount(context),
          ),
          const Divider(),
          const ListTile(
            title: Text('Versão'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deletar conta?'),
        content: const Text('Esta ação é irreversível e removerá seus dados do MindMatch.'),
        actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx); // fecha dialogo
                await _deleteAccount(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Deletar'),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firebase = Provider.of<FirebaseService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      // Delete Firestore user doc and related simple data (best-effort)
      try {
        await firebase.deleteUserData(user.uid);
      } catch (e) {
        debugPrint('Non-fatal: error deleting user data: $e');
      }

      await user.delete();
      messenger.showSnackBar(const SnackBar(content: Text('Conta deletada')));
      if (context.mounted) context.go('/login');
    } catch (e) {
      debugPrint('Delete account error: $e');
      messenger.showSnackBar(const SnackBar(content: Text('Falha ao deletar conta. Talvez reautenticar.')));
    }
  }
}
