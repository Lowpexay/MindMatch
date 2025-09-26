import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
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
