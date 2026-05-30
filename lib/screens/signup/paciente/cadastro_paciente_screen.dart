import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../widgets/app_dropdown.dart';
import '../../../utils/app_colors.dart';

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

  void _next() {
    final String? convenioId = _selectedConvenioId;
    if (convenioId == null || convenioId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecione o convênio.')));
      return;
    }
    final stateExtra = GoRouterState.of(context).extra;
    final previous =
        widget.data ?? (stateExtra is Map<String, dynamic> ? stateExtra : null);
    debugPrint('[CadastroPaciente] previous=$previous convenioId=$convenioId');
    context.push('/home', extra: {
      ...?previous,
      'convenio': convenioId,
    });
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
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('Continuar'),
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
