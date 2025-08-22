import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../security/eventlog_service.dart';
import 'eventlog_test_screen.dart';

class SecurityReportsScreen extends StatefulWidget {
  const SecurityReportsScreen({super.key});

  @override
  State<SecurityReportsScreen> createState() => _SecurityReportsScreenState();
}

class _SecurityReportsScreenState extends State<SecurityReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isConnected = false;
  
  List<Map<String, dynamic>> _failedLogins = [];
  List<Map<String, dynamic>> _securityAlerts = [];
  Map<String, dynamic>? _securityStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Testar conexão
      _isConnected = await EventLogService.testConnection();
      
      if (_isConnected) {
        final user = FirebaseAuth.instance.currentUser;
        final userId = user?.uid;
        
        // Carregar dados em paralelo
        final results = await Future.wait([
          EventLogService.getFailedLoginAttempts(userId: userId),
          EventLogService.getSecurityAlerts(userId: userId),
          EventLogService.getSecurityStats(userId: userId),
        ]);
        
        setState(() {
          _failedLogins = results[0] as List<Map<String, dynamic>>;
          _securityAlerts = results[1] as List<Map<String, dynamic>>;
          _securityStats = results[2] as Map<String, dynamic>?;
        });
      }
    } catch (e) {
      print('Error loading security data: $e');
      _showErrorSnackBar('Erro ao carregar dados de segurança');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[600],
        action: SnackBarAction(
          label: 'Tentar Novamente',
          textColor: Colors.white,
          onPressed: _loadData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios de Segurança'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isConnected
              ? _buildConnectionError()
              : Column(
                  children: [
                    _buildStatusCard(),
                    TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Theme.of(context).primaryColor,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.warning_amber),
                          text: 'Tentativas',
                        ),
                        Tab(
                          icon: Icon(Icons.shield_outlined),
                          text: 'Alertas',
                        ),
                        Tab(
                          icon: Icon(Icons.analytics_outlined),
                          text: 'Estatísticas',
                        ),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildFailedLoginsTab(),
                          _buildAlertsTab(),
                          _buildStatsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildConnectionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Não foi possível conectar ao EventLog Analyzer',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Verifique se o servidor está online e as configurações estão corretas.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventLogTestWidget(),
                  ),
                );
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Testar Conexão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isConnected
              ? [Colors.green[400]!, Colors.green[600]!]
              : [Colors.red[400]!, Colors.red[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (_isConnected ? Colors.green : Colors.red).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            _isConnected ? Icons.security : Icons.security_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isConnected ? 'Sistema Conectado' : 'Sistema Desconectado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isConnected
                      ? 'EventLog Analyzer ativo'
                      : 'Verificar configurações',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_securityAlerts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_securityAlerts.length} alertas',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFailedLoginsTab() {
    if (_failedLogins.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle_outline,
        title: 'Nenhuma tentativa de login falhada',
        subtitle: 'Todas as tentativas de login foram bem-sucedidas.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _failedLogins.length,
      itemBuilder: (context, index) {
        final attempt = _failedLogins[index];
        final timestamp = DateTime.tryParse(attempt['timestamp'] ?? '');
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red[100],
              child: Icon(
                Icons.lock_outline,
                color: Colors.red[600],
              ),
            ),
            title: Text(attempt['username'] ?? 'Usuário desconhecido'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IP: ${attempt['ip_address'] ?? 'Desconhecido'}'),
                if (timestamp != null)
                  Text(_formatDateTime(timestamp)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showAttemptDetails(attempt),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    if (_securityAlerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shield_outlined,
        title: 'Nenhum alerta ativo',
        subtitle: 'Sua conta está segura no momento.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _securityAlerts.length,
      itemBuilder: (context, index) {
        final alert = _securityAlerts[index];
        final severity = alert['severity'] ?? 'info';
        final color = _getSeverityColor(severity);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(
                _getSeverityIcon(severity),
                color: color,
              ),
            ),
            title: Text(alert['name'] ?? 'Alerta de Segurança'),
            subtitle: Text(alert['description'] ?? ''),
            trailing: Chip(
              label: Text(
                severity.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: color.withOpacity(0.1),
              side: BorderSide(color: color),
            ),
            onTap: () => _showAlertDetails(alert),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab() {
    if (_securityStats == null) {
      return _buildEmptyState(
        icon: Icons.analytics_outlined,
        title: 'Estatísticas não disponíveis',
        subtitle: 'Não foi possível carregar os dados estatísticos.',
      );
    }

    final stats = _securityStats!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(
            'Total de Logins',
            stats['total_logins']?.toString() ?? '0',
            Icons.login,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Tentativas Falhadas',
            stats['failed_logins']?.toString() ?? '0',
            Icons.warning,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Taxa de Sucesso',
            '${stats['success_rate']?.toStringAsFixed(1) ?? '0'}%',
            Icons.check_circle,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Alertas Gerados',
            stats['alerts_generated']?.toString() ?? '0',
            Icons.notifications,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red[800]!;
      case 'high':
        return Colors.red[600]!;
      case 'medium':
        return Colors.orange[600]!;
      case 'low':
        return Colors.yellow[700]!;
      default:
        return Colors.blue[600]!;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.dangerous;
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      case 'low':
        return Icons.notification_important;
      default:
        return Icons.info_outline;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/'
        '${dateTime.month.toString().padLeft(2, '0')}/'
        '${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showAttemptDetails(Map<String, dynamic> attempt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalhes da Tentativa'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Usuário', attempt['username'] ?? 'N/A'),
              _buildDetailRow('IP', attempt['ip_address'] ?? 'N/A'),
              _buildDetailRow('Dispositivo', attempt['device_info'] ?? 'N/A'),
              _buildDetailRow('Plataforma', attempt['platform'] ?? 'N/A'),
              if (attempt['timestamp'] != null)
                _buildDetailRow('Data/Hora', _formatDateTime(
                  DateTime.parse(attempt['timestamp']),
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert['name'] ?? 'Alerta'),
        content: Text(alert['description'] ?? 'Sem descrição disponível'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
