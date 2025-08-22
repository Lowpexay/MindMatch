# 🔐 Integração ManageEngine EventLog Analyzer

## Visão Geral

O MindMatch agora possui integração completa com o ManageEngine EventLog Analyzer para monitoramento de segurança em tempo real. Esta integração permite:

- **Monitoramento de Tentativas de Login**: Rastreamento automático de login bem-sucedidos e falhados
- **Alertas de Segurança**: Notificações automáticas para atividades suspeitas
- **Relatórios Detalhados**: Dashboard completo com estatísticas de segurança
- **Análise de Comportamento**: Detecção de padrões anômalos de acesso

## 🚀 Configuração Inicial

### 1. Configurar URL do Servidor

No arquivo `lib/security/eventlog_service.dart`, atualize a URL base:

```dart
static const String _baseUrl = 'https://SEU-SERVIDOR-EVENTLOG.com/api';
```

### 2. Verificar API Key

A API key já está configurada no código:
```dart
static const String _apiKey = 'mte1zjc3ndktmzdhzs00zwq5ltk5otgtmgzjztgzndm2owu2';
```

### 3. Configurar ManageEngine EventLog Analyzer

#### Endpoints Necessários:

- `POST /api/logs/login-attempts` - Registrar tentativas de login
- `POST /api/logs/security-events` - Registrar eventos de segurança
- `GET /api/logs/query` - Consultar logs
- `GET /api/reports/security-stats` - Obter estatísticas
- `GET /api/alerts` - Listar alertas ativos
- `POST /api/alerts/rules` - Configurar regras de alerta
- `GET /api/health` - Verificar status do servidor

#### Estrutura de Dados Esperada:

**Login Attempt:**
```json
{
  "timestamp": "2024-01-15T10:30:00Z",
  "application": "MindMatch",
  "event_type": "login_attempt",
  "user_id": "firebase_user_id",
  "username": "user@example.com",
  "success": true,
  "device_info": "mobile_device",
  "ip_address": "192.168.1.100",
  "user_agent": "mobile_app",
  "platform": "mobile",
  "severity": "info",
  "category": "authentication"
}
```

## 📊 Funcionalidades Implementadas

### 1. Logging Automático
- ✅ Tentativas de login (email/senha e Google)
- ✅ Eventos de segurança genéricos
- ✅ Informações de dispositivo e plataforma
- ✅ Timestamps precisos

### 2. Dashboard de Relatórios
- ✅ Lista de tentativas de login falhadas
- ✅ Alertas de segurança ativos
- ✅ Estatísticas de segurança (30 dias)
- ✅ Interface responsiva com abas

### 3. Alertas Configuráveis
- ✅ Múltiplas tentativas de login falhadas (5 em 15min)
- ✅ Login de localizações diferentes (1 hora)
- ✅ Configuração automática para novos usuários

### 4. Acesso via Drawer
- ✅ Nova opção "Relatórios de Segurança" no menu
- ✅ Ícone de segurança intuitivo
- ✅ Navegação direta para o dashboard

## 🔧 Como Usar

### Para Usuários:

1. **Acessar Relatórios**: Menu → Relatórios de Segurança
2. **Visualizar Tentativas**: Aba "Tentativas" mostra logins falhados
3. **Verificar Alertas**: Aba "Alertas" exibe notificações de segurança
4. **Ver Estatísticas**: Aba "Estatísticas" com métricas dos últimos 30 dias

### Para Desenvolvedores:

#### Registrar Evento Personalizado:
```dart
await EventLogService.logSecurityEvent(
  userId: 'user_id',
  eventType: 'suspicious_activity',
  description: 'Múltiplos acessos em horário incomum',
  severity: 'medium',
  additionalData: {'location': 'mobile_app'},
);
```

#### Verificar Conectividade:
```dart
bool isConnected = await EventLogService.testConnection();
if (isConnected) {
  print('EventLog Analyzer conectado!');
}
```

#### Obter Dados de Segurança:
```dart
// Tentativas falhadas
List<Map<String, dynamic>> failed = await EventLogService.getFailedLoginAttempts();

// Estatísticas
Map<String, dynamic>? stats = await EventLogService.getSecurityStats();

// Alertas ativos
List<Map<String, dynamic>> alerts = await EventLogService.getSecurityAlerts();
```

## 🛡️ Tipos de Alertas

### 1. Múltiplas Tentativas Falhadas
- **Condição**: 5+ tentativas em 15 minutos
- **Severidade**: Alta
- **Ações**: Email + Dashboard

### 2. Login Suspeito
- **Condição**: Logins de locais diferentes em 1 hora
- **Severidade**: Média
- **Ações**: Dashboard

### 3. Atividade Fora do Horário
- **Condição**: Login entre 2h-6h (configurável)
- **Severidade**: Baixa
- **Ações**: Log apenas

## 📈 Métricas Coletadas

- **Total de Logins**: Quantidade de acessos no período
- **Tentativas Falhadas**: Número de falhas de autenticação
- **Taxa de Sucesso**: Percentual de logins bem-sucedidos
- **Alertas Gerados**: Quantidade de alertas disparados
- **Dispositivos Únicos**: Diferentes devices utilizados
- **Horários de Pico**: Períodos de maior atividade

## 🔒 Segurança e Privacidade

- **Criptografia**: Todas as comunicações via HTTPS
- **Autenticação**: API Key obrigatória
- **Dados Sensíveis**: Senhas nunca são logadas
- **Retenção**: Logs mantidos conforme política do EventLog
- **Anonimização**: IPs podem ser mascarados se necessário

## 🚨 Solução de Problemas

### Problema: "Sistema Desconectado"
1. Verificar URL do servidor em `eventlog_service.dart`
2. Confirmar que API Key está correta
3. Testar conectividade de rede
4. Verificar logs do servidor EventLog

### Problema: "Dados não aparecem"
1. Confirmar que eventos estão sendo enviados
2. Verificar configuração de endpoints
3. Checar permissões da API Key
4. Validar estrutura JSON dos dados

### Problema: "Alertas não funcionam"
1. Verificar se regras foram criadas
2. Confirmar configuração de notificações
3. Testar thresholds dos alertas
4. Verificar logs de erro

## 📞 Suporte

Para problemas específicos do ManageEngine EventLog Analyzer:
- Documentação oficial: https://help.manageengine.com/eventlog-analyzer/
- Suporte técnico: Contatar administrador do sistema
- Logs de debug: Ativar modo debug no Flutter para mais detalhes

## 🔄 Atualizações Futuras

- [ ] Dashboard em tempo real com WebSockets
- [ ] Geolocalização mais precisa
- [ ] Machine Learning para detecção de anomalias
- [ ] Integração com outras ferramentas SIEM
- [ ] Relatórios customizáveis por usuário
- [ ] Notificações push para alertas críticos
