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

      await firebaseService.createBasicProfile(user.uid, name, email);

      if (dobMs != null) {
        await firebaseService.addProfileFields(user.uid, {'birthDate': dobMs});
      }
      if (bio.isNotEmpty) {
        await firebaseService.addProfileFields(user.uid, {'bio': bio});
      }
      if (goal.isNotEmpty) {
        await firebaseService.addProfileFields(user.uid, {'goal': goal});
      }
      if (tags.isNotEmpty) {
        await firebaseService.addProfileFields(user.uid, {
          'tag_count': tags.length,
          'tags_string': tags.join(','),
        });
        for (int i=0;i<tags.length && i<10;i++) {
          await firebaseService.addProfileFields(user.uid, {'tag_$i': tags[i]});
        }
      }

      if (_image != null) {
        try {
          final bytes = await _image!.readAsBytes();
          // try upload (function might create url) fallback base64
          String? imageUrl;
          try { imageUrl = await firebaseService.uploadUserProfileImage(user.uid, bytes); } catch(_){ imageUrl = null; }
          if (imageUrl != null && imageUrl.isNotEmpty) {
            await firebaseService.addProfileFields(user.uid, {'profileImageUrl': imageUrl});
          } else if (bytes.isNotEmpty) {
            final base64 = base64Encode(bytes);
            await firebaseService.addProfileFields(user.uid, {'profileImageBase64': base64});
          }
        } catch (_) {}
      }

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
