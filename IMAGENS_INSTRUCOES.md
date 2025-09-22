# 🖼️ Instruções para Substituir as Imagens do MindMatch

## 📁 Localização dos Arquivos
As imagens estão localizadas em: `assets/images/`

## 🦊 Imagens a Substituir

### 1. **luma_mascot.png**
- **Descrição**: Mascote da Luma (raposa laranja com camiseta azul "MindMatch")
- **Uso**: 
  - Avatar da Luma no chat (texto e voz)
  - Splash screen (tela inicial do app)
  - Widget de voz da Luma
- **Dimensões recomendadas**: 512x512px (PNG com fundo transparente)

### 2. **mindmatch_heart_logo.png**
- **Descrição**: Logo do coração laranja com raposa dentro
- **Uso**: 
  - Tela de login
  - Tela de cadastro
- **Dimensões recomendadas**: 256x256px (PNG com fundo transparente)

### 3. **mindmatch_logo_gradient.png**
- **Descrição**: Logo com fundo gradiente azul-roxo
- **Uso**: 
  - Pode ser usado como ícone do app ou em futuras telas
- **Dimensões recomendadas**: 512x512px (PNG)

## 🔄 Como Substituir

1. **Salve suas imagens** com os nomes exatos listados acima
2. **Substitua os arquivos** na pasta `assets/images/`
3. **Execute** `flutter clean` e `flutter pub get`
4. **Teste** o app para verificar se as imagens aparecem corretamente

## ✅ Fallbacks Implementados

O código já tem fallbacks implementados:
- Se uma imagem não carregar, volta para o ícone original
- Isso garante que o app não quebra se houver problemas com as imagens

## 🎨 Recomendações de Design

- **Luma**: Mantenha o estilo cartoon/amigável
- **Logo**: Use cores que combinem com o tema laranja/azul do app
- **Formato**: PNG com fundo transparente sempre que possível
- **Qualidade**: Imagens de alta resolução para diferentes tamanhos de tela

## 🚀 Após Substituir

Após substituir as imagens, você pode:
- Gerar um novo APK: `flutter build apk --release`
- Testar em dispositivo: `flutter run`
- Verificar todas as telas onde as imagens aparecem