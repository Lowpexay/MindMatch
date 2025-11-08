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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : Colors.white;
    final textPrimary = isDark ? Colors.white : AppColors.textPrimary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Pessoas com mais afinidade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Top 3 usuários em destaque
        if (compatibleUsers.length >= 3) ...[
          _buildTopThreeUsers(context),
          const SizedBox(height: 20),
          Divider(color: isDark ? Colors.white12 : null),
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
                      backgroundColor: isDark ? AppColorsProfile.blackFont : AppColorsProfile.whiteBack,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        'Selecione alguém para conversar!',
                        style: TextStyle(
                          fontSize: 17,
                          color:  isDark? AppColorsProfile.whiteBack : AppColorsProfile.blackFont,
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
              backgroundColor: AppColorsProfile.purpleBack,
              shadowColor: Colors.transparent,
              elevation: 0,
            ),
            child: Text(
              'Conhecer outros usuários',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColorsProfile.whiteBack,
                fontSize: 16
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTopThreeUsers(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final top3 = compatibleUsers.take(3).toList();

    return Column(
      children: [
        Text(
          '🏆 Top 3 Compatibilidades',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 2º lugar
            if (top3.length > 1)
              _buildPodiumUser(top3[1], 2, Colors.grey[400]!, context),

            // 1º lugar
            _buildPodiumUser(top3[0], 1, Colors.amber, context),

            // 3º lugar
            if (top3.length > 2)
              _buildPodiumUser(top3[2], 3, Colors.brown[300]!, context),
          ],
        ),
      ],
    );
  }

  Widget _buildPodiumUser(Map<String, dynamic> user, int position, Color medalColor, BuildContext context) {
    final compatibility = user['compatibility'] as double;
    final name = user['name'] ?? 'Usuário';
    final profileImage = user['profileImageUrl'] as String?;
    final profileImageBase64 = user['profileImageBase64'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Decodificar base64 com tratamento de erro
    Uint8List? imageBytes;
    if (profileImageBase64 != null && profileImageBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(profileImageBase64);
      print('✅ Decoded podium base64 image for $name: ${imageBytes.length} bytes');
      } catch (e) {
        print('❌ Error decoding podium base64 for $name: $e');
        imageBytes = null;
      }
    } else {
      print('ℹ️ No base64 image for podium user $name');
    }

    print('🏆 Building podium user $position for $name:');
    print('   - profileImageUrl: $profileImage');
    print(
        '   - profileImageBase64: ${profileImageBase64 != null ? '${profileImageBase64.length} chars' : 'null'}');
    print(
        '   - imageBytes: ${imageBytes != null ? '${imageBytes.length} bytes' : 'null'}');

    return GestureDetector(
      onTap: () => onUserTapped(user),
      child: Column(
        children: [
          // Medal
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: position == 1 ? 80 : 70,
                height: position == 1 ? 80 : 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: medalColor,
                    width: 3,
                  ),
                ),
                child: UserAvatar(
                  imageUrl: profileImage,
                  imageBytes: imageBytes,
                  radius: position == 1 ? 35 : 30,
                  // no fallback asset; use default icon when missing
                ),
              ),
              Positioned(
                bottom: -5,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: medalColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Nome
          SizedBox(
            width: 80,
            child: Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),

          // Porcentagem
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${compatibility.toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final compatibility = user['compatibility'] as double;
    final name = user['name'] ?? 'Usuário';
    final age = user['age'] as int?;
    final city = user['city'] as String?;
    final profileImage = user['profileImageUrl'] as String?;
    final profileImageBase64 = user['profileImageBase64'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

    // Parse tags
    final tags = <String>[];
    final tagsString = user['tags_string'] as String?;
    if (tagsString != null && tagsString.isNotEmpty) {
      tags.addAll(tagsString.split(',').take(3));
    }

    // Determinar emoção predominante baseada no humor
    final predominantEmotion = _getPredominantEmotion(user);

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
                  color: isDark ? AppColors.darkSurface : AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white12 : AppColors.gray200,
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
                            color: _getCompatibilityColor(compatibility),
                            borderRadius: BorderRadius.circular(10),
                          border: Border.all(color:isDark ? AppColorsProfile.blackFont : Colors.white, width: 1.5),
                          ),
                          child: Text(
                            '${compatibility.toInt()}%',
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
                                color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (age != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '$age anos',
                                style: TextStyle(
                                  fontSize: 14,
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                            ],
                          ],
                        ),

                        // Cidade
                        if (city != null && city.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                              color: isDark ? Colors.white70 : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                city,
                                style: TextStyle(
                                  fontSize: 12,
                                color: isDark ? Colors.white70 : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Emoção predominante
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              predominantEmotion['icon'],
                              size: 16,
                              color: predominantEmotion['color'],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${predominantEmotion['emotion']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: predominantEmotion['color'],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      // // Bio
                        // if (bio != null && bio.isNotEmpty) ...[
                        //   const SizedBox(height: 4),
                        //   Text(
                        //     bio,
                        //     maxLines: 1,
                        //     overflow: TextOverflow.ellipsis,
                        //     style: TextStyle(
                        //       fontSize: 12,
                      //       color: AppColors.textSecondary,
                        //     ),
                        //   ),
                        // ],

                      // // Tags
                      // if (tags.isNotEmpty) ...[
                      //   const SizedBox(height: 8),
                      //   Wrap(
                      //     spacing: 4,
                      //     children: tags
                      //         .map((tag) => Container(
                      //               padding: const EdgeInsets.symmetric(
                      //                   horizontal: 8, vertical: 2),
                      //               decoration: BoxDecoration(
                      //                 color: AppColors.primary.withOpacity(0.1),
                      //                 borderRadius: BorderRadius.circular(8),
                      //               ),
                      //               child: Text(
                      //                 tag,
                      //                 style: TextStyle(
                      //                   fontSize: 10,
                      //                   color: AppColors.primary,
                      //                   fontWeight: FontWeight.w500,
                      //                 ),
                      //               ),
                      //             ))
                      //         .toList(),
                      //   ),
                      // ],
                      ],
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                  ),
                // Seta
              ],
              ),
          ),
        ),
      ),
    );
  }

  Color _getCompatibilityColor(double compatibility) {
    if (compatibility >= 80) return Colors.green;
    if (compatibility >= 60) return Colors.orange;
    if (compatibility >= 40) return Colors.amber;
    return Colors.red;
  }

  // Determina a emoção predominante do usuário com base no humor
  Map<String, dynamic> _getPredominantEmotion(Map<String, dynamic> user) {
    // Simular dados de humor - em produção viria do Firebase
    final happiness = (user['happiness'] as int?) ?? 5;
    final energy = (user['energy'] as int?) ?? 5;
    final clarity = (user['clarity'] as int?) ?? 5;
    final stress = (user['stress'] as int?) ?? 5;

    // Calcular scores
    final positiveScore = ((happiness + energy + clarity) / 3);
    final negativeScore = stress.toDouble();

    String emotion;
    IconData icon;
    Color color;

    if (positiveScore >= 7 && negativeScore <= 3) {
      emotion = 'Radiante';
      icon = Icons.sentiment_very_satisfied;
      color = Colors.green;
    } else if (positiveScore >= 6 && negativeScore <= 4) {
      emotion = 'Animado';
      icon = Icons.sentiment_satisfied;
      color = Colors.lightGreen;
    } else if (positiveScore >= 5 && negativeScore <= 5) {
      emotion = 'Equilibrado';
      icon = Icons.sentiment_neutral;
      color = Colors.orange;
    } else if (positiveScore >= 4 && negativeScore <= 6) {
      emotion = 'Pensativo';
      icon = Icons.sentiment_dissatisfied;
      color = Colors.amber;
    } else if (negativeScore >= 7) {
      emotion = 'Estressado';
      icon = Icons.sentiment_very_dissatisfied;
      color = Colors.red;
    } else {
      emotion = 'Sereno';
      icon = Icons.sentiment_neutral;
      color = Colors.blue;
    }

    return {
      'emotion': emotion,
      'icon': icon,
      'color': color,
    };
  }
}
