# Integração Telegram local

## 1. Criar o bot

No Telegram, abra `@BotFather`, use `/newbot` e escolha:

- Nome: `MindMatch Consultas`
- Username: `Mindmatch_Consultas_bot`

Copie o token somente para a variável `TELEGRAM_BOT_TOKEN`. Não coloque o token no Flutter nem no Git.

## 2. Configurar o Firebase Admin

No Firebase Console, crie uma chave privada de uma conta de serviço e coloque o JSON inteiro, em uma linha, em `FIREBASE_SERVICE_ACCOUNT_JSON`.

## 3. Executar o backend

No PowerShell, dentro de `MindMatch/backend`:

```powershell
$env:TELEGRAM_BOT_TOKEN = 'TOKEN_DO_BOT'
$env:TELEGRAM_BOT_USERNAME = 'Mindmatch_Consultas_bot'
$env:TELEGRAM_WEBHOOK_SECRET = 'um-segredo-longo-e-aleatorio'
$env:FIREBASE_SERVICE_ACCOUNT_PATH = 'C:\Users\gabriel\Downloads\mindmatch-ba671-firebase-adminsdk-fbsvc-a2231ff5dc.json'
$env:PUBLIC_BACKEND_URL = 'https://URL_PUBLICA_HTTPS'
npm start
```

O arquivo de credenciais não deve ser commitado. Para testar apenas a tela do app sem webhook, ainda é possível iniciar o servidor sem `PUBLIC_BACKEND_URL`; o webhook, porém, precisa de uma URL HTTPS acessível pelo Telegram.

O backend envia a confirmação da consulta ao paciente e ao psicólogo quando os dois estiverem vinculados. A cada minuto, enquanto o backend estiver aberto, ele verifica consultas agendadas e envia ao paciente um lembrete na janela de aproximadamente 24 horas antes do horário.

## 4. Apontar o app para o backend local

Desktop/web:

```powershell
flutter run --dart-define=BACKEND_URL=http://127.0.0.1:3000
```

Android Emulator:

```powershell
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:3000
```

Em aparelho físico, use o IP da máquina na rede local, por exemplo `http://192.168.0.10:3000`.
