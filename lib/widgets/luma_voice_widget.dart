import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class LumaVoiceWidget extends StatefulWidget {
  final bool isSpeaking;
  final String? currentMessage;
  final VoidCallback? onTap;

  const LumaVoiceWidget({
    super.key,
    required this.isSpeaking,
    this.currentMessage,
    this.onTap,
  });

  @override
  State<LumaVoiceWidget> createState() => _LumaVoiceWidgetState();
}

class _LumaVoiceWidgetState extends State<LumaVoiceWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animação de pulso para quando está falando
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animação de onda sonora
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animações se estiver falando
    if (widget.isSpeaking) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(LumaVoiceWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      if (widget.isSpeaking) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.stop();
    _pulseController.reset();
    _waveController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar da Luma com animações
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: widget.isSpeaking ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.primary.withOpacity(0.05),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                          child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/luma_chat_avatar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback para emoji se a imagem não carregar
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade300,
                                        Colors.orange.shade500,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '🦊',
                                      style: TextStyle(fontSize: 60),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              // Nome da Luma
              const Text(
                'Luma',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Status/Indicador de fala
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isSpeaking 
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.gray100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.isSpeaking 
                        ? AppColors.primary
                        : AppColors.gray300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador de áudio
                    if (widget.isSpeaking) ...[
                      AnimatedBuilder(
                        animation: _waveAnimation,
                        builder: (context, child) {
                          return Row(
                            children: List.generate(3, (index) {
                              final delay = index * 0.2;
                              final animValue = (_waveAnimation.value + delay) % 1.0;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 3,
                                height: 12 + (animValue * 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                    
                    Text(
                      widget.isSpeaking ? 'Falando...' : 'Pronta para conversar',
                      style: TextStyle(
                        color: widget.isSpeaking 
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 15),
              
              // Balãozinho com texto atual (se tiver)
              if (widget.currentMessage != null && widget.currentMessage!.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.currentMessage!,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Setinha do balão
                        const SizedBox(height: 6),
                        CustomPaint(
                          size: const Size(16, 8),
                          painter: _BubbleTailPainter(),
                        ),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Instruções
              Text(
                widget.isSpeaking 
                    ? 'Toque para parar'
                    : 'Toque para conversar por voz',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2 - 10, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width / 2 + 10, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
