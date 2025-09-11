# 🧠 MindMatch - Emotional Wellness & Connection App

<div align="center">
  
  **Um aplicativo Flutter para bem-estar emocional e conexões humanas significativas**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.8+-blue.svg)](https://flutter.dev/)
  [![Firebase](https://img.shields.io/badge/Firebase-Integrated-orange.svg)](https://firebase.google.com/)
  
</div>

### 🌟 Visão
Criar um espaço seguro onde as pessoas possam cuidar de sua saúde mental e se conectar com base em compatibilidade emocional e intelectual, promovendo relacionamentos mais profundos e significativos.

### 💡 Inspiração
Baseado nos princípios da **Society 5.0** (Sociedade 5.0), integrando tecnologia avançada com necessidades humanas fundamentais.

---

## 🆕 Últimas Atualizações

### 🎯 **11/09/2025 - Sistema de Cursos Aprimorado e Dados Reais**

**� Sistema de Cursos Inteligente:**
- ✅ **Marcação Visual de Conclusão**: Cursos concluídos mostram ícone ✅ verde antes de entrar
- ✅ **Barra de Progresso**: Cursos iniciados mostram porcentagem de conclusão
- ✅ **Status Dinâmico**: "Concluído", "X% concluído" ou informações de aulas/exercícios
- ✅ **Progresso Persistente**: Todo progresso salvo por usuário entre sessões
- ✅ **Dados Específicos por Usuário**: Isolamento completo de dados usando Firebase Auth

**� Sistema de Conquistas Conectado:**
- ✅ **Conquistas Automáticas**: Desbloqueio automático ao completar lições, exercícios e cursos
- ✅ **Integração em Tempo Real**: CourseProgressService dispara conquistas automaticamente
- ✅ **Notificações de Conquista**: Feedback visual quando conquistas são desbloqueadas
- ✅ **Dependency Injection**: AchievementService integrado ao progresso dos cursos

**� Histórico de Checkups com Dados Reais:**
- ✅ **DailyCheckupHistoryService**: Novo serviço para histórico completo de checkups
- ✅ **Dados Reais nos Gráficos**: Humor dos últimos 7 dias baseado em checkups reais
- ✅ **Estatísticas Automáticas**: Cálculo de humor, energia e estresse médios
- ✅ **Relatórios Atualizados**: Progresso mensal com dados reais do usuário

**🔄 Arquitetura de Dados Aprimorada:**
- ✅ **Isolamento por Usuário**: Todos os dados específicos usando Firebase Auth user.uid
- ✅ **SharedPreferences Seguro**: Chaves únicas por usuário para persistência local
- ✅ **Sincronização Automática**: Dados carregados automaticamente no login
- ✅ **Provider Pattern**: Estado global gerenciado com Consumer widgets

### 🎯 **17/08/2025 - Chat por Voz com Luma**

**🗣️ Nova Experiência de Voz:**
- ✅ **Chat por Voz Completo**: Luma agora fala suas respostas usando ElevenLabs TTS
- ✅ **Modo Visual da Luma**: Interface dedicada para conversa por voz com avatar animado  
- ✅ **Duas Modalidades**: Usuário pode escolher entre chat por texto ou por voz
- ✅ **Controles Intuitivos**: Toque para parar/continuar a fala
- ✅ **Configuração Persistente**: O app lembra sua preferência de modo

**🤖 Chat com IA Avançado:**
- Chat por texto tradicional com histórico
- **🆕 Chat por voz com síntese de fala**
- **🆕 Modo visual da Luma com avatar animado**
- **🆕 Controles de voz intuitivos (toque para parar/continuar)**
- Contexto baseado no humor atual
- Suporte emocional personalizado
- **🆕 Configuração persistente de modo (texto/voz)**
  [![AI](https://img.shields.io/badge/AI-Google%20Gemini-green.svg)](https://ai.google.dev/)
  [![TTS](https://img.shields.io/badge/TTS-ElevenLabs-purple.svg)](https://elevenlabs.io/)
  [![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

  **✨ Atualizado em 17/08/2025 - Versão com Chat por Voz da Luma ✨**
</div>

---

## 📋 Índice

- [Sobre o Projeto](#-sobre-o-projeto)
- [🆕 Últimas Atualizações](#-últimas-atualizações)
- [Características Principais](#-características-principais)
- [Funcionalidades Implementadas](#-funcionalidades-implementadas)
- [Arquitetura](#-arquitetura)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Configuração do Projeto](#-configuração-do-projeto)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Funcionalidades Pendentes](#-funcionalidades-pendentes)
- [Como Usar](#-como-usar)
- [Contribuição](#-contribuição)
- [Roadmap](#-roadmap)

---

## 🎯 Sobre o Projeto

MindMatch é uma plataforma inovadora que combina **bem-estar emocional** com **conexões humanas significativas**. O aplicativo utiliza inteligência artificial para análise emocional e algoritmos de compatibilidade para conectar pessoas com afinidades e valores similares.

### 🌟 Visão
Criar um espaço seguro onde as pessoas possam se conectar com base em compatibilidade emocional e intelectual, promovendo relacionamentos mais profundos e significativos.

### � Inspiração
Baseado nos princípios da **Society 5.0** (Sociedade 5.0), integrando tecnologia avançada com necessidades humanas fundamentais.
- **Google Sign-In**: Autenticação social
- **Sign in with Apple**: Autenticação Apple
- **Image Picker**: Seleção de imagens

## 📦 Dependências Principais

---

## ✨ Características Principais

### 🧠 **Inteligência Emocional**
- Monitoramento diário do estado emocional
- Análise de bem-estar com score personalizado
- Suporte emocional com IA (Google Gemini)
- Perguntas reflexivas personalizadas

### 💬 **Sistema de Chat Avançado**
- Conversas em tempo real
- Histórico de conversas sincronizado
- Notificações de mensagens não lidas
- Interface intuitiva similar ao WhatsApp

### 💬 **Sistema de Chat Entre Usuários**
- Conversas em tempo real
- Histórico de conversas sincronizado  
- Notificações de mensagens não lidas
- Interface intuitiva similar ao WhatsApp

### 🤝 **Algoritmo de Compatibilidade**
- Análise baseada em respostas às perguntas reflexivas
- Score de compatibilidade (30-100%)
- Perfis detalhados com interesses e objetivos
- Limitação inteligente de sugestões (máximo 6 usuários)

### 🎧 **🆕 Sistema de Text-to-Speech**
- Integração com ElevenLabs TTS API
- Voz feminina natural (Rachel)
- Controle de reprodução em tempo real
- Estados visuais para feedback do usuário
- Sistema de fallback robusto

### 🔐 **Segurança & Privacidade**
- Autenticação Firebase (Email, Google, Apple)
- Regras de segurança Firestore
- Dados criptografados
- Controle total sobre informações pessoais

---

## ✅ Funcionalidades Implementadas
- [x] Check-in diário de humor
- [x] Indicador de bem-estar
- [x] Perguntas reflexivas personalizadas
- [x] Lista de usuários compatíveis
- [x] Suporte emocional com IA
- [x] Navegação global com drawer

### 💭 **Sistema de Humor**
- [x] 4 dimensões: Felicidade, Energia, Clareza, Estresse
- [x] Cálculo automático de score de bem-estar
- [x] Histórico de humor
- [x] Detecção automática de necessidade de suporte
- [x] Interface visual intuitiva

### ❓ **Perguntas Reflexivas**
- [x] Geração automática com IA
- [x] 20 perguntas personalizadas por usuário
- [x] Sistema de respostas Sim/Não
- [x] Salvamento de respostas no Firestore
- [x] Interface progressiva

### 🤖 **Chat com IA - Luma**
- [x] Integração com Google Gemini 1.5 Flash
- [x] Contexto baseado no humor atual
- [x] Suporte emocional personalizado
- [x] Interface de chat natural
- [x] Histórico de conversas
- [x] **🆕 Chat por voz com TTS (ElevenLabs)**
- [x] **🆕 Modo visual da Luma com avatar**
- [x] **🆕 Escolha entre modo texto/voz**
- [x] **🆕 Controles de reprodução (play/pause)**
- [x] **🆕 Configuração persistente de preferências**
- [x] **🆕 Animações visuais durante a fala**
- [x] **🆕 Sistema robusto de estados de voz**

### 👥 **Sistema de Usuários Compatíveis**
- [x] Algoritmo de compatibilidade avançado
- [x] Score baseado em respostas comuns
- [x] Perfis detalhados com bio, idade, cidade
- [x] Sistema de tags de interesses
- [x] Limite de 6 usuários por vez

### 💬 **Chat Entre Usuários**
- [x] Conversas em tempo real
- [x] Criação automática de conversas
- [x] Sistema de mensagens com timestamp
- [x] Status de leitura (✓✓)
- [x] Interface similar ao WhatsApp

### 📱 **Histórico de Conversas**
- [x] Lista de todas as conversas ativas
- [x] Última mensagem e horário
- [x] Contador de mensagens não lidas
- [x] Badge de notificação na navegação
- [x] Ordenação por última atividade
- [x] Atualização em tempo real

### 🔐 **Autenticação**
- [x] Login com email/senha
- [x] Integração com Google Sign-In
- [x] Integração com Apple Sign-In (preparado)
- [x] Tela de onboarding
- [x] Persistência de sessão

### 🎨 **Interface & UX**
- [x] Design Material Design 3
- [x] Tema consistente (AppColors)
- [x] Navegação bottom tabs + drawer global
- [x] Animações suaves
- [x] Responsivo para diferentes tamanhos
- [x] Estados de loading e erro
- [x] **🆕 Interface visual para chat por voz**
- [x] **🆕 Animações de avatar da Luma**
- [x] **🆕 Indicadores visuais de estado de fala**
- [x] **🆕 Scaffold wrapping para todas as telas**

### 🔥 **Firebase Integration**
- [x] Firestore para dados em tempo real
- [x] Authentication multi-provider
- [x] Storage para imagens de perfil
- [x] Cloud Functions preparado
- [x] Regras de segurança configuradas

---

## 🏗️ Arquitetura

### 📐 **Padrões de Design**
- **Provider Pattern** para gerenciamento de estado
- **Clean Architecture** com separação de responsabilidades
- **Repository Pattern** para acesso aos dados
- **Singleton** para serviços globais

### 📁 **Estrutura de Pastas**
```
lib/
├── 📱 screens/          # Telas do aplicativo
├── 🧩 widgets/          # Componentes reutilizáveis
├── 🔧 services/         # Lógica de negócio e APIs
├── 📊 models/           # Modelos de dados
├── 🎛️ providers/        # Gerenciamento de estado
├── 🎨 utils/            # Utilitários e constantes
└── 🔧 main.dart         # Ponto de entrada
```

### 🔥 **Firebase Collections**
```
firestore/
├── users/               # Dados dos usuários
├── conversations/       # Conversas entre usuários
│   └── messages/        # Mensagens (subcoleção)
├── questions/           # Perguntas reflexivas
├── question_responses/  # Respostas dos usuários
├── mood_tracking/       # Histórico de humor
└── notifications/       # Notificações
```

---

## 🛠️ Tecnologias Utilizadas

### 🎯 **Frontend**
- **Flutter 3.8+** - Framework principal
- **Material Design 3** - Sistema de design
- **Provider** - Gerenciamento de estado
- **go_router** - Navegação declarativa

### ☁️ **Backend & Cloud**
- **Firebase Authentication** - Autenticação
- **Cloud Firestore** - Banco de dados NoSQL
- **Firebase Storage** - Armazenamento de arquivos
- **Firebase Cloud Functions** - Funções serverless

### 🤖 **Inteligência Artificial & TTS**
- **Google Gemini 1.5 Flash** - IA conversacional
- **Gemini API** - Geração de conteúdo
- **🆕 ElevenLabs TTS** - Síntese de voz natural
- **🆕 Voice API Integration** - Controle de reprodução
- **Prompt Engineering** - Otimização de respostas

### 🔧 **Ferramentas de Desenvolvimento**
- **VS Code** - IDE principal
- **Firebase CLI** - Deployment e configuração
- **GitHub** - Controle de versão
- **Dart DevTools** - Debug e performance

---

## ⚙️ Configuração do Projeto

### 📋 **Pré-requisitos**
- Flutter SDK 3.8 ou superior
- Dart SDK 3.0+
- Android Studio / VS Code
- Firebase CLI
- Conta do Google Cloud (para Gemini API)

### 🚀 **Instalação**

1. **Clone o repositório**
   ```bash
   git clone https://github.com/Lowpexay/MindMatch.git
   cd MindMatch
   ```

2. **Instale as dependências**
   ```bash
   flutter pub get
   ```

3. **Configure o Firebase**
   ```bash
   # Instale Firebase CLI
   npm install -g firebase-tools
   
   # Login no Firebase
   firebase login
   
   # Configure o projeto
   flutterfire configure
   ```

4. **Configure APIs**
   
   **Google Gemini API:**
   - Acesse [Google AI Studio](https://makersuite.google.com/)
   - Gere uma API key
   - Adicione no arquivo `lib/services/gemini_service.dart`
   
   **🆕 ElevenLabs TTS API:**
   - Acesse [ElevenLabs](https://elevenlabs.io/)
   - Crie uma conta e gere uma API key
   - Adicione no arquivo `lib/config/api_keys.dart`

5. **Execute o aplicativo**
   ```bash
   flutter run
   ```

### 🔧 **Configuração do Firebase**

1. **Firestore Rules** (desenvolvimento)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

2. **Authentication Providers**
   - ✅ Email/Password
   - ✅ Google
   - 🔄 Apple (preparado)

---

## 📂 Estrutura do Projeto

```
mindmatch-app/
├── 📱 android/                 # Configurações Android
├── 🍎 ios/                     # Configurações iOS
├── 🌐 web/                     # Configurações Web
├── 📚 lib/                     # Código principal
│   ├── 🏠 screens/
│   │   ├── home_screen.dart
│   │   ├── conversations_screen.dart
│   │   ├── user_chat_screen.dart
│   │   ├── ai_chat_screen.dart              # 🆕 Modo voz adicionado
│   │   ├── login_screen.dart
│   │   ├── onboarding_screen.dart
│   │   └── main_navigation.dart
│   ├── 🧩 widgets/
│   │   ├── mood_check_widget.dart
│   │   ├── reflective_questions_widget.dart
│   │   ├── compatible_users_widget.dart
│   │   ├── luma_voice_widget.dart           # 🆕 Widget para modo voz
│   │   ├── global_drawer.dart
│   │   └── custom_text_field.dart
│   ├── 🔧 services/
│   │   ├── auth_service.dart
│   │   ├── firebase_service.dart
│   │   ├── gemini_service.dart
│   │   ├── elevenlabs_service.dart          # 🆕 Serviço TTS
│   │   └── preferences_service.dart         # 🆕 Gerenciar preferências
│   ├── 📊 models/
│   │   ├── user_model.dart
│   │   ├── mood_data.dart
│   │   ├── question_models.dart
│   │   └── conversation_models.dart
│   ├── 🎛️ providers/
│   │   └── conversations_provider.dart
│   ├── 🎨 utils/
│   │   ├── app_colors.dart
│   │   └── scaffold_utils.dart              # 🆕 Utilidades de UI
│   ├── ⚙️ config/
│   │   └── api_keys.dart                    # 🆕 Configurações de API
│   └── 🔧 main.dart
├── 🎨 assets/                  # Recursos estáticos
│   ├── images/
│   │   └── luma_avatar.png                  # 🆕 Avatar da Luma
│   ├── icons/
│   └── fonts/
├── 📋 pubspec.yaml            # Dependências
├── 🔥 firebase.json           # Configuração Firebase
└── 📖 README.md               # Este arquivo
```

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_storage: ^11.5.6
  
  # Authentication
  google_sign_in: ^6.1.6
  sign_in_with_apple: ^5.0.0
  
  # AI Integration
  google_generative_ai: ^0.2.2
  
  # UI & Navigation
  go_router: ^12.1.3
  provider: ^6.1.1
  image_picker: ^1.0.4
  shared_preferences: ^2.2.2
  
  # 🆕 Text-to-Speech & Audio
  http: ^1.1.2                  # Para ElevenLabs API
  dio: ^5.3.4                   # HTTP client otimizado
  audioplayers: ^5.2.1         # Reprodução de áudio
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.1.0
```

---

## 🔄 Funcionalidades Pendentes

### 🎯 **Alta Prioridade**
- [ ] **Perfil do Usuário**
  - [ ] Tela de edição de perfil
  - [ ] Upload de foto de perfil
  - [ ] Configurações de privacidade
  - [ ] Preferências de notificação

- [ ] **Sistema de Notificações**
  - [ ] Push notifications
  - [ ] Notificações de novas mensagens
  - [ ] Lembretes de check-in diário
  - [ ] Badges de contadores

- [ ] **Melhorias no Chat**
  - [ ] Envio de imagens
  - [ ] Áudios de voz
  - [ ] Emojis e reações
  - [ ] Status "digitando..."

### 🎨 **Média Prioridade**
- [ ] **Funcionalidades Sociais**
  - [ ] Sistema de bloqueio/desbloqueio
  - [ ] Denúncias de usuários
  - [ ] Conversas arquivadas
  - [ ] Grupos de interesse

- [ ] **Analytics & Insights**
  - [ ] Dashboard de bem-estar
  - [ ] Relatórios de humor
  - [ ] Estatísticas de uso
  - [ ] Insights de compatibilidade

- [ ] **Gamificação**
  - [ ] Sistema de conquistas
  - [ ] Streaks de check-in
  - [ ] Níveis de bem-estar
  - [ ] Badges de progresso

### 🔧 **Baixa Prioridade**
- [ ] **Recursos Avançados**
  - [ ] Modo offline
  - [ ] Backup de dados
  - [ ] Exportação de relatórios
  - [ ] Integração com wearables

- [ ] **Plataformas**
  - [ ] Versão Web completa
  - [ ] App para desktop
  - [ ] Widget para iOS/Android

### 🛡️ **Segurança & Performance**
- [ ] **Otimizações**
  - [ ] Cache inteligente
  - [ ] Lazy loading
  - [ ] Compressão de imagens
  - [ ] Otimização de queries

- [ ] **Segurança**
  - [ ] Criptografia end-to-end
  - [ ] 2FA (Autenticação em dois fatores)
  - [ ] Auditoria de segurança
  - [ ] LGPD compliance

---

## 📱 Como Usar

### 🚀 **Primeiro Acesso**
1. **Cadastro/Login**
   - Crie uma conta ou faça login
   - Complete o onboarding inicial

2. **Check-in de Humor**
   - Registre como você está se sentindo
   - Use os sliders para ajustar os níveis

3. **Perguntas Reflexivas**
   - Responda às perguntas personalizadas
   - Complete todas para melhor compatibilidade

### 💬 **Conversas**
1. **Encontrar Pessoas**
   - Veja usuários compatíveis na tela inicial
   - Explore perfis detalhados

2. **Iniciar Chat**
   - Toque em "Conversar" no perfil
   - Envie sua primeira mensagem

3. **Gerenciar Conversas**
   - Acesse o histórico na aba "Conversas"
   - Veja mensagens não lidas

### 🤖 **IA de Suporte - Luma**
1. **Chat com IA**
   - Acesse através da mensagem de suporte
   - **🆕 Escolha entre modo texto ou voz**
   - Converse sobre seus sentimentos
   - Receba orientações personalizadas

2. **🆕 Modo Voz da Luma**
   - Toque em "Falar com a Luma" no setup inicial
   - Ouça as respostas faladas pela Luma
   - Toque no avatar para pausar/continuar
   - Configure uma vez, o app lembra sua preferência

---

## 📊 Status do Projeto

<div align="center">

![Progresso](https://progress-bar.dev/85/?title=Desenvolvimento&width=200)

**🎯 Core Features:** 85% completo  
**🎨 UI/UX:** 90% completo  
**🔥 Backend:** 75% completo  
**🗣️ Chat por Voz:** 95% completo  
**🧪 Testes:** 35% completo  

**🆕 Última atualização:** Sistema de chat por voz com Luma implementado!

</div>

---

## 🚀 Build & Deploy

### 📱 **APK para Android**
```bash
# Build para release
flutter build apk --release

# APK otimizado por arquitetura
flutter build apk --split-per-abi
```

**Localização dos APKs:**
- `build/app/outputs/flutter-apk/app-release.apk` (universal)
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (recomendado)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

### 🍎 **iOS Build**
```bash
# Build para iOS
flutter build ios --release
```

---

## 🤝 Contribuição

Contribuições são sempre bem-vindas! 

### 📋 **Como Contribuir**
1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

### 🐛 **Reportar Bugs**
- Use as Issues do GitHub
- Inclua detalhes sobre o erro
- Adicione prints se possível

### 💡 **Sugerir Features**
- Abra uma Issue com a tag `enhancement`
- Descreva a funcionalidade desejada
- Explique o caso de uso

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👥 Equipe

<div align="center">

**Desenvolvido com ❤️ por:**

**Gabriel Gramacho** 
**Gustavo Teodoro**
**Felipe Kindermann**
**Kauã Granata**
**Marcelo Furnaletto**
</div>

---

## 📞 Contato

- 📧 Email: contatomindmatch@gmail.com
- 🐦 Twitter: [@MindMatchApp](https://twitter.com/MindMatchApp)
- 💬 Discord: [Servidor da Comunidade](https://discord.gg/mindmatch)

---

<div align="center">
*MindMatch - Conectando corações, criando futuro* 💙🧠✨

[⬆ Voltar ao topo](#-mindmatch---emotional-wellness--connection-app)

</div>
