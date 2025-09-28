import 'package:flutter/material.dart';
import '../security/eventlog_service.dart';
import '../utils/app_colors.dart';

class EventLogReportScreen extends StatefulWidget {
  const EventLogReportScreen({super.key});

  @override
  State<EventLogReportScreen> createState() => _EventLogReportScreenState();
}

class _EventLogReportScreenState extends State<EventLogReportScreen> {
  // Agora usamos EventLogService centralizado; estes campos antigos foram removidos.
  
  List<Map<String, dynamic>> _loginAttempts = [];
  bool _isLoading = false;
  bool _isConnected = false;
  int _totalAttempts = 0;
  int _successfulLogins = 0;
  int _failedLogins = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEventLogData();
  }

  // Verificar conectividade com o ManageEngine EventLog Analyzer
  Future<bool> _checkConnection() async {
    // Usa método de teste já existente
    return await EventLogService.testConnection();
  }

  Future<void> _loadEventLogData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar conectividade com ManageEngine
      _isConnected = await _checkConnection();
      
  // Carregar eventos reais (sucesso + falha) via serviço
  final events = await EventLogService.getLoginAttempts(limit: 80);
      
      // Processar estatísticas
      _totalAttempts = events.length;
  _successfulLogins = events.where((e) => (e['status'] ?? '').toString().toUpperCase() == 'SUCCESS').length;
  _failedLogins = events.where((e) => (e['status'] ?? '').toString().toUpperCase() == 'FAILURE').length;

      setState(() {
        _loginAttempts = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar dados: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios EventLog'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEventLogData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildDashboardContent(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erro de Conexão',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadEventLogData,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return Column(
      children: [
        // Status de Conexão
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: _isConnected ? Colors.green[100] : Colors.orange[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isConnected ? Icons.check_circle : Icons.warning,
                color: _isConnected ? Colors.green[700] : Colors.orange[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _isConnected 
                    ? 'Conectado ao ManageEngine EventLog Analyzer'
                    : 'Usando dados locais - Verifique conexão',
                style: TextStyle(
                  color: _isConnected ? Colors.green[700] : Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Estatísticas
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total',
                  _totalAttempts.toString(),
                  Colors.blue,
                  Icons.event_note,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sucessos',
                  _successfulLogins.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Falhas',
                  _failedLogins.toString(),
                  Colors.red,
                  Icons.error,
                ),
              ),
            ],
          ),
        ),

        // Lista de Eventos
        Expanded(
          child: _buildEventsList(),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:  isDark ? AppColors.blackFont : AppColors.whiteBack,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_loginAttempts.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum evento encontrado',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loginAttempts.length,
      itemBuilder: (context, index) {
        final event = _loginAttempts[index];
        return _buildEventCard(event);
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
  final isSuccess = (event['status'] ?? '').toString().toUpperCase() == 'SUCCESS';
  final timestamp = DateTime.tryParse(event['timestamp'] ?? '') ?? DateTime.now();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isSuccess ? 'Login Bem-sucedido' : 'Tentativa de Login Falhada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green[700] : Colors.red[700],
                  ),
                ),
                const Spacer(),
                Text(
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  event['user'] ?? 'Usuário desconhecido',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            
            Row(
              children: [
                Icon(Icons.devices, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  event['device'] ?? 'Device desconhecido',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  event['ip'] ?? 'IP desconhecido',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            
            if (event['eventId'] != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.tag, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Event ID: ${event['eventId']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
