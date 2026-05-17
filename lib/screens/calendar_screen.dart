import 'package:flutter/material.dart';
import '../global/appCor.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  final List<Map<String, String>> _eventos = const [
    {
      'titulo': 'Campanha de vacinação',
      'data': '03/04/2025',
      'local': 'Posto de Saúde central',
    },
    {
      'titulo': 'Doação de sangue',
      'data': '19/03/2025',
      'local': 'Hemocentro central',
    },
    {
      'titulo': 'Evento de conscientização',
      'data': '10/06/2025',
      'local': 'Praça Central',
    },
    {
      'titulo': 'Mutirão de Saúde e Prevenção',
      'data': '20/05/2026',
      'local': 'Centro Comunitário',
    },
    {
      'titulo': 'Roda de diálogo sobre saúde mental',
      'data': '22/05/2026',
      'local': 'Auditório da Prefeitura',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Próximos eventos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _eventos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final evento = _eventos[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      leading: const Icon(Icons.event, color: AppCor.primary),
                      title: Text(evento['titulo']!),
                      subtitle: Text('${evento['data']} • ${evento['local']}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Evento: ${evento['titulo']}'),
                            backgroundColor: AppCor.primary,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
