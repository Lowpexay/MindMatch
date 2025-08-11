# 🔑 Configuração Google Sign-In - INSTRUÇÕES IMPORTANTES

## ❌ Problema Detectado:
O Google Sign-In está falhando com `ApiException: 10` porque as chaves SHA-1 e SHA-256 não estão configuradas no Firebase Console.

## 🔧 Chaves SHA Detectadas:
- **SHA-1**: `18:9C:72:D7:AF:FD:5A:D6:B2:57:F9:15:FF:A0:49:98:63:74:39:05`
- **SHA-256**: `4D:25:9D:3B:26:ED:EC:F6:FC:B4:0A:49:33:55:44:00:88:73:06:07:E6:A3:3B:77:4A:CC:47:C5:2B`

## 📋 Passos para Configurar:

### 1. Abrir Firebase Console:
   - Acesse: https://console.firebase.google.com/
   - Selecione o projeto: **mindmatch-ba671**

### 2. Configurar as Chaves SHA:
   - Vá em **Project Settings** (⚙️ ícone de engrenagem)
   - Na aba **General**, encontre a seção **Your apps**
   - Clique no app Android: `com.company.mindmatch`
   - Na seção **SHA certificate fingerprints**, clique em **Add fingerprint**
   
### 3. Adicionar as Chaves:
   **Primeira chave (SHA-1):**
   ```
   189C72D7AFFD5AD6B257F915FFA0499863743905
   ```
   
   **Segunda chave (SHA-256):**
   ```
   4D259D3B26EDECF6FCB40A493355440088730607E6A33B774ACC47C52B
   ```

### 4. Baixar o novo google-services.json:
   - Após adicionar as chaves, baixe o arquivo atualizado
   - Substitua o arquivo em: `android/app/google-services.json`

### 5. Teste:
   - Reinicie o app: `flutter run`
   - Teste o Google Sign-In

## ⚠️ Importante:
- As chaves devem ser adicionadas SEM os dois pontos (:)
- Use apenas letras e números
- Certifique-se de baixar o google-services.json atualizado

## 🔗 Links Úteis:
- [Firebase Console](https://console.firebase.google.com/)
- [Documentação SHA fingerprints](https://developers.google.com/android/guides/client-auth)

## ✅ Status:
- [x] Chaves SHA detectadas
- [x] Chaves adicionadas ao Firebase Console
- [x] google-services.json atualizado
- [x] Package name corrigido para com.company.mindmatch
- [ ] Teste do Google Sign-In realizado

## 🎉 CONFIGURAÇÃO CONCLUÍDA!
O arquivo `google-services.json` foi atualizado com as chaves SHA-1 corretas.
O Google Sign-In deve funcionar agora!

## 🧪 Para Testar:
1. Execute: `flutter run`
2. Na tela de login, clique em "Entrar com Google"
3. Selecione sua conta Google
4. Confirme as permissões
5. Você deve ser redirecionado para a Home Screen

## ⚠️ Se ainda houver problemas:
- Limpe o cache: `flutter clean && flutter pub get`
- Reinstale o app completamente
- Verifique se as chaves SHA estão corretas no Firebase Console
