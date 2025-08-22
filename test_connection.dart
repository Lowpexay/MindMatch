import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testando conectividade com EventLog Analyzer...\n');
  
  const baseUrl = 'http://desktop-ne646bh:8400';
  const apiKey = 'mte1zjc3ndktmzdhzs00zwq5ltk5otgtmgzjztgzndm2owu2';
  
  final headers = {
    'Content-Type': 'application/json',
    'AuthToken': apiKey,
    'Accept': 'application/json',
  };
  
  // Lista de endpoints para testar
  final testEndpoints = [
    baseUrl,
    '$baseUrl/event',
    '$baseUrl/event/index2.do',
    '$baseUrl/event/restapi',
    '$baseUrl/event/restapi/health',
  ];
  
  for (final endpoint in testEndpoints) {
    try {
      print('🔍 Testando: $endpoint');
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('✅ Status: ${response.statusCode}');
      print('📄 Content-Type: ${response.headers['content-type']}');
      print('📏 Body Length: ${response.body.length} chars');
      
      if (response.statusCode == 200) {
        print('🎉 SUCESSO! Endpoint funcionando: $endpoint');
      }
      
      print('─' * 50);
      
    } catch (e) {
      print('❌ ERRO: $e');
      print('─' * 50);
    }
  }
  
  // Teste adicional: verificar se o serviço está rodando na porta
  print('\n🔌 Testando conectividade de porta...');
  try {
    final socket = await Socket.connect('desktop-ne646bh', 8400, timeout: Duration(seconds: 5));
    print('✅ Porta 8400 está aberta e acessível');
    socket.destroy();
  } catch (e) {
    print('❌ Não foi possível conectar na porta 8400: $e');
  }
  
  print('\n📋 Resumo:');
  print('• Host: desktop-ne646bh');
  print('• Porta: 8400');
  print('• API Key: $apiKey');
  print('• Headers: AuthToken (ao invés de Bearer)');
  
  print('\n💡 Próximos passos se todos os testes falharam:');
  print('1. Verificar se o EventLog Analyzer está rodando');
  print('2. Confirmar se a API REST está habilitada');
  print('3. Verificar firewall/antivírus');
  print('4. Testar no navegador: http://desktop-ne646bh:8400');
}
