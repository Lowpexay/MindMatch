import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/firebase_service.dart';

class CadastroPsicologoScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const CadastroPsicologoScreen({super.key, this.data});

  @override
  State<CadastroPsicologoScreen> createState() => _CadastroPsicologoScreenState();
}

class _CadastroPsicologoScreenState extends State<CadastroPsicologoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _crpController = TextEditingController();
  final _careerStartController = TextEditingController();
  final _officeAddressController = TextEditingController();
  final _officePhoneController = TextEditingController();
  final _healthPlansController = TextEditingController();
  final _availabilityDaysController = TextEditingController();
  final _availabilityHoursController = TextEditingController();
  final _personalizedMessageController = TextEditingController();

  final List<Map<String, String>> _modalities = const [
    {'value': 'ONLINE', 'label': 'Online'},
    {'value': 'PRESENTIAL', 'label': 'Presencial'},
    {'value': 'BOTH', 'label': 'Online e presencial'},
  ];

  final List<String> _specialtyOptions = const [
    'depressão',
    'traumas',
    'autismo',
    'TOC',
    'TDAH',
    'família',
    'ansiedade',
    'relacionamentos',
    'luto',
    'burnout',
  ];

  String? _selectedModality;
  final Set<String> _selectedSpecialties = <String>{};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _crpController.dispose();
    _careerStartController.dispose();
    _officeAddressController.dispose();
    _officePhoneController.dispose();
    _healthPlansController.dispose();
    _availabilityDaysController.dispose();
    _availabilityHoursController.dispose();
    _personalizedMessageController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _incomingData {
    final stateExtra = GoRouterState.of(context).extra;
    return widget.data ??
        (stateExtra is Map<String, dynamic> ? stateExtra : null);
  }

  bool _validateCurrentStep() {
    switch (_tabController.index) {
      case 0:
        if (_crpController.text.trim().isEmpty) {
          _showSnack('Informe o CRP.');
          return false;
        }
        if (_selectedModality == null || _selectedModality!.isEmpty) {
          _showSnack('Selecione o tipo de atendimento.');
          return false;
        }
        return true;
      case 1:
        if (_availabilityDaysController.text.trim().isEmpty) {
          _showSnack('Informe os dias de atendimento.');
          return false;
        }
        if (_availabilityHoursController.text.trim().isEmpty) {
          _showSnack('Informe os horários de atendimento.');
          return false;
        }
        return true;
      case 2:
        if (_selectedSpecialties.isEmpty) {
          _showSnack('Selecione ao menos uma especialidade.');
          return false;
        }
        return true;
      case 3:
        if (_personalizedMessageController.text.trim().isEmpty) {
          _showSnack('Escreva sua mensagem personalizada.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _next() async {
    if (!_validateCurrentStep()) return;

    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
      return;
    }

    final previous = _incomingData;
    final email = previous?['email']?.toString().trim() ?? '';
    final password = previous?['password']?.toString() ?? '';
    final name = previous?['name']?.toString().trim() ?? '';

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Dados de e-mail/senha ausentes. Refaça o cadastro.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      final userCredential = await authService.createUserWithEmailAndPassword(
        email,
        password,
      );
      final uid = userCredential.user?.uid;

      if (uid == null) {
        throw Exception('Falha ao obter o usuário após o cadastro.');
      }

      if (name.isNotEmpty) {
        await authService.updateProfile(displayName: name);
      }

      await firebaseService.createUserWithRole(
        userData: {
          'name': name,
          'email': email,
          'role': 'PSYCHOLOGIST',
          'goal': previous?['goal'] ?? 'Psicólogo(a) procurando por pacientes',
          'crp': _crpController.text.trim(),
          'careerStart': _careerStartController.text.trim(),
          'modality': _selectedModality,
          'officeAddress': _officeAddressController.text.trim(),
          'officePhone': _officePhoneController.text.trim(),
          'healthPlans': _healthPlansController.text.trim(),
          'availabilityDays': _availabilityDaysController.text.trim(),
          'availabilityHours': _availabilityHoursController.text.trim(),
          'specialties': _selectedSpecialties.toList(),
          'personalizedMessage': _personalizedMessageController.text.trim(),
        },
        role: 'PSYCHOLOGIST',
        roleSpecificData: {
          'crp': _crpController.text.trim(),
          'careerStart': _careerStartController.text.trim(),
          'modality': _selectedModality,
          'officeAddress': _officeAddressController.text.trim(),
          'officePhone': _officePhoneController.text.trim(),
          'healthPlans': _healthPlansController.text.trim(),
          'availabilityDays': _availabilityDaysController.text.trim(),
          'availabilityHours': _availabilityHoursController.text.trim(),
          'specialties': _selectedSpecialties.toList(),
          'personalizedMessage': _personalizedMessageController.text.trim(),
        },
        documentId: uid,
      );

      if (!mounted) return;
      debugPrint('[CadastroPsicologo] Conta criada com sucesso para $email (uid=$uid)');
      context.go('/home');
    } catch (error) {
      debugPrint('[CadastroPsicologo] Erro ao criar conta: $error');
      if (!mounted) return;
      _showSnack('Erro ao criar conta: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Psicólogo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: isDark ? Colors.white : AppColors.textPrimary,
          unselectedLabelColor: isDark ? Colors.white70 : AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Dados médicos'),
            Tab(text: 'Atendimento'),
            Tab(text: 'Especialidades'),
            Tab(text: 'Mensagem'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMedicalStep(context),
                _buildAttendanceStep(context),
                _buildSpecialtiesStep(context),
                _buildMessageStep(context),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_tabController.index == _tabController.length - 1
                          ? 'Concluir cadastro'
                          : 'Continuar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Dados médicos'),
        const SizedBox(height: 16),
        _field(_crpController, 'CRP'),
        const SizedBox(height: 12),
        _field(_careerStartController, 'Ano de início da carreira'),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedModality,
          decoration: _fieldDecoration('Tipo de atendimento'),
          items: _modalities
              .map((item) => DropdownMenuItem<String>(
                    value: item['value'],
                    child: Text(item['label'] ?? ''),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedModality = value),
        ),
        const SizedBox(height: 12),
        _field(_officeAddressController, 'Endereço do consultório'),
        const SizedBox(height: 12),
        _field(_officePhoneController, 'Telefone do consultório'),
        const SizedBox(height: 12),
        _field(_healthPlansController, 'Planos atendidos'),
      ],
    );
  }

  Widget _buildAttendanceStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Atendimento'),
        const SizedBox(height: 16),
        _field(_availabilityDaysController, 'Dias da semana que atende'),
        const SizedBox(height: 12),
        _field(_availabilityHoursController, 'Horários disponíveis'),
        const SizedBox(height: 12),
        _hintCard(
          'Exemplo: Segunda, quarta e sexta • 08:00 às 18:00',
        ),
      ],
    );
  }

  Widget _buildSpecialtiesStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Especialidades'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _specialtyOptions.map((specialty) {
            final selected = _selectedSpecialties.contains(specialty);
            return FilterChip(
              label: Text(specialty),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedSpecialties.add(specialty);
                  } else {
                    _selectedSpecialties.remove(specialty);
                  }
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.18),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _hintCard('Escolha as especialidades que melhor descrevem seu atendimento.'),
      ],
    );
  }

  Widget _buildMessageStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Mensagem'),
        const SizedBox(height: 16),
        _field(
          _personalizedMessageController,
          'Mensagem personalizada',
          maxLines: 6,
        ),
        const SizedBox(height: 12),
        _hintCard('Explique em poucas linhas como você acolhe e atende seus pacientes.'),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color.fromRGBO(0, 0, 0, 0.3) : const Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 12,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: _fieldDecoration(label),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.gray300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _hintCard(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text),
    );
  }
}
