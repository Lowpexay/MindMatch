import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfessionalDetailScreen extends StatelessWidget {
  const ProfessionalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stateExtra = GoRouterState.of(context).extra ?? ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> profile = stateExtra is Map<String, dynamic> ? stateExtra as Map<String, dynamic> : {};

    final name = profile['name'] ?? 'Profissional';
    final approach = profile['approach'] ?? '';
    final location = profile['location'] ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 36, child: Icon(Icons.person, size: 36)),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(approach),
            const SizedBox(height: 8),
            Text('Local: $location'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                try {
                  context.go('/scheduleAppointment', extra: profile);
                } catch (_) {
                  Navigator.pushNamed(context, '/scheduleAppointment', arguments: profile);
                }
              },
              child: const Text('Marcar consulta'),
            )
          ],
        ),
      ),
    );
  }
}
