import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/firebase_service.dart';
import '../services/auth_service.dart';

class AppColorsProfile {
  static const Color whiteBack = Color(0xFFF9FAFA);
  static const Color purpleBack = Color(0xFF6365F1);
  static const Color blackFont = Color(0xFF262626);
  static const Color lightGreyFont = Color(0xFFcac9c9);
}

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

  File? _imageFile;
  String? _existingImageUrl;
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentProfile());
  }

  Future<void> _loadCurrentProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);

    final user = auth.currentUser;
    if (user == null) return;

    try {
      final profile = await firebaseService.getUserProfile(user.uid);
      if (profile != null) {
        setState(() {
          nomeController.text = (profile['name'] ?? '') as String;
          emailController.text = (profile['email'] ?? '') as String;
          cidadeController.text = (profile['city'] ?? '') as String;
          bioController.text = (profile['bio'] ?? '') as String;
          instagramController.text = (profile['instagram'] ?? '') as String;
          twitterController.text = (profile['twitter'] ?? '') as String;
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
          _existingImageUrl = profile['profileImageUrl'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar perfil: $e')));
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
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário não autenticado')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? uploadedUrl;
      if (_imageFile != null) {
        uploadedUrl = await firebaseService.uploadProfilePicture(_imageFile!, user.uid);
      }

      final updates = <String, dynamic>{};
      if (nomeController.text.trim().isNotEmpty) updates['name'] = nomeController.text.trim();
      if (emailController.text.trim().isNotEmpty) updates['email'] = emailController.text.trim();
      if (cidadeController.text.trim().isNotEmpty) updates['city'] = cidadeController.text.trim();
      if (bioController.text.trim().isNotEmpty) updates['bio'] = bioController.text.trim();
      if (instagramController.text.trim().isNotEmpty) updates['instagram'] = instagramController.text.trim();
      if (twitterController.text.trim().isNotEmpty) updates['twitter'] = twitterController.text.trim();
      if (selectedDate != null) updates['birthdate'] = selectedDate!.millisecondsSinceEpoch;
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) updates['profileImageUrl'] = uploadedUrl;

      if (updates.isNotEmpty) {
        await firebaseService.updateUserProfile(user.uid, updates);
      }

      // Update firebase auth profile for displayName/photoURL
      await auth.updateUserProfile(displayName: nomeController.text.trim().isEmpty ? null : nomeController.text.trim(), photoURL: uploadedUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil salvo com sucesso')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar perfil: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.push('/profile');
          },
          icon: const Icon(Icons.cancel_outlined),
          tooltip: 'Cancelar',
          color: AppColorsProfile.whiteBack,
        ),
        title: Text(
          'Editar Perfil',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColorsProfile.whiteBack),
        ),
        actions: [
          IconButton(onPressed: _isLoading ? null : _saveProfile, icon: const Icon(Icons.done), color: AppColorsProfile.whiteBack)
        ],
        centerTitle: true,
        backgroundColor: AppColorsProfile.purpleBack,
      ),
      body: SingleChildScrollView(
        child: Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(30),
          decoration: const BoxDecoration(color: AppColorsProfile.purpleBack),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                              ? NetworkImage(_existingImageUrl!)
                              : null,
                      child: (_imageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty))
                          ? const Icon(Icons.add_a_photo, size: 30, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Adicionar Foto', style: TextStyle(color: AppColorsProfile.whiteBack, fontWeight: FontWeight.bold))
                ],
              ),
              const SizedBox(height: 25),
              InputDadoPerfil(icon: Icons.person_outline, label: 'Nome:', controller: nomeController),
              const SizedBox(height: 25),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data de nascimento:', style: TextStyle(color: AppColorsProfile.whiteBack, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: birthdayController,
                    readOnly: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColorsProfile.whiteBack,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColorsProfile.lightGreyFont)),
                      prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColorsProfile.purpleBack),
                    ),
                    onTap: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              InputDadoPerfil(icon: Icons.location_on_outlined, label: 'Cidade:', controller: cidadeController),
              const SizedBox(height: 25),
              InputDadoPerfil(icon: Icons.email, label: 'Email:', controller: emailController),
              const SizedBox(height: 25),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bio:', style: TextStyle(color: AppColorsProfile.whiteBack, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: bioController,
                    maxLines: 5,
                    minLines: 3,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(hintText: 'Bio', filled: true, fillColor: AppColorsProfile.whiteBack),
                  )
                ],
              ),
              const SizedBox(height: 25),
              InputDadoPerfil(icon: Icons.camera_alt_outlined, label: 'Instagram:', controller: instagramController),
              const SizedBox(height: 25),
              InputDadoPerfil(icon: Icons.wifi_tethering_outlined, label: 'Twitter:', controller: twitterController),
            ],
          ),
        ),
      ),
    );
  }
}

class InputDadoPerfil extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;

  const InputDadoPerfil({Key? key, required this.icon, required this.label, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColorsProfile.whiteBack, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: const TextStyle(color: AppColorsProfile.lightGreyFont),
            filled: true,
            fillColor: AppColorsProfile.whiteBack,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColorsProfile.lightGreyFont)),
            prefixIcon: Icon(icon, color: AppColorsProfile.purpleBack),
          ),
        )
      ],
    );
  }
}

