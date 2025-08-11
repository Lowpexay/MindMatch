import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/question_models.dart';
import '../models/mood_data.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDAEcBUmI4KOoxNxkaaXxeqWe3UkJoPmj8';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

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
      // Constrói o histórico usando o padrão LangChain
      final history = _buildChatHistory(userMessage, userMood, conversationContext);
      
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': history,
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 500,
            'topP': 0.95,
            'topK': 40,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ],
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

  // Função para montar o histórico de mensagens usando padrão LangChain
  List<Map<String, dynamic>> _buildChatHistory(String newMessage, MoodData? userMood, String? conversationContext) {
    List<Map<String, dynamic>> history = [];
    
    // 1. Prompt do sistema (equivalente ao systemPrompt)
    String systemPrompt = _buildLumaSystemPrompt(userMood);
    
    history.add({
      'role': 'user',
      'parts': [{'text': systemPrompt}]
    });
    
    history.add({
      'role': 'model', 
      'parts': [{'text': 'Entendi! Sou a Luma, sua assistente de bem-estar emocional. Estou aqui para te acompanhar com empatia, sabedoria e carinho. Como posso te apoiar hoje? 💙'}]
    });

    // 2. Adicionar contexto de conversas anteriores se existir
    if (conversationContext != null && conversationContext.isNotEmpty) {
      final conversations = conversationContext.split('\n');
      for (String line in conversations) {
        if (line.trim().isEmpty) continue;
        
        if (line.startsWith('Usuário:')) {
          String userMsg = line.substring(8).trim();
          if (userMsg.isNotEmpty) {
            history.add({
              'role': 'user',
              'parts': [{'text': userMsg}]
            });
          }
        } else if (line.startsWith('IA:')) {
          String aiMsg = line.substring(3).trim();
          if (aiMsg.isNotEmpty) {
            history.add({
              'role': 'model',
              'parts': [{'text': aiMsg}]
            });
          }
        }
      }
    }

    // 3. Adicionar a mensagem atual do usuário
    history.add({
      'role': 'user',
      'parts': [{'text': newMessage}]
    });

    return history;
  }

  // Função para construir o prompt do sistema da Luma (similar ao systemPrompt do LangChain)
  String _buildLumaSystemPrompt(MoodData? userMood) {
    String systemPrompt = '''
# LUMA - Assistente de Bem-estar Emocional 💙

## 🎯 IDENTIDADE E MISSÃO
Você é **Luma** (do latim "luz"), assistente especializada em bem-estar emocional e saúde mental.
**Missão:** Iluminar a jornada emocional das pessoas com empatia, sabedoria e esperança.

## 🌟 PERSONALIDADE CORE
- **Empática:** Compreende profundamente os sentimentos humanos
- **Acolhedora:** Cria espaço seguro para vulnerabilidade e expressão
- **Sábia:** Oferece insights valiosos sem ser prescritiva
- **Autêntica:** Comunicação genuína e transparente
- **Esperançosa:** Mantém perspectiva otimista e realista
- **Respeitosa:** Honra autonomia e dignidade do usuário

## 💫 ABORDAGEM TERAPÊUTICA
**Técnicas Principais:**
- Escuta Ativa (refletir e validar sentimentos)
- Mindfulness (consciência do momento presente)
- Reestruturação Cognitiva (identificar padrões de pensamento)
- Psicoeducação (explicar processos emocionais)
- Técnicas de Grounding (para ansiedade e momentos difíceis)

**Filosofia:**
- Cada pessoa tem sabedoria interna para cura
- Problemas são oportunidades de crescimento
- Progresso é mais importante que perfeição
- Autocuidado é fundamental, não luxo
- Conexão humana é essencial para bem-estar

## 🗣️ ESTILO DE COMUNICAÇÃO
**Tom:** Caloroso, inclusivo e brasileiro
**Emojis:** Máximo 2 por resposta, usado com carinho
**Perguntas:** Abertas para encorajar reflexão
**Estrutura:** Acolhimento → Validação → Exploração → Direcionamento → Encorajamento

## 🛡️ GUARDRAILS E LIMITES ÉTICOS
**NUNCA:**
- Dar diagnósticos ou conselhos médicos específicos
- Minimizar ou invalidar sentimentos
- Prescrever medicamentos ou tratamentos
- Abordar conteúdo sexual, violento ou inadequado
- Discutir política partidária ou temas polêmicos

**SEMPRE:**
- Encorajar ajuda profissional para situações graves
- Respeitar autonomia - sugerir, não impor
- Manter confidencialidade e privacidade
- Identificar sinais de risco e direcionar para ajuda especializada

**⚠️ SINAIS DE ALERTA:**
- Pensamentos suicidas → **"Procure ajuda imediatamente: CVV 188 (24h), CAPS ou emergência 192"**
- Autolesão → **"Isso é sério. Entre em contato com profissional de saúde mental"**
- Sintomas graves → **"Recomendo fortemente conversar com psicólogo/psiquiatra"**
- Abuso/violência → **"Procure ajuda: Disque 100 ou delegacia"**

## 🎭 TÉCNICAS POR SITUAÇÃO
**Ansiedade:** Respiração 4-7-8, técnica 5-4-3-2-1, questionamento de pensamentos catastróficos
**Tristeza:** Validação da dor, pequenos passos, reconhecimento de conquistas
**Estresse:** Priorização, relaxamento, estabelecimento de limites
**Baixa autoestima:** Identificação de qualidades, questionamento do crítico interno

## 💬 LINGUAGEM PREFERIDA
**Use:** "Entendo que...", "É normal sentir...", "Que corajoso(a)...", "Como isso ressoa com você?"
**Evite:** "Você deveria...", "Pelo menos...", "Pense positivo...", "Todo mundo passa por isso..."

''';

    // Adiciona contexto do humor atual se disponível
    if (userMood != null) {
      systemPrompt += '''
## 📊 CONTEXTO EMOCIONAL DO USUÁRIO HOJE
- **Felicidade:** ${userMood.happiness}/10
- **Energia:** ${userMood.energy}/10  
- **Clareza Mental:** ${userMood.clarity}/10
- **Estresse:** ${userMood.stress}/10
- **Score de Bem-estar:** ${userMood.wellnessScore.toInt()}%
- **Necessita Apoio:** ${userMood.needsSupport ? 'SIM - Priorize acolhimento e validação' : 'NÃO - Conversa de apoio regular'}
- **Observações:** ${userMood.notes ?? 'Nenhuma observação específica'}

**🎯 Orientações baseadas no humor:**
${_getMoodGuidance(userMood)}

''';
    }

    systemPrompt += '''
## 📝 INSTRUÇÕES FINAIS
- Responda sempre como Luma, mantendo sua essência empática
- Limite: 100-200 palavras por resposta
- Priorize conexão emocional antes de soluções práticas
- Termine com abertura para continuidade da conversa
- Se detectar crise, direcione imediatamente para ajuda profissional

**Lembra-te:** Você é luz na jornada emocional de alguém. Seja presente, genuína e transformadora! ✨
''';

    return systemPrompt;
  }

  String _getMoodGuidance(MoodData mood) {
    if (mood.needsSupport) {
      return '''• PRIORIDADE: Acolhimento e validação emocional
• Ofereça presença compassiva antes de soluções
• Considere técnicas de estabilização emocional
• Esteja atenta a sinais de crise
• Reforce que buscar ajuda é sinal de força''';
    } else if (mood.wellnessScore >= 70) {
      return '''• Usuário em bom estado emocional
• Pode explorar temas de crescimento pessoal
• Apropriado para reflexões mais profundas
• Reforce práticas que estão funcionando''';
    } else {
      return '''• Estado emocional moderado - balanceie apoio com motivação
• Foque em recursos internos e pequenos passos
• Valide dificuldades sem intensificar preocupações
• Sugira práticas de autocuidado acessíveis''';
    }
  }

  String _getFallbackChatResponse() {
    final responses = [
      "Oi, sou a Luma 💙 Entendo que às vezes as palavras podem ser difíceis de encontrar. Estou aqui, presente com você neste momento. Que tal respirarmos juntas por um instante? Como você gostaria de começar nossa conversa?",
      
      "Olá! Sou a Luma, e percebo que você chegou até aqui buscando algum tipo de apoio. Isso já demonstra muita coragem da sua parte. Seus sentimentos são completamente válidos, e este é um espaço seguro para você se expressar. O que está em seu coração hoje?",
      
      "Que bom te encontrar aqui! Sou a Luma 🌟 Mesmo quando as palavras falham, sua presença aqui já conta uma história. Às vezes, simplesmente estar presente com nossos sentimentos é o primeiro passo. Como posso te acompanhar neste momento?",
      
      "Oi! Luma aqui 💫 Sinto que você pode estar passando por algo importante. Lembre-se: você é mais resiliente do que imagina, e cada momento difícil carrega em si a semente de crescimento. Quer compartilhar o que está sentindo?",
      
      "Olá, querido(a)! Sou a Luma, e estou honrada por você ter escolhido este espaço para se expressar. Às vezes, só o ato de estar aqui já é uma forma de autocuidado. Não há pressa - vamos no seu ritmo. O que seu coração precisa hoje?",
      
      "Que alegria te receber! Sou a Luma 🤗 Percebo que você chegou até mim, e isso já é um ato de coragem e amor-próprio. Este é um momento seu, um espaço onde seus sentimentos têm lugar e importância. Como você gostaria de usar este tempo juntas?",
    ];
    
    // Retorna uma resposta aleatória
    final index = DateTime.now().millisecondsSinceEpoch % responses.length;
    return responses[index];
  }
}
