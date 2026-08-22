import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../utils/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../../services/firebase_service.dart';

class CadastroPacienteScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const CadastroPacienteScreen({super.key, this.data});

  @override
  State<CadastroPacienteScreen> createState() => _CadastroPacienteScreenState();
}

class _CadastroPacienteScreenState extends State<CadastroPacienteScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedFiles = [];
  final List<Map<String, String>> _convenios = const [
    {'id': 'U', 'label': 'Unimed'},
    {'id': 'A', 'label': 'Amil'},
    {'id': 'B', 'label': 'Bradesco Saúde'},
    {'id': 'S', 'label': 'SulAmérica'},
    {'id': 'N', 'label': 'Não tenho convênio'},
  ];

  String? _selectedConvenioId;
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _addDocument() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    if (!mounted) return;
    setState(() {
      _selectedFiles.add(pickedFile);
    });
  }

  Future<void> _next() async {
    final String? convenioId = _selectedConvenioId;
    if (convenioId == null || convenioId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione o convênio.')));
      return;
    }
    final stateExtra = GoRouterState.of(context).extra;
    final previous =
        widget.data ?? (stateExtra is Map<String, dynamic> ? stateExtra : null);
    final email = previous?['email']?.toString() ?? '';
    final password = previous?['password']?.toString() ?? '';
    final name = previous?['name']?.toString() ?? '';
    final goal = previous?['goal']?.toString() ?? '';

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Dados de e-mail/senha ausentes. Refaça o cadastro.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1) Criar a conta no Firebase Auth (sem isso o HomeRoleGate volta para o login)
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential =
          await authService.createUserWithEmailAndPassword(email, password);
      final uid = userCredential.user?.uid;

      if (uid == null) {
        throw Exception('Falha ao obter o usuário após o cadastro.');
      }

      // Atualizar o displayName no Auth
      if (name.isNotEmpty) {
        await authService.updateProfile(displayName: name);
      }

      // 2) Criar perfil no Firestore com role e dados do paciente
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      await firebaseService.createUserWithRole(
        userData: {
          'name': name,
          'email': email,
          'role': 'PATIENT',
          'goal': goal,
          'healthPlan': convenioId,
          'dob': previous?['dob'],
          'gender': previous?['gender'],
          'cpf': previous?['cpf'],
          'nTelefone': previous?['nTelefone'],
          'bio': previous?['bio'],
          'tags': previous?['tags'],
        },
        role: 'PATIENT',
        roleSpecificData: {
          'healthPlan': convenioId,
          'documentPaths': _selectedFiles.map((file) => file.path).toList(),
          'documentNames': _selectedFiles.map((file) => file.name).toList(),
        },
        documentId: uid,
      );

      if (!mounted) return;
      debugPrint(
          '[CadastroPaciente] Conta criada com sucesso para $email (uid=$uid)');
      context.go('/home');
    } catch (e) {
      debugPrint('[CadastroPaciente] Erro ao criar conta: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar conta: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: AppColors.textPrimary),
        title: const Text('Cadastro de Paciente'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text('Informe seu convênio',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 12),
                      AppDropdown(
                        value: _selectedConvenioId,
                        hint: 'Selecione seu convênio...',
                        items: _convenios.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'],
                            child: Text(item['label'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedConvenioId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      Text('Anexe aqui seus documentos',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Laudo médico, receitas...',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _addDocument,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 18, horizontal: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            child: Text('Anexe um documento aqui...',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary)),
                          ),
                        ),
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Column(
                          children: _selectedFiles.map((file) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.gray100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ListTile(
                                leading: const Icon(Icons.insert_drive_file,
                                    color: Colors.black54),
                                title: Text(file.name,
                                    style: const TextStyle(fontSize: 14)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.black54),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFiles.remove(file);
                                    });
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Text('Continuar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
