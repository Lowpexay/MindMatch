import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/user_avatar.dart';
import '../screens/profile_screen.dart';
import '../utils/app_colors.dart';

class CompatibleUsersWidget extends StatelessWidget {
  final List<Map<String, dynamic>> compatibleUsers;
  final Function(Map<String, dynamic>) onUserTapped;

  const CompatibleUsersWidget({
    super.key,
    required this.compatibleUsers,
    required this.onUserTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            ],
          ),
          const SizedBox(height: 20),
          if (compatibleUsers.isEmpty)
            _buildEmptyState()
          else
            _buildUsersList(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Responda algumas perguntas para encontrar pessoas compatíveis!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Suas respostas ajudam a calcular afinidade com outros usuários.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList(BuildContext context) {
    return Column(
      children: [
        // Top 3 usuários em destaque
        if (compatibleUsers.length >= 3) ...[
          _buildTopThreeUsers(context),
          const SizedBox(height: 20),
          Divider(color: Colors.white12),
          const SizedBox(height: 20),
        ],

        // Lista dos demais usuários
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: AlertDialog(
                      backgroundColor: AppColorsProfile.blackFont,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        'Selecione alguém para conversar!',
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColorsProfile.whiteBack,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: compatibleUsers
                                .skip(3)
                                .map((user) => _buildUserCard(context, user))
                                .toList(),
                          ),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Fechar',
                            style: TextStyle(
                              color: AppColorsProfile.purpleBack,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: AppColors.primary,
              shadowColor: Colors.transparent,
              elevation: 0,
            ),
            child: Text(
              'Ver outras consultas',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColorsProfile.whiteBack,
                  fontSize: 16),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTopThreeUsers(BuildContext context) {
    return Column(
      children: [],
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final name = user['name'] ?? 'Usuário';
    final dataHoraConsulta = '';
    final profileImage = user['profileImageUrl'] as String?;
    final profileImageBase64 = user['profileImageBase64'] as String?;

    // Decodificar base64 com tratamento de erro
    Uint8List? imageBytes;
    if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(profileImageBase64);
        print('✅ Decoded base64 image for $name: ${imageBytes.length} bytes');
      } catch (e) {
        print('❌ Error decoding base64 for $name: $e');
        imageBytes = null;
      }
    } else {
      print('ℹ️ No base64 image for $name');
    }

    print('🎭 Building user card for $name:');
    print('   - profileImageUrl: $profileImage');
    print(
        '   - profileImageBase64: ${profileImageBase64 != null ? '${profileImageBase64.length} chars' : 'null'}');
    print(
        '   - imageBytes: ${imageBytes != null ? '${imageBytes.length} bytes' : 'null'}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onUserTapped(user),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white12,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Avatar com porcentagem
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent, // sua cor desejada
                        shape: BoxShape.circle,
                      ),
                      child: UserAvatar(
                        imageUrl: profileImage,
                        imageBytes: imageBytes,
                        radius: 30,
                      ),
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColorsProfile.blackFont, width: 1.5),
                        ),
                        child: Text(
                          dataHoraConsulta,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Informações do usuário
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome e idade
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white54,
                ),
                // Seta
              ],
            ),
          ),
        ),
      ),
    );
  }
}
