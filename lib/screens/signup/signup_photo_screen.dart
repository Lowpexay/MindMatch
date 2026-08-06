import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/firebase_service.dart';
import '../../utils/safe_navigation.dart';
import 'package:go_router/go_router.dart';

class SignupPhotoScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const SignupPhotoScreen({super.key, this.data});

  @override
  State<SignupPhotoScreen> createState() => _SignupPhotoScreenState();
}

class _SignupPhotoScreenState extends State<SignupPhotoScreen> {
  File? _image;
  bool _isLoading = false;

  Future<void> _pick() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() => _image = File(file.path));
    }
  }

  Future<void> _finish() async {
    final stateExtra = GoRouterState.of(context).extra;
    final args = widget.data ?? (stateExtra is Map<String,dynamic> ? stateExtra : {});
    debugPrint('[SignupPhoto] received args=$args');
    final name = (args['name'] as String?)?.trim() ?? '';
    final email = (args['email'] as String?)?.trim() ?? '';
    final password = (args['password'] as String?) ?? '';
    final dobMs = args['dob'] as int?;
    final bio = (args['bio'] as String?)?.trim() ?? '';
    final tags = (args['tags'] as List<String>?) ?? const [];
    final goal = (args['goal'] as String?)?.trim() ?? '';
    final role = (args['role'] as String?)?.trim().toUpperCase() ?? 'PATIENT';
    final gender = (args['gender'] as String?)?.trim() ?? '';
    final cpf = (args['cpf'] as String?)?.trim() ?? '';
    final phone = (args['nTelefone'] as String?)?.trim() ?? '';
    final healthPlan = (args['healthPlan'] as String?)?.trim() ?? '';
    final documentPaths = (args['documentPaths'] as List?)?.cast<String>() ?? const <String>[];
    final documentNames = (args['documentNames'] as List?)?.cast<String>() ?? const <String>[];
    final crp = (args['crp'] as String?)?.trim() ?? '';
    final careerStart = (args['careerStart'] as String?)?.trim() ?? '';
    final modality = (args['modality'] as String?)?.trim() ?? '';
    final officeAddress = (args['officeAddress'] as String?)?.trim() ?? '';
    final officePhone = (args['officePhone'] as String?)?.trim() ?? '';
    final availabilityDays = (args['availabilityDays'] as String?)?.trim() ?? '';
    final availabilityHours = (args['availabilityHours'] as String?)?.trim() ?? '';
    final healthPlans = (args['healthPlans'] as String?)?.trim() ?? '';
    final personalizedMessage = (args['personalizedMessage'] as String?)?.trim() ?? '';
    final specialties = (args['specialties'] as List?)?.map((item) => item.toString()).toList() ?? const <String>[];

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      // Se algo realmente essencial sumiu, avisar e voltar ao início do fluxo.
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informações essenciais ausentes. Reinicie o cadastro.')));
      debugPrint('[SignupPhoto] Missing essentials name=$name email=$email passwordLen=${password.length}');
      if (mounted) context.go('/signupBasic');
      return;
    }

    setState(()=> _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen:false);
      final firebaseService = Provider.of<FirebaseService>(context, listen:false);

      try {
        await auth.signUpWithEmail(email, password);
      } catch (e) {
        // Erros Pigeon/List podem ocorrer mas o usuário pode ter sido criado
        if (e.toString().contains('PigeonUserDetails') || e.toString().contains('List<Object?>')) {
          await Future.delayed(const Duration(milliseconds: 400));
        } else {
          rethrow;
        }
      }
      final user = auth.currentUser;
      if (user == null) throw Exception('Falha na autenticação (usuário nulo após signup)');
      String? profileImageUrl;

      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'birthDate': dobMs,
        'bio': bio,
        'goal': goal,
        'gender': gender,
        'cpf': cpf,
        'phone': phone,
        'tags': tags,
        'role': role,
      };

      final Map<String, dynamic> roleSpecificData = {
        'goal': goal,
      };

      if (role == 'PATIENT') {
        roleSpecificData.addAll({
          'healthPlan': healthPlan,
          'documentPaths': documentPaths,
          'documentNames': documentNames,
        });
      } else {
        roleSpecificData.addAll({
          'crp': crp,
          'careerStart': careerStart,
          'modality': modality,
          'officeAddress': officeAddress,
          'officePhone': officePhone,
          'availabilityDays': availabilityDays,
          'availabilityHours': availabilityHours,
          'healthPlans': healthPlans,
          'personalizedMessage': personalizedMessage,
          'specialties': specialties,
        });
      }

      if (_image != null) {
        try {
          final bytes = await _image!.readAsBytes();
          // try upload (function might create url) fallback base64
          String? imageUrl;
          try {
            imageUrl = await firebaseService.uploadUserProfileImage(user.uid, bytes);
          } catch (_) {
            imageUrl = null;
          }
          if (imageUrl != null && imageUrl.isNotEmpty) {
            profileImageUrl = imageUrl;
            userData['profileImageUrl'] = imageUrl;
            roleSpecificData['profileImageUrl'] = imageUrl;
          } else if (bytes.isNotEmpty) {
            final base64 = base64Encode(bytes);
            userData['profileImageBase64'] = base64;
            roleSpecificData['profileImageBase64'] = base64;
          }
        } catch (_) {}
      }

      if (documentPaths.isNotEmpty) {
        final uploadedDocuments = <Map<String, String>>[];
        for (var i = 0; i < documentPaths.length; i++) {
          try {
            final path = documentPaths[i];
            final file = File(path);
            final fileName = i < documentNames.length ? documentNames[i] : file.path.split(RegExp(r'[\\/]')).last;
            final ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
            final storagePath = 'users/${user.uid}/documents/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';
            final url = await firebaseService.uploadFile(file, storagePath);
            uploadedDocuments.add({'name': fileName, 'url': url});
          } catch (_) {}
        }
        if (uploadedDocuments.isNotEmpty) {
          roleSpecificData['documents'] = uploadedDocuments;
        }
      }

      if (goal.isNotEmpty) {
        userData['goal'] = goal;
        roleSpecificData['goal'] = goal;
      }
      if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
        userData['profileImageUrl'] = profileImageUrl;
        roleSpecificData['profileImageUrl'] = profileImageUrl;
      }

      await auth.updateUserProfile(displayName: name);
      await firebaseService.createUserWithRole(
        userData: userData,
        role: role,
        roleSpecificData: roleSpecificData,
        documentId: user.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada!')));
        await SafeNavigation.safeNavigate(context, '/home');
      }
    } catch (e) {
      // Se for erro de transporte mas usuário existe, prosseguir para home
      final auth = Provider.of<AuthService>(context, listen:false);
      if (auth.currentUser != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada (com avisos).')));
        await SafeNavigation.safeNavigate(context, '/home');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    } finally {
      if (mounted) setState(()=> _isLoading=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: isDark? Colors.white: AppColors.textPrimary),
        title: const Text('Foto de perfil (Opcional)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark? Colors.white: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pick,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gray300),
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  ),
                  child: _image==null ? const Icon(Icons.add_a_photo, size: 40, color: AppColors.gray500) : ClipOval(child: Image.file(_image!, fit: BoxFit.cover)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Adicione uma foto', style: TextStyle(color: isDark? Colors.white70 : AppColors.textSecondary)),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading ? const SizedBox(height:24,width:24,child: CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Text('Começar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
