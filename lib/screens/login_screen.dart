import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as imgpkg;
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/app_colors.dart';
import '../utils/safe_navigation.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/configuration_error_dialog.dart';
import '../widgets/tag_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isLoading = false;
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Form keys
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();
  
  // Signup data
  File? _profileImage;
  List<String> _selectedTags = [];
  String _selectedGoal = '';
  
  final List<String> _availableTags = [
    '#filosofia', '#saúde mental', '#tecnologia', '#cinema', 
    '#música', '#arte', '#literatura', '#viagem', '#culinária',
    '#esportes', '#meditação', '#yoga', '#psicologia', '#ciência',
    '#natureza', '#fotografia', '#design', '#empreendedorismo'
  ];
  
  final List<String> _goals = [
    'Desabafar e ser ouvido(a)',
    'Conversar sobre temas profundos',
    'Aprender com outras perspectivas',
    'Fazer novas amizades',
    'Encontrar apoio emocional',
    'Compartilhar experiências'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'assets/images/luma_com_fundo.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback para o ícone antigo se a imagem não carregar
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 40,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Title
              Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Text(
                  _isLogin ? 'Bem-vindo de volta!' : 'Criar conta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                );
              }),
              
              const SizedBox(height: 8),
              
              Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Text(
                  _isLogin
                      ? 'Entre para continuar sua jornada no MindMatch'
                      : 'Junte-se à nossa comunidade de conexões significativas',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                );
              }),
              
              const SizedBox(height: 40),
              
              // Social login buttons
              _buildSocialButtons(),
              const SizedBox(height: 16),

              // Toggle between login/signup (agora logo abaixo do Google)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Builder(builder: (context) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Text(
                      _isLogin ? 'Não tem uma conta? ' : 'Já tem uma conta? ',
                      style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
                    );
                  }),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin ? 'Cadastre-se' : 'Entrar',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              
              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : null)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'ou',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : null)),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Form
              _isLogin ? _buildLoginForm() : _buildSignupForm(),
              
              // (toggle movido para cima)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    const double maxButtonWidth = 420;
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxButtonWidth),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _isLogin ? 'Entrar com Google' : 'Cadastrar com Google',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                style: () {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppColors.primary : Colors.white,
                    foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                    side: isDark ? const BorderSide(color: Colors.transparent, width: 0) : const BorderSide(color: AppColors.gray300, width: 1),
                    minimumSize: const Size(double.infinity, 54),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                    elevation: isDark ? 2 : 0,
                  );
                }(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Apple Sign In (iOS only) - Temporariamente desabilitado
        /*
        if (Theme.of(context).platform == TargetPlatform.iOS)
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxButtonWidth),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithApple,
                  icon: const Icon(Icons.apple, size: 28),
                  label: Text(_isLogin ? 'Entrar com Apple' : 'Cadastrar com Apple'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkSurface,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ),
        */
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          CustomTextField(
            controller: _emailController,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu e-mail';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Por favor, insira um e-mail válido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _passwordController,
            label: 'Senha',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira sua senha';
              }
              if (value.length < 6) {
                return 'A senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Entrar'),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          TextButton(
            onPressed: _resetPassword,
            child: const Text(
              'Esqueceu sua senha?',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile picture
          Center(
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: _profileImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Image.file(
                          _profileImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: AppColors.gray500,
                      ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Basic info
          CustomTextField(
            controller: _emailController,
            label: 'E-mail',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira seu e-mail';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Por favor, insira um e-mail válido';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _passwordController,
            label: 'Senha',
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira sua senha';
              }
              if (value.length < 6) {
                return 'A senha deve ter pelo menos 6 caracteres';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirmar senha',
            obscureText: true,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'As senhas não coincidem';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _nameController,
                  label: 'Nome',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira seu nome';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _ageController,
                  label: 'Idade',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Insira sua idade';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 18 || age > 100) {
                      return 'Idade inválida';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _cityController,
            label: 'Cidade (opcional)',
          ),
          
          const SizedBox(height: 16),
          
          CustomTextField(
            controller: _bioController,
            label: 'Bio pessoal (opcional)',
            maxLines: 3,
            maxLength: 200,
          ),
          
          const SizedBox(height: 24),
          
          // Tags
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Text(
              'Tags de interesse:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            );
          }),
          
          const SizedBox(height: 12),
          
          TagSelector(
            availableTags: _availableTags,
            selectedTags: _selectedTags,
            onTagsChanged: (tags) {
              setState(() {
                _selectedTags = tags;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Goals
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Text(
              'Seu objetivo no app:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            );
          }),
          
          const SizedBox(height: 12),
          
          ..._goals.map((goal) => RadioListTile<String>(
            title: Text(goal),
            value: goal,
            groupValue: _selectedGoal,
            onChanged: (value) {
              setState(() {
                _selectedGoal = value ?? '';
              });
            },
            activeColor: AppColors.primary,
          )),
          
          const SizedBox(height: 32),
          
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUpWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Criar conta'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential = await authService.signInWithGoogle();
      
      if (userCredential != null && mounted) {
        await SafeNavigation.safeNavigate(context, '/home');
      }
    } catch (e) {
      // Check if it's the known Pigeon error but user was authenticated
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>') ||
          e.toString().contains('channel-error')) {
        
        // Wait a moment and check if user is actually authenticated
        await Future.delayed(Duration(milliseconds: 500));
        final authService = Provider.of<AuthService>(context, listen: false);
        
        if (authService.currentUser != null) {
          // User is authenticated despite the error, proceed to home
          if (mounted) {
            await SafeNavigation.safeNavigate(context, '/home');
          }
          return;
        }
      }
      
      if (mounted) {
        if (e.toString().contains('configuração do Google Sign-In')) {
          ConfigurationErrorDialog.show(
            context,
            title: 'Configuração do Google Sign-In',
            message: 'O Google Sign-In precisa ser configurado no Firebase Console para funcionar corretamente.',
            steps: [
              'Acesse: console.firebase.google.com',
              'Selecione o projeto mindmatch-ba671',
              'Vá em Project Settings > Your apps',
              'Adicione as chaves SHA-1 e SHA-256',
              'Baixe o google-services.json atualizado',
              'Reinicie o aplicativo'
            ],
            onRetry: _signInWithGoogle,
          );
        } else {
          // Only show error if user is not authenticated
          final authService = Provider.of<AuthService>(context, listen: false);
          if (authService.currentUser == null) {
            _showErrorSnackBar('Erro ao entrar com Google: $e');
          }
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Temporariamente desabilitado
  /*
  Future<void> _signInWithApple() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userCredential = await authService.signInWithApple();
      
      if (userCredential != null && mounted) {
        await SafeNavigation.safeNavigate(context, '/home');
      }
    } catch (e) {
      _showErrorSnackBar('Erro ao entrar com Apple: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  */

  Future<void> _signInWithEmail() async {
    if (!_loginFormKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      if (mounted) {
        await SafeNavigation.safeNavigate(context, '/home');
      }
    } catch (e) {
      // Check if it's the known Pigeon error but user was authenticated
      if (e.toString().contains('PigeonUserDetails') || 
          e.toString().contains('List<Object?>') ||
          e.toString().contains('channel-error')) {
        
        // Wait a moment and check if user is actually authenticated
        await Future.delayed(Duration(milliseconds: 500));
        final authService = Provider.of<AuthService>(context, listen: false);
        
        if (authService.currentUser != null) {
          // User is authenticated despite the error, proceed to home
          if (mounted) {
            await SafeNavigation.safeNavigate(context, '/home');
          }
          return;
        }
      }
      
      // Only show error if user is not authenticated
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.currentUser == null) {
        _showErrorSnackBar('Erro ao entrar: $e');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_signupFormKey.currentState!.validate()) return;
    
    if (_selectedTags.isEmpty) {
      _showErrorSnackBar('Por favor, selecione pelo menos uma tag de interesse');
      return;
    }
    
    if (_selectedGoal.isEmpty) {
      _showErrorSnackBar('Por favor, selecione seu objetivo no app');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final firebaseService = Provider.of<FirebaseService>(context, listen: false);
      
      print('🚀 Starting simplified user registration...');
      
      // Step 1: Create user account with explicit error handling
      try {
        await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
        print('✅ User authentication successful');
      } catch (authError) {
        print('❌ Auth error: $authError');
        
        // Check if it's the known Pigeon error but user was still created
        if (authError.toString().contains('PigeonUserDetails') || 
            authError.toString().contains('List<Object?>') ||
            authError.toString().contains('channel-error')) {
          print('🔧 Pigeon error detected, checking if user was created anyway...');
          
          // Wait a moment and check if user exists
          await Future.delayed(Duration(seconds: 1));
          if (authService.currentUser != null) {
            print('✅ User was created despite Pigeon error!');
            // User exists, continue with profile creation
          } else {
            print('❌ User was not created, this is a real error');
            throw authError; // Re-throw if user wasn't actually created
          }
        } else {
          // For other types of errors, check if user was still created
          await Future.delayed(Duration(milliseconds: 500));
          if (authService.currentUser == null) {
            throw authError; // Re-throw if user wasn't actually created
          } else {
            print('✅ User was created despite other error!');
          }
        }
      }
      
      // Step 2: Create profile if user exists
      final currentUser = authService.currentUser;
      if (currentUser != null) {
        final userId = currentUser.uid;
        print('✅ User confirmed: $userId');
        
        try {
          // Create basic profile first
          print('📝 Creating basic profile...');
          await firebaseService.createBasicProfile(
            userId,
            _nameController.text.trim(),
            _emailController.text.trim(),
          );
          print('✅ Basic profile created');
          
          // Add additional fields gradually
          print('📝 Adding additional profile data...');
          
          // Add age safely
          final age = int.tryParse(_ageController.text) ?? 0;
          if (age > 0) {
            await firebaseService.addProfileFields(userId, {'age': age});
          }
          
          // Add optional fields
          if (_cityController.text.trim().isNotEmpty) {
            await firebaseService.addProfileFields(userId, {
              'city': _cityController.text.trim()
            });
          }
          
          if (_bioController.text.trim().isNotEmpty) {
            await firebaseService.addProfileFields(userId, {
              'bio': _bioController.text.trim()
            });
          }
          
          // Add goal
          await firebaseService.addProfileFields(userId, {
            'goal': _selectedGoal
          });
          
          // Add tags as individual fields to avoid List issues
          final cleanTags = _selectedTags
              .where((tag) => tag.trim().isNotEmpty)
              .map((tag) => tag.trim())
              .toList();
          
          if (cleanTags.isNotEmpty) {
            await firebaseService.addProfileFields(userId, {
              'tag_count': cleanTags.length,
              'tags_string': cleanTags.join(','),
            });
            
            // Add individual tag fields
            for (int i = 0; i < cleanTags.length && i < 10; i++) {
              await firebaseService.addProfileFields(userId, {
                'tag_$i': cleanTags[i]
              });
            }
          }
          
          // Upload profile picture last — try byte upload + Base64 fallback (same behavior as profile edit)
          if (_profileImage != null) {
            try {
              // Resize/compress to fit Firestore-friendly limit
              final resized = await _resizeImageIfNeeded(_profileImage!, 700000);
              final bytes = resized;

              String? imageUrl;
              try {
                imageUrl = await firebaseService.uploadUserProfileImage(userId, bytes);
              } catch (e) {
                print('⚠️ uploadUserProfileImage failed: $e');
                imageUrl = null;
              }

              if (imageUrl != null && imageUrl.isNotEmpty) {
                await firebaseService.addProfileFields(userId, {'profileImageUrl': imageUrl});
                print('✅ Profile picture uploaded via bytes');
              } else if (bytes.isNotEmpty) {
                // Fallback to base64 in Firestore
                final base64 = base64Encode(bytes);
                await firebaseService.addProfileFields(userId, {
                  'profileImageBase64': base64,
                  'profileImageStoredIn': 'firestore_base64'
                });
                print('✅ Profile picture saved as base64 in Firestore');
              }
            } catch (imageError) {
              print('⚠️ Profile picture processing failed: $imageError');
              // Continue anyway
            }
          }
          
          print('✅ Complete profile creation finished!');
          
        } catch (profileError) {
          print('⚠️ Profile creation error: $profileError');
          // Don't throw - user is created, profile can be completed later
        }
        
        // Always navigate to home if user exists
        if (mounted) {
          _showSuccessSnackBar('Conta criada com sucesso!');
          await SafeNavigation.safeNavigate(context, '/home');
        }
        
      } else {
        throw Exception('Falha na criação do usuário');
      }
      
    } catch (e) {
      print('❌ Registration error: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Check for Pigeon errors first
      bool isPigeonError = e.toString().contains('PigeonUserDetails') || 
                          e.toString().contains('List<Object?>') ||
                          e.toString().contains('channel-error');
      
      // Final check - sometimes user gets created despite errors
      await Future.delayed(Duration(milliseconds: 500));
      final auth = Provider.of<AuthService>(context, listen: false);
      
      if (auth.currentUser != null) {
        print('✅ User exists despite error, proceeding to home');
        if (mounted) {
          if (isPigeonError) {
            _showSuccessSnackBar('Conta criada com sucesso!');
          } else {
            _showSuccessSnackBar('Conta criada! Complete seu perfil depois.');
          }
          await SafeNavigation.safeNavigate(context, '/home');
        }
      } else {
        // Show appropriate error message only if user wasn't created
        String errorMessage = 'Erro ao criar conta';
        
        if (isPigeonError) {
          errorMessage = 'Erro de comunicação. Tente novamente.';
        } else if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Este e-mail já está em uso';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'A senha é muito fraca';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'E-mail inválido';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet.';
        }
        _showErrorSnackBar(errorMessage);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      _showErrorSnackBar('Por favor, insira seu e-mail primeiro');
      return;
    }
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendPasswordResetEmail(_emailController.text.trim());
      _showSuccessSnackBar('E-mail de recuperação enviado!');
    } catch (e) {
      _showErrorSnackBar('Erro ao enviar e-mail de recuperação: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  // Resize image file to try to get under maxBytes; returns JPEG bytes
  Future<Uint8List> _resizeImageIfNeeded(File file, int maxBytes) async {
    try {
      final original = await file.readAsBytes();
      if (original.lengthInBytes <= maxBytes) return original;

      final img = imgpkg.decodeImage(original);
      if (img == null) return original;

      int quality = 85;
      int width = img.width;
      int height = img.height;
      Uint8List encoded = Uint8List.fromList(imgpkg.encodeJpg(img, quality: quality));

      while (encoded.lengthInBytes > maxBytes && (width > 100 || height > 100)) {
        width = (width * 0.8).floor();
        height = (height * 0.8).floor();
        final resized = imgpkg.copyResize(img, width: width, height: height);
        encoded = Uint8List.fromList(imgpkg.encodeJpg(resized, quality: quality));
        if (quality > 40 && encoded.lengthInBytes > maxBytes) {
          quality -= 10;
          encoded = Uint8List.fromList(imgpkg.encodeJpg(resized, quality: quality));
        }
        if (quality <= 30 && (width <= 100 || height <= 100)) break;
      }

      return encoded;
    } catch (e) {
      print('⚠️ Error resizing image: $e');
      return Uint8List(0);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
