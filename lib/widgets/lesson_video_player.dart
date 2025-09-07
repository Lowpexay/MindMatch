import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../utils/app_colors.dart';

class LessonVideoPlayer extends StatefulWidget {
  final Lesson lesson;
  final VoidCallback? onVideoCompleted;

  const LessonVideoPlayer({
    Key? key,
    required this.lesson,
    this.onVideoCompleted,
  }) : super(key: key);

  @override
  State<LessonVideoPlayer> createState() => _LessonVideoPlayerState();
}

class _LessonVideoPlayerState extends State<LessonVideoPlayer> {
  bool _isPlaying = false;
  bool _isCompleted = false;
  double _progress = 0.0;
  int _currentTimeInSeconds = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video placeholder (since we don't have real video URLs)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.8),
                  AppColors.secondary.withOpacity(0.6),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 80,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.lesson.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Duração: ${widget.lesson.duration} min',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Play/Pause Button
          if (!_isCompleted)
            Positioned(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

          // Completed overlay
          if (_isCompleted)
            Positioned(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ),

          // Progress bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Time indicator
          if (_isPlaying || _isCompleted)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_formatTime(_currentTimeInSeconds)} / ${_formatTime(widget.lesson.duration * 60)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _togglePlayPause() {
    if (_isCompleted) return;

    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _startVideoSimulation();
    }
  }

  void _startVideoSimulation() {
    // Simulate video playback for demo purposes
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isPlaying && mounted) {
        setState(() {
          _currentTimeInSeconds += 1;
          _progress = _currentTimeInSeconds / (widget.lesson.duration * 60);
          
          if (_progress >= 1.0) {
            _progress = 1.0;
            _isPlaying = false;
            _isCompleted = true;
            widget.onVideoCompleted?.call();
          }
        });
        
        if (_isPlaying) {
          _startVideoSimulation();
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

// Simple video controls widget
class VideoControls extends StatelessWidget {
  final bool isPlaying;
  final bool isCompleted;
  final double progress;
  final VoidCallback onPlayPause;
  final Function(double) onSeek;

  const VideoControls({
    Key? key,
    required this.isPlaying,
    required this.isCompleted,
    required this.progress,
    required this.onPlayPause,
    required this.onSeek,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withOpacity(0.2),
              trackHeight: 2,
            ),
            child: Slider(
              value: progress,
              onChanged: isCompleted ? null : onSeek,
              min: 0.0,
              max: 1.0,
            ),
          ),
          
          // Play controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: isCompleted ? null : onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause : Icons.play_arrow,
                  color: isCompleted ? Colors.grey : Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
