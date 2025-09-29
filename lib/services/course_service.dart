import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/course_models.dart';
import 'achievement_service.dart';

class CourseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AchievementService _achievementService;

  CourseService(this._achievementService);

  // Collections
  static const String coursesCollection = 'courses';
  static const String lessonsCollection = 'lessons';
  static const String exercisesCollection = 'exercises';
  static const String courseProgressCollection = 'course_progress';
  static const String userFavoritesCollection = 'user_favorites';

  // Cache
  List<Course> _courses = [];
  Map<String, List<Lesson>> _courseLessons = {};
  Map<String, CourseProgress> _userProgress = {};
  Set<String> _favoriteCourseIds = {};

  // Delegates para conteúdo estático - usando switch inline para evitar problemas
  // de resolução de símbolos durante o build
  List<Lesson> _staticLessonsFor(String courseId) {
    print('🎓 _staticLessonsFor chamado para: $courseId');
    // Normalização: aceitar ids curtos (sem prefixo) e mapear para versão canônica 'curso_*'
    String id = courseId;
    switch (courseId) {
      case 'respiracao': id = 'curso_respiracao'; break;
      case 'mindfulness': id = 'curso_mindfulness'; break;
      case 'emocoes': id = 'curso_emocoes'; break;
      case 'autoestima': id = 'curso_autoestima'; break;
      case 'estresse': id = 'curso_estresse'; break;
      case 'sono_reparador': id = 'curso_sono_reparador'; break;
      case 'resiliencia_emocional': id = 'curso_resiliencia_emocional'; break;
      case 'comunicacao_empatica': id = 'curso_comunicacao_empatica'; break;
      case 'equilibrio_digital': id = 'curso_equilibrio_digital'; break;
      case 'autocompaixao': id = 'curso_autocompaixao'; break;
    }

    switch (id) {
      case 'curso_respiracao':
        return [
          Lesson(
            id: 'resp_lesson_1',
            courseId: courseId,
            title: 'Introdução à Respiração Consciente',
            description: 'Entenda os fundamentos científicos da respiração e seu impacto na ansiedade',
            videoUrl: 'https://www.youtube.com/watch?v=YRPh_GaiL8s',
            duration: 720,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resp_lesson_2',
            courseId: courseId,
            title: 'Técnica 4-7-8 para Relaxamento',
            description: 'Aprenda a técnica 4-7-8 desenvolvida pelo Dr. Andrew Weil',
            videoUrl: 'https://www.youtube.com/watch?v=YQq4VwkDwWQ',
            duration: 480,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resp_lesson_3',
            courseId: courseId,
            title: 'Respiração Diafragmática',
            description: 'Pratique a respiração profunda usando o diafragma',
            videoUrl: 'https://www.youtube.com/watch?v=1Dv-ldGLnIY',
            duration: 600,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resp_lesson_4',
            courseId: courseId,
            title: 'Respiração Box (Quadrada)',
            description: 'Técnica de respiração em 4 tempos para concentração',
            videoUrl: 'https://www.youtube.com/watch?v=tEmt1Znux58',
            duration: 540,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resp_lesson_5',
            courseId: courseId,
            title: 'Prática Guiada Completa',
            description: 'Sessão completa combinando todas as técnicas aprendidas',
            videoUrl: 'https://www.youtube.com/watch?v=DbDoBzGY3vo',
            duration: 900,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_mindfulness':
        return [
          Lesson(
            id: 'mind_lesson_1',
            courseId: courseId,
            title: 'O que é Mindfulness?',
            description: 'Introdução aos conceitos fundamentais da atenção plena',
            videoUrl: 'https://www.youtube.com/watch?v=HmEo6RI4Wvs',
            duration: 840,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'mind_lesson_2',
            courseId: courseId,
            title: 'Meditação da Respiração',
            description: 'Aprenda a técnica básica de meditação focada na respiração',
            videoUrl: 'https://www.youtube.com/watch?v=ZToicYcHIOU',
            duration: 600,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'mind_lesson_3',
            courseId: courseId,
            title: 'Observação dos Pensamentos',
            description: 'Desenvolva a habilidade de observar pensamentos sem julgamento',
            videoUrl: 'https://www.youtube.com/watch?v=mMMerxh_12U',
            duration: 720,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'mind_lesson_4',
            courseId: courseId,
            title: 'Body Scan - Varredura Corporal',
            description: 'Técnica de relaxamento e consciência corporal',
            videoUrl: 'https://www.youtube.com/watch?v=15q-N-_kkrU',
            duration: 780,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'mind_lesson_5',
            courseId: courseId,
            title: 'Mindfulness no Dia a Dia',
            description: 'Como aplicar a atenção plena nas atividades cotidianas',
            videoUrl: 'https://www.youtube.com/watch?v=3nwwKbM_vJc',
            duration: 660,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_emocoes':
        return [
          Lesson(
            id: 'emo_lesson_1',
            courseId: courseId,
            title: 'Compreendendo as Emoções',
            description: 'Aprenda sobre o papel das emoções e como elas funcionam',
            videoUrl: 'https://www.youtube.com/watch?v=R1vskiVDwl4',
            duration: 720,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'emo_lesson_2',
            courseId: courseId,
            title: 'Identificando Gatilhos Emocionais',
            description: 'Reconheça situações que desencadeiam reações emocionais',
            videoUrl: 'https://www.youtube.com/watch?v=h-rGgpUbR7k',
            duration: 600,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'emo_lesson_3',
            courseId: courseId,
            title: 'Técnicas de Regulação Emocional',
            description: 'Estratégias práticas para gerenciar emoções intensas',
            videoUrl: 'https://www.youtube.com/watch?v=BG46IwVfSu8',
            duration: 780,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'emo_lesson_4',
            courseId: courseId,
            title: 'Empatia e Relacionamentos',
            description: 'Como desenvolver empatia e melhorar relacionamentos',
            videoUrl: 'https://www.youtube.com/watch?v=1Evwgu369Jw',
            duration: 660,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'emo_lesson_5',
            courseId: courseId,
            title: 'Construindo Resiliência Emocional',
            description: 'Desenvolva capacidade de recuperação após adversidades',
            videoUrl: 'https://www.youtube.com/watch?v=NWH8N-BvhAw',
            duration: 840,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_autoestima':
        return [
          Lesson(
            id: 'auto_lesson_1',
            courseId: courseId,
            title: 'Entendendo a Autoestima',
            description: 'Conceitos fundamentais sobre autoestima e autoimagem',
            videoUrl: 'https://www.youtube.com/watch?v=f-m2YcdMdFw',
            duration: 720,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'auto_lesson_2',
            courseId: courseId,
            title: 'Identificando Crenças Limitantes',
            description: 'Reconheça pensamentos que sabotam sua autoestima',
            videoUrl: 'https://www.youtube.com/watch?v=IC3W1BiUjp0',
            duration: 600,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'auto_lesson_3',
            courseId: courseId,
            title: 'Praticando Autocompaixão',
            description: 'Aprenda a ser gentil consigo mesmo',
            videoUrl: 'https://www.youtube.com/watch?v=IvtZBUSplr4',
            duration: 540,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'auto_lesson_4',
            courseId: courseId,
            title: 'Estabelecendo Limites Saudáveis',
            description: 'Como dizer não e proteger seu bem-estar',
            videoUrl: 'https://www.youtube.com/watch?v=7bk_DG0eSWE',
            duration: 660,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'auto_lesson_5',
            courseId: courseId,
            title: 'Celebrando Suas Conquistas',
            description: 'Aprenda a reconhecer e valorizar seus progressos',
            videoUrl: 'https://www.youtube.com/watch?v=psN1DORYYV0',
            duration: 480,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_estresse':
        return [
          Lesson(
            id: 'stress_lesson_1',
            courseId: courseId,
            title: 'Compreendendo o Estresse',
            description: 'Entenda as causas e efeitos do estresse no organismo',
            videoUrl: 'https://www.youtube.com/watch?v=hnpQrMqDoqE',
            duration: 780,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'stress_lesson_2',
            courseId: courseId,
            title: 'Técnicas de Relaxamento',
            description: 'Métodos eficazes para reduzir tensão e estresse',
            videoUrl: 'https://www.youtube.com/watch?v=92i5m3tV5XY',
            duration: 600,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'stress_lesson_3',
            courseId: courseId,
            title: 'Gerenciamento de Tempo',
            description: 'Organize seu tempo para reduzir pressão e ansiedade',
            videoUrl: 'https://www.youtube.com/watch?v=oTugjssqOT0',
            duration: 720,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'stress_lesson_4',
            courseId: courseId,
            title: 'Exercícios Físicos e Estresse',
            description: 'Como a atividade física ajuda no controle do estresse',
            videoUrl: 'https://www.youtube.com/watch?v=DsVzKCk066g',
            duration: 540,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'stress_lesson_5',
            courseId: courseId,
            title: 'Construindo Resiliência',
            description: 'Desenvolva capacidade de lidar com pressões do trabalho',
            videoUrl: 'https://www.youtube.com/watch?v=R18OvzOe9p0',
            duration: 660,
            order: 5,
            type: LessonType.video,
          ),
        ];






      case 'curso_sono_reparador':
        return [
          Lesson(
            id: 'sono_lesson_1',
            courseId: courseId,
            title: 'A Importância do Sono Reparador',
            description: 'Compreenda como o sono afeta sua saúde mental e física',
            videoUrl: 'https://www.youtube.com/watch?v=5MuIMqhT8DM',
            duration: 720,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'sono_lesson_2',
            courseId: courseId,
            title: 'Higiene do Sono',
            description: 'Estabeleça rotinas saudáveis para melhorar a qualidade do sono',
            videoUrl: 'https://www.youtube.com/watch?v=nm1TxQj9IsQ',
            duration: 600,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'sono_lesson_3',
            courseId: courseId,
            title: 'Técnicas de Relaxamento para Dormir',
            description: 'Métodos eficazes para relaxar antes de dormir',
            videoUrl: 'https://www.youtube.com/watch?v=1ZYbU82GVz4',
            duration: 540,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'sono_lesson_4',
            courseId: courseId,
            title: 'Alimentação e Sono',
            description: 'Como a dieta afeta a qualidade do seu sono',
            videoUrl: 'https://www.youtube.com/watch?v=EiEIdWZzuT0',
            duration: 480,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'sono_lesson_5',
            courseId: courseId,
            title: 'Criando o Ambiente Ideal',
            description: 'Otimize seu quarto para um sono reparador',
            videoUrl: 'https://www.youtube.com/watch?v=t0kACis_dJE',
            duration: 420,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_resiliencia_emocional':
        return [
          Lesson(
            id: 'resil_lesson_1',
            courseId: courseId,
            title: 'Entendendo a Resiliência',
            description: 'O que é resiliência e por que ela é importante',
            videoUrl: 'https://www.youtube.com/watch?v=NWH8N-BvhAw',
            duration: 780,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resil_lesson_2',
            courseId: courseId,
            title: 'Desenvolvendo Mentalidade de Crescimento',
            description: 'Como cultivar uma mentalidade que vê desafios como oportunidades',
            videoUrl: 'https://www.youtube.com/watch?v=hiiEeMN7vbQ',
            duration: 660,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resil_lesson_3',
            courseId: courseId,
            title: 'Regulação Emocional em Crises',
            description: 'Técnicas para manter equilíbrio emocional em momentos difíceis',
            videoUrl: 'https://www.youtube.com/watch?v=BG46IwVfSu8',
            duration: 720,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resil_lesson_4',
            courseId: courseId,
            title: 'Construindo Redes de Apoio',
            description: 'A importância das conexões sociais para a resiliência',
            videoUrl: 'https://www.youtube.com/watch?v=1Evwgu369Jw',
            duration: 600,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'resil_lesson_5',
            courseId: courseId,
            title: 'Transformando Adversidades em Crescimento',
            description: 'Como extrair aprendizados e força de experiências difíceis',
            videoUrl: 'https://www.youtube.com/watch?v=R18OvzOe9p0',
            duration: 840,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_comunicacao_empatica':
        return [
          Lesson(
            id: 'com_lesson_1',
            courseId: courseId,
            title: 'Fundamentos da Comunicação Empática',
            description: 'Os pilares da comunicação com empatia e compaixão',
            videoUrl: 'https://www.youtube.com/watch?v=1Evwgu369Jw',
            duration: 720,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'com_lesson_2',
            courseId: courseId,
            title: 'Escuta Ativa e Presença',
            description: 'Como estar verdadeiramente presente nas conversas',
            videoUrl: 'https://www.youtube.com/watch?v=rzsVh8YwZEQ',
            duration: 600,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'com_lesson_3',
            courseId: courseId,
            title: 'Validação Emocional',
            description: 'Técnicas para validar e acolher emoções dos outros',
            videoUrl: 'https://www.youtube.com/watch?v=h-rGgpUbR7k',
            duration: 540,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'com_lesson_4',
            courseId: courseId,
            title: 'Comunicação Não-Violenta',
            description: 'Princípios da CNV para diálogos mais conectivos',
            videoUrl: 'https://www.youtube.com/watch?v=l7TONauJGfc',
            duration: 780,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'com_lesson_5',
            courseId: courseId,
            title: 'Resolvendo Conflitos com Empatia',
            description: 'Como mediar conflitos priorizando conexão e entendimento',
            videoUrl: 'https://www.youtube.com/watch?v=8sjA90hvnQ0',
            duration: 660,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_equilibrio_digital':
        return [
          Lesson(
            id: 'dig_lesson_1',
            courseId: courseId,
            title: 'Reconhecendo a Sobrecarga Digital',
            description: 'Identifique sinais de uso problemático da tecnologia',
            videoUrl: 'https://www.youtube.com/watch?v=NUMa0QkPzns',
            duration: 600,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'dig_lesson_2',
            courseId: courseId,
            title: 'Estabelecendo Limites Digitais',
            description: 'Estratégias para criar limites saudáveis com tecnologia',
            videoUrl: 'https://www.youtube.com/watch?v=VpHyLG-sc4g',
            duration: 540,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'dig_lesson_3',
            courseId: courseId,
            title: 'Uso Consciente da Tecnologia',
            description: 'Como usar dispositivos de forma intencional e produtiva',
            videoUrl: 'https://www.youtube.com/watch?v=wf2VxeIm1no',
            duration: 480,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'dig_lesson_4',
            courseId: courseId,
            title: 'Desintoxicação Digital',
            description: 'Técnicas para fazer pausas regulares da tecnologia',
            videoUrl: 'https://www.youtube.com/watch?v=CdkCg8XJdBk',
            duration: 420,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'dig_lesson_5',
            courseId: courseId,
            title: 'Criando Rotinas Offline',
            description: 'Desenvolva hábitos saudáveis longe das telas',
            videoUrl: 'https://www.youtube.com/watch?v=3nwwKbM_vJc',
            duration: 540,
            order: 5,
            type: LessonType.video,
          ),
        ];

      case 'curso_autocompaixao':
        return [
          Lesson(
            id: 'autocomp_lesson_1',
            courseId: courseId,
            title: 'O que é Autocompaixão',
            description: 'Compreenda os três pilares da autocompaixão',
            videoUrl: 'https://www.youtube.com/watch?v=IvtZBUSplr4',
            duration: 720,
            order: 1,
            type: LessonType.video,
          ),
          Lesson(
            id: 'autocomp_lesson_2',
            courseId: courseId,
            title: 'Identificando a Autocrítica',
            description: 'Reconheça padrões de pensamento autocrítico',
            videoUrl: 'https://www.youtube.com/watch?v=IC3W1BiUjp0',
            duration: 600,
            order: 2,
            type: LessonType.video,
          ),
          Lesson(
            id: 'autocomp_lesson_3',
            courseId: courseId,
            title: 'Praticando Gentileza Consigo',
            description: 'Exercícios para desenvolver um diálogo interno gentil',
            videoUrl: 'https://www.youtube.com/watch?v=psN1DORYYV0',
            duration: 540,
            order: 3,
            type: LessonType.video,
          ),
          Lesson(
            id: 'autocomp_lesson_4',
            courseId: courseId,
            title: 'Mindfulness Autocompassivo',
            description: 'Como combinar mindfulness com autocompaixão',
            videoUrl: 'https://www.youtube.com/watch?v=3nwwKbM_vJc',
            duration: 660,
            order: 4,
            type: LessonType.video,
          ),
          Lesson(
            id: 'autocomp_lesson_5',
            courseId: courseId,
            title: 'Humanidade Compartilhada',
            description: 'Entenda que o sofrimento faz parte da experiência humana',
            videoUrl: 'https://www.youtube.com/watch?v=f-m2YcdMdFw',
            duration: 480,
            order: 5,
            type: LessonType.video,
          ),
        ];

      default:
        return const <Lesson>[];
    }
  }

  List<Exercise> _staticExercisesFor(String courseId) {
    print('📝 _staticExercisesFor chamado para: $courseId');
    // Normalização: aceitar ids curtos (sem prefixo) e mapear para versão canônica 'curso_*'
    String id = courseId;
    switch (courseId) {
      case 'respiracao': id = 'curso_respiracao'; break;
      case 'mindfulness': id = 'curso_mindfulness'; break;
      case 'emocoes': id = 'curso_emocoes'; break;
      case 'autoestima': id = 'curso_autoestima'; break;
      case 'estresse': id = 'curso_estresse'; break;
      case 'sono_reparador': id = 'curso_sono_reparador'; break;
      case 'resiliencia_emocional': id = 'curso_resiliencia_emocional'; break;
      case 'comunicacao_empatica': id = 'curso_comunicacao_empatica'; break;
      case 'equilibrio_digital': id = 'curso_equilibrio_digital'; break;
      case 'autocompaixao': id = 'curso_autocompaixao'; break;
    }

    switch (id) {
      case 'curso_respiracao':
        return [
          Exercise(
            id: 'resp_ex_1',
            lessonId: 'resp_lesson_1',
            question: 'Qual é o principal benefício da respiração consciente?',
            options: [
              'Aumentar a frequência cardíaca',
              'Reduzir ansiedade e estresse',
              'Melhorar a digestão',
              'Fortalecer os músculos'
            ],
            correctAnswer: 1,
            explanation: 'A respiração consciente ativa o sistema nervoso parassimpático, promovendo relaxamento e reduzindo ansiedade.',
            order: 1,
          ),
          Exercise(
            id: 'resp_ex_2',
            lessonId: 'resp_lesson_2',
            question: 'Na técnica 4-7-8, qual é a sequência correta?',
            options: [
              'Inspire 4, segure 7, expire 8',
              'Inspire 7, segure 4, expire 8',
              'Inspire 8, segure 7, expire 4',
              'Inspire 4, segure 8, expire 7'
            ],
            correctAnswer: 0,
            explanation: 'A técnica 4-7-8 consiste em inspirar por 4 segundos, segurar por 7 e expirar por 8 segundos.',
            order: 2,
          ),
          Exercise(
            id: 'resp_ex_3',
            lessonId: 'resp_lesson_3',
            question: 'Onde deve estar posicionada a mão durante a respiração diafragmática?',
            options: [
              'No peito',
              'No abdome',
              'Nas costas',
              'No pescoço'
            ],
            correctAnswer: 1,
            explanation: 'Na respiração diafragmática, a mão deve estar no abdome para sentir o movimento do diafragma.',
            order: 3,
          ),
        ];

      case 'curso_mindfulness':
        return [
          Exercise(
            id: 'mind_ex_1',
            lessonId: 'mind_lesson_1',
            question: 'O que significa "mindfulness"?',
            options: [
              'Pensar muito sobre tudo',
              'Atenção plena ao momento presente',
              'Fazer várias coisas ao mesmo tempo',
              'Evitar pensamentos negativos'
            ],
            correctAnswer: 1,
            explanation: 'Mindfulness é a prática de manter atenção plena ao momento presente, sem julgamento.',
            order: 1,
          ),
          Exercise(
            id: 'mind_ex_2',
            lessonId: 'mind_lesson_2',
            question: 'Durante a meditação da respiração, quando a mente divagar, você deve:',
            options: [
              'Se criticar por perder o foco',
              'Parar a meditação imediatamente',
              'Gentilmente retornar a atenção à respiração',
              'Tentar bloquear todos os pensamentos'
            ],
            correctAnswer: 2,
            explanation: 'É normal a mente divagar. O importante é perceber quando isso acontece e gentilmente retornar a atenção à respiração.',
            order: 2,
          ),
        ];

      case 'curso_emocoes':
        return [
          Exercise(
            id: 'emo_ex_1',
            lessonId: 'emo_lesson_1',
            question: 'Qual é a função principal das emoções?',
            options: [
              'Nos atrapalhar no dia a dia',
              'Fornecer informações sobre nosso ambiente',
              'Controlar nossos pensamentos',
              'Nos fazer sofrer'
            ],
            correctAnswer: 1,
            explanation: 'As emoções fornecem informações valiosas sobre nosso ambiente e nos ajudam a responder adequadamente às situações.',
            order: 1,
          ),
        ];

      case 'curso_autoestima':
        return [
          Exercise(
            id: 'auto_ex_1',
            lessonId: 'auto_lesson_1',
            question: 'A autoestima saudável envolve:',
            options: [
              'Acreditar que você é melhor que todos',
              'Aceitar-se com qualidades e defeitos',
              'Nunca admitir erros',
              'Comparar-se constantemente com outros'
            ],
            correctAnswer: 1,
            explanation: 'A autoestima saudável envolve aceitar a si mesmo com qualidades e defeitos, reconhecendo seu valor intrínseco.',
            order: 1,
          ),
          Exercise(
            id: 'auto_ex_2',
            lessonId: 'auto_lesson_2',
            question: 'Uma crença limitante típica é:',
            options: [
              '"Eu posso aprender coisas novas"',
              '"Erros são oportunidades de crescimento"',
              '"Eu nunca sou bom o suficiente"',
              '"Cada pessoa tem seu próprio ritmo"'
            ],
            correctAnswer: 2,
            explanation: 'Crenças limitantes como "eu nunca sou bom o suficiente" sabotam nossa autoestima e devem ser identificadas e questionadas.',
            order: 2,
          ),
        ];

      case 'curso_estresse':
        return [
          Exercise(
            id: 'stress_ex_1',
            lessonId: 'stress_lesson_1',
            question: 'O estresse crônico pode causar:',
            options: [
              'Apenas cansaço mental',
              'Problemas físicos e mentais',
              'Aumento da criatividade',
              'Melhora do sistema imunológico'
            ],
            correctAnswer: 1,
            explanation: 'O estresse crônico pode causar diversos problemas físicos (doenças cardiovasculares, digestivas) e mentais (ansiedade, depressão).',
            order: 1,
          ),
          Exercise(
            id: 'stress_ex_2',
            lessonId: 'stress_lesson_2',
            question: 'Uma técnica eficaz para relaxamento é:',
            options: [
              'Beber mais cafeína',
              'Trabalhar sem pausas',
              'Respiração profunda e lenta',
              'Assistir TV até tarde'
            ],
            correctAnswer: 2,
            explanation: 'A respiração profunda e lenta ativa o sistema nervoso parassimpático, promovendo relaxamento.',
            order: 2,
          ),
          Exercise(
            id: 'stress_ex_3',
            lessonId: 'stress_lesson_3',
            question: 'Para gerenciar melhor o tempo, você deve:',
            options: [
              'Fazer tudo ao mesmo tempo',
              'Nunca dizer não',
              'Priorizar tarefas importantes',
              'Trabalhar sem pausas'
            ],
            correctAnswer: 2,
            explanation: 'Priorizar tarefas importantes ajuda a focar energia nas atividades que realmente importam, reduzindo o estresse.',
            order: 3,
          ),
          Exercise(
            id: 'stress_ex_4',
            lessonId: 'stress_lesson_4',
            question: 'O exercício físico ajuda no controle do estresse porque:',
            options: [
              'Libera endorfinas naturais',
              'Aumenta a ansiedade',
              'Causa mais cansaço',
              'Diminui a autoestima'
            ],
            correctAnswer: 0,
            explanation: 'O exercício físico libera endorfinas, que são substâncias naturais que melhoram o humor e reduzem o estresse.',
            order: 4,
          ),
          Exercise(
            id: 'stress_ex_5',
            lessonId: 'stress_lesson_5',
            question: 'O que é resiliência?',
            options: [
              'Nunca sentir estresse',
              'Evitar todos os problemas',
              'Capacidade de se adaptar e se recuperar de adversidades',
              'Ser sempre otimista'
            ],
            correctAnswer: 2,
            explanation: 'Resiliência é a capacidade de se adaptar, se recuperar e crescer a partir de adversidades e desafios.',
            order: 5,
          ),
        ];

      case 'curso_sono_reparador':
        return [
          Exercise(
            id: 'sono_ex_1',
            lessonId: 'sono_lesson_1',
            question: 'Quantas horas de sono são recomendadas para adultos?',
            options: [
              '4-5 horas',
              '6-7 horas',
              '7-9 horas',
              '10-12 horas'
            ],
            correctAnswer: 2,
            explanation: 'A maioria dos adultos precisa de 7-9 horas de sono por noite para um funcionamento ideal.',
            order: 1,
          ),
          Exercise(
            id: 'sono_ex_2',
            lessonId: 'sono_lesson_2',
            question: 'Qual é uma boa prática de higiene do sono?',
            options: [
              'Usar telas antes de dormir',
              'Manter o quarto fresco e escuro',
              'Beber cafeína à noite',
              'Fazer exercícios intensos antes de dormir'
            ],
            correctAnswer: 1,
            explanation: 'Manter o quarto fresco, escuro e silencioso ajuda o corpo a entrar naturalmente no modo de sono.',
            order: 2,
          ),
          Exercise(
            id: 'sono_ex_3',
            lessonId: 'sono_lesson_3',
            question: 'Uma técnica eficaz para relaxar antes de dormir é:',
            options: [
              'Revisar problemas do trabalho',
              'Respiração profunda e progressiva',
              'Assistir notícias',
              'Fazer listas de tarefas'
            ],
            correctAnswer: 1,
            explanation: 'A respiração profunda e o relaxamento muscular progressivo ajudam a acalmar o sistema nervoso.',
            order: 3,
          ),
          Exercise(
            id: 'sono_ex_4',
            lessonId: 'sono_lesson_4',
            question: 'Que tipo de alimento deve ser evitado antes de dormir?',
            options: [
              'Frutas leves',
              'Chá de camomila',
              'Alimentos ricos em cafeína',
              'Leite morno'
            ],
            correctAnswer: 2,
            explanation: 'Cafeína pode permanecer no sistema por 6-8 horas, atrapalhando o adormecer.',
            order: 4,
          ),
        ];

      case 'curso_resiliencia_emocional':
        return [
          Exercise(
            id: 'resil_ex_1',
            lessonId: 'resil_lesson_1',
            question: 'A resiliência significa:',
            options: [
              'Nunca sentir dor emocional',
              'Capacidade de se adaptar e se recuperar',
              'Evitar todos os desafios',
              'Ser sempre forte'
            ],
            correctAnswer: 1,
            explanation: 'Resiliência é a capacidade de se adaptar, aprender e crescer a partir de experiências difíceis.',
            order: 1,
          ),
          Exercise(
            id: 'resil_ex_2',
            lessonId: 'resil_lesson_2',
            question: 'Uma mentalidade de crescimento envolve:',
            options: [
              'Acreditar que habilidades são fixas',
              'Evitar desafios difíceis',
              'Ver falhas como oportunidades de aprendizado',
              'Comparar-se constantemente com outros'
            ],
            correctAnswer: 2,
            explanation: 'A mentalidade de crescimento vê desafios e falhas como oportunidades para desenvolver habilidades.',
            order: 2,
          ),
          Exercise(
            id: 'resil_ex_3',
            lessonId: 'resil_lesson_3',
            question: 'Para regular emoções em crises, é importante:',
            options: [
              'Suprimir todos os sentimentos',
              'Reagir imediatamente',
              'Pausar e respirar antes de agir',
              'Culpar outros pela situação'
            ],
            correctAnswer: 2,
            explanation: 'Fazer uma pausa e respirar conscientemente ajuda a regular emoções e responder de forma mais equilibrada.',
            order: 3,
          ),
        ];

      case 'curso_comunicacao_empatica':
        return [
          Exercise(
            id: 'com_ex_1',
            lessonId: 'com_lesson_1',
            question: 'A comunicação empática se baseia em:',
            options: [
              'Sempre concordar com o outro',
              'Compreender e validar sentimentos',
              'Dar conselhos rapidamente',
              'Julgar comportamentos'
            ],
            correctAnswer: 1,
            explanation: 'A comunicação empática foca em compreender e validar os sentimentos da outra pessoa.',
            order: 1,
          ),
          Exercise(
            id: 'com_ex_2',
            lessonId: 'com_lesson_2',
            question: 'Escuta ativa envolve:',
            options: [
              'Preparar sua resposta enquanto o outro fala',
              'Dar atenção total ao que está sendo dito',
              'Interromper com sugestões',
              'Pensar em outros assuntos'
            ],
            correctAnswer: 1,
            explanation: 'Escuta ativa requer atenção total ao que a pessoa está comunicando, verbal e não-verbalmente.',
            order: 2,
          ),
          Exercise(
            id: 'com_ex_3',
            lessonId: 'com_lesson_3',
            question: 'Validar emoções significa:',
            options: [
              'Concordar com tudo que a pessoa diz',
              'Reconhecer que os sentimentos são legítimos',
              'Minimizar a importância das emoções',
              'Dar soluções imediatas'
            ],
            correctAnswer: 1,
            explanation: 'Validar emoções é reconhecer que os sentimentos da pessoa são legítimos e compreensíveis.',
            order: 3,
          ),
        ];

      case 'curso_equilibrio_digital':
        return [
          Exercise(
            id: 'dig_ex_1',
            lessonId: 'dig_lesson_1',
            question: 'Um sinal de uso problemático de tecnologia é:',
            options: [
              'Usar dispositivos para trabalho',
              'Sentir ansiedade quando sem o celular',
              'Assistir vídeos educativos',
              'Usar apps de meditação'
            ],
            correctAnswer: 1,
            explanation: 'Ansiedade quando separado do dispositivo pode indicar dependência digital.',
            order: 1,
          ),
          Exercise(
            id: 'dig_ex_2',
            lessonId: 'dig_lesson_2',
            question: 'Uma estratégia para limites digitais é:',
            options: [
              'Usar dispositivos a qualquer hora',
              'Criar zonas livres de tecnologia',
              'Manter o celular sempre à mão',
              'Nunca desligar notificações'
            ],
            correctAnswer: 1,
            explanation: 'Criar zonas e horários livres de tecnologia ajuda a estabelecer limites saudáveis.',
            order: 2,
          ),
          Exercise(
            id: 'dig_ex_3',
            lessonId: 'dig_lesson_3',
            question: 'Para usar tecnologia conscientemente:',
            options: [
              'Fazer multitarefas constantemente',
              'Definir intenções claras antes do uso',
              'Navegar sem objetivo específico',
              'Manter todas as notificações ativadas'
            ],
            correctAnswer: 1,
            explanation: 'Definir intenções claras ajuda a usar tecnologia de forma mais consciente e produtiva.',
            order: 3,
          ),
        ];

      case 'curso_autocompaixao':
        return [
          Exercise(
            id: 'comp_ex_1',
            lessonId: 'comp_lesson_1',
            question: 'Os três pilares da autocompaixão são:',
            options: [
              'Autocrítica, isolamento e negação',
              'Bondade, mindfulness e humanidade comum',
              'Perfecionismo, controle e julgamento',
              'Competição, comparação e crítica'
            ],
            correctAnswer: 1,
            explanation: 'Os três pilares são: bondade consigo mesmo, mindfulness das dificuldades e senso de humanidade comum.',
            order: 1,
          ),
          Exercise(
            id: 'comp_ex_2',
            lessonId: 'comp_lesson_2',
            question: 'Quando você comete um erro, é mais compassivo:',
            options: [
              'Se criticar severamente',
              'Tratar-se como trataria um bom amigo',
              'Ignorar completamente o erro',
              'Culpar outras pessoas'
            ],
            correctAnswer: 1,
            explanation: 'Autocompaixão envolve tratar a si mesmo com a mesma bondade que ofereceria a um bom amigo.',
            order: 2,
          ),
          Exercise(
            id: 'comp_ex_3',
            lessonId: 'comp_lesson_3',
            question: 'Humanidade compartilhada significa:',
            options: [
              'Todos são perfeitos',
              'Só você enfrenta dificuldades',
              'Dificuldades fazem parte da experiência humana',
              'Você deve resolver tudo sozinho'
            ],
            correctAnswer: 2,
            explanation: 'Reconhecer que dificuldades e imperfeições fazem parte da experiência humana comum.',
            order: 3,
          ),
        ];



      default:
        return const <Exercise>[];
    }
  }

  List<Course> get courses => _courses;
  Set<String> get favoriteCourseIds => _favoriteCourseIds;
  List<Course> get favoriteCourses =>
      _courses.where((c) => _favoriteCourseIds.contains(c.id)).toList();
  bool isFavorite(String courseId) => _favoriteCourseIds.contains(courseId);

  // Métodos públicos para acessar aulas e exercícios
  List<Lesson> getLessonsForCourse(String courseId) {
    return _staticLessonsFor(courseId);
  }

  List<Exercise> getExercisesForCourse(String courseId) {
    return _staticExercisesFor(courseId);
  }

  Future<void> loadCourses() async {
    try {
      final snapshot = await _firestore
          .collection(coursesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      _courses = snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();

      notifyListeners();
    } catch (e) {
      print('Erro ao carregar cursos: $e');
    }
  }

  /// Garante que uma lista de cursos base (vindos originalmente da Home) exista no Firestore.
  /// Se algum id ainda não existir, ele é criado. Não sobrescreve existentes.
  Future<void> ensureBaseHomeCourses() async {
    final base = <Course>[
      Course(
        id: 'respiracao',
        title: 'Técnicas de Respiração para Ansiedade',
        description: 'Aprenda técnicas científicas de respiração para controlar a ansiedade e o estresse no dia a dia',
        imageUrl: 'https://img.youtube.com/vi/YRPh_GaiL8s/maxresdefault.jpg',
        category: 'Ansiedade',
        duration: 240,
        lessonsCount: 5,
        exercisesCount: 3,
        level: CourseLevel.beginner,
        tags: ['respiração', 'ansiedade', 'relaxamento', 'meditação'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        isPopular: true,
      ),
      Course(
        id: 'mindfulness',
        title: 'Mindfulness e Meditação Diária',
        description: 'Desenvolva a prática da atenção plena com exercícios guiados e técnicas comprovadas cientificamente',
        imageUrl: 'https://img.youtube.com/vi/ZToicYcHIOU/maxresdefault.jpg',
        category: 'Mindfulness',
        duration: 300,
        lessonsCount: 5,
        exercisesCount: 2,
        level: CourseLevel.beginner,
        tags: ['mindfulness', 'meditação', 'atenção plena', 'foco'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isPopular: true,
      ),
      Course(
        id: 'emocoes',
        title: 'Inteligência Emocional na Prática',
        description: 'Aprenda a identificar, compreender e gerenciar suas emoções de forma saudável e produtiva',
        imageUrl: 'https://img.youtube.com/vi/R1vskiVDwl4/maxresdefault.jpg',
        category: 'Autoconhecimento',
        duration: 360,
        lessonsCount: 5,
        exercisesCount: 1,
        level: CourseLevel.intermediate,
        tags: ['emoções', 'autoconhecimento', 'inteligência emocional', 'relacionamentos'],
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      Course(
        id: 'autoestima',
        title: 'Construindo Autoestima Saudável',
        description: 'Desenvolva uma autoestima equilibrada através de exercícios práticos e mudança de perspectiva',
        imageUrl: 'https://img.youtube.com/vi/f-m2YcdMdFw/maxresdefault.jpg',
        category: 'Autoestima',
        duration: 240,
        lessonsCount: 5,
        exercisesCount: 2,
        level: CourseLevel.beginner,
        tags: ['autoestima', 'autoconfiança', 'autocuidado', 'desenvolvimento pessoal'],
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isPopular: true,
      ),
      Course(
        id: 'estresse',
        title: 'Gestão de Estresse no Trabalho',
        description: 'Estratégias práticas para lidar com pressão, deadlines e demandas do ambiente profissional',
        imageUrl: 'https://img.youtube.com/vi/hnpQrMqDoqE/maxresdefault.jpg',
        category: 'Estresse',
        duration: 270,
        lessonsCount: 5,
        exercisesCount: 2,
        level: CourseLevel.intermediate,
        tags: ['estresse', 'trabalho', 'produtividade', 'equilíbrio'],
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
      ),
    ];

    for (final course in base) {
      try {
        final doc = await _firestore.collection(coursesCollection).doc(course.id).get();
        if (!doc.exists) {
          await _firestore.collection(coursesCollection).doc(course.id).set(course.toFirestore());
        }
      } catch (e) {
        print('Erro ao garantir curso base ${course.id}: $e');
      }
    }
  }

  /// Carrega favoritos do usuário logado
  Future<void> loadFavorites() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return; // usuário não logado

    try {
      final doc = await _firestore
          .collection(userFavoritesCollection)
          .doc(userId)
          .get();
      if (doc.exists) {
        final data = doc.data();
        final List<dynamic>? raw = data?['courseIds'];
        _favoriteCourseIds =
            raw != null ? raw.whereType<String>().toSet() : <String>{};
      } else {
        _favoriteCourseIds = <String>{};
      }
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar favoritos: $e');
    }
  }

  /// Alterna favorito e persiste no Firestore (coleção user_favorites)
  Future<void> toggleFavorite(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return; // ignorar se não logado

    final isFav = _favoriteCourseIds.contains(courseId);
    try {
      if (isFav) {
        _favoriteCourseIds.remove(courseId);
        await _firestore
            .collection(userFavoritesCollection)
            .doc(userId)
            .set({
          'courseIds': FieldValue.arrayRemove([courseId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        _favoriteCourseIds.add(courseId);
        await _firestore
            .collection(userFavoritesCollection)
            .doc(userId)
            .set({
          'courseIds': FieldValue.arrayUnion([courseId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      notifyListeners();
    } catch (e) {
      print('Erro ao alternar favorito: $e');
    }
  }

  Future<List<Course>> getPopularCourses() async {
    try {
      final snapshot = await _firestore
          .collection(coursesCollection)
          .where('isPopular', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(6)
          .get();

      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar cursos populares: $e');
      return [];
    }
  }

  Future<List<Course>> getCoursesByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(coursesCollection)
          .where('category', isEqualTo: category)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar cursos por categoria: $e');
      return [];
    }
  }

  Future<List<Lesson>> getCourseLessons(String courseId) async {
    if (_courseLessons.containsKey(courseId)) {
      return _courseLessons[courseId]!;
    }

    try {
      final snapshot = await _firestore
          .collection(lessonsCollection)
          .where('courseId', isEqualTo: courseId)
          .orderBy('order')
          .get();

      final lessons = snapshot.docs
          .map((doc) => Lesson.fromFirestore(doc.data(), doc.id))
          .toList();

      _courseLessons[courseId] = lessons;
      return lessons;
    } catch (e) {
      print('Erro ao carregar lições do curso: $e');
      return [];
    }
  }

  Future<List<Exercise>> getLessonExercises(String lessonId) async {
    try {
      final snapshot = await _firestore
          .collection(exercisesCollection)
          .where('lessonId', isEqualTo: lessonId)
          .orderBy('order')
          .get();

      return snapshot.docs
          .map((doc) => Exercise.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar exercícios da lição: $e');
      return [];
    }
  }

  Future<CourseProgress?> getUserCourseProgress(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    final progressKey = '${userId}_$courseId';
    if (_userProgress.containsKey(progressKey)) {
      return _userProgress[progressKey];
    }

    try {
      final snapshot = await _firestore
          .collection(courseProgressCollection)
          .where('userId', isEqualTo: userId)
          .where('courseId', isEqualTo: courseId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final progress = CourseProgress.fromFirestore(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
        _userProgress[progressKey] = progress;
        return progress;
      }

      return null;
    } catch (e) {
      print('Erro ao carregar progresso do curso: $e');
      return null;
    }
  }

  Future<void> enrollInCourse(String courseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final progress = CourseProgress(
        id: '',
        userId: userId,
        courseId: courseId,
        completedLessons: [],
        completedExercises: [],
        currentLessonOrder: 0,
        progressPercentage: 0.0,
        startedAt: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(courseProgressCollection)
          .add(progress.toFirestore());

      _userProgress['${userId}_$courseId'] = progress.copyWith(id: docRef.id);
      notifyListeners();
    } catch (e) {
      print('Erro ao se inscrever no curso: $e');
      throw e;
    }
  }

  Future<void> completeLesson(String courseId, String lessonId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final progress = await getUserCourseProgress(courseId);
      if (progress == null) return;

      final updatedCompletedLessons = List<String>.from(progress.completedLessons);
      if (!updatedCompletedLessons.contains(lessonId)) {
        updatedCompletedLessons.add(lessonId);
      }

      // Calcular novo progresso
      final totalLessons = await getCourseLessons(courseId);
      final newProgressPercentage = (updatedCompletedLessons.length / totalLessons.length) * 100;
      
      final isCompleted = newProgressPercentage >= 100;
      
      final updatedProgress = progress.copyWith(
        completedLessons: updatedCompletedLessons,
        progressPercentage: newProgressPercentage,
        currentLessonOrder: progress.currentLessonOrder + 1,
        isCompleted: isCompleted,
        completedAt: isCompleted ? DateTime.now() : null,
      );

      await _firestore
          .collection(courseProgressCollection)
          .doc(progress.id)
          .update(updatedProgress.toFirestore());

      _userProgress['${userId}_$courseId'] = updatedProgress;

      // Registrar conquistas
      await _achievementService.onLessonCompleted();
      
      if (isCompleted) {
        await _achievementService.onCourseCompleted();
      }

      notifyListeners();
    } catch (e) {
      print('Erro ao completar lição: $e');
      throw e;
    }
  }

  Future<void> completeExercise(String courseId, String exerciseId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final progress = await getUserCourseProgress(courseId);
      if (progress == null) return;

      final updatedCompletedExercises = List<String>.from(progress.completedExercises);
      if (!updatedCompletedExercises.contains(exerciseId)) {
        updatedCompletedExercises.add(exerciseId);
      }

      final updatedProgress = progress.copyWith(
        completedExercises: updatedCompletedExercises,
      );

      await _firestore
          .collection(courseProgressCollection)
          .doc(progress.id)
          .update(updatedProgress.toFirestore());

      _userProgress['${userId}_$courseId'] = updatedProgress;

      // Registrar conquistas
      await _achievementService.onExerciseCompleted();

      notifyListeners();
    } catch (e) {
      print('Erro ao completar exercício: $e');
      throw e;
    }
  }

  Future<List<Course>> getUserEnrolledCourses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final progressSnapshot = await _firestore
          .collection(courseProgressCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final courseIds = progressSnapshot.docs
          .map((doc) => doc.data()['courseId'] as String)
          .toList();

      if (courseIds.isEmpty) return [];

      final coursesSnapshot = await _firestore
          .collection(coursesCollection)
          .where(FieldPath.documentId, whereIn: courseIds)
          .get();

      return coursesSnapshot.docs
          .map((doc) => Course.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Erro ao carregar cursos inscritos: $e');
      return [];
    }
  }

  // Métodos para criar dados de exemplo
  Future<void> createSampleCourses() async {
    final sampleCourses = [
      Course(
        id: '',
        title: 'Gerenciando a Ansiedade',
        description: 'Aprenda técnicas eficazes para identificar, compreender e gerenciar a ansiedade no dia a dia.',
        imageUrl: '',
        category: 'Ansiedade',
        duration: 45,
        lessonsCount: 6,
        exercisesCount: 12,
        level: CourseLevel.beginner,
        tags: ['ansiedade', 'respiração', 'mindfulness', 'técnicas'],
        createdAt: DateTime.now(),
        isPopular: true,
      ),
      Course(
        id: '',
        title: 'Construindo Autoestima',
        description: 'Desenvolva uma autoimagem positiva e aprenda a valorizar suas qualidades únicas.',
        imageUrl: '',
        category: 'Autoestima',
        duration: 60,
        lessonsCount: 8,
        exercisesCount: 16,
        level: CourseLevel.intermediate,
        tags: ['autoestima', 'autoconhecimento', 'confiança'],
        createdAt: DateTime.now(),
        isPopular: true,
      ),
      Course(
        id: '',
        title: 'Relacionamentos Saudáveis',
        description: 'Aprenda a construir e manter relacionamentos equilibrados e significativos.',
        imageUrl: '',
        category: 'Relacionamentos',
        duration: 75,
        lessonsCount: 10,
        exercisesCount: 20,
        level: CourseLevel.intermediate,
        tags: ['relacionamentos', 'comunicação', 'empatia'],
        createdAt: DateTime.now(),
      ),
      Course(
        id: '',
        title: 'Lidando com o Estresse',
        description: 'Identifique fontes de estresse e desenvolva estratégias para lidar com elas de forma saudável.',
        imageUrl: '',
        category: 'Estresse',
        duration: 40,
        lessonsCount: 5,
        exercisesCount: 10,
        level: CourseLevel.beginner,
        tags: ['estresse', 'relaxamento', 'organização'],
        createdAt: DateTime.now(),
      ),
    ];

    for (final course in sampleCourses) {
      await _firestore.collection(coursesCollection).add(course.toFirestore());
    }
  }

  /// Cria um conjunto expandido de cursos adicionais (usar uma vez manualmente)
  Future<void> createAdditionalCourses() async {
    // Definições canônicas com IDs fixos
    final canonical = [
      Course(
        id: 'curso_sono_reparador',
        title: 'Sono Reparador',
        description: 'Estratégias práticas para melhorar a higiene do sono e restaurar sua energia mental.',
        imageUrl: '',
        category: 'Estresse',
        duration: 50,
        lessonsCount: 5, // Ajustado para refletir conteúdo criado
        exercisesCount: 4,
        level: CourseLevel.beginner,
        tags: ['sono', 'rotina', 'bem-estar'],
        createdAt: DateTime.now(),
        isPopular: true,
      ),
      Course(
        id: 'curso_resiliencia_emocional',
        title: 'Resiliência Emocional',
        description: 'Fortaleça sua capacidade de se recuperar de situações desafiadoras.',
        imageUrl: '',
        category: 'Autoestima',
        duration: 70,
        lessonsCount: 5,
        exercisesCount: 3,
        level: CourseLevel.intermediate,
        tags: ['resiliência', 'emoções', 'força interna'],
        createdAt: DateTime.now(),
      ),
      Course(
        id: 'curso_comunicacao_empatica',
        title: 'Comunicação Empática',
        description: 'Melhore conexões através de técnicas de escuta ativa e validação emocional.',
        imageUrl: '',
        category: 'Relacionamentos',
        duration: 65,
        lessonsCount: 5,
        exercisesCount: 3,
        level: CourseLevel.intermediate,
        tags: ['empatia', 'comunicação', 'relacionamentos'],
        createdAt: DateTime.now(),
        isPopular: true,
      ),
      Course(
        id: 'curso_equilibrio_digital',
        title: 'Equilíbrio Digital',
        description: 'Reduza sobrecarga mental e otimize seu uso de tecnologia conscientemente.',
        imageUrl: '',
        category: 'Estresse',
        duration: 40,
        lessonsCount: 5,
        exercisesCount: 3,
        level: CourseLevel.beginner,
        tags: ['foco', 'equilíbrio', 'produtividade'],
        createdAt: DateTime.now(),
        isPopular: false,
      ),
      Course(
        id: 'curso_autocompaixao',
        title: 'Autocompaixão na Prática',
        description: 'Desenvolva um diálogo interno gentil e reduza a autocrítica excessiva.',
        imageUrl: '',
        category: 'Autoestima',
        duration: 52,
        lessonsCount: 5,
        exercisesCount: 3,
        level: CourseLevel.beginner,
        tags: ['autocompaixão', 'aceitação', 'bem-estar'],
        createdAt: DateTime.now(),
      ),
    ];

    for (final course in canonical) {
      try {
        final docRef = _firestore.collection(coursesCollection).doc(course.id);
        final exists = await docRef.get();
        if (!exists.exists) {
          // Verifica se há um doc antigo com mesmo título (id aleatório) para migrar
          final dupQuery = await _firestore
              .collection(coursesCollection)
              .where('title', isEqualTo: course.title)
              .limit(1)
              .get();
          if (dupQuery.docs.isNotEmpty && dupQuery.docs.first.id != course.id) {
            // Copia dados antigos (preserva createdAt se existir)
            final old = dupQuery.docs.first.data();
            final merged = {
              ...course.toFirestore(),
              'createdAt': old['createdAt'] ?? course.createdAt.millisecondsSinceEpoch,
            };
            await docRef.set(merged);
            // Remove doc antigo para evitar duplicados
            await _firestore.collection(coursesCollection).doc(dupQuery.docs.first.id).delete();
          } else {
            await docRef.set(course.toFirestore());
          }
        } else {
          // Opcional: atualizar counts se divergirem do conteúdo real
          // Sincroniza contagens reais a partir do conteúdo estático
          // Usa acesso direto à classe para evitar problemas de resolução dos helpers top-level
          final lessons = _staticLessonsFor(course.id);
          final exercises = _staticExercisesFor(course.id);
          final dataNeedsUpdate = (exists.data()!['lessonsCount'] != lessons.length) || (exists.data()!['exercisesCount'] != exercises.length);
          if (dataNeedsUpdate) {
            await docRef.update({
              'lessonsCount': lessons.length,
              'exercisesCount': exercises.length,
            });
          }
        }
      } catch (e) {
        print('Erro ao garantir curso adicional ${course.id}: $e');
      }
    }
  }

  /// Seed unificado: garante cursos base + adiciona extras se total ainda for baixo.
  Future<void> seedAllIfEmpty({int minTotal = 8}) async {
    try {
      await ensureBaseHomeCourses();
      await loadCourses();
      // Sempre garantir cursos adicionais canônicos (idempotente)
      await createAdditionalCourses();
      await loadCourses();
    } catch (e) {
      print('Erro no seedAllIfEmpty: $e');
    }
  }
}

extension CourseProgressExtension on CourseProgress {
  CourseProgress copyWith({
    String? id,
    String? userId,
    String? courseId,
    List<String>? completedLessons,
    List<String>? completedExercises,
    int? currentLessonOrder,
    double? progressPercentage,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isCompleted,
  }) {
    return CourseProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      completedLessons: completedLessons ?? this.completedLessons,
      completedExercises: completedExercises ?? this.completedExercises,
      currentLessonOrder: currentLessonOrder ?? this.currentLessonOrder,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
