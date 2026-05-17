import 'package:flutter/material.dart';
import '../global/appCor.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<String> _filtros = [
    'Todas',
    'Vacinação',
    'Doações',
    'Urgentes',
    'Eventos',
  ];
  String _filtroSelecionado = 'Todas';

  final List<Map<String, String>> _notificacoes = [
    {
      'titulo': 'Campanha de doação de sangue',
      'descricao': 'Participe da campanha no hemocentro amanhã.',
      'categoria': 'Doações',
      'data': '30/05/2025',
    },
    {
      'titulo': 'Nova vacina disponível',
      'descricao': 'A vacina contra influenza está disponível.',
      'categoria': 'Vacinação',
      'data': '03/04/2025',
    },
    {
      'titulo': 'Evento comunitário',
      'descricao': 'Encontre apoio e informações sobre saúde.',
      'categoria': 'Eventos',
      'data': '10/06/2025',
    },
    {
      'titulo': 'Alerta de emergência',
      'descricao': 'Doação de sangue O- com urgência.',
      'categoria': 'Urgentes',
      'data': '19/03/2025',
    },
  ];

  List<Map<String, String>> get _notificacoesFiltradas {
    if (_filtroSelecionado == 'Todas') return _notificacoes;
    return _notificacoes
        .where((item) => item['categoria'] == _filtroSelecionado)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtrar por categoria',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _filtros.map((filtro) {
                return ChoiceChip(
                  label: Text(filtro),
                  selected: _filtroSelecionado == filtro,
                  selectedColor: AppCor.primary,
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color: _filtroSelecionado == filtro
                        ? Colors.white
                        : AppCor.textTitle,
                  ),
                  onSelected: (_) => setState(() => _filtroSelecionado = filtro),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: _notificacoesFiltradas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final item = _notificacoesFiltradas[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.04),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(item['titulo']!),
                      subtitle: Text(item['descricao']!),
                      trailing: Text(item['data']!),
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
