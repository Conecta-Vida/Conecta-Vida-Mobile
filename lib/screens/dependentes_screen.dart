import 'package:flutter/material.dart';
import '../models/dependente.dart';
import '../models/noticia.dart';
import '../services/supabase_service.dart';
import 'news_details_page.dart';

class DependentesScreen extends StatefulWidget {
  final int usuarioId;

  const DependentesScreen({super.key, required this.usuarioId});

  @override
  State<DependentesScreen> createState() => _DependentesScreenState();
}

class _DependentesScreenState extends State<DependentesScreen> {
  List<DependenteModel> items = [];
  Map<int, List<NewsModel>> campanhasPorDependente = {};
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

        final campanhasPorId = <int, NewsModel>{};
        for (final campanha in campanhas) {
          if (campanha.id != null) {
            campanhasPorId[campanha.id!] = campanha;
          }
        }

        final agrupadas = <int, List<NewsModel>>{};
        for (final inscricao in inscricoes) {
          final dependenteId = _toInt(inscricao['dependente_id']);
          final comunicacaoId = _toInt(
            inscricao['comunicacao_id'] ?? inscricao['comunicacaoId'],
          );
          if (dependenteId == null || comunicacaoId == null) continue;

          final campanha = campanhasPorId[comunicacaoId];
          if (campanha == null) continue;
          final lista = agrupadas.putIfAbsent(dependenteId, () => []);
          if (!lista.any((item) => item.id == campanha.id)) {
            lista.add(campanha);
          }
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

  static String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> edit([DependenteModel? old]) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: old?.nomeCompleto ?? '');
    final other = TextEditingController();
    final email = TextEditingController(text: old?.emailDependente ?? '');
    // No cadastro a data não vem preenchida: o usuário precisa escolher.
    DateTime? birth = old?.dataNascimento;
    var birthMissing = false;
    var declarou = false;
    var declaracaoFaltando = false;
    var salvando = false;
    const relations = [
      'Filho(a)',
      'Pai',
      'Mãe',
      'Cônjuge',
      'Tutelado',
      'Outro',
    ];
    var relation = old == null
        ? relations.first
        : (relations.contains(old.parentesco) ? old.parentesco : 'Outro');
    if (relation == 'Outro' && old != null) other.text = old.parentesco;
    var sex = old?.sexo ?? '';
    final novoCadastro = old == null;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, refresh) {
          final cores = Theme.of(ctx).colorScheme;
          // Adulto (que não é tutelado) precisa autorizar pelo próprio login.
          final precisaAutorizar =
              birth != null &&
              DependenteModel.exigeAutorizacaoDoDependente(birth!, relation);

          return AlertDialog(
            title: Text(novoCadastro ? 'Adicionar dependente' : 'Editar dependente'),
            content: SingleChildScrollView(
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nome completo'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Informe o nome' : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.cake_outlined),
                      title: const Text('Data de nascimento'),
                      subtitle: Text(
                        birth == null
                            ? (birthMissing
                                  ? 'Informe a data de nascimento'
                                  : 'Toque para selecionar')
                            : _formatarData(birth!),
                        style: birthMissing && birth == null
                            ? TextStyle(color: cores.error)
                            : null,
                      ),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () async {
                        final hoje = DateTime.now();
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate:
                              birth ?? DateTime(hoje.year - 10, hoje.month, hoje.day),
                          firstDate: DateTime(1900),
                          lastDate: hoje,
                          helpText: 'Data de nascimento',
                        );
                        if (d != null) {
                          refresh(() {
                            birth = d;
                            birthMissing = false;
                          });
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: relation,
                      decoration: const InputDecoration(labelText: 'Parentesco'),
                      items: relations
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) =>
                          refresh(() => relation = v ?? relations.first),
                    ),
                    if (relation == 'Outro')
                      TextFormField(
                        controller: other,
                        decoration: const InputDecoration(
                          labelText: 'Informe o parentesco',
                        ),
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
                        DropdownMenuItem(
                          value: 'Não informado',
                          child: Text('Não informar'),
                        ),
                      ],
                      onChanged: (v) => refresh(() => sex = v ?? ''),
                    ),

                    // Como o vínculo passa a valer (só no cadastro).
                    if (novoCadastro && birth != null) ...[
                      const SizedBox(height: 16),
                      if (precisaAutorizar) ...[
                        TextFormField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'E-mail do dependente',
                            helperText: 'O mesmo e-mail da conta dele no Conecta Vida',
                          ),
                          validator: (v) {
                            final texto = (v ?? '').trim();
                            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(texto)) {
                              return 'Informe um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 18, color: cores.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Por ser maior de idade, esta pessoa precisa '
                                'autorizar o vínculo. O pedido aparece no '
                                'aplicativo dela, em Ajustes → Autorizações. '
                                'Até lá, o cadastro fica pendente.',
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: declarou,
                          onChanged: (v) => refresh(() {
                            declarou = v ?? false;
                            declaracaoFaltando = false;
                          }),
                          title: const Text(
                            'Declaro que sou o responsável legal por esta pessoa.',
                          ),
                          subtitle: declaracaoFaltando
                              ? Text(
                                  'Marque a declaração para continuar.',
                                  style: TextStyle(color: cores.error),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: salvando ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: salvando
                    ? null
                    : () async {
                        final formOk = key.currentState!.validate();
                        final semData = birth == null;
                        final semDeclaracao =
                            novoCadastro && !semData && !precisaAutorizar && !declarou;
                        if (semData || semDeclaracao) {
                          refresh(() {
                            birthMissing = semData;
                            declaracaoFaltando = semDeclaracao;
                          });
                        }
                        if (!formOk || semData || semDeclaracao) return;

                        final item = DependenteModel(
                          id: old?.id,
                          nomeCompleto: name.text.trim(),
                          dataNascimento: birth!,
                          parentesco:
                              relation == 'Outro' ? other.text.trim() : relation,
                          sexo: sex.isEmpty ? null : sex,
                          emailDependente:
                              precisaAutorizar ? email.text.trim() : null,
                          declarouResponsabilidade: declarou,
                        );
                        refresh(() => salvando = true);
                        try {
                          if (novoCadastro) {
                            await SupabaseService.criarDependente(
                              widget.usuarioId,
                              item,
                            );
                          } else {
                            await SupabaseService.atualizarDependente(
                              widget.usuarioId,
                              item,
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx, true);
                        } catch (e) {
                          if (!ctx.mounted) return;
                          refresh(() => salvando = false);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                e.toString().replaceFirst('Exception: ', ''),
                              ),
                            ),
                          );
                        }
                      },
                child: Text(salvando ? 'Salvando...' : 'Salvar'),
              ),
            ],
          );
        },
      ),
    );

    name.dispose();
    other.dispose();
    email.dispose();
    if (saved == true) await load();
  }

  Future<void> remove(DependenteModel item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover dependente?'),
        content: Text(
          'Remover ${item.nomeCompleto}? As inscrições dessa pessoa em campanhas '
          'ainda abertas serão canceladas.',
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
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
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
                          ? const <NewsModel>[]
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
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.parentesco} • ${_formatarData(item.dataNascimento)}',
                                    ),
                                    if (item.pendente) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Aguardando autorização de ${item.emailDependente ?? 'e-mail informado'}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
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
                                    if (item.pendente)
                                      Text(
                                        'Depois de autorizado, você poderá inscrever esta pessoa em campanhas.',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      )
                                    else ...[
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
                                          .map(
                                            (campanha) => ActionChip(
                                              avatar: const Icon(
                                                Icons.campaign_outlined,
                                                size: 18,
                                              ),
                                              label: Text(campanha.titulo),
                                              tooltip: 'Ver informações da campanha',
                                              onPressed: () {
                                                Navigator.of(ctx).push(
                                                  MaterialPageRoute(
                                                    builder: (_) => NewsDetailsPage(
                                                      noticia: campanha,
                                                      userId: widget.usuarioId,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          )
                                          .toList(),
                                      ),
                                    ],
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
