import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('🧪 Testando Syslog direto via TCP...\n');

  try {
    // Conectar ao EventLog Analyzer via TCP
    final socket = await Socket.connect('10.0.0.168', 514);
    print('✅ Conectado ao EventLog Analyzer na porta 514');

    // Criar mensagem MSWinEventLog format
    final timestamp = DateTime.now().toIso8601String();
    final priority = 14; // Local use facility (1) + Info severity (6)
    
    // Teste 1: Login bem-sucedido
    final successMessage = '<$priority>MSWinEventLog\t1\tSecurity\t${DateTime.now().millisecondsSinceEpoch}\t${timestamp}\t4624\tMindMatch\tN/A\tSuccess Audit\tgabriel.test@mindmatch.com\tMindMatch Security Events\tLogon Type: 10\tLogon Process: User32\tAuthentication Package: Negotiate\tWorkstation Name: MINDMATCH-APP\tLogon GUID: {12345678-1234-5678-9012-123456789012}\tTransmitted Services: -\tPackage Name (NTLM only): -\tKey Length: 0\tCaller Computer Name: 192.168.1.100\tCaller User Name: MindMatch\tCaller Domain: MOBILE\tCaller Logon ID: 0x1234567890\tCaller Process ID: 1234\tCaller Process Name: C:\\MindMatch\\App.exe';
    
    socket.write(successMessage + '\n');
    print('📤 Enviado evento de sucesso: ${successMessage.length} bytes');
    
    await Future.delayed(Duration(seconds: 2));
    
    // Teste 2: Login falha  
    final failMessage = '<$priority>MSWinEventLog\t1\tSecurity\t${DateTime.now().millisecondsSinceEpoch}\t${timestamp}\t4625\tMindMatch\tN/A\tFailure Audit\thacker.test@evil.com\tMindMatch Security Events\tLogon Type: 3\tLogon Process: NtLmSsp\tAuthentication Package: NTLM\tWorkstation Name: HACKER-PC\tLogon GUID: {00000000-0000-0000-0000-000000000000}\tTransmitted Services: -\tPackage Name (NTLM only): NTLM\tKey Length: 0\tCaller Computer Name: 192.168.1.200\tCaller User Name: Hacker\tCaller Domain: UNKNOWN\tCaller Logon ID: 0x0\tCaller Process ID: 666\tCaller Process Name: C:\\Hacker\\Tools.exe\tSource Network Address: 192.168.1.200\tSource Port: 12345';
    
    socket.write(failMessage + '\n');
    print('📤 Enviado evento de falha: ${failMessage.length} bytes');
    
    await socket.close();
    print('✅ Conexão fechada com sucesso');
    
    print('\n🎯 Teste completo! Verifique no EventLog Analyzer:');
    print('- Evento 4624 (Success): gabriel.test@mindmatch.com');
    print('- Evento 4625 (Failure): hacker.test@evil.com');
    
  } catch (e) {
    print('❌ Erro no teste: $e');
    exit(1);
  }
}
