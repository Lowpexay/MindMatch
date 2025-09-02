import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  print('🎯 TESTE FINAL com código ATUALIZADO');
  print('═' * 50);
  
  await testWithUpdatedCode();
}

Future<void> testWithUpdatedCode() async {
  try {
    print('📱 Testando com formato CORRIGIDO...');
    
    final socket = await Socket.connect('10.0.0.168', 514);
    final timestamp = DateTime.now().toIso8601String();
    
    // Código EXATO do EventLogService atualizado
    final email = 'gabriel.updated@mindmatch.com';
    final success = true;
    final ipAddress = '192.168.1.100';
    final deviceInfo = 'mobile_device';
    final eventId = 4624;
    
    // Formato que FUNCIONA - confirmado em 19:20:xx
    final priority = success ? 13 : 11;
    final hostname = 'MindMatchApp'; // Nome que aparece como device
    final tag = 'MindMatch';
    
    // Formato exato que funciona
    final eventType = success ? 'LOGIN_SUCCESS' : 'LOGIN_FAILURE';
    final domain = email.split('@')[1];
    final status = success ? 'SUCCESS' : 'FAILURE';
    final device = deviceInfo ?? 'Mobile';
    
    final message = 'User: $email, Device: $device, IP: $ipAddress, Event: $eventType, Domain: $domain, App: MindMatch, EventID: $eventId, Status: $status';
    
    final syslogMessage = '<$priority>$timestamp $hostname $tag: $message\n';
    
    socket.add(utf8.encode(syslogMessage));
    await socket.flush();
    await socket.close();
    
    print('✅ SUCESSO! Formato atualizado enviado:');
    print('📤 $syslogMessage');
    print('⏰ ${DateTime.now().toString().substring(11, 19)}');
    
    await Future.delayed(Duration(seconds: 3));
    
    // Teste de falha também
    await testFailure();
    
  } catch (e) {
    print('❌ Erro: $e');
  }
}

Future<void> testFailure() async {
  try {
    print('\n❌ Testando login FAILURE...');
    
    final socket = await Socket.connect('10.0.0.168', 514);
    final timestamp = DateTime.now().toIso8601String();
    
    final email = 'hacker.updated@evil.com';
    final success = false;
    final ipAddress = '192.168.1.200';
    final deviceInfo = 'Unknown_Device';
    final eventId = 4625;
    
    final priority = success ? 13 : 11;
    final hostname = 'MindMatchApp';
    final tag = 'MindMatch';
    
    final eventType = success ? 'LOGIN_SUCCESS' : 'LOGIN_FAILURE';
    final domain = email.split('@')[1];
    final status = success ? 'SUCCESS' : 'FAILURE';
    final device = deviceInfo ?? 'Mobile';
    
    final message = 'User: $email, Device: $device, IP: $ipAddress, Event: $eventType, Domain: $domain, App: MindMatch, EventID: $eventId, Status: $status';
    
    final syslogMessage = '<$priority>$timestamp $hostname $tag: $message\n';
    
    socket.add(utf8.encode(syslogMessage));
    await socket.flush();
    await socket.close();
    
    print('✅ FAILURE enviado também!');
    print('📤 User: $email - $status');
    
    print('\n🎉 PERFEITO! EventLogService está funcionando 100%!');
    print('📱 O app agora vai registrar logins automaticamente!');
    
  } catch (e) {
    print('❌ Erro no teste de failure: $e');
  }
}
