import 'package:flutter/material.dart';
import '../models/dependente.dart';
import '../models/noticia.dart';
import '../services/supabase_service.dart';

class DependentesScreen extends StatefulWidget {
  final int usuarioId;

  const DependentesScreen({super.key, required this.usuarioId});

  @override
  State<DependentesScreen> createState() => _DependentesScreenState();
}

class _DependentesScreenState extends State<DependentesScreen> {
  List<DependenteModel> items = [];
  Map<int, List<String>> campanhasPorDependente = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        campanhasPorDependente = {};
      });
    }

    try {
      final dependentes = await SupabaseService.fetchDependentes(widget.usuarioId);
      if (!mounted) return;
      setState(() => items = dependentes);

      try {
        final resultados = await Future.wait([
          SupabaseService.fetchMinhasInscricoes(),
          SupabaseService.fetchNoticiasPorCategoria(4, forceRefresh: true),
        ]);

        final inscricoes = resultados[0] as List<Map<String, dynamic>>;
        final campanhas = resultados[1] as List<NewsModel>;

        final titulosPorCampanha = <int, String>{};
        for (final campanha in campanhas) {
          if (campanha.id != null) {
            titulosPorCampanha[campanha.id!] = campanha.titulo;
          }
        }

        final agrupadas = <int, List<String>>{};
        for (final inscricao in inscricoes) {
          final dependenteId = _toInt(inscricao['dependente_id']);
          final comunicacaoId = _toInt(
            inscricao['comunicacao_id'] ?? inscricao['comunicacaoId'],
          );
          if (dependenteId == null || comunicacaoId == null) continue;

          final titulo = titulosPorCampanha[comunicacaoId] ??
              'Campanha #$comunicacaoId';
          final lista = agrupadas.putIfAbsent(dependenteId, () => []);
          if (!lista.contains(titulo)) lista.add(titulo);
        }

        if (mounted) {
          setState(() => campanhasPorDependente = agrupadas);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dependentes carregados, mas não foi possível buscar as campanhas: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dependentes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit([DependenteModel? old]) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: old?.nomeCompleto ?? '');
    final other = TextEditingController();
    var birth = old?.dataNascimento ?? DateTime(2015);
    const relations = [
      'Pai',
      'Mãe',
      'Filho(a)',
      'Cônjuge',
      'Tutelado',
      'Outro',
    ];
    var relation = relations.contains(old?.parentesco)
        ? (old?.parentesco ?? 'Tutelado')
        : 'Outro';
    if (relation == 'Outro' && old != null) other.text = old.parentesco;
    var sex = old?.sexo ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) => AlertDialog(
          title: Text(old == null ? 'Adicionar dependente' : 'Editar dependente'),
          content: SingleChildScrollView(
            child: Form(
              key: key,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                  ),
                  ListTile(
                    title: const Text('Data de nascimento'),
                    subtitle: Text('${birth.day}/${birth.month}/${birth.year}'),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: birth,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) refresh(() => birth = d);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: relation,
                    decoration: const InputDecoration(labelText: 'Parentesco'),
                    items: relations
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => refresh(() => relation = v ?? 'Tutelado'),
                  ),
                  if (relation == 'Outro')
                    TextFormField(
                      controller: other,
                      decoration: const InputDecoration(labelText: 'Informe o parentesco'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Informe o parentesco'
                          : null,
                    ),
                  DropdownButtonFormField<String>(
                    initialValue: sex.isEmpty ? null : sex,
                    decoration: const InputDecoration(labelText: 'Sexo (opcional)'),
                    items: const [
                      DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                      DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
                      DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                      DropdownMenuItem(value: 'Não informado', child: Text('Não informar')),
                    ],
                    onChanged: (v) => refresh(() => sex = v ?? ''),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!key.currentState!.validate()) return;
                final item = DependenteModel(
                  id: old?.id,
                  nomeCompleto: name.text.trim(),
                  dataNascimento: birth,
                  parentesco: relation == 'Outro' ? other.text.trim() : relation,
                  sexo: sex.isEmpty ? null : sex,
                );
                try {
                  if (old == null) {
                    await SupabaseService.criarDependente(widget.usuarioId, item);
                  } else {
                    await SupabaseService.atualizarDependente(widget.usuarioId, item);
                  }
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    other.dispose();
    if (saved == true) await load();
  }

  Future<void> remove(DependenteModel item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover dependente?'),
        content: Text(
          'Remover ${item.nomeCompleto}? O histórico de inscrições será preservado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (yes != true || item.id == null) return;
    try {
      await SupabaseService.excluirDependente(widget.usuarioId, item.id!);
      await load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus Dependentes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.person_add),
        label: const Text('Adicionar'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('Nenhum dependente cadastrado.'))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final campanhas = item.id == null
                          ? const <String>[]
                          : campanhasPorDependente[item.id!] ?? [];

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(item.nomeCompleto),
                                subtitle: Text(
                                  '${item.parentesco} • ${item.dataNascimento.day}/${item.dataNascimento.month}/${item.dataNascimento.year}',
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (v) =>
                                      v == 'editar' ? edit(item) : remove(item),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'editar',
                                      child: Text('Editar'),
                                    ),
                                    PopupMenuItem(
                                      value: 'remover',
                                      child: Text('Remover'),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Campanhas inscritas',
                                      style: Theme.of(context).textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 8),
                                    if (campanhas.isEmpty)
                                      Text(
                                        'Nenhuma inscrição em campanha.',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      )
                                    else
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: campanhas
                                            .map((titulo) => Chip(
                                                  avatar: const Icon(
                                                    Icons.campaign_outlined,
                                                    size: 18,
                                                  ),
                                                  label: Text(titulo),
                                                ))
                                            .toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
