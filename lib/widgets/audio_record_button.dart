import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AudioRecordButton extends StatefulWidget {
  final bool isRecording;
  final bool isEnabled;
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final String? partialText;
  
  const AudioRecordButton({
    super.key,
    this.isRecording = false,
    this.isEnabled = true,
    this.onStartRecording,
    this.onStopRecording,
    this.partialText,
  });

  @override
  State<AudioRecordButton> createState() => _AudioRecordButtonState();
}

class _AudioRecordButtonState extends State<AudioRecordButton> 
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animação de pulso para quando está gravando
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animação de escala
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));

    if (widget.isRecording) {
      _startAnimations();
    }
  }

  @override
  void didUpdateWidget(AudioRecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _startAnimations();
      } else {
        _stopAnimations();
      }
    }
  }

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _waveController.forward();
  }

  void _stopAnimations() {
    _pulseController.stop();
    _waveController.reverse();
    _pulseController.reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Texto parcial (se houver)
        if (widget.partialText?.isNotEmpty == true) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.mic,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.partialText!,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Botão de gravação
        GestureDetector(
          onTapDown: (_) => _waveController.forward(),
          onTapUp: (_) => _waveController.reverse(),
          onTapCancel: () => _waveController.reverse(),
          onTap: widget.isEnabled 
            ? (widget.isRecording 
                ? widget.onStopRecording 
                : widget.onStartRecording)
            : null,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isEnabled 
                      ? (widget.isRecording 
                          ? Colors.red.withOpacity(0.8)
                          : AppColors.primary)
                      : Colors.grey,
                    boxShadow: [
                      BoxShadow(
                        color: widget.isRecording 
                          ? Colors.red.withOpacity(0.3) 
                          : AppColors.primary.withOpacity(0.3),
                        blurRadius: widget.isRecording ? 16 : 8,
                        spreadRadius: widget.isRecording ? 2 : 0,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: widget.isRecording ? 28 : 32,
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Texto do status
        Text(
          widget.isRecording 
            ? 'Gravando... (toque para parar)'
            : widget.isEnabled 
              ? 'Toque para gravar áudio'
              : 'Microfone indisponível',
          style: TextStyle(
            color: widget.isRecording 
              ? Colors.red 
              : widget.isEnabled 
                ? AppColors.textSecondary
                : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Indicador de ondas sonoras quando gravando (simplificado)
        if (widget.isRecording) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 100)),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: widget.isRecording ? 8 + (index % 3 * 8) : 4,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}