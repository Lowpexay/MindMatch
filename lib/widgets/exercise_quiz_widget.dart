import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../utils/app_colors.dart';

class ExerciseQuizWidget extends StatefulWidget {
  final List<Exercise> exercises;
  final Function(String exerciseId, bool isCorrect) onExerciseCompleted;

  const ExerciseQuizWidget({
    Key? key,
    required this.exercises,
    required this.onExerciseCompleted,
  }) : super(key: key);

  @override
  State<ExerciseQuizWidget> createState() => _ExerciseQuizWidgetState();
}

class _ExerciseQuizWidgetState extends State<ExerciseQuizWidget> {
  int _currentExerciseIndex = 0;
  int? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  Map<String, bool> _completedExercises = {};

  Exercise get _currentExercise => widget.exercises[_currentExerciseIndex];

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum exercício disponível',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          
          const SizedBox(height: 24),
          
          // Question
          _buildQuestionCard(),
          
          const SizedBox(height: 24),
          
          // Options
          _buildOptionsSection(),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons(),
          
          if (_showResult) ...[
            const SizedBox(height: 24),
            _buildResultSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Exercício ${_currentExerciseIndex + 1} de ${widget.exercises.length}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${((_currentExerciseIndex + 1) / widget.exercises.length * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentExerciseIndex + 1) / widget.exercises.length,
          backgroundColor: AppColors.gray200,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
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
          const Row(
            children: [
              Icon(
                Icons.quiz,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Pergunta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _currentExercise.question,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha a resposta correta:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_currentExercise.options.length, (index) {
          return _buildOptionCard(index);
        }),
      ],
    );
  }

  Widget _buildOptionCard(int index) {
    final bool isSelected = _selectedAnswer == index;
    final bool isCorrect = index == _currentExercise.correctAnswer;
    final bool showCorrectAnswer = _showResult && isCorrect;
    final bool showWrongAnswer = _showResult && isSelected && !isCorrect;

    Color borderColor = AppColors.gray200;
    Color backgroundColor = Colors.white;
    Color textColor = AppColors.textPrimary;

    if (showCorrectAnswer) {
      borderColor = Colors.green;
      backgroundColor = Colors.green.withOpacity(0.1);
      textColor = Colors.green.shade700;
    } else if (showWrongAnswer) {
      borderColor = Colors.red;
      backgroundColor = Colors.red.withOpacity(0.1);
      textColor = Colors.red.shade700;
    } else if (isSelected) {
      borderColor = AppColors.primary;
      backgroundColor = AppColors.primary.withOpacity(0.05);
      textColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _showResult ? null : () {
          setState(() {
            _selectedAnswer = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected || showCorrectAnswer || showWrongAnswer
                        ? Colors.transparent
                        : AppColors.gray300,
                    width: 2,
                  ),
                  color: showCorrectAnswer
                      ? Colors.green
                      : showWrongAnswer
                          ? Colors.red
                          : isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                ),
                child: showCorrectAnswer || showWrongAnswer
                    ? Icon(
                        showCorrectAnswer ? Icons.check : Icons.close,
                        size: 16,
                        color: Colors.white,
                      )
                    : isSelected
                        ? const Icon(
                            Icons.circle,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _currentExercise.options[index],
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: isSelected || showCorrectAnswer || showWrongAnswer
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        if (_currentExerciseIndex > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _goToPreviousExercise,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.gray300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Anterior'),
            ),
          ),
        
        if (_currentExerciseIndex > 0)
          const SizedBox(width: 12),
        
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _getButtonAction(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_getButtonText()),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _isCorrect ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isCorrect ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.cancel,
                color: _isCorrect ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _isCorrect ? 'Resposta Correta!' : 'Resposta Incorreta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Explicação:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentExercise.explanation,
            style: TextStyle(
              fontSize: 14,
              color: _isCorrect ? Colors.green.shade600 : Colors.red.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (!_showResult) {
      return _selectedAnswer != null ? 'Verificar Resposta' : 'Selecione uma opção';
    } else {
      return _currentExerciseIndex < widget.exercises.length - 1
          ? 'Próxima Pergunta'
          : 'Concluir Exercícios';
    }
  }

  VoidCallback? _getButtonAction() {
    if (!_showResult) {
      return _selectedAnswer != null ? _checkAnswer : null;
    } else {
      return _currentExerciseIndex < widget.exercises.length - 1
          ? _goToNextExercise
          : _completeExercises;
    }
  }

  void _checkAnswer() {
    setState(() {
      _isCorrect = _selectedAnswer == _currentExercise.correctAnswer;
      _showResult = true;
    });

    // Registrar conclusão do exercício
    widget.onExerciseCompleted(_currentExercise.id, _isCorrect);
    _completedExercises[_currentExercise.id] = _isCorrect;
  }

  void _goToNextExercise() {
    setState(() {
      _currentExerciseIndex++;
      _selectedAnswer = null;
      _showResult = false;
      _isCorrect = false;
    });
  }

  void _goToPreviousExercise() {
    setState(() {
      _currentExerciseIndex--;
      _selectedAnswer = null;
      _showResult = false;
      _isCorrect = false;
    });
  }

  void _completeExercises() {
    // Mostrar resultado final
    final correctAnswers = _completedExercises.values.where((c) => c).length;
    final totalAnswers = _completedExercises.length;
    final percentage = (correctAnswers / totalAnswers * 100).round();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.celebration, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Exercícios Concluídos!',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Você acertou $correctAnswers de $totalAnswers questões',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$percentage% de aproveitamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: percentage >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              percentage >= 70 
                ? '🎉 Parabéns! Você foi aprovado!' 
                : '📚 Continue praticando para melhorar!',
              style: TextStyle(
                fontSize: 14,
                color: percentage >= 70 ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          if (percentage < 70)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fechar dialog
                // Reiniciar quiz
                setState(() {
                  _currentExerciseIndex = 0;
                  _selectedAnswer = null;
                  _showResult = false;
                  _isCorrect = false;
                  _completedExercises.clear();
                });
              },
              child: const Text('Tentar Novamente'),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar dialog
              if (percentage >= 70) {
                // Marcar todos os exercícios como concluídos
                for (var exercise in widget.exercises) {
                  widget.onExerciseCompleted(exercise.id, true);
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exercícios concluídos com sucesso! ✅'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              Navigator.of(context).pop(); // Voltar para tela anterior
            },
            child: Text(percentage >= 70 ? 'Concluir' : 'Voltar'),
          ),
        ],
      ),
    );
  }
}
