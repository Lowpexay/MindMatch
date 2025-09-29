import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';

/// Tela pública de perfil acessada a partir de um chat (informações básicas, interesses, objetivo, botão para iniciar chat já oculto pois já estamos em um).
class UserPublicProfileScreen extends StatelessWidget {
  final String userId;
  const UserPublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firebase = Provider.of<FirebaseService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream: firebase.getUserProfileStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Perfil não encontrado'));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final name = (data['name'] ?? 'Usuário').toString();
          final age = data['age'];
          final city = data['city'];
          final bio = (data['bio'] ?? '').toString();
          final goal = (data['goal'] ?? '').toString();
            final tags = (data['interests'] as List?)?.cast<String>() ?? <String>[];
          final base64Img = data['profileImageBase64'] as String?;
          Uint8List? bytes;
          if (base64Img != null && base64Img.isNotEmpty) {
            try { bytes = base64Decode(base64Img); } catch (_) {}
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  backgroundImage: bytes != null ? MemoryImage(bytes) : null,
                  child: bytes == null ? const Icon(Icons.person, size: 60, color: AppColors.primary) : null,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              if (age != null) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '$age anos',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
              if (city != null && (city as String).isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: isDark ? Colors.white54 : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      city,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (bio.isNotEmpty) _section(
                context,
                title: 'Sobre',
                child: Text(bio, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textPrimary, height: 1.5)),
              ),
              if (goal.isNotEmpty) _section(
                context,
                title: 'Objetivo',
                child: Text(goal, style: TextStyle(color: isDark ? Colors.white70 : AppColors.primary, fontWeight: FontWeight.w500)),
              ),
              if (tags.isNotEmpty) _section(
                context,
                title: 'Interesses',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? AppColors.primary.withOpacity(0.4) : AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Text(t, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : AppColors.primary, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 32),
              // Placeholder para futuras ações (denunciar, adicionar amigo, etc.)
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, {required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}