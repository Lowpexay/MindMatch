param(
  [Parameter(Mandatory = $true)]
  [string]$GeminiApiKey
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($GeminiApiKey)) {
  throw 'Informe uma chave Gemini válida.'
}

flutter pub get
flutter build apk --release "--dart-define=GEMINI_API_KEY=$GeminiApiKey"

Write-Host 'APK gerado em build/app/outputs/flutter-apk/app-release.apk'
