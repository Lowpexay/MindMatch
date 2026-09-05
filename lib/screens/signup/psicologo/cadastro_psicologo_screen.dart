import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../utils/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/firebase_service.dart';
import '../../../services/crp_validation_service.dart';

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
  final _customHealthPlanController = TextEditingController();
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

  final List<String> _weekdays = const [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  String? _selectedModality;
  final Set<String> _selectedSpecialties = <String>{};
  final Set<String> _selectedAvailabilityDays = <String>{};
  final Set<String> _selectedHealthPlans = <String>{};
  TimeOfDay? _availabilityStart;
  TimeOfDay? _availabilityEnd;
  bool _isLoading = false;
  final _crpValidationService = CrpValidationService();
  CrpValidationResult? _crpValidation;

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
    _customHealthPlanController.dispose();
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
        if (_selectedAvailabilityDays.isEmpty) {
          _showSnack('Selecione ao menos um dia de atendimento.');
          return false;
        }
        if (_availabilityStart == null || _availabilityEnd == null) {
          _showSnack('Informe o horário de início e fim do atendimento.');
          return false;
        }
        if (_timeInMinutes(_availabilityEnd!) <= _timeInMinutes(_availabilityStart!)) {
          _showSnack('O horário final deve ser depois do horário inicial.');
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

    if (_tabController.index == 0 && _crpValidation == null) {
      setState(() => _isLoading = true);
      try {
        _crpValidation = await _crpValidationService.validate(_crpController.text);
        _crpController.text = _crpValidation!.registration;
        if (!mounted) return;
        _showSnack('CRP validado com sucesso no CFP.');
      } catch (error) {
        debugPrint('[CadastroPsicologo] Falha na validação do CRP: $error');
        if (!mounted) return;
        _showSnack(error.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

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
          'crp': _crpValidation?.registration ?? _crpController.text.trim(),
          'crpStatus': _crpValidation?.status,
          'crpVerifiedAt': DateTime.now().toUtc().toIso8601String(),
          'careerStart': _careerStartController.text.trim(),
          'modality': _selectedModality,
          'officeAddress': _selectedModality == 'ONLINE' ? '' : _officeAddressController.text.trim(),
          'officePhone': _selectedModality == 'ONLINE' ? '' : _officePhoneController.text.trim(),
          'healthPlans': _selectedHealthPlans.join(', '),
          'healthPlansList': _selectedHealthPlans.toList(),
          'availabilityDays': _availabilityDaysController.text.trim(),
          'availabilityHours': _availabilityHoursController.text.trim(),
          'specialties': _selectedSpecialties.toList(),
          'personalizedMessage': _personalizedMessageController.text.trim(),
        },
        role: 'PSYCHOLOGIST',
        roleSpecificData: {
          'crp': _crpValidation?.registration ?? _crpController.text.trim(),
          'crpStatus': _crpValidation?.status,
          'crpVerifiedAt': DateTime.now().toUtc().toIso8601String(),
          'careerStart': _careerStartController.text.trim(),
          'modality': _selectedModality,
          'officeAddress': _selectedModality == 'ONLINE' ? '' : _officeAddressController.text.trim(),
          'officePhone': _selectedModality == 'ONLINE' ? '' : _officePhoneController.text.trim(),
          'healthPlans': _selectedHealthPlans.join(', '),
          'healthPlansList': _selectedHealthPlans.toList(),
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
        _field(_crpController, 'CRP', onChanged: (_) {
          if (_crpValidation != null) {
            setState(() => _crpValidation = null);
          }
        }),
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
          onChanged: (value) => setState(() {
            _selectedModality = value;
            if (value == 'ONLINE') {
              _officeAddressController.clear();
              _officePhoneController.clear();
            }
          }),
        ),
        if (_selectedModality != 'ONLINE') ...[
          const SizedBox(height: 12),
          _field(_officeAddressController, 'Endereço do consultório'),
          const SizedBox(height: 12),
          _field(_officePhoneController, 'Telefone do consultório'),
        ],
        const SizedBox(height: 12),
        _buildHealthPlansInput(context),
      ],
    );
  }

  Widget _buildAttendanceStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Atendimento'),
        const SizedBox(height: 8),
        _hintCard('Selecione os dias e o período em que os pacientes podem agendar.'),
        const SizedBox(height: 16),
        Text(
          'Dias de atendimento',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textColor(context)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekdays.map((day) {
            final selected = _selectedAvailabilityDays.contains(day);
            return FilterChip(
              label: Text(day),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedAvailabilityDays.add(day);
                  } else {
                    _selectedAvailabilityDays.remove(day);
                  }
                  _availabilityDaysController.text = _weekdays
                      .where(_selectedAvailabilityDays.contains)
                      .join(', ');
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.18),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Horário de atendimento',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textColor(context)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _timePickerButton(context, 'Início', _availabilityStart, true)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('até'),
            ),
            Expanded(child: _timePickerButton(context, 'Fim', _availabilityEnd, false)),
          ],
        ),
        _hintCard(
          'Exemplo salvo no perfil: Segunda, Quarta e Sexta • 08:00 às 18:00',
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

  Widget _buildHealthPlansInput(BuildContext context) {
    const commonPlans = [
      'Particular',
      'Unimed',
      'Bradesco Saúde',
      'SulAmérica',
      'Amil',
      'Hapvida',
      'NotreDame Intermédica',
      'Porto Seguro Saúde',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Convênios e formas de atendimento',
          style: TextStyle(fontWeight: FontWeight.w700, color: _textColor(context)),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione os convênios aceitos ou adicione outro.',
          style: TextStyle(color: _textColor(context).withOpacity(0.7)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commonPlans.map((plan) {
            final selected = _selectedHealthPlans.contains(plan);
            return FilterChip(
              label: Text(plan),
              selected: selected,
              onSelected: (value) {
                setState(() {
                  if (value) {
                    _selectedHealthPlans.add(plan);
                  } else {
                    _selectedHealthPlans.remove(plan);
                  }
                  _healthPlansController.text = _selectedHealthPlans.join(', ');
                });
              },
              selectedColor: AppColors.primary.withOpacity(0.18),
              checkmarkColor: AppColors.primary,
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _field(_customHealthPlanController, 'Adicionar convênio', onSubmitted: (_) => _addCustomHealthPlan()),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: IconButton.filled(
                onPressed: _addCustomHealthPlan,
                icon: const Icon(Icons.add),
                tooltip: 'Adicionar convênio',
              ),
            ),
          ],
        ),
        if (_selectedHealthPlans.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Selecionados: ${_selectedHealthPlans.join(', ')}',
            style: TextStyle(color: _textColor(context).withOpacity(0.75)),
          ),
        ],
      ],
    );
  }

  void _addCustomHealthPlan() {
    final plan = _customHealthPlanController.text.trim();
    if (plan.isEmpty) return;
    final alreadyAdded = _selectedHealthPlans.any((item) => item.toLowerCase() == plan.toLowerCase());
    if (!alreadyAdded) _selectedHealthPlans.add(plan);
    _customHealthPlanController.clear();
    setState(() => _healthPlansController.text = _selectedHealthPlans.join(', '));
  }

  Color _textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.textPrimary;
  }

  Widget _timePickerButton(
    BuildContext context,
    String label,
    TimeOfDay? value,
    bool isStart,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? (isStart ? const TimeOfDay(hour: 8, minute: 0) : const TimeOfDay(hour: 18, minute: 0)),
        );
        if (picked == null || !mounted) return;
        setState(() {
          if (isStart) {
            _availabilityStart = picked;
          } else {
            _availabilityEnd = picked;
          }
          if (_availabilityStart != null && _availabilityEnd != null) {
            _availabilityHoursController.text =
                '${_formatTime(_availabilityStart!)} às ${_formatTime(_availabilityEnd!)}';
          }
        });
      },
      icon: const Icon(Icons.access_time),
      label: Text(value == null ? label : _formatTime(value)),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        side: BorderSide(color: AppColors.primary.withOpacity(0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  int _timeInMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _field(TextEditingController controller, String label,
      {int maxLines = 1,
      ValueChanged<String>? onChanged,
      ValueChanged<String>? onSubmitted}) {
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
        onChanged: onChanged,
        onSubmitted: onSubmitted,
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
