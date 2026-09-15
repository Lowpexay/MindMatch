import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
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
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final user = auth.currentUser;

    return Scaffold(
      body: user == null
          ? const Center(child: Text('Usuário não autenticado'))
          : StreamBuilder(
              stream: firebaseService.getUserProfileStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Erro: ${snapshot.error}'));
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final data = (snapshot.data as dynamic).data()
                        as Map<String, dynamic>? ??
                    {};
                final logData = Map<String, dynamic>.from(data)
                  ..remove('profileImageBase64');
                debugPrint(
                  '[ProfileScreen] Retorno do Firebase para $user.uid: $logData',
                );

                final name = _value(data['name'], user.displayName, 'Usuário');
                final email = _value(data['email'], user.email);
                final city = _value(data['city']);
                final profileImageUrl = _value(data['profileImageUrl']);
                final profileImageBase64 = _value(data['profileImageBase64']);
                final Uint8List? profileImageBytes =
                    _decodeImage(profileImageBase64);
                final role =
                    _value(data['role'], null, 'PATIENT').toUpperCase();
                final documentNames = _readList(data['documentNames']);
                final documentCount = documentNames.isNotEmpty
                    ? documentNames.length
                    : _readList(data['documentPaths']).length;
                final age = _ageFromBirthdate(data['birthdate'] ?? data['dob']);
                final isPsychologist = role == 'PSYCHOLOGIST';

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(
                        name: name,
                        role: role == 'PATIENT' ? 'Paciente' : _roleLabel(role),
                        age: age,
                        city: city,
                        imageUrl:
                            profileImageUrl.isNotEmpty ? profileImageUrl : null,
                        imageBytes: profileImageBytes,
                        rating: isPsychologist
                            ? _value(data['rating'], null, '')
                            : '',
                        reviews: isPsychologist
                            ? _value(data['reviewCount'], null, '')
                            : '',
                        verified: isPsychologist &&
                            data['crpStatus']?.toString().toUpperCase() ==
                                'ACTIVE',
                        onEdit: () => context.push('/profileEdit'),
                      ),
                      const SizedBox(height: 12),
                      if (isPsychologist) ...[
                        const _InfoBanner(
                            text:
                                'Acolher é o primeiro passo para\na mudança.'),
                        const SizedBox(height: 12),
                        _ProfessionalSections(data: data, email: email),
                      ] else ...[
                        const _InfoBanner(
                            text:
                                'Cuidar da sua saúde mental\ntambém é um ato de força.'),
                        const SizedBox(height: 12),
                        _ProfileCard(
                          icon: Icons.people_alt_outlined,
                          title: 'Dados pessoais',
                          children: [
                            _ProfileRow(
                                label: 'CPF', value: _value(data['cpf'])),
                            _ProfileRow(
                                label: 'Telefone',
                                value:
                                    _value(data['nTelefone'] ?? data['phone'])),
                            _ProfileRow(label: 'E-mail', value: email),
                            _ProfileRow(label: 'Endereço', value: city),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ProfileCard(
                          icon: Icons.medical_services_outlined,
                          title: 'Plano médico',
                          children: [
                            _ProfileRow(
                                label: 'Plano',
                                value: _value(data['healthPlan'])),
                            _ProfileRow(
                                label: 'Carteirinha',
                                value: _value(data['healthPlanCard'] ??
                                    data['insuranceCard'])),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _ProfileCard(
                          icon: Icons.insert_drive_file_outlined,
                          title: 'Anexos',
                          children: [_AttachmentRow(count: documentCount)],
                        ),
                      ],
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
      if (birthdate is String) {
        final dt = DateTime.tryParse(birthdate);
        if (dt != null)
          return (DateTime.now().difference(dt).inDays / 365).floor();
      }
    } catch (_) {}
    return 0;
  }

  static String _value(dynamic value,
      [dynamic fallback, String fallbackText = 'Não informado']) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
    final fallbackValue = fallback?.toString().trim() ?? '';
    return fallbackValue.isNotEmpty ? fallbackValue : fallbackText;
  }

  static List<String> _readList(dynamic value) {
    if (value is List)
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    if (value is String)
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    return const [];
  }

  static Uint8List? _decodeImage(String value) {
    if (value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static String _roleLabel(String role) {
    if (role == 'PSYCHOLOGIST') return 'Psicólogo';
    return role.toLowerCase().replaceAll('_', ' ');
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String role;
  final int age;
  final String city;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String rating;
  final String reviews;
  final bool verified;
  final VoidCallback onEdit;

  const _ProfileHeader(
      {required this.name,
      required this.role,
      required this.age,
      required this.city,
      required this.imageUrl,
      required this.imageBytes,
      this.rating = '',
      this.reviews = '',
      this.verified = false,
      required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      UserAvatar(imageUrl: imageUrl, imageBytes: imageBytes, radius: 43),
      const SizedBox(width: 14),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Flexible(
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface))),
          if (verified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: AppColors.primary),
          ],
        ]),
        const SizedBox(height: 3),
        Text(role,
            style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(height: 5),
        if (rating.isNotEmpty)
          Row(children: [
            const Icon(Icons.star, size: 15, color: Colors.amber),
            const SizedBox(width: 3),
            Text(rating,
                style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
            if (reviews.isNotEmpty)
              Text(' ($reviews avaliações)',
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
          ])
        else
          Text(age > 0 ? '$age anos' : 'Idade não informada',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 2),
        Row(children: [
          Icon(Icons.location_on_outlined,
              size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Expanded(
              child: Text(city,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)))
        ])
      ])),
      IconButton(
          onPressed: onEdit,
          tooltip: 'Editar perfil',
          icon: const Icon(Icons.edit_outlined),
          color: AppColors.primary),
    ]);
  }
}

class _ProfessionalSections extends StatelessWidget {
  final Map<String, dynamic> data;
  final String email;

  const _ProfessionalSections({required this.data, required this.email});

  @override
  Widget build(BuildContext context) {
    final plans =
        ProfileScreen._readList(data['healthPlansList'] ?? data['healthPlans']);
    final days = _days(data['availabilityDays']);
    final modality = _modality(data['modality']);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _ProfileCard(
        icon: Icons.people_alt_outlined,
        title: 'Informações profissionais',
        children: [
          _ProfileRow(label: 'CRP', value: _value(data['crp'])),
          _ProfileRow(label: 'Modelo de atendimento', value: modality),
          _ProfileRow(
              label: 'Endereço do consultório',
              value: _value(data['officeAddress'])),
          _ProfileRow(label: 'Telefone', value: _value(data['officePhone'])),
          _ProfileRow(label: 'E-mail', value: email),
        ],
      ),
      const SizedBox(height: 10),
      _ProfileCard(
        icon: Icons.health_and_safety_outlined,
        title: 'Planos médicos aceitos',
        children: [
          if (plans.isEmpty)
            const _EmptyProfileText(text: 'Nenhum plano informado')
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: plans.map((plan) => _PlanChip(label: plan)).toList(),
            ),
        ],
      ),
      const SizedBox(height: 10),
      _ProfileCard(
        icon: Icons.calendar_month_outlined,
        title: 'Agenda de atendimento',
        children: [
          if (days.isEmpty)
            const _EmptyProfileText(text: 'Disponibilidade não informada')
          else
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: days.map((day) => _DayChip(label: day)).toList(),
            ),
          if (_value(data['availabilityHours'], null, '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.access_time,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 7),
              Text(_value(data['availabilityHours']),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ],
        ],
      ),
    ]);
  }

  static String _value(dynamic value,
          [dynamic fallback, String fallbackText = 'Não informado']) =>
      ProfileScreen._value(value, fallback, fallbackText);

  static List<String> _days(dynamic value) {
    final raw = ProfileScreen._readList(value);
    final labels = <String, String>{
      'SEGUNDA': 'Seg',
      'SEG': 'Seg',
      'TERCA': 'Ter',
      'TERÇA': 'Ter',
      'TER': 'Ter',
      'QUARTA': 'Qua',
      'QUA': 'Qua',
      'QUINTA': 'Qui',
      'QUI': 'Qui',
      'SEXTA': 'Sex',
      'SEX': 'Sex',
      'SABADO': 'Sáb',
      'SÁBADO': 'Sáb',
      'SAB': 'Sáb',
      'DOMINGO': 'Dom',
      'DOM': 'Dom',
    };
    return raw
        .expand((item) => item.split(RegExp(r'\s*(?:,|;|\|)\s*')))
        .map((item) => labels[item.trim().toUpperCase()] ?? item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _modality(dynamic value) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    if (raw == 'ONLINE') return 'Online';
    if (raw == 'IN_PERSON' || raw == 'PRESENCIAL') return 'Presencial';
    if (raw.contains('BOTH') || raw.contains('ONLINE E PRESENCIAL')) {
      return 'Online e presencial';
    }
    return value?.toString().trim().isNotEmpty == true
        ? value.toString()
        : 'Não informado';
  }
}

class _PlanChip extends StatelessWidget {
  final String label;

  const _PlanChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11)),
      );
}

class _DayChip extends StatelessWidget {
  final String label;

  const _DayChip({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      );
}

class _EmptyProfileText extends StatelessWidget {
  final String text;

  const _EmptyProfileText({required this.text});

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 11));
}

class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primary.withOpacity(0.13),
              child: const Icon(Icons.favorite,
                  size: 17, color: AppColors.primary)),
          const SizedBox(width: 11),
          Text(text,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  height: 1.35))
        ]),
      );
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _ProfileCard(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: scheme.outline.withOpacity(0.18))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              child: Icon(icon, size: 17, color: AppColors.primary)),
          const SizedBox(width: 9),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  fontSize: 13))
        ]),
        const SizedBox(height: 8),
        ...children,
      ]),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 105,
              child: Text(label,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11))),
          Expanded(
              child: Text(value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)))
        ]),
      );
}

class _AttachmentRow extends StatelessWidget {
  final int count;

  const _AttachmentRow({required this.count});

  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(Icons.description_outlined,
            size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('Documentos',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11)),
        const Spacer(),
        Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              Icon(Icons.insert_drive_file_outlined,
                  size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Text('$count arquivo${count == 1 ? '' : 's'}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600))
            ])),
        const SizedBox(width: 5),
        Icon(Icons.chevron_right,
            size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)
      ]);
}

class DadoPerfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final String dado;

  const DadoPerfil(
      {Key? key, required this.icon, required this.label, required this.dado})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16))
      ]),
      const SizedBox(height: 8),
      Text(dado,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18))
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
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withOpacity(0.4))),
      child: Text('#$dado',
          style:
              TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w600)),
    );
  }
}
