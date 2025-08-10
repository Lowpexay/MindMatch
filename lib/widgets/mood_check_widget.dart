import 'package:flutter/material.dart';
import '../models/mood_data.dart';
import '../utils/app_colors.dart';

class MoodCheckWidget extends StatefulWidget {
  final Function(MoodData) onMoodSubmitted;
  final MoodData? initialMood;

  const MoodCheckWidget({
    super.key,
    required this.onMoodSubmitted,
    this.initialMood,
  });

  @override
  State<MoodCheckWidget> createState() => _MoodCheckWidgetState();
}

class _MoodCheckWidgetState extends State<MoodCheckWidget> {
  late int _happiness;
  late int _energy;
  late int _clarity;
  late int _stress;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _happiness = widget.initialMood?.happiness ?? 5;
    _energy = widget.initialMood?.energy ?? 5;
    _clarity = widget.initialMood?.clarity ?? 5;
    _stress = widget.initialMood?.stress ?? 5;
    _notesController.text = widget.initialMood?.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  'Como você está se sentindo hoje?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          _buildMoodSlider(
            label: 'Felicidade',
            value: _happiness,
            onChanged: (value) => setState(() => _happiness = value),
            color: Colors.orange,
            icon: Icons.mood,
          ),
          
          const SizedBox(height: 16),
          
          _buildMoodSlider(
            label: 'Energia',
            value: _energy,
            onChanged: (value) => setState(() => _energy = value),
            color: Colors.green,
            icon: Icons.battery_charging_full,
          ),
          
          const SizedBox(height: 16),
          
          _buildMoodSlider(
            label: 'Clareza Mental',
            value: _clarity,
            onChanged: (value) => setState(() => _clarity = value),
            color: Colors.blue,
            icon: Icons.lightbulb_outline,
          ),
          
          const SizedBox(height: 16),
          
          _buildMoodSlider(
            label: 'Estresse',
            value: _stress,
            onChanged: (value) => setState(() => _stress = value),
            color: Colors.red,
            icon: Icons.warning_amber,
            isStress: true,
          ),
          
          const SizedBox(height: 20),
          
          // Campo de observações
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Observações (opcional)',
              hintText: 'Como foi seu dia? O que está sentindo?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.note_alt_outlined),
            ),
            maxLines: 2,
            maxLength: 200,
          ),
          
          const SizedBox(height: 20),
          
          // Botão de salvar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitMood,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Registrar Estado',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSlider({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
    required Color color,
    required IconData icon,
    bool isStress = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$value/10',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.3),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
            trackHeight: 6,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            onChanged: (newValue) => onChanged(newValue.round()),
          ),
        ),
        
        // Labels dos extremos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isStress ? 'Calmo' : 'Baixo',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                isStress ? 'Estressado' : 'Alto',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submitMood() {
    final moodData = MoodData(
      userId: '', // Será preenchido pelo service
      date: DateTime.now(),
      happiness: _happiness,
      energy: _energy,
      clarity: _clarity,
      stress: _stress,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    widget.onMoodSubmitted(moodData);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
