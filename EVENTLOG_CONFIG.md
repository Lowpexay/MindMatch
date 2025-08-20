# 🔧 Configuração ManageEngine EventLog Analyzer

## Informações do Seu Servidor

**URL do Servidor**: `http://desktop-ne646bh:8400`  
**API Key**: `mte1zjc3ndktmzdhzs00zwq5ltk5otgtmgzjztgzndm2owu2`  
**Status**: ✅ Ativo (baseado na captura de tela)

## Endpoints Configurados

Com base na sua instalação do ManageEngine EventLog Analyzer, foram configurados os seguintes endpoints:

### 1. Envio de Logs
```
POST http://desktop-ne646bh:8400/event/index2.do/restapi/logdata
```
**Função**: Enviar dados de tentativas de login e eventos de segurança

### 2. Busca de Logs
```
GET http://desktop-ne646bh:8400/event/index2.do/restapi/logdata/search
```
**Função**: Consultar tentativas de login falhadas

### 3. Relatórios
```
GET http://desktop-ne646bh:8400/event/index2.do/restapi/logdata/reports
```
**Função**: Obter estatísticas de segurança

### 4. Alertas
```
GET http://desktop-ne646bh:8400/event/index2.do/restapi/alerts
POST http://desktop-ne646bh:8400/event/index2.do/restapi/alerts/rules
```
**Função**: Gerenciar alertas de segurança

### 5. Health Check
```
GET http://desktop-ne646bh:8400/event/index2.do/restapi/health
```
**Função**: Verificar conectividade

## Event IDs Utilizados

O sistema está configurado para usar Event IDs padrão do Windows:

- **4624**: Login bem-sucedido
- **4625**: Falha de login
- **5000**: Eventos de segurança customizados

## Estrutura de Headers

```json
{
  "Content-Type": "application/json",
  "AuthToken": "mte1zjc3ndktmzdhzs00zwq5ltk5otgtmgzjztgzndm2owu2",
  "Accept": "application/json"
}
```

## Formato de Dados Enviados

### Tentativa de Login:
```json
{
  "timestamp": "2025-08-19T10:30:00Z",
  "application": "MindMatch",
  "event_type": "login_attempt",
  "user_id": "firebase_user_id",
  "username": "user@example.com",
  "success": true,
  "device_info": "mobile_device",
  "ip_address": "dynamic",
  "user_agent": "mobile_app",
  "platform": "mobile",
  "severity": "info",
  "category": "authentication",
  "source": "MindMatch Mobile App",
  "eventid": 4624,
  "details": {
    "app_version": "1.0.0",
    "login_method": "email_password",
    "session_id": "mindmatch_1692448200000"
  }
}
```

## Como Testar a Integração

1. **Teste de Conectividade**:
   ```dart
   bool isConnected = await EventLogService.testConnection();
   print('Conectado: $isConnected');
   ```

2. **Enviar Log de Teste**:
   ```dart
   await EventLogService.logLoginAttempt(
     userId: 'test_user',
     userName: 'teste@example.com',
     deviceInfo: 'test_device',
     isSuccessful: true,
   );
   ```

3. **Verificar no EventLog Analyzer**:
   - Acesse: `http://desktop-ne646bh:8400/event/index2.do`
   - Vá para **Search** → **Custom Search**
   - Filtre por: `application = "MindMatch"`

## Configurações Específicas do ManageEngine

### 1. Habilitar API REST
Certifique-se de que a API REST está habilitada em:
- **Settings** → **API Settings** → **Enable REST API**

### 2. Configurar AuthToken
O token já está configurado no código:
- Visível em: **Settings** → **API Settings** → **AuthTokens**
- Token ativo: `mte1***qwu2`

### 3. Configurar Alertas
Para receber notificações automáticas:
- **Alerts** → **Alert Profiles** → **Create New Profile**
- Configurar regras para Event IDs 4624/4625
- Associar ao aplicativo "MindMatch"

## Monitoramento

### Dashboard MindMatch
Acesse através do app: **Menu** → **Relatórios de Segurança**

### Dashboard EventLog
Acesse: `http://desktop-ne646bh:8400/event/index2.do/url=emberapp#/settings/apisettings`

## Troubleshooting

### ❌ Problema: "Não foi possível conectar ao EventLog Analyzer"

**Passos de Diagnóstico:**

1. **Verificar se o EventLog Analyzer está rodando:**
   ```bash
   # Testar no navegador
   http://desktop-ne646bh:8400
   
   # Testar conectividade de porta
   Test-NetConnection -ComputerName desktop-ne646bh -Port 8400
   ```

2. **Executar script de debug:**
   ```bash
   dart run test_connection.dart
   ```

3. **Verificar configurações da API REST:**
   - Acesse: `http://desktop-ne646bh:8400/event/index2.do`
   - Vá para: **Settings** → **API Settings**
   - Confirme: **Enable REST API** = ✅ Ativado
   - Verificar: **AuthTokens** lista deve conter seu token

4. **Possíveis URLs alternativas:**
   ```
   http://localhost:8400                    (se local)
   http://127.0.0.1:8400                   (se local)
   http://desktop-ne646bh:8400/event       (com /event)
   https://desktop-ne646bh:8400            (se HTTPS habilitado)
   ```

5. **Verificar Firewall/Antivírus:**
   - Windows Defender pode estar bloqueando
   - Adicionar exceção para porta 8400
   - Verificar regras de firewall corporativo

6. **Logs do EventLog Analyzer:**
   - Verificar: `C:\ManageEngine\EventLog Analyzer\logs\`
   - Procurar por erros de API ou conectividade

**Soluções Rápidas:**

- ✅ **API REST desabilitada**: Settings → API Settings → Enable REST API
- ✅ **Token inválido**: Gerar novo AuthToken nas configurações
- ✅ **Porta bloqueada**: Adicionar exceção no firewall para porta 8400
- ✅ **Serviço parado**: Reiniciar serviço ManageEngine EventLog Analyzer

### Problema: "Dados não aparecem"
1. Verificar logs do EventLog Analyzer
2. Confirmar formato JSON dos dados enviados
3. Testar endpoints manualmente
4. Verificar permissões do AuthToken

### Problema: "Alertas não funcionam"
1. Configurar regras de alerta no EventLog
2. Verificar thresholds configurados
3. Confirmar notificações habilitadas
4. Testar com dados de exemplo

## Status Atual

✅ **Configuração Completa**  
✅ **Endpoints Atualizados**  
✅ **AuthToken Configurado**  
✅ **Event IDs Definidos**  
✅ **Headers Corretos**  

🔄 **Próximos Passos**:
1. Testar conectividade
2. Enviar primeiro log
3. Configurar alertas
4. Validar dashboard
