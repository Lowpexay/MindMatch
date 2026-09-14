param(
  [Parameter(Mandatory = $true)]
  [string]$TelegramBotToken,
  [string]$PublicBackendUrl = ''
)

$env:TELEGRAM_BOT_TOKEN = $TelegramBotToken
$env:TELEGRAM_BOT_USERNAME = 'Mindmatch_Consultas_bot'
$env:TELEGRAM_WEBHOOK_SECRET = 'mindmatch-telegram-webhook-918273'
$env:FIREBASE_SERVICE_ACCOUNT_PATH = 'C:\Users\gabriel\Downloads\mindmatch-ba671-firebase-adminsdk-fbsvc-a2231ff5dc.json'
$env:PUBLIC_BACKEND_URL = $PublicBackendUrl

npm start
