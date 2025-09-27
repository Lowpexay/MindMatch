import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/user_avatar.dart';

// Legacy static colors (fallback); dynamic theme now preferred
class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
  static const Color blackFont = Color(0xFF262626);
  static const Color lightGreyFont = Color(0xFFcac9c9);
  static const Color lighterGreyBack = Color.fromARGB(255, 240, 239, 239);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final user = auth.currentUser;

    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: scheme.onPrimary,
          tooltip: 'Voltar',
          onPressed: () {
            context.go('/home');
          },
        ),
        title: Text('Perfil', style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            color: scheme.onPrimary,
            onPressed: () => context.push('/profileEdit'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            color: scheme.onPrimary,
            tooltip: 'Configurações',
            onPressed: () => context.push('/settings'),
          ),
        ],
        centerTitle: true,
        backgroundColor: scheme.primary,
      ),
      body: user == null
          ? const Center(child: Text('Usuário não autenticado'))
          : StreamBuilder(
              stream: firebaseService.getUserProfileStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final data = (snapshot.data as dynamic).data() as Map<String, dynamic>? ?? {};

                final name = data['name'] ?? user.displayName ?? '';
                final email = data['email'] ?? user.email ?? '';
                final city = data['city'] ?? '';
                final bio = data['bio'] ?? '';
                final tagsString = data['tags_string'] ?? '';
                final goal = data['goal'] ?? '';
                final profileImageUrl = data['profileImageUrl'] ?? '';
                final profileImageBase64 = data['profileImageBase64'] ?? '';
                final Uint8List? profileImageBytes = profileImageBase64 is String && profileImageBase64.isNotEmpty ? base64Decode(profileImageBase64) : null;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.3,
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 0.8,
                          heightFactor: 0.8,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              UserAvatar(
                                imageUrl: profileImageUrl != null && profileImageUrl.isNotEmpty ? profileImageUrl : null,
                                imageBytes: profileImageBytes,
                                radius: 50,
                              ),
                              Text(name, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: scheme.onPrimary)),
                              Text(data['birthdate'] != null ? '${_ageFromBirthdate(data['birthdate'])} Anos' : '', style: TextStyle(fontSize: 20, color: scheme.onPrimary)),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.location_on, color: scheme.onPrimary, size: 15),
                                const SizedBox(width: 6),
                                Text(city, style: TextStyle(fontSize: 15, color: scheme.onPrimary)),
                              ])
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(30),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          DadoPerfil(dado: email, label: 'E-mail:', icon: Icons.email_outlined),
                          const SizedBox(height: 25),
                          DadoPerfil(dado: bio, label: 'Bio:', icon: Icons.chat_outlined),
                          const SizedBox(height: 25),
                          DadoPerfil(dado: data['instagram'] ?? '', label: 'Instagram:', icon: Icons.camera_alt_outlined),
                          const SizedBox(height: 25),
                          DadoPerfil(dado: data['twitter'] ?? '', label: 'Twitter:', icon: Icons.wifi_tethering_outlined),
                          const SizedBox(height: 25),
                          Text('Interesses', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: (tagsString as String).isNotEmpty
                                ? tagsString.split(',').map((t) => InteressesLabel(dado: t)).toList()
                                : [],
                          ),
                          const SizedBox(height: 25),
                          Text('Objetivo', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(12),
                            height: 50,
                            decoration: BoxDecoration(
                              color: scheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: scheme.outline.withOpacity(0.3)),
                              boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [Text('🤝', style: TextStyle(color: scheme.primary, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Text(goal ?? '', style: TextStyle(color: scheme.onSurface))]),
                          )
                        ]),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }

  static int _ageFromBirthdate(dynamic birthdate) {
    try {
      if (birthdate is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(birthdate);
        final diff = DateTime.now().difference(dt);
        return (diff.inDays / 365).floor();
      }
    } catch (_) {}
    return 0;
  }
}

class DadoPerfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final String dado;

  const DadoPerfil({Key? key, required this.icon, required this.label, required this.dado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, color: Theme.of(context).colorScheme.primary), const SizedBox(width: 8), Text(label, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16))]),
      const SizedBox(height: 8),
      Text(dado, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18))
    ]);
  }
}

class InteressesLabel extends StatelessWidget {
  final String dado;

  const InteressesLabel({Key? key, required this.dado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: scheme.outline.withOpacity(0.4))),
      child: Text('#$dado', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}
