import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/date_picker_field.dart';
import '../../widgets/styled_text_field.dart';

/// Etapa de bio (opcional). Agora recebe explicitamente o mapa acumulado via construtor
/// para reduzir risco de perda de dados quando GoRouterState.extra não propaga.
/// Mantemos fallback em GoRouterState.of(context).extra por segurança.
class SignupBioScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const SignupBioScreen({super.key, this.data});

  @override
  State<SignupBioScreen> createState() => _SignupBioScreenState();
}

class _SignupBioScreenState extends State<SignupBioScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _cpfFocusNode = FocusNode();
  final _cpfController = TextEditingController();
  final _telefoneFocusNode = FocusNode();
  final _telefoneController = TextEditingController();
  final _dobController = TextEditingController();
  bool _isLoading = false;

  String? _selectedGender;
  DateTime? _selectedDate;
  final List<Map<String, String>> _genderItems = [
    {'value': 'M', 'text': 'Masculino'},
    {'value': 'F', 'text': 'Feminino'},
    {'value': 'P', 'text': 'Prefiro não identificar'},
    {'value': 'O', 'text': 'Outros'},
  ];

  Map<String, dynamic>? get _incomingData {
    // Prioriza widget.data; fallback para state.extra se disponível.
    final stateExtra = GoRouterState.of(context).extra;
    return widget.data ??
        (stateExtra is Map<String, dynamic> ? stateExtra : null);
  }

  @override
  void initState() {
    super.initState();
    _cpfFocusNode.addListener(() {
      if (!_cpfFocusNode.hasFocus) {
        _formatCpf();
      }
    });
    _telefoneFocusNode.addListener(() {
      if (!_telefoneFocusNode.hasFocus) {
        _formatPhone();
      }
    });
    // Logging inicial para diagnóstico de perda de dados.
    // (Não impacta produção significativamente; pode ser removido depois.)
    debugPrint(
        '[SignupBio] init data = ' + (widget.data?.toString() ?? 'null'));
  }

  @override
  void dispose() {
    _controller.dispose();
    _cpfController.dispose();
    _cpfFocusNode.dispose();
    _telefoneController.dispose();
    _telefoneFocusNode.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _formatCpf() {
    final digits = _cpfController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    final truncated = digits.substring(0, digits.length.clamp(0, 11));
    final buffer = StringBuffer();

    for (var i = 0; i < truncated.length; i++) {
      buffer.write(truncated[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }

    _cpfController.text = buffer.toString();
  }

  void _formatPhone() {
    final digits = _telefoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    final truncated = digits.substring(0, digits.length.clamp(0, 11));
    final buffer = StringBuffer();

    for (var i = 0; i < truncated.length; i++) {
      if (i == 0) buffer.write('(');
      buffer.write(truncated[i]);
      if (i == 1) buffer.write(') ');
      if (i == 6 && truncated.length > 6) buffer.write('-');
    }

    _telefoneController.text = buffer.toString();
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    final previous = _incomingData;
    debugPrint(
        '[SignupBio] forwarding with previous=$previous bio=${_controller.text.trim()}');
    context.push('/signupGoal', extra: {
      ...?previous,
      'gender': _selectedGender,
      'cpf': _cpfController,
      'dob': _selectedDate?.millisecondsSinceEpoch,
      'nTelefone': _telefoneController,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading:
            BackButton(color: AppColors.primary),
        title: const Text('Dados Pessoais'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppDropdown(
                        value: _selectedGender,
                        hint: 'Selecione seu gênero...',
                        items: _genderItems.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['value'],
                            child: Text(item['text'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      StyledTextField(
                        controller: _cpfController,
                        label: 'CPF',
                        keyboardType: TextInputType.number,
                        focusNode: _cpfFocusNode,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (v) {
                          final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                          if (digits.length != 11)
                            return 'Informe um CPF válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DatePickerField(
                        controller: _dobController,
                        label: 'Data de nascimento',
                        selectedDate: _selectedDate,
                        locale: const Locale('pt', 'BR'),
                        helpText: 'Selecione sua data de nascimento',
                        onDateSelected: (picked) {
                          setState(() {
                            _selectedDate = picked;
                          });
                        },
                        validator: (_) {
                          if (_selectedDate == null) return 'Selecione a data';
                          final now = DateTime.now();
                          int age = now.year - _selectedDate!.year;
                          if (now.month < _selectedDate!.month ||
                              (now.month == _selectedDate!.month &&
                                  now.day < _selectedDate!.day)) {
                            age--;
                          }
                          if (age < 18) return 'Você deve ter 18+';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      StyledTextField(
                        controller: _telefoneController,
                        label: 'Número de Telefone',
                        keyboardType: TextInputType.phone,
                        focusNode: _telefoneFocusNode,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(11),
                        ],
                        validator: (v) {
                          final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                          if (digits.length < 10)
                            return 'Informe um telefone válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppButton(
              label: 'Continuar',
              onPressed: _isLoading ? null : _next,
              isLoading: _isLoading,
              filled: true,
            ),
          ],
        ),
      ),
    );
  }
}
