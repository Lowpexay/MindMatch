import '../models/course_models.dart';

class CourseContentService {
  static Map<String, List<Lesson>> getLessonsForCourse(String courseId) {
    // Normalização: aceitar ids curtos (sem prefixo) e mapear para versão canônica 'curso_*'
    String id = courseId;
    switch (courseId) {
      case 'respiracao': id = 'curso_respiracao'; break;
      case 'mindfulness': id = 'curso_mindfulness'; break;
      case 'emocoes': id = 'curso_emocoes'; break;
      case 'autoestima': id = 'curso_autoestima'; break;
      case 'estresse': id = 'curso_estresse'; break;
    }
    switch (id) {
      case 'curso_respiracao':
        return {
          courseId: [
            Lesson(
              id: 'resp_lesson_1',
              courseId: courseId,
              title: 'Introdução à Respiração Consciente',
              description: 'Entenda os fundamentos científicos da respiração e seu impacto na ansiedade',
              videoUrl: 'https://www.youtube.com/watch?v=YRPh_GaiL8s', // Técnicas de respiração para ansiedade
              duration: 720, // 12 minutos em segundos
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resp_lesson_2',
              courseId: courseId,
              title: 'Técnica 4-7-8 para Relaxamento',
              description: 'Aprenda a técnica 4-7-8 desenvolvida pelo Dr. Andrew Weil',
              videoUrl: 'https://www.youtube.com/watch?v=YQq4VwkDwWQ', // Respiração 4-7-8
              duration: 480, // 8 minutos em segundos
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resp_lesson_3',
              courseId: courseId,
              title: 'Respiração Diafragmática',
              description: 'Pratique a respiração profunda usando o diafragma',
              videoUrl: 'https://www.youtube.com/watch?v=1Dv-ldGLnIY', // Respiração diafragmática
              duration: 600, // 10 minutos em segundos
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resp_lesson_4',
              courseId: courseId,
              title: 'Respiração Box (Quadrada)',
              description: 'Técnica de respiração em 4 tempos para concentração',
              videoUrl: 'https://www.youtube.com/watch?v=tEmt1Znux58', // Box breathing
              duration: 540, // 9 minutos em segundos
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resp_lesson_5',
              courseId: courseId,
              title: 'Prática Guiada Completa',
              description: 'Sessão completa combinando todas as técnicas aprendidas',
              videoUrl: 'https://www.youtube.com/watch?v=DbDoBzGY3vo', // Meditação respiração guiada
              duration: 900, // 15 minutos em segundos
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_mindfulness':
        return {
          courseId: [
            Lesson(
              id: 'mind_lesson_1',
              courseId: courseId,
              title: 'O que é Mindfulness?',
              description: 'Introdução aos conceitos fundamentais da atenção plena',
              videoUrl: 'https://www.youtube.com/watch?v=HmEo6RI4Wvs', // Mindfulness explicado
              duration: 840, // 14 minutos em segundos
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'mind_lesson_2',
              courseId: courseId,
              title: 'Atenção Plena na Respiração',
              description: 'Como usar a respiração como âncora para o presente',
              videoUrl: 'https://www.youtube.com/watch?v=ZToicYcHIOU', // Mindfulness respiração
              duration: 720, // 12 minutos em segundos
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'mind_lesson_3',
              courseId: courseId,
              title: 'Body Scan - Varredura Corporal',
              description: 'Técnica de escaneamento corporal para relaxamento',
              videoUrl: 'https://www.youtube.com/watch?v=15q-N-_kkrU', // Body scan meditação
              duration: 1200, // 20 minutos em segundos
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'mind_lesson_4',
              courseId: courseId,
              title: 'Mindfulness nas Atividades Diárias',
              description: 'Como praticar atenção plena durante tarefas cotidianas',
              videoUrl: 'https://www.youtube.com/watch?v=F6eFFCi12v8', // Mindfulness cotidiano
              duration: 660, // 11 minutos em segundos
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'mind_lesson_5',
              courseId: courseId,
              title: 'Lidando com Pensamentos Intrusivos',
              description: 'Estratégias mindfulness para gerenciar pensamentos negativos',
              videoUrl: 'https://www.youtube.com/watch?v=w6T02g5hnT4', // Mindfulness pensamentos
              duration: 780, // 13 minutos em segundos
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_emocoes':
        return {
          courseId: [
            Lesson(
              id: 'emoc_lesson_1',
              courseId: courseId,
              title: 'Entendendo as Emoções',
              description: 'A ciência por trás das emoções humanas',
              videoUrl: 'https://www.youtube.com/watch?v=l7TONauJGfc', // Neurociência emoções
              duration: 900, // 15 minutos em segundos
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'emoc_lesson_2',
              courseId: courseId,
              title: 'Identificando Gatilhos Emocionais',
              description: 'Como reconhecer e mapear seus gatilhos emocionais',
              videoUrl: 'https://www.youtube.com/watch?v=gAMbkJk6gnE', // Gatilhos emocionais
              duration: 720, // 12 minutos em segundos
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'emoc_lesson_3',
              courseId: courseId,
              title: 'Técnicas de Regulação Emocional',
              description: 'Estratégias práticas para regular emoções intensas',
              videoUrl: 'https://www.youtube.com/watch?v=BCV5QQLLZ_E', // Regulação emocional
              duration: 840, // 14 minutos em segundos
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'emoc_lesson_4',
              courseId: courseId,
              title: 'Comunicação Emocional Assertiva',
              description: 'Como expressar suas emoções de forma saudável',
              videoUrl: 'https://www.youtube.com/watch?v=vlwmfiCb-vc', // Comunicação assertiva
              duration: 600, // 10 minutos em segundos
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'emoc_lesson_5',
              courseId: courseId,
              title: 'Construindo Inteligência Emocional',
              description: 'Desenvolvendo habilidades emocionais a longo prazo',
              videoUrl: 'https://www.youtube.com/watch?v=Y7m9eNoB3NU', // Inteligência emocional
              duration: 960, // 16 minutos em segundos
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_autoestima':
        return {
          courseId: [
            Lesson(
              id: 'auto_lesson_1',
              courseId: courseId,
              title: 'Compreendendo a Autoestima',
              description: 'O que é autoestima e como ela se desenvolve',
              videoUrl: 'https://www.youtube.com/watch?v=w-HYZv6HzAs', // Autoestima explicada
              duration: 780, // 13 minutos em segundos
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'auto_lesson_2',
              courseId: courseId,
              title: 'Identificando Crenças Limitantes',
              description: 'Como reconhecer pensamentos que sabotam sua autoestima',
              videoUrl: 'https://www.youtube.com/watch?v=IC3W1BiUjp0', // Crenças limitantes
              duration: 660, // 11 minutos em segundos
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'auto_lesson_3',
              courseId: courseId,
              title: 'Autoaceitação e Autocompaixão',
              description: 'Desenvolvendo uma relação mais gentil consigo mesmo',
              videoUrl: 'https://www.youtube.com/watch?v=IvtZBUSplr4', // Autocompaixão
              duration: 840, // 14 minutos em segundos
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'auto_lesson_4',
              courseId: courseId,
              title: 'Construindo Autoimagem Positiva',
              description: 'Técnicas para melhorar sua percepção sobre si mesmo',
              videoUrl: 'https://www.youtube.com/watch?v=qR3rK0kZFkg', // Autoimagem positiva
              duration: 720, // 12 minutos em segundos
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'auto_lesson_5',
              courseId: courseId,
              title: 'Mantendo a Autoestima Saudável',
              description: 'Estratégias para manter e fortalecer sua autoestima',
              videoUrl: 'https://www.youtube.com/watch?v=d-diB65scQU', // Manter autoestima
              duration: 600, // 10 minutos em segundos
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_estresse':
        return {
          courseId: [
            Lesson(
              id: 'stress_lesson_1',
              courseId: courseId,
              title: 'O que é o Estresse?',
              description: 'Entendendo a resposta fisiológica do estresse',
              videoUrl: 'https://www.youtube.com/watch?v=WuyPuH9ojmE', // Estresse explicado
              duration: 720, // 12 minutos em segundos
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'stress_lesson_2',
              courseId: courseId,
              title: 'Identificando Fontes de Estresse',
              description: 'Como mapear e compreender seus estressores',
              videoUrl: 'https://www.youtube.com/watch?v=hnpQrMqDoqE', // Fontes de estresse
              duration: 600, // 10 minutos em segundos
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'stress_lesson_3',
              courseId: courseId,
              title: 'Técnicas de Relaxamento Rápido',
              description: 'Métodos imediatos para reduzir o estresse agudo',
              videoUrl: 'https://www.youtube.com/watch?v=1vx8iUvfyCY', // Relaxamento rápido
              duration: 480, // 8 minutos em segundos
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'stress_lesson_4',
              courseId: courseId,
              title: 'Gestão do Tempo e Prioridades',
              description: 'Como organizar sua vida para reduzir o estresse',
              videoUrl: 'https://www.youtube.com/watch?v=iDbdXTMnOmE', // Gestão tempo estresse
              duration: 840, // 14 minutos em segundos
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'stress_lesson_5',
              courseId: courseId,
              title: 'Construindo Resiliência',
              description: 'Desenvolvendo capacidade de lidar com adversidades',
              videoUrl: 'https://www.youtube.com/watch?v=NWH8N-BvhAw', // Resiliência
              duration: 900, // 15 minutos em segundos
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      // --- Novos cursos adicionais (sem conteúdo anteriormente) ---
      case 'curso_sono_reparador':
        return {
          courseId: [
            Lesson(
              id: 'sono_lesson_1',
              courseId: courseId,
              title: 'Fundamentos do Sono',
              description: 'Como o sono atua na regulação emocional e mental',
              videoUrl: 'https://www.youtube.com/watch?v=4Mtw3vBQYOg',
              duration: 720,
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'sono_lesson_2',
              courseId: courseId,
              title: 'Higiene do Sono',
              description: 'Rotinas e ajustes ambientais para dormir melhor',
              videoUrl: 'https://www.youtube.com/watch?v=4Ln1VQZsQ9k',
              duration: 660,
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'sono_lesson_3',
              courseId: courseId,
              title: 'Ciclo Circadiano',
              description: 'Entenda a importância da exposição à luz e horários fixos',
              videoUrl: 'https://www.youtube.com/watch?v=QWNoiVrJDsE',
              duration: 780,
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'sono_lesson_4',
              courseId: courseId,
              title: 'Relaxamento Pré-Sono',
              description: 'Técnicas para reduzir ativação mental antes de dormir',
              videoUrl: 'https://www.youtube.com/watch?v=ZBnPlqQFPKs',
              duration: 600,
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'sono_lesson_5',
              courseId: courseId,
              title: 'Checklist Noturno',
              description: 'Construindo uma rotina consistente de preparação para o sono',
              videoUrl: 'https://www.youtube.com/watch?v=M0t1IjsHVNI',
              duration: 540,
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_resiliencia_emocional':
        return {
          courseId: [
            Lesson(
              id: 'resil_lesson_1',
              courseId: courseId,
              title: 'O que é Resiliência?',
              description: 'Conceito e mitos sobre resiliência emocional',
              videoUrl: 'https://www.youtube.com/watch?v=1Vxq8F2QSQ0',
              duration: 720,
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resil_lesson_2',
              courseId: courseId,
              title: 'Mentalidade de Crescimento',
              description: 'Reenquadrando desafios como oportunidades',
              videoUrl: 'https://www.youtube.com/watch?v=M1CHPnZfFmU',
              duration: 660,
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resil_lesson_3',
              courseId: courseId,
              title: 'Gestão do Fracasso',
              description: 'Estratégias para aprender com erros e seguir',
              videoUrl: 'https://www.youtube.com/watch?v=H14bBuluwB8',
              duration: 780,
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resil_lesson_4',
              courseId: courseId,
              title: 'Redes de Apoio',
              description: 'Como cultivar suporte emocional e pedir ajuda',
              videoUrl: 'https://www.youtube.com/watch?v=KZbzIf_C6Y4',
              duration: 600,
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'resil_lesson_5',
              courseId: courseId,
              title: 'Plano de Recuperação Pessoal',
              description: 'Montando um plano para momentos difíceis',
              videoUrl: 'https://www.youtube.com/watch?v=ajB4a-pPiho',
              duration: 540,
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_comunicacao_empatica':
        return {
          courseId: [
            Lesson(
              id: 'comp_lesson_1',
              courseId: courseId,
              title: 'Bases da Comunicação Empática',
              description: 'Princípios essenciais de comunicação não violenta',
              videoUrl: 'https://www.youtube.com/watch?v=c8N72t7aScY',
              duration: 780,
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'comp_lesson_2',
              courseId: courseId,
              title: 'Escuta Ativa',
              description: 'Ferramentas práticas para ouvir de verdade',
              videoUrl: 'https://www.youtube.com/watch?v=mD6uSGSjgr4',
              duration: 660,
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'comp_lesson_3',
              courseId: courseId,
              title: 'Validação Emocional',
              description: 'Como reconhecer e legitimar sentimentos do outro',
              videoUrl: 'https://www.youtube.com/watch?v=vdQjFuXcbd0',
              duration: 720,
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'comp_lesson_4',
              courseId: courseId,
              title: 'Expressando Necessidades',
              description: 'Estrutura em 4 passos para pedidos claros',
              videoUrl: 'https://www.youtube.com/watch?v=5lHOcJwMUX8',
              duration: 600,
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'comp_lesson_5',
              courseId: courseId,
              title: 'Conversas Difíceis',
              description: 'Protocolos para conflitos sem escalada',
              videoUrl: 'https://www.youtube.com/watch?v=khC4J2b3ITQ',
              duration: 780,
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_equilibrio_digital':
        return {
          courseId: [
            Lesson(
              id: 'eqdig_lesson_1',
              courseId: courseId,
              title: 'Consumo Digital Consciente',
              description: 'Mapeando hábitos e controlando gatilhos de dopamina',
              videoUrl: 'https://www.youtube.com/watch?v=PMjyoZyR5FQ',
              duration: 720,
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'eqdig_lesson_2',
              courseId: courseId,
              title: 'Foco Profundo',
              description: 'Estratégias para proteger blocos de concentração',
              videoUrl: 'https://www.youtube.com/watch?v=ft_DXwgUXB0',
              duration: 660,
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'eqdig_lesson_3',
              courseId: courseId,
              title: 'Detox Programado',
              description: 'Ciclos e micro-pausas digitais estratégicas',
              videoUrl: 'https://www.youtube.com/watch?v=EFT9m5sV1iI',
              duration: 600,
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'eqdig_lesson_4',
              courseId: courseId,
              title: 'Ambiente Livre de Distrações',
              description: 'Customizando notificações e layout mental',
              videoUrl: 'https://www.youtube.com/watch?v=ldhMZJz66fQ',
              duration: 540,
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'eqdig_lesson_5',
              courseId: courseId,
              title: 'Plano de Equilíbrio Sustentável',
              description: 'Juntando métricas e ajustes contínuos',
              videoUrl: 'https://www.youtube.com/watch?v=nuPZUUED5uk',
              duration: 780,
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      case 'curso_autocompaixao':
        return {
          courseId: [
            Lesson(
              id: 'autoComp_lesson_1',
              courseId: courseId,
              title: 'Fundamentos da Autocompaixão',
              description: 'O que é e o que não é autocompaixão',
              videoUrl: 'https://www.youtube.com/watch?v=IvtZBUSplr4',
              duration: 720,
              order: 1,
              type: LessonType.video,
            ),
            Lesson(
              id: 'autoComp_lesson_2',
              courseId: courseId,
              title: 'Identificando o Crítico Interno',
              description: 'Mapeando padrões de autocrítica',
              videoUrl: 'https://www.youtube.com/watch?v=-kfUE41-JFw',
              duration: 660,
              order: 2,
              type: LessonType.video,
            ),
            Lesson(
              id: 'autoComp_lesson_3',
              courseId: courseId,
              title: 'Diálogo Interno Gentil',
              description: 'Introduzindo frases de apoio e reformulação',
              videoUrl: 'https://www.youtube.com/watch?v=erR5MobmRtY',
              duration: 600,
              order: 3,
              type: LessonType.video,
            ),
            Lesson(
              id: 'autoComp_lesson_4',
              courseId: courseId,
              title: 'Prática de Bondade Amorosa',
              description: 'Exercício guiado de compaixão',
              videoUrl: 'https://www.youtube.com/watch?v=sit6XsTsMbg',
              duration: 780,
              order: 4,
              type: LessonType.video,
            ),
            Lesson(
              id: 'autoComp_lesson_5',
              courseId: courseId,
              title: 'Plano de Autocuidado',
              description: 'Estruturando rituais de manutenção emocional',
              videoUrl: 'https://www.youtube.com/watch?v=csunzsAtvB4',
              duration: 780,
              order: 5,
              type: LessonType.video,
            ),
          ]
        };

      default:
        return {courseId: []};
    }
  }

  static Map<String, List<Exercise>> getExercisesForCourse(String courseId) {
    String id = courseId;
    switch (courseId) {
      case 'respiracao': id = 'curso_respiracao'; break;
      case 'mindfulness': id = 'curso_mindfulness'; break;
      case 'emocoes': id = 'curso_emocoes'; break;
      case 'autoestima': id = 'curso_autoestima'; break;
      case 'estresse': id = 'curso_estresse'; break;
    }
    switch (id) {
      case 'curso_respiracao':
        return {
          courseId: [
            Exercise(
              id: 'resp_ex_1',
              lessonId: 'resp_lesson_2',
              question: 'Qual é a sequência correta da técnica de respiração 4-7-8?',
              options: [
                'Inspire por 4, segure por 7, expire por 8',
                'Inspire por 7, segure por 4, expire por 8',
                'Inspire por 8, segure por 7, expire por 4',
                'Inspire por 4, segure por 8, expire por 7'
              ],
              correctAnswer: 0,
              explanation: 'A técnica 4-7-8 consiste em inspirar por 4 segundos, segurar a respiração por 7 segundos e expirar por 8 segundos.',
              order: 1,
            ),
            Exercise(
              id: 'resp_ex_2',
              lessonId: 'resp_lesson_3',
              question: 'Qual é o principal músculo envolvido na respiração diafragmática?',
              options: [
                'Músculos intercostais',
                'Diafragma',
                'Músculos abdominais',
                'Músculos do pescoço'
              ],
              correctAnswer: 1,
              explanation: 'O diafragma é o principal músculo respiratório, localizado entre o tórax e o abdome.',
              order: 2,
            ),
            Exercise(
              id: 'resp_ex_3',
              lessonId: 'resp_lesson_4',
              question: 'Quantos tempos iguais tem a respiração Box (quadrada)?',
              options: [
                '2 tempos',
                '3 tempos',
                '4 tempos',
                '5 tempos'
              ],
              correctAnswer: 2,
              explanation: 'A respiração Box tem 4 tempos iguais: inspirar, segurar, expirar, segurar.',
              order: 3,
            ),
            Exercise(
              id: 'resp_ex_4',
              lessonId: 'resp_lesson_1',
              question: 'Qual é o principal benefício da respiração consciente para a ansiedade?',
              options: [
                'Aumenta a frequência cardíaca',
                'Ativa o sistema nervoso simpático',
                'Ativa o sistema nervoso parassimpático',
                'Reduz a concentração de oxigênio'
              ],
              correctAnswer: 2,
              explanation: 'A respiração consciente ativa o sistema nervoso parassimpático, responsável pelo relaxamento e recuperação.',
              order: 4,
            ),
            Exercise(
              id: 'resp_ex_5',
              lessonId: 'resp_lesson_5',
              question: 'Com que frequência é recomendado praticar exercícios de respiração?',
              options: [
                'Apenas quando sentir ansiedade',
                'Uma vez por semana',
                'Diariamente, de preferência no mesmo horário',
                'Apenas antes de dormir'
              ],
              correctAnswer: 2,
              explanation: 'A prática diária, preferencialmente no mesmo horário, ajuda a criar o hábito e maximiza os benefícios.',
              order: 5,
            ),
          ]
        };

      case 'curso_mindfulness':
        return {
          courseId: [
            Exercise(
              id: 'mind_ex_1',
              lessonId: 'mind_lesson_1',
              question: 'O que significa "mindfulness" em português?',
              options: [
                'Mente vazia',
                'Atenção plena',
                'Pensamento positivo',
                'Relaxamento profundo'
              ],
              correctAnswer: 1,
              explanation: 'Mindfulness significa atenção plena - estar completamente presente e consciente do momento atual.',
              order: 1,
            ),
            Exercise(
              id: 'mind_ex_2',
              lessonId: 'mind_lesson_2',
              question: 'Na prática de mindfulness, o que devemos fazer quando percebemos que nossa mente divagou?',
              options: [
                'Criticar a nós mesmos por ter perdido o foco',
                'Parar imediatamente a prática',
                'Gentilmente retornar a atenção para a respiração',
                'Tentar não pensar em nada'
              ],
              correctAnswer: 2,
              explanation: 'Quando percebemos que a mente divagou, devemos gentilmente retornar a atenção para o objeto de foco, sem julgamento.',
              order: 2,
            ),
            Exercise(
              id: 'mind_ex_3',
              lessonId: 'mind_lesson_3',
              question: 'O que é a técnica "Body Scan"?',
              options: [
                'Uma varredura corporal com atenção dirigida',
                'Um exame médico detalhado',
                'Um exercício de respiração',
                'Uma técnica de visualização'
              ],
              correctAnswer: 0,
              explanation: 'Body Scan é uma varredura corporal onde dirigimos a atenção sistematicamente para diferentes partes do corpo.',
              order: 3,
            ),
            Exercise(
              id: 'mind_ex_4',
              lessonId: 'mind_lesson_4',
              question: 'Como podemos praticar mindfulness durante atividades cotidianas?',
              options: [
                'Fazendo várias tarefas ao mesmo tempo',
                'Prestando atenção plena a uma atividade de cada vez',
                'Pensando no futuro enquanto fazemos a tarefa',
                'Acelerando o máximo possível'
              ],
              correctAnswer: 1,
              explanation: 'Mindfulness nas atividades cotidianas significa prestar atenção plena ao que estamos fazendo no momento presente.',
              order: 4,
            ),
            Exercise(
              id: 'mind_ex_5',
              lessonId: 'mind_lesson_5',
              question: 'Qual é a atitude recomendada em relação aos pensamentos intrusivos durante a prática de mindfulness?',
              options: [
                'Lutar contra eles e tentar eliminá-los',
                'Observá-los sem julgamento e deixá-los passar',
                'Analisá-los profundamente',
                'Ignorá-los completamente'
              ],
              correctAnswer: 1,
              explanation: 'A atitude mindful é observar os pensamentos sem julgamento, reconhecendo-os e deixando-os passar naturalmente.',
              order: 5,
            ),
          ]
        };

      // --- Exercícios para cursos adicionais ---
      case 'curso_sono_reparador':
        return {
          courseId: [
            Exercise(
              id: 'sono_ex_1',
              lessonId: 'sono_lesson_1',
              question: 'Qual hormônio é mais diretamente associado ao ciclo sono-vigília?',
              options: ['Serotonina', 'Melatonina', 'Cortisol', 'Adrenalina'],
              correctAnswer: 1,
              explanation: 'A melatonina regula o ciclo circadiano e prepara o corpo para o sono.',
              order: 1,
            ),
            Exercise(
              id: 'sono_ex_2',
              lessonId: 'sono_lesson_2',
              question: 'Higiene do sono NÃO inclui:',
              options: ['Reduzir luz azul à noite', 'Evitar cafeína tarde', 'Dormir em horários aleatórios', 'Ambiente escuro e silencioso'],
              correctAnswer: 2,
              explanation: 'Horários aleatórios atrapalham a sincronização do relógio biológico.',
              order: 2,
            ),
            Exercise(
              id: 'sono_ex_3',
              lessonId: 'sono_lesson_3',
              question: 'Exposição à luz natural pela manhã ajuda a:',
              options: ['Aumentar ansiedade', 'Ajustar o relógio biológico', 'Reduzir necessidade de sono', 'Bloquear produção de serotonina'],
              correctAnswer: 1,
              explanation: 'Luz matinal reforça o alinhamento circadiano.',
              order: 3,
            ),
            Exercise(
              id: 'sono_ex_4',
              lessonId: 'sono_lesson_4',
              question: 'Práticas de relaxamento antes de dormir reduzem:',
              options: ['Ativação fisiológica', 'Produtividade', 'Homeostase', 'Nutrição'],
              correctAnswer: 0,
              explanation: 'Reduzem hiperativação mental e corporal facilitando o adormecer.',
              order: 4,
            ),
          ]
        };

      case 'curso_resiliencia_emocional':
        return {
          courseId: [
            Exercise(
              id: 'resil_ex_1',
              lessonId: 'resil_lesson_1',
              question: 'Resiliência NÃO significa:',
              options: ['Nunca sentir emoções negativas', 'Adaptar-se após dificuldades', 'Aprender com falhas', 'Recuperar-se após estresse'],
              correctAnswer: 0,
              explanation: 'Resiliência envolve sentir emoções e ainda assim recuperar-se.',
              order: 1,
            ),
            Exercise(
              id: 'resil_ex_2',
              lessonId: 'resil_lesson_2',
              question: 'Mentalidade de crescimento foca em:',
              options: ['Talento fixo', 'Esforço e aprendizagem', 'Evitar desafios', 'Resultados imediatos'],
              correctAnswer: 1,
              explanation: 'A ênfase está em esforço deliberado e aprendizado incremental.',
              order: 2,
            ),
            Exercise(
              id: 'resil_ex_3',
              lessonId: 'resil_lesson_3',
              question: 'Falhas são:',
              options: ['Evidência de incapacidade', 'Oportunidades de ajuste', 'Sempre permanentes', 'Irrelevantes'],
              correctAnswer: 1,
              explanation: 'Falhas bem analisadas geram adaptação.',
              order: 3,
            ),
          ]
        };

      case 'curso_comunicacao_empatica':
        return {
          courseId: [
            Exercise(
              id: 'comp_ex_1',
              lessonId: 'comp_lesson_1',
              question: 'Comunicação empática baseia-se em:',
              options: ['Julgar intenções', 'Escuta + necessidades', 'Responder rápido', 'Impor soluções'],
              correctAnswer: 1,
              explanation: 'Envolve observar sem julgar e conectar necessidades.',
              order: 1,
            ),
            Exercise(
              id: 'comp_ex_2',
              lessonId: 'comp_lesson_2',
              question: 'Escuta ativa NÃO inclui:',
              options: ['Parafrasear', 'Interromper com conselhos imediatos', 'Contato visual suave', 'Validar sentimentos'],
              correctAnswer: 1,
              explanation: 'Interromper quebra a presença e invalida o fluxo emocional.',
              order: 2,
            ),
            Exercise(
              id: 'comp_ex_3',
              lessonId: 'comp_lesson_3',
              question: 'Validar emoções significa:',
              options: ['Concordar com tudo', 'Reconhecer a experiência do outro', 'Oferecer solução rápida', 'Ignorar intensidade'],
              correctAnswer: 1,
              explanation: 'Validar ≠ concordar; é legitimar a vivência.',
              order: 3,
            ),
          ]
        };

      case 'curso_equilibrio_digital':
        return {
          courseId: [
            Exercise(
              id: 'eqdig_ex_1',
              lessonId: 'eqdig_lesson_1',
              question: 'O uso digital consciente começa por:',
              options: ['Desinstalar tudo', 'Mapear hábitos e gatilhos', 'Usar mais notificações', 'Trocar de aparelho'],
              correctAnswer: 1,
              explanation: 'Autoconhecimento de padrões precede intervenção eficaz.',
              order: 1,
            ),
            Exercise(
              id: 'eqdig_ex_2',
              lessonId: 'eqdig_lesson_2',
              question: 'Foco profundo exige:',
              options: ['Alternar tarefas rápido', 'Reduzir interrupções planejadas', 'Aumentar estímulos', 'Checar mensagens sempre'],
              correctAnswer: 1,
              explanation: 'Proteção de blocos focados reduz custo de troca.',
              order: 2,
            ),
            Exercise(
              id: 'eqdig_ex_3',
              lessonId: 'eqdig_lesson_3',
              question: 'Micro pausas digitais servem para:',
              options: ['Perder tempo', 'Reset atencional e regulação', 'Gerar mais notificações', 'Aumentar dependência'],
              correctAnswer: 1,
              explanation: 'Pequenas pausas restauram foco e reduzem fadiga cognitiva.',
              order: 3,
            ),
          ]
        };

      case 'curso_autocompaixao':
        return {
          courseId: [
            Exercise(
              id: 'autocomp_ex_1',
              lessonId: 'autoComp_lesson_1',
              question: 'Autocompaixão NÃO é:',
              options: ['Passividade', 'Autocuidado saudável', 'Reconhecer dor', 'Gentileza interna'],
              correctAnswer: 0,
              explanation: 'Não é autoindulgência; envolve ação cuidadosa.',
              order: 1,
            ),
            Exercise(
              id: 'autocomp_ex_2',
              lessonId: 'autoComp_lesson_2',
              question: 'O “crítico interno” é melhor tratado com:',
              options: ['Punição', 'Expulsão mental', 'Curiosidade e reformulação', 'Ignorar totalmente'],
              correctAnswer: 2,
              explanation: 'Consciência + reformulação cria alternativa gentil.',
              order: 2,
            ),
            Exercise(
              id: 'autocomp_ex_3',
              lessonId: 'autoComp_lesson_4',
              question: 'Prática de bondade amorosa inclui:',
              options: ['Frases de cuidado e desejo de bem-estar', 'Culpa focada', 'Autocrítica estruturada', 'Comparação social'],
              correctAnswer: 0,
              explanation: 'Mantras compassivos reforçam calor emocional.',
              order: 3,
            ),
          ]
        };

      case 'curso_emocoes':
        return {
          courseId: [
            Exercise(
              id: 'emoc_ex_1',
              lessonId: 'emoc_lesson_1',
              question: 'Quais são as emoções básicas universais segundo Paul Ekman?',
              options: [
                'Alegria, tristeza, raiva, medo, surpresa, nojo',
                'Amor, ódio, inveja, ciúme',
                'Felicidade, depressão, ansiedade',
                'Orgulho, vergonha, culpa'
              ],
              correctAnswer: 0,
              explanation: 'Paul Ekman identificou seis emoções básicas universais: alegria, tristeza, raiva, medo, surpresa e nojo.',
              order: 1,
            ),
            Exercise(
              id: 'emoc_ex_2',
              lessonId: 'emoc_lesson_2',
              question: 'O que são gatilhos emocionais?',
              options: [
                'Exercícios para controlar emoções',
                'Situações que desencadeiam respostas emocionais intensas',
                'Técnicas de respiração',
                'Medicamentos para emoções'
              ],
              correctAnswer: 1,
              explanation: 'Gatilhos emocionais são situações, pessoas ou eventos que desencadeiam respostas emocionais intensas e automáticas.',
              order: 2,
            ),
            Exercise(
              id: 'emoc_ex_3',
              lessonId: 'emoc_lesson_3',
              question: 'Qual é uma técnica eficaz de regulação emocional?',
              options: [
                'Reprimir todas as emoções',
                'Expressar emoções de forma explosiva',
                'Técnica da pausa e respiração profunda',
                'Ignorar completamente as emoções'
              ],
              correctAnswer: 2,
              explanation: 'A técnica da pausa e respiração profunda permite um espaço entre o estímulo e a resposta, facilitando a regulação emocional.',
              order: 3,
            ),
            Exercise(
              id: 'emoc_ex_4',
              lessonId: 'emoc_lesson_4',
              question: 'O que caracteriza a comunicação emocional assertiva?',
              options: [
                'Expressar emoções de forma agressiva',
                'Nunca mostrar emoções',
                'Expressar sentimentos de forma clara e respeitosa',
                'Manipular outros através das emoções'
              ],
              correctAnswer: 2,
              explanation: 'Comunicação assertiva significa expressar sentimentos e necessidades de forma clara, direta e respeitosa.',
              order: 4,
            ),
            Exercise(
              id: 'emoc_ex_5',
              lessonId: 'emoc_lesson_5',
              question: 'Qual é um componente fundamental da inteligência emocional?',
              options: [
                'Suprimir todas as emoções negativas',
                'Autoconhecimento emocional',
                'Controlar as emoções dos outros',
                'Nunca demonstrar vulnerabilidade'
              ],
              correctAnswer: 1,
              explanation: 'O autoconhecimento emocional - a capacidade de reconhecer e entender suas próprias emoções - é fundamental para a inteligência emocional.',
              order: 5,
            ),
          ]
        };

      case 'curso_autoestima':
        return {
          courseId: [
            Exercise(
              id: 'auto_ex_1',
              lessonId: 'auto_lesson_1',
              question: 'O que é autoestima?',
              options: [
                'Ser melhor que os outros',
                'A avaliação subjetiva do próprio valor',
                'Nunca admitir erros',
                'Sempre estar feliz'
              ],
              correctAnswer: 1,
              explanation: 'Autoestima é a avaliação subjetiva que fazemos do nosso próprio valor e dignidade como pessoa.',
              order: 1,
            ),
            Exercise(
              id: 'auto_ex_2',
              lessonId: 'auto_lesson_2',
              question: 'O que são crenças limitantes?',
              options: [
                'Pensamentos positivos sobre si mesmo',
                'Metas realistas de vida',
                'Pensamentos negativos que limitam nosso potencial',
                'Técnicas de motivação'
              ],
              correctAnswer: 2,
              explanation: 'Crenças limitantes são pensamentos negativos e distorcidos sobre nós mesmos que limitam nosso potencial e bem-estar.',
              order: 2,
            ),
            Exercise(
              id: 'auto_ex_3',
              lessonId: 'auto_lesson_3',
              question: 'O que significa autocompaixão?',
              options: [
                'Ter pena de si mesmo',
                'Tratar-se com a mesma gentileza que trataria um bom amigo',
                'Nunca se responsabilizar por erros',
                'Sempre se colocar em primeiro lugar'
              ],
              correctAnswer: 1,
              explanation: 'Autocompaixão significa tratar a si mesmo com a mesma gentileza e compreensão que ofereceria a um bom amigo.',
              order: 3,
            ),
            Exercise(
              id: 'auto_ex_4',
              lessonId: 'auto_lesson_4',
              question: 'Como construir uma autoimagem mais positiva?',
              options: [
                'Ignorar todos os defeitos',
                'Comparar-se constantemente com outros',
                'Focar nas qualidades e conquistas pessoais',
                'Buscar aprovação externa constantemente'
              ],
              correctAnswer: 2,
              explanation: 'Construir autoimagem positiva envolve reconhecer e valorizar suas qualidades, conquistas e progressos pessoais.',
              order: 4,
            ),
            Exercise(
              id: 'auto_ex_5',
              lessonId: 'auto_lesson_5',
              question: 'Qual é uma estratégia para manter autoestima saudável?',
              options: [
                'Evitar todos os desafios',
                'Praticar autoafirmações positivas regulares',
                'Nunca aceitar críticas',
                'Comparar-se sempre com pessoas menos capazes'
              ],
              correctAnswer: 1,
              explanation: 'Autoafirmações positivas regulares ajudam a reforçar uma autoimagem saudável e fortalecer a autoestima.',
              order: 5,
            ),
          ]
        };

      case 'curso_estresse':
        return {
          courseId: [
            Exercise(
              id: 'stress_ex_1',
              lessonId: 'stress_lesson_1',
              question: 'O que acontece no corpo durante a resposta ao estresse?',
              options: [
                'Diminuição do cortisol',
                'Ativação do sistema nervoso parassimpático',
                'Liberação de adrenalina e cortisol',
                'Redução da frequência cardíaca'
              ],
              correctAnswer: 2,
              explanation: 'Durante o estresse, o corpo libera hormônios como adrenalina e cortisol, preparando-se para a resposta de "luta ou fuga".',
              order: 1,
            ),
            Exercise(
              id: 'stress_ex_2',
              lessonId: 'stress_lesson_2',
              question: 'Qual é um exemplo de estressor externo?',
              options: [
                'Pensamentos negativos',
                'Perfeccionismo',
                'Trânsito intenso',
                'Baixa autoestima'
              ],
              correctAnswer: 2,
              explanation: 'Trânsito intenso é um estressor externo - uma situação do ambiente que pode causar estresse.',
              order: 2,
            ),
            Exercise(
              id: 'stress_ex_3',
              lessonId: 'stress_lesson_3',
              question: 'Qual é uma técnica de relaxamento rápido eficaz?',
              options: [
                'Beber café',
                'Respiração profunda',
                'Assistir TV',
                'Comer doces'
              ],
              correctAnswer: 1,
              explanation: 'A respiração profunda é uma técnica rápida e eficaz para ativar a resposta de relaxamento do corpo.',
              order: 3,
            ),
            Exercise(
              id: 'stress_ex_4',
              lessonId: 'stress_lesson_4',
              question: 'Qual é um princípio importante da gestão do tempo para reduzir estresse?',
              options: [
                'Fazer tudo ao mesmo tempo',
                'Nunca dizer não',
                'Priorizar tarefas importantes',
                'Trabalhar sem pausas'
              ],
              correctAnswer: 2,
              explanation: 'Priorizar tarefas importantes ajuda a focar energia nas atividades que realmente importam, reduzindo o estresse.',
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
          ]
        };

      default:
        return {courseId: []};
    }
  }
}

// Helpers de acesso direto (evitam necessidade de referenciar a classe ao usar alias de import)
Map<String, List<Lesson>> lessonsForCourse(String courseId) => CourseContentService.getLessonsForCourse(courseId);
Map<String, List<Exercise>> exercisesForCourse(String courseId) => CourseContentService.getExercisesForCourse(courseId);
