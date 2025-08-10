import 'package:flutter/material.dart';
import '../models/question_models.dart';
import '../utils/app_colors.dart';

class ReflectiveQuestionsWidget extends StatefulWidget {
  final List<ReflectiveQuestion> questions;
  final Function(QuestionResponse) onQuestionAnswered;
  final Map<String, bool> existingAnswers;

  const ReflectiveQuestionsWidget({
    super.key,
    required this.questions,
    required this.onQuestionAnswered,
    this.existingAnswers = const {},
  });

  @override
  State<ReflectiveQuestionsWidget> createState() => _ReflectiveQuestionsWidgetState();
}

class _ReflectiveQuestionsWidgetState extends State<ReflectiveQuestionsWidget> {
  int _currentQuestionIndex = 0;
  final Map<String, bool> _answers = {};

  @override
  void initState() {
    super.initState();
    _answers.addAll(widget.existingAnswers);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return _buildEmptyState();
    }

    final currentQuestion = widget.questions[_currentQuestionIndex];
    final hasAnswered = _answers.containsKey(currentQuestion.id);

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
          // Header
          Row(
            children: [
              Icon(
                Icons.psychology_alt,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Perguntas Reflexivas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildQuestionCounter(),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Indicador de progresso
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            backgroundColor: AppColors.gray200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          
          const SizedBox(height: 24),
          
          // Categoria da pergunta
          _buildQuestionCategory(currentQuestion.type, currentQuestion.category),
          
          const SizedBox(height: 16),
          
          // Pergunta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              currentQuestion.question,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Botões de resposta
          if (!hasAnswered) ...[
            Row(
              children: [
                Expanded(
                  child: _buildAnswerButton(
                    label: 'NÃO',
                    value: false,
                    color: Colors.red,
                    icon: Icons.close,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildAnswerButton(
                    label: 'SIM',
                    value: true,
                    color: Colors.green,
                    icon: Icons.check,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Mostrar resposta dada
            _buildAnswerGiven(_answers[currentQuestion.id]!),
          ],
          
          const SizedBox(height: 20),
          
          // Navegação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
              TextButton.icon(
                onPressed: _currentQuestionIndex < widget.questions.length - 1 
                    ? _nextQuestion 
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Próxima'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
        children: [
          Icon(
            Icons.psychology_alt,
            size: 48,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          const Text(
            'Carregando perguntas reflexivas...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${_currentQuestionIndex + 1}/${widget.questions.length}',
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildQuestionCategory(QuestionType type, String? category) {
    final categoryName = _getCategoryName(type);
    final categoryColor = _getCategoryColor(type);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        categoryName,
        style: TextStyle(
          color: categoryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required bool value,
    required Color color,
    required IconData icon,
  }) {
    return ElevatedButton.icon(
      onPressed: () => _answerQuestion(value),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildAnswerGiven(bool answer) {
    final color = answer ? Colors.green : Colors.red;
    final label = answer ? 'SIM' : 'NÃO';
    final icon = answer ? Icons.check_circle : Icons.cancel;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            'Você respondeu: $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(QuestionType type) {
    switch (type) {
      case QuestionType.philosophical:
        return '🤔 Filosófica';
      case QuestionType.personal:
        return '🎯 Pessoal';
      case QuestionType.social:
        return '👥 Social';
      case QuestionType.funny:
        return '😄 Divertida';
      case QuestionType.hypothetical:
        return '💭 Hipotética';
    }
  }

  Color _getCategoryColor(QuestionType type) {
    switch (type) {
      case QuestionType.philosophical:
        return Colors.purple;
      case QuestionType.personal:
        return Colors.blue;
      case QuestionType.social:
        return Colors.green;
      case QuestionType.funny:
        return Colors.orange;
      case QuestionType.hypothetical:
        return Colors.indigo;
    }
  }

  void _answerQuestion(bool answer) {
    final currentQuestion = widget.questions[_currentQuestionIndex];
    
    setState(() {
      _answers[currentQuestion.id] = answer;
    });

    final response = QuestionResponse(
      userId: '', // Será preenchido pelo service
      questionId: currentQuestion.id,
      answer: answer,
      answeredAt: DateTime.now(),
    );

    widget.onQuestionAnswered(response);

    // Auto-navegar para próxima pergunta após 1 segundo
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _currentQuestionIndex < widget.questions.length - 1) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }
}
