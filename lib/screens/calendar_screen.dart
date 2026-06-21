import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../global/appCor.dart';
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';

class CalendarScreen extends StatefulWidget {
  final UserModel usuario;

  const CalendarScreen({super.key, required this.usuario});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const String _boxPreferencias = 'preferencias';
  static const String _keyLembretesCampanhas = 'lembretes_campanhas';

  late Future<List<NewsModel>> _campanhasFuture;
  late Future<List<String>> _lembretesFuture;

  @override
  void initState() {
    super.initState();
    _campanhasFuture = _carregarCampanhas();
    _lembretesFuture = _carregarLembretesSalvos();
  }

  Future<Box> _obterBoxPreferencias() async {
    if (Hive.isBoxOpen(_boxPreferencias)) {
      return Hive.box(_boxPreferencias);
    }
    return Hive.openBox(_boxPreferencias);
  }

  Future<List<NewsModel>> _carregarCampanhas() async {
    if (widget.usuario.id == null) return [];
    return SupabaseService.fetchCampanhasAtivasDoUsuario(widget.usuario.id!);
  }

  Future<List<String>> _carregarLembretesSalvos() async {
    final box = await _obterBoxPreferencias();
    return List<String>.from(box.get(_keyLembretesCampanhas, defaultValue: <String>[]));
  }

  Future<void> _atualizar() async {
    setState(() {
      _campanhasFuture = _carregarCampanhas();
      _lembretesFuture = _carregarLembretesSalvos();
    });
    await _campanhasFuture;
  }

  Future<void> _desinscrever(NewsModel campanha) async {
    if (widget.usuario.id == null || campanha.id == null) return;

    await SupabaseService.desinscreverUsuarioDaCampanha(
      comunicacaoId: campanha.id!,
      usuarioId: widget.usuario.id!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Você se desinscreveu de "${campanha.titulo}".'),
        backgroundColor: AppCor.primary,
      ),
    );
    await _atualizar();
  }

  String _formatarDataFim(String valor) {
    final d = DateTime.tryParse(valor);
    if (d == null) return valor.isEmpty ? 'Sem data final definida' : valor;
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final ano = d.year.toString();
    return '$dia/$mes/$ano';
  }

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
              'Campanhas ativas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<String>>(
              future: _lembretesFuture,
              builder: (context, snapshot) {
                final lembretes = snapshot.data ?? const <String>[];
                if (lembretes.isEmpty) return const SizedBox.shrink();

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Você tem ${lembretes.length} lembrete(s) salvo(s) no relógio.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
            Expanded(
              child: FutureBuilder<List<NewsModel>>(
                future: _campanhasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppCor.primary),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Não foi possível carregar seu calendário de campanhas.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _atualizar,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  final campanhas = snapshot.data ?? [];
                  if (campanhas.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _atualizar,
                      child: ListView(
                        children: const [
                          SizedBox(height: 140),
                          Icon(Icons.event_busy_outlined, size: 52, color: AppCor.textSubtitle),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Você ainda não está inscrito em campanhas ativas.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _atualizar,
                    child: ListView.separated(
                      itemCount: campanhas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final campanha = campanhas[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
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
                            title: Text(campanha.titulo),
                            subtitle: Text(
                              'Termina em ${_formatarDataFim(campanha.dataFim)} • ${campanha.local}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Desinscrever',
                              icon: const Icon(Icons.remove_circle_outline, color: AppCor.error),
                              onPressed: () => _desinscrever(campanha),
                            ),
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
