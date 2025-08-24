import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
  static const Color blackFont = Color(0xFF262626);
  static const Color lightGreyFont = Color(0xFFcac9c9);
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          color: AppColorsProfile.whiteBack,
          tooltip: 'Voltar',
          onPressed: () {
            context.go('/home');
          },
        ),
        title: Text('Perfil', style: TextStyle(color: AppColorsProfile.whiteBack, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            color: AppColorsProfile.whiteBack,
            onPressed: () => context.push('/profileEdit'),
          )
        ],
        centerTitle: true,
        backgroundColor: AppColorsProfile.purpleBack,
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

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.3,
                        decoration: const BoxDecoration(
                          color: AppColorsProfile.purpleBack,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: 0.8,
                          heightFactor: 0.8,
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : const AssetImage('assets/images/luma_chat_avatar.png') as ImageProvider,
                              ),
                              Text(name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColorsProfile.whiteBack)),
                              Text(data['birthdate'] != null ? '${_ageFromBirthdate(data['birthdate'])} Anos' : '', style: const TextStyle(fontSize: 20, color: AppColorsProfile.whiteBack)),
                              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.location_on, color: AppColorsProfile.whiteBack, size: 15),
                                const SizedBox(width: 6),
                                Text(city, style: const TextStyle(fontSize: 15, color: AppColorsProfile.whiteBack)),
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
                          const Text('Interesses', style: TextStyle(color: AppColorsProfile.purpleBack, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: (tagsString as String).isNotEmpty
                                ? (tagsString as String).split(',').map((t) => InteressesLabel(dado: t)).toList()
                                : [],
                          ),
                          const SizedBox(height: 25),
                          const Text('Objetivo', style: TextStyle(color: AppColorsProfile.purpleBack, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(12),
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColorsProfile.whiteBack,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColorsProfile.lightGreyFont),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Row(children: [const Text('🤝', style: TextStyle(color: AppColorsProfile.blackFont, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(width: 8), Text(goal ?? '')]),
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
      Row(children: [Icon(icon, color: AppColorsProfile.purpleBack), const SizedBox(width: 8), Text(label, style: const TextStyle(color: AppColorsProfile.purpleBack, fontWeight: FontWeight.bold, fontSize: 16))]),
      const SizedBox(height: 8),
      Text(dado, style: const TextStyle(color: AppColorsProfile.blackFont, fontWeight: FontWeight.bold, fontSize: 18))
    ]);
  }
}

class InteressesLabel extends StatelessWidget {
  final String dado;

  const InteressesLabel({Key? key, required this.dado}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColorsProfile.lightGreyFont)),
      child: Text('#$dado', style: const TextStyle(color: AppColorsProfile.blackFont, fontWeight: FontWeight.w600)),
    );
  }
}
