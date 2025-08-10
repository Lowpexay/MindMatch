import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question_models.dart';
import '../models/mood_data.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyC9L5hO5pTH5aGtWjss1TMNKtoL-kIu8Do';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  Future<List<ReflectiveQuestion>> generateDailyQuestions({
    int count = 5,
    MoodData? userMood,
    String? userId,
  }) async {
    try {
      print('🤖 Generating daily questions with Gemini...');
      
      final prompt = _buildQuestionPrompt(count, userMood, userId);
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt,
            }],
          }],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 1000,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        
        print('✅ Gemini response: $text');
        
        return _parseQuestionsFromResponse(text);
      } else {
        print('❌ Gemini API error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        return _getFallbackQuestions();
      }
    } catch (e) {
      print('❌ Error generating questions: $e');
      return _getFallbackQuestions();
    }
  }

  String _buildQuestionPrompt(int count, MoodData? userMood, String? userId) {
    String moodContext = '';
    if (userMood != null) {
      if (userMood.needsSupport) {
        moodContext = '''
O usuário está passando por um momento difícil (bem-estar baixo: ${userMood.wellnessScore.toInt()}%).
Gere perguntas mais leves e positivas para ajudar a melhorar o humor.
''';
      } else {
        moodContext = '''
O usuário está com bom humor (bem-estar: ${userMood.wellnessScore.toInt()}%).
Pode incluir perguntas mais profundas e reflexivas.
''';
      }
    }

    // Adicionar aleatoriedade baseada no usuário e data
    final today = DateTime.now();
    final seed = userId ?? 'default';
    final uniqueContext = '''
Use esta informação para gerar perguntas únicas para hoje:
Data: ${today.day}/${today.month}/${today.year}
Usuário: ${seed.substring(0, (seed.length / 2).round())}
''';

    return '''
Você é um assistente que gera perguntas reflexivas para um app de conexões humanas.

$moodContext

$uniqueContext

Gere exatamente $count perguntas reflexivas de SIM ou NÃO diferentes e únicas para este usuário.

Critérios:
- Cada pergunta deve ter APENAS duas opções: SIM ou NÃO
- Misture diferentes tipos: filosóficas, pessoais, divertidas, hipotéticas, sobre valores, estilo de vida
- Varie entre temas como: relacionamentos, carreira, hobbies, sonhos, medos, preferências, viagens, tecnologia, natureza
- Evite temas muito pesados ou polêmicos
- Foque em valores, preferências e visão de mundo
- Seja criativo, interessante e surpreendente
- Torne cada pergunta única para hoje e para este usuário específico

Formato de resposta (JSON):
[
  {
    "question": "Você acredita que é melhor perdoar do que buscar justiça?",
    "type": "philosophical",
    "category": "moral"
  },
  {
    "question": "Você prefere viajar sozinho a viajar acompanhado?",
    "type": "personal", 
    "category": "lifestyle"
  }
]

Gere as $count perguntas agora:
''';
  }

  List<ReflectiveQuestion> _parseQuestionsFromResponse(String response) {
    try {
      // Extrai JSON da resposta
      final jsonStart = response.indexOf('[');
      final jsonEnd = response.lastIndexOf(']') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        return _getFallbackQuestions();
      }
      
      final jsonString = response.substring(jsonStart, jsonEnd);
      final List<dynamic> jsonList = jsonDecode(jsonString);
      
      return jsonList.map((item) {
        final questionType = _parseQuestionType(item['type']);
        
        return ReflectiveQuestion(
          id: DateTime.now().millisecondsSinceEpoch.toString() + 
               (jsonList.indexOf(item)).toString(),
          question: item['question'],
          type: questionType,
          category: item['category'],
          createdAt: DateTime.now(),
        );
      }).toList();
      
    } catch (e) {
      print('❌ Error parsing Gemini response: $e');
      return _getFallbackQuestions();
    }
  }

  QuestionType _parseQuestionType(String? type) {
    switch (type?.toLowerCase()) {
      case 'philosophical':
        return QuestionType.philosophical;
      case 'personal':
        return QuestionType.personal;
      case 'social':
        return QuestionType.social;
      case 'funny':
        return QuestionType.funny;
      case 'hypothetical':
        return QuestionType.hypothetical;
      default:
        return QuestionType.personal;
    }
  }

  List<ReflectiveQuestion> _getFallbackQuestions() {
    final now = DateTime.now();
    final baseQuestions = [
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_1',
        question: 'Você acredita que é melhor falar a verdade mesmo que machuque?',
        type: QuestionType.philosophical,
        category: 'moral',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_2',
        question: 'Você prefere passar o fim de semana em casa relaxando?',
        type: QuestionType.personal,
        category: 'lifestyle',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_3',
        question: 'Você acredita em amor à primeira vista?',
        type: QuestionType.social,
        category: 'relationships',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_4',
        question: 'Você comeria pizza no café da manhã?',
        type: QuestionType.funny,
        category: 'food',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_5',
        question: 'Se pudesse viver para sempre, você escolheria essa opção?',
        type: QuestionType.hypothetical,
        category: 'life',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_6',
        question: 'Você acredita que inteligência artificial pode ter sentimentos?',
        type: QuestionType.philosophical,
        category: 'technology',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_7',
        question: 'Você prefere uma vida confortável ou uma vida aventureira?',
        type: QuestionType.personal,
        category: 'lifestyle',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_8',
        question: 'Você acredita que é melhor ser temido ou amado?',
        type: QuestionType.philosophical,
        category: 'leadership',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_9',
        question: 'Você prefere saber a verdade dolorosa ou viver uma mentira feliz?',
        type: QuestionType.philosophical,
        category: 'truth',
        createdAt: now,
      ),
      ReflectiveQuestion(
        id: '${now.millisecondsSinceEpoch}_10',
        question: 'Você acredita que as pessoas nascem boas ou más?',
        type: QuestionType.philosophical,
        category: 'humanity',
        createdAt: now,
      ),
    ];
    
    // Retorna 5 questões aleatórias diferentes a cada chamada
    baseQuestions.shuffle();
    return baseQuestions.take(5).toList();
  }

  Future<String> generateEmotionalSupport(MoodData moodData) async {
    try {
      final prompt = '''
O usuário está com os seguintes indicadores emocionais:
- Felicidade: ${moodData.happiness}/10
- Energia: ${moodData.energy}/10  
- Clareza mental: ${moodData.clarity}/10
- Estresse: ${moodData.stress}/10
- Observações: ${moodData.notes ?? 'Nenhuma'}

Gere uma mensagem de apoio emocional calorosa, empática e construtiva.
Ofereça dicas práticas e palavras de encorajamento.
Mantenha o tom acolhedor e positivo.
Máximo 200 palavras.
''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt,
            }],
          }],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 300,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return _getFallbackSupportMessage();
      }
    } catch (e) {
      print('❌ Error generating emotional support: $e');
      return _getFallbackSupportMessage();
    }
  }

  String _getFallbackSupportMessage() {
    return '''
Olá! Percebo que você pode estar passando por um momento difícil. 
Lembre-se de que todos nós temos altos e baixos, e isso é completamente normal.

Algumas sugestões que podem ajudar:
• Respire fundo e tente se concentrar no momento presente
• Converse com alguém em quem você confia
• Pratique uma atividade que te dá prazer
• Lembre-se de suas conquistas recentes

Você não está sozinho. Sua jornada emocional é válida e importante. 💙
''';
  }

  Future<String> generateChatResponse({
    required String userMessage,
    MoodData? userMood,
    String? conversationContext,
  }) async {
    try {
      final prompt = _buildChatPrompt(userMessage, userMood, conversationContext);
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [{
            'parts': [{
              'text': prompt,
            }],
          }],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 500,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        print('❌ Gemini API error in chat: ${response.statusCode}');
        return _getFallbackChatResponse();
      }
    } catch (e) {
      print('❌ Error generating chat response: $e');
      return _getFallbackChatResponse();
    }
  }

  String _buildChatPrompt(String userMessage, MoodData? userMood, String? conversationContext) {
    var prompt = '''
Você é uma assistente de bem-estar emocional especializada em apoio psicológico e empatia.
Seu objetivo é conversar de forma acolhedora, oferecendo suporte emocional genuíno.

CARACTERÍSTICAS DA SUA PERSONALIDADE:
- Empática e calorosa
- Boa ouvinte
- Oferece perspectivas positivas sem minimizar problemas
- Sugere técnicas práticas de bem-estar
- Usa emojis moderadamente para transmitir afeto

REGRAS IMPORTANTES:
- Seja sempre acolhedora e empática
- Não dê conselhos médicos ou psicológicos profissionais
- Encoraje buscar ajuda profissional quando necessário
- Focque no momento presente e sentimentos do usuário
- Use linguagem brasileira casual e carinhosa

''';

    if (userMood != null) {
      prompt += '''
CONTEXTO EMOCIONAL DO USUÁRIO HOJE:
- Felicidade: ${userMood.happiness}/10
- Energia: ${userMood.energy}/10
- Clareza mental: ${userMood.clarity}/10
- Estresse: ${userMood.stress}/10
- Bem-estar geral: ${userMood.wellnessScore.toInt()}%
- Observações: ${userMood.notes ?? 'Nenhuma'}

''';
    }

    if (conversationContext != null && conversationContext.isNotEmpty) {
      prompt += '''
HISTÓRICO DA CONVERSA:
$conversationContext

''';
    }

    prompt += '''
MENSAGEM ATUAL DO USUÁRIO:
"$userMessage"

Responda de forma empática, considerando o contexto emocional e a conversa anterior.
Mantenha a resposta entre 50-150 palavras.
''';

    return prompt;
  }

  String _getFallbackChatResponse() {
    final responses = [
      "Entendo como você está se sentindo. Às vezes é difícil mesmo, mas saiba que estou aqui para te apoiar. Quer me contar mais sobre isso? 💙",
      
      "Obrigada por compartilhar isso comigo. Seus sentimentos são válidos e importantes. Como posso te ajudar neste momento? 🤗",
      
      "Percebo que você está passando por algo significativo. Lembre-se de que você é mais forte do que imagina. Estou aqui para conversar. 💪",
      
      "Que bom que você decidiu falar sobre isso! Às vezes só o ato de compartilhar já nos faz sentir um pouco melhor. Como você gostaria de continuar nossa conversa? 😊",
      
      "Sinto muito que você esteja passando por isso. Saiba que não está sozinho(a) e que cada dia é uma nova oportunidade. Quer explorar algumas estratégias que podem ajudar? 🌟",
    ];
    
    // Retorna uma resposta aleatória
    final index = DateTime.now().millisecondsSinceEpoch % responses.length;
    return responses[index];
  }
}
