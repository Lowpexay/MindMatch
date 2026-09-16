import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as imgpkg;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/user_avatar.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreen();
}

class _ProfileEditScreen extends State<ProfileEditScreen> {
  DateTime? selectedDate;
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController cidadeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController cpfController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController enderecoController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController healthPlanController = TextEditingController();
  final TextEditingController healthPlanCardController =
      TextEditingController();
  final TextEditingController crpController = TextEditingController();
  final TextEditingController officePhoneController = TextEditingController();
  final TextEditingController modalityController = TextEditingController();
  final TextEditingController officeAddressController = TextEditingController();
  final TextEditingController healthPlansController = TextEditingController();
  final TextEditingController availabilityDaysController =
      TextEditingController();
  final TextEditingController availabilityHoursController =
      TextEditingController();

  File? _imageFile;
  String? _existingImageUrl;
  String? _profileImageBase64;
  String _role = 'PATIENT';
  int _documentCount = 0;
  String? _selectedModality;
  final Set<String> _selectedAvailabilityDays = <String>{};
  final Set<String> _selectedHealthPlans = <String>{};
  TimeOfDay? _availabilityStart;
  TimeOfDay? _availabilityEnd;
  static const _weekdays = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];
  static const _modalities = [
    {'value': 'ONLINE', 'label': 'Online'},
    {'value': 'PRESENTIAL', 'label': 'Presencial'},
    {'value': 'BOTH', 'label': 'Online e presencial'},
  ];
  static const _healthPlanOptions = [
    'Particular',
    'Unimed',
    'Bradesco Saúde',
    'SulAmérica',
    'Amil',
    'Hapvida',
    'NotreDame Intermédica',
    'Porto Seguro Saúde',
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    nomeController.dispose();
    birthdayController.dispose();
    cidadeController.dispose();
    emailController.dispose();
    bioController.dispose();
    instagramController.dispose();
    twitterController.dispose();
    cpfController.dispose();
    telefoneController.dispose();
    enderecoController.dispose();
    bairroController.dispose();
    cepController.dispose();
    healthPlanController.dispose();
    healthPlanCardController.dispose();
    crpController.dispose();
    officePhoneController.dispose();
    modalityController.dispose();
    officeAddressController.dispose();
    healthPlansController.dispose();
    availabilityDaysController.dispose();
    availabilityHoursController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentProfile());
  }

  Future<void> _loadCurrentProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    final user = auth.currentUser;
    if (user == null) return;

    try {
      final profile = await firebaseService.getUserProfile(user.uid);
      if (profile != null) {
        setState(() {
          nomeController.text = _text(profile['name']);
          emailController.text = _text(profile['email']);
          cidadeController.text = _text(profile['city']);
          bioController.text = _text(profile['bio']);
          instagramController.text = _text(profile['instagram']);
          twitterController.text = _text(profile['twitter']);
          cpfController.text = _text(profile['cpf']);
          telefoneController.text =
              _text(profile['nTelefone'] ?? profile['phone']);
          enderecoController.text = _text(profile['address']);
          bairroController.text = _text(profile['neighborhood']);
          cepController.text = _text(profile['cep'] ?? profile['zipCode']);
          healthPlanController.text = _text(profile['healthPlan']);
          healthPlanCardController.text =
              _text(profile['healthPlanCard'] ?? profile['insuranceCard']);
          crpController.text = _text(profile['crp']);
          officePhoneController.text = _text(profile['officePhone']);
          modalityController.text = _text(profile['modality']);
          officeAddressController.text = _text(profile['officeAddress']);
          healthPlansController.text =
              _listText(profile['healthPlansList'] ?? profile['healthPlans']);
          _selectedHealthPlans
            ..clear()
            ..addAll(_splitList(healthPlansController.text));
          availabilityDaysController.text = _text(profile['availabilityDays']);
          availabilityHoursController.text =
              _text(profile['availabilityHours']);
          _role = _text(profile['role'], fallback: 'PATIENT').toUpperCase();
          _selectedModality = _normalizeModality(profile['modality']);
          _selectedAvailabilityDays
            ..clear()
            ..addAll(_parseDays(profile['availabilityDays']));
          _parseHours(profile['availabilityHours']);
          final documents =
              profile['documentNames'] ?? profile['documentPaths'];
          _documentCount = documents is List ? documents.length : 0;
          if (profile['birthdate'] != null) {
            final ts = profile['birthdate'];
            if (ts is int) {
              final dt = DateTime.fromMillisecondsSinceEpoch(ts);
              selectedDate = dt;
              birthdayController.text = DateFormat('dd/MM/yyyy').format(dt);
            } else if (ts is String) {
              birthdayController.text = ts;
            }
          }
          _existingImageUrl = _text(profile['profileImageUrl'], fallback: '');
          _profileImageBase64 =
              _text(profile['profileImageBase64'], fallback: '');
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao carregar perfil: $e')));
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        birthdayController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário não autenticado')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? uploadedUrl;
      String? base64Image;
      if (_imageFile != null) {
        try {
          // Resize/compress image to try to fit under the Firestore-friendly limit
          final resized = await _resizeImageIfNeeded(_imageFile!, 700000);
          final bytes = resized;
          uploadedUrl =
              await firebaseService.uploadUserProfileImage(user.uid, bytes);

          // If Storage upload failed, fallback to saving Base64 in Firestore (free tier)
          if ((uploadedUrl == null || uploadedUrl.isEmpty) &&
              bytes.isNotEmpty) {
            base64Image = base64Encode(bytes);
          }
        } catch (e) {
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erro ao enviar imagem: $e')));
        }
      }

      final updates = <String, dynamic>{};
      if (nomeController.text.trim().isNotEmpty)
        updates['name'] = nomeController.text.trim();
      if (emailController.text.trim().isNotEmpty)
        updates['email'] = emailController.text.trim();
      if (cidadeController.text.trim().isNotEmpty)
        updates['city'] = cidadeController.text.trim();
      if (bioController.text.trim().isNotEmpty)
        updates['bio'] = bioController.text.trim();
      if (instagramController.text.trim().isNotEmpty)
        updates['instagram'] = instagramController.text.trim();
      if (twitterController.text.trim().isNotEmpty)
        updates['twitter'] = twitterController.text.trim();
      if (cpfController.text.trim().isNotEmpty)
        updates['cpf'] = cpfController.text.trim();
      if (telefoneController.text.trim().isNotEmpty)
        updates['nTelefone'] = telefoneController.text.trim();
      if (enderecoController.text.trim().isNotEmpty)
        updates['address'] = enderecoController.text.trim();
      if (bairroController.text.trim().isNotEmpty)
        updates['neighborhood'] = bairroController.text.trim();
      if (cepController.text.trim().isNotEmpty)
        updates['cep'] = cepController.text.trim();
      if (_role == 'PATIENT') {
        if (healthPlanController.text.trim().isNotEmpty)
          updates['healthPlan'] = healthPlanController.text.trim();
        if (healthPlanCardController.text.trim().isNotEmpty)
          updates['healthPlanCard'] = healthPlanCardController.text.trim();
      } else {
        if (crpController.text.trim().isNotEmpty)
          updates['crp'] = crpController.text.trim();
        updates['officePhone'] = officePhoneController.text.trim();
        if (_selectedModality != null) updates['modality'] = _selectedModality;
        updates['officeAddress'] = officeAddressController.text.trim();
        if (healthPlansController.text.trim().isNotEmpty) {
          updates['healthPlans'] = healthPlansController.text.trim();
          updates['healthPlansList'] = _splitList(healthPlansController.text);
        }
        if (availabilityDaysController.text.trim().isNotEmpty)
          updates['availabilityDays'] = availabilityDaysController.text.trim();
        if (availabilityHoursController.text.trim().isNotEmpty)
          updates['availabilityHours'] =
              availabilityHoursController.text.trim();
      }
      if (selectedDate != null)
        updates['birthdate'] = selectedDate!.millisecondsSinceEpoch;
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        updates['profileImageUrl'] = uploadedUrl;
        // Clear any previous base64 stored image
        updates.remove('profileImageBase64');
      } else if (base64Image != null && base64Image.isNotEmpty) {
        updates['profileImageBase64'] = base64Image;
        // Mark that image is stored in Firestore
        updates['profileImageStoredIn'] = 'firestore_base64';
      }

      if (updates.isNotEmpty) {
        await firebaseService.updateUserProfile(user.uid, updates);
      }

      // Update firebase auth profile for displayName/photoURL
      await auth.updateUserProfile(
          displayName: nomeController.text.trim().isEmpty
              ? null
              : nomeController.text.trim(),
          photoURL: uploadedUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil salvo com sucesso')));
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro ao salvar perfil: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Resize image file to try to get under maxBytes; returns JPEG bytes
  Future<Uint8List> _resizeImageIfNeeded(File file, int maxBytes) async {
    final original = await file.readAsBytes();
    if (original.lengthInBytes <= maxBytes) return original;

    // Decode
    final img = imgpkg.decodeImage(original);
    if (img == null) return original;

    // Iteratively reduce size by scaling down and lowering quality
    int quality = 85;
    int width = img.width;
    int height = img.height;
    Uint8List encoded =
        Uint8List.fromList(imgpkg.encodeJpg(img, quality: quality));

    while (encoded.lengthInBytes > maxBytes && (width > 100 || height > 100)) {
      width = (width * 0.8).floor();
      height = (height * 0.8).floor();
      final resized = imgpkg.copyResize(img, width: width, height: height);
      encoded = Uint8List.fromList(imgpkg.encodeJpg(resized, quality: quality));
      if (quality > 40 && encoded.lengthInBytes > maxBytes) {
        quality -= 10;
        encoded =
            Uint8List.fromList(imgpkg.encodeJpg(resized, quality: quality));
      }
      // safety to avoid infinite loop
      if (quality <= 30 && (width <= 100 || height <= 100)) break;
    }

    return encoded;
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String _listText(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).join(', ');
    return _text(value);
  }

  static List<String> _splitList(String value) => value
      .split(RegExp(r'[,;]'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  static Uint8List? _decodeBase64(String value) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  static String? _normalizeModality(dynamic value) {
    final raw = value?.toString().trim().toUpperCase() ?? '';
    if (raw == 'ONLINE') return 'ONLINE';
    if (raw == 'PRESENTIAL' || raw == 'PRESENCIAL' || raw == 'IN_PERSON') {
      return 'PRESENTIAL';
    }
    if (raw == 'BOTH' || raw.contains('ONLINE E PRESENCIAL')) return 'BOTH';
    return null;
  }

  static Set<String> _parseDays(dynamic value) {
    final raw = value?.toString() ?? '';
    return _weekdays
        .where((day) => raw.toLowerCase().contains(day.toLowerCase()))
        .toSet();
  }

  void _parseHours(dynamic value) {
    final matches = RegExp(r'(\d{1,2}):(\d{2})')
        .allMatches(value?.toString() ?? '')
        .toList();
    if (matches.length < 2) return;
    TimeOfDay parseMatch(RegExpMatch match) => TimeOfDay(
          hour: int.parse(match.group(1)!),
          minute: int.parse(match.group(2)!),
        );
    _availabilityStart = parseMatch(matches[0]);
    _availabilityEnd = parseMatch(matches[1]);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _selectAvailabilityTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? (_availabilityStart ?? const TimeOfDay(hour: 8, minute: 0))
          : (_availabilityEnd ?? const TimeOfDay(hour: 18, minute: 0)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _availabilityStart = picked;
      } else {
        _availabilityEnd = picked;
      }
      if (_availabilityStart != null && _availabilityEnd != null) {
        availabilityHoursController.text =
            '${_formatTime(_availabilityStart!)} às ${_formatTime(_availabilityEnd!)}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPsychologist = _role == 'PSYCHOLOGIST';
    final imageBytes =
        _profileImageBase64 == null || _profileImageBase64!.isEmpty
            ? null
            : _decodeBase64(_profileImageBase64!);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.cancel_outlined),
          tooltip: 'Cancelar',
          color: Colors.black,
        ),
        title: const Text('Editar perfil',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
              onPressed: _isLoading ? null : _saveProfile,
              icon: const Icon(Icons.done),
              color: Colors.black,
              tooltip: 'Salvar')
        ],
        centerTitle: true,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EditProfileHeader(
              nameController: nomeController,
              emailController: emailController,
              birthdayController: birthdayController,
              imageUrl: _imageFile == null ? _existingImageUrl : null,
              imageBytes: imageBytes,
              imageFile: _imageFile,
              onPickImage: _pickImage,
              onSelectDate: () => _selectDate(context),
            ),
            const SizedBox(height: 10),
            if (isPsychologist)
              _PsychologistEditForm(
                crpController: crpController,
                telefoneController: officePhoneController,
                modalityController: modalityController,
                healthPlansController: healthPlansController,
                officeAddressController: officeAddressController,
                availabilityDaysController: availabilityDaysController,
                availabilityHoursController: availabilityHoursController,
                selectedModality: _selectedModality,
                selectedDays: _selectedAvailabilityDays,
                modalities: _modalities,
                weekdays: _weekdays,
                availabilityStart: _availabilityStart,
                availabilityEnd: _availabilityEnd,
                onModalityChanged: (value) {
                  setState(() {
                    _selectedModality = value;
                    modalityController.text = value ?? '';
                    if (value == 'ONLINE') {
                      officeAddressController.clear();
                      officePhoneController.clear();
                    }
                  });
                },
                onDayChanged: (day, selected) {
                  setState(() {
                    if (selected) {
                      _selectedAvailabilityDays.add(day);
                    } else {
                      _selectedAvailabilityDays.remove(day);
                    }
                    availabilityDaysController.text = _weekdays
                        .where(_selectedAvailabilityDays.contains)
                        .join(', ');
                  });
                },
                selectedHealthPlans: _selectedHealthPlans,
                healthPlanOptions: _healthPlanOptions,
                isOnline: _selectedModality == 'ONLINE',
                onHealthPlanChanged: (plan, selected) {
                  setState(() {
                    if (selected) {
                      _selectedHealthPlans.add(plan);
                    } else {
                      _selectedHealthPlans.remove(plan);
                    }
                    healthPlansController.text =
                        _selectedHealthPlans.join(', ');
                  });
                },
                onTimeSelected: _selectAvailabilityTime,
              )
            else
              _PatientEditForm(
                emailController: emailController,
                cpfController: cpfController,
                telefoneController: telefoneController,
                enderecoController: enderecoController,
                bairroController: bairroController,
                cidadeController: cidadeController,
                cepController: cepController,
                healthPlanController: healthPlanController,
                healthPlanCardController: healthPlanCardController,
                documentCount: _documentCount,
              ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileHeader extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController birthdayController;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final File? imageFile;
  final VoidCallback onPickImage;
  final VoidCallback onSelectDate;

  const _EditProfileHeader({
    required this.nameController,
    required this.emailController,
    required this.birthdayController,
    required this.imageUrl,
    required this.imageBytes,
    required this.imageFile,
    required this.onPickImage,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                if (imageFile != null)
                  CircleAvatar(
                      radius: 42, backgroundImage: FileImage(imageFile!))
                else
                  UserAvatar(
                      imageUrl: imageUrl,
                      imageBytes: imageBytes,
                      radius: 42,
                      useAuthPhoto: false),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined,
                      size: 14, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _EditField(label: 'Nome', controller: nameController),
                const SizedBox(height: 7),
                _EditField(
                    label: 'E-mail',
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 7),
                GestureDetector(
                  onTap: onSelectDate,
                  child: AbsorbPointer(
                    child: _EditField(
                        label: 'Data de nascimento',
                        controller: birthdayController,
                        suffixIcon: Icons.calendar_today_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _PatientEditForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController cpfController;
  final TextEditingController telefoneController;
  final TextEditingController enderecoController;
  final TextEditingController bairroController;
  final TextEditingController cidadeController;
  final TextEditingController cepController;
  final TextEditingController healthPlanController;
  final TextEditingController healthPlanCardController;
  final int documentCount;

  const _PatientEditForm({
    required this.emailController,
    required this.cpfController,
    required this.telefoneController,
    required this.enderecoController,
    required this.bairroController,
    required this.cidadeController,
    required this.cepController,
    required this.healthPlanController,
    required this.healthPlanCardController,
    required this.documentCount,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _EditCard(
            icon: Icons.lock_outline,
            title: 'Dados de contato',
            children: [
              _EditField(
                  label: 'E-mail',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 9),
              const _ReadOnlyPasswordField(),
            ],
          ),
          const SizedBox(height: 10),
          _EditCard(
            icon: Icons.description_outlined,
            title: 'Documentos',
            children: [
              _EditField(
                  label: 'CPF',
                  controller: cpfController,
                  keyboardType: TextInputType.number)
            ],
          ),
          const SizedBox(height: 10),
          _EditCard(
            icon: Icons.location_on_outlined,
            title: 'Telefones',
            children: [
              _EditField(label: 'Endereço', controller: enderecoController),
              const SizedBox(height: 7),
              Row(children: [
                Expanded(
                    child: _EditField(
                        label: 'Bairro', controller: bairroController)),
                const SizedBox(width: 7),
                Expanded(
                    child: _EditField(
                        label: 'Cidade', controller: cidadeController)),
              ]),
              const SizedBox(height: 7),
              Row(children: [
                Expanded(
                    child: _EditField(
                        label: 'CEP',
                        controller: cepController,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 7),
                Expanded(
                    child: _EditField(
                        label: 'Telefone',
                        controller: telefoneController,
                        keyboardType: TextInputType.phone)),
              ]),
            ],
          ),
          const SizedBox(height: 10),
          _EditCard(
            icon: Icons.medical_services_outlined,
            title: 'Plano médico',
            children: [
              _EditField(label: 'Plano', controller: healthPlanController),
              const SizedBox(height: 7),
              _EditField(
                  label: 'Carteirinha', controller: healthPlanCardController),
            ],
          ),
          const SizedBox(height: 10),
          _EditCard(
            icon: Icons.insert_drive_file_outlined,
            title: 'Anexos',
            children: [
              Row(children: [
                Icon(Icons.description_outlined,
                    size: 17,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 7),
                Text('Documentos',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const Spacer(),
                Text('$documentCount arquivo${documentCount == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700)),
              ]),
            ],
          ),
        ],
      );
}

class _PsychologistEditForm extends StatelessWidget {
  final TextEditingController crpController;
  final TextEditingController telefoneController;
  final TextEditingController modalityController;
  final TextEditingController healthPlansController;
  final TextEditingController officeAddressController;
  final TextEditingController availabilityDaysController;
  final TextEditingController availabilityHoursController;
  final String? selectedModality;
  final Set<String> selectedDays;
  final List<Map<String, String>> modalities;
  final List<String> weekdays;
  final TimeOfDay? availabilityStart;
  final TimeOfDay? availabilityEnd;
  final ValueChanged<String?> onModalityChanged;
  final void Function(String day, bool selected) onDayChanged;
  final Set<String> selectedHealthPlans;
  final List<String> healthPlanOptions;
  final void Function(String plan, bool selected) onHealthPlanChanged;
  final Future<void> Function(bool isStart) onTimeSelected;
  final bool isOnline;

  const _PsychologistEditForm({
    required this.crpController,
    required this.telefoneController,
    required this.modalityController,
    required this.healthPlansController,
    required this.officeAddressController,
    required this.availabilityDaysController,
    required this.availabilityHoursController,
    required this.selectedModality,
    required this.selectedDays,
    required this.modalities,
    required this.weekdays,
    required this.availabilityStart,
    required this.availabilityEnd,
    required this.onModalityChanged,
    required this.onDayChanged,
    required this.selectedHealthPlans,
    required this.healthPlanOptions,
    required this.onHealthPlanChanged,
    required this.onTimeSelected,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _EditCard(
            icon: Icons.people_alt_outlined,
            title: 'Informações profissionais',
            children: [
              const SizedBox(height: 7),
              _EditField(
                  label: 'Telefone',
                  controller: telefoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !isOnline),
              const SizedBox(height: 9),
              DropdownButtonFormField<String>(
                value: selectedModality,
                decoration:
                    _dropdownDecoration(context, 'Modelo de atendimento'),
                items: modalities
                    .map((item) => DropdownMenuItem<String>(
                          value: item['value'],
                          child: Text(item['label']!,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: onModalityChanged,
              ),
              const SizedBox(height: 7),
              const Text('Planos médicos aceitos',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: healthPlanOptions
                    .map((plan) => FilterChip(
                          label:
                              Text(plan, style: const TextStyle(fontSize: 13)),
                          selected: selectedHealthPlans.contains(plan),
                          onSelected: (selected) =>
                              onHealthPlanChanged(plan, selected),
                          selectedColor: AppColors.primary.withOpacity(0.18),
                          checkmarkColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                        ))
                    .toList(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _EditCard(
            icon: Icons.location_on_outlined,
            title: 'Endereço do consultório',
            children: [
              _EditField(
                label: 'Endereço',
                controller: officeAddressController,
                enabled: !isOnline,
              )
            ],
          ),
          const SizedBox(height: 10),
          _EditCard(
            icon: Icons.calendar_month_outlined,
            title: 'Horário de atendimento',
            children: [
              const Text('Dias de atendimento',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: weekdays
                    .map((day) => FilterChip(
                          label:
                              Text(day, style: const TextStyle(fontSize: 13)),
                          selected: selectedDays.contains(day),
                          onSelected: (selected) => onDayChanged(day, selected),
                          selectedColor: AppColors.primary.withOpacity(0.18),
                          checkmarkColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              const Text('Horário de atendimento',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                      child: _TimeButton(
                          label: 'Início',
                          value: availabilityStart,
                          onPressed: () => onTimeSelected(true))),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('até', style: TextStyle(fontSize: 14))),
                  Expanded(
                      child: _TimeButton(
                          label: 'Fim',
                          value: availabilityEnd,
                          onPressed: () => onTimeSelected(false))),
                ],
              ),
            ],
          ),
        ],
      );

  InputDecoration _dropdownDecoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      );
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay? value;
  final VoidCallback onPressed;

  const _TimeButton(
      {required this.label, required this.value, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.access_time, size: 19),
        label: Text(
            value == null
                ? label
                : '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
          side: BorderSide(color: AppColors.primary.withOpacity(0.45)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}

class _EditCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _EditCard(
      {required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.18)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Icon(icon, size: 16, color: AppColors.primary)),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 9),
          ...children,
        ]),
      );
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hintText;
  final IconData? suffixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool enabled;

  const _EditField(
      {required this.label,
      required this.controller,
      this.hintText,
      this.suffixIcon,
      this.keyboardType,
      this.maxLines = 1,
      this.enabled = true});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          hintStyle: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, size: 18),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                  color:
                      Theme.of(context).colorScheme.outline.withOpacity(0.2))),
        ),
      );
}

class _ReadOnlyPasswordField extends StatelessWidget {
  const _ReadOnlyPasswordField();

  @override
  Widget build(BuildContext context) => TextField(
        obscureText: true,
        readOnly: true,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          labelText: 'Senha',
          hintText: '••••••••',
          suffixIcon: const Icon(Icons.visibility_outlined, size: 18),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
}
