import 'package:flutter/material.dart';
import '../models/dependente.dart';
import '../services/supabase_service.dart';

class DependentesScreen extends StatefulWidget {
  final int usuarioId;
  const DependentesScreen({super.key, required this.usuarioId});
  @override
  State<DependentesScreen> createState() => _DependentesScreenState();
}

class _DependentesScreenState extends State<DependentesScreen> {
  List<DependenteModel> items = [];
  bool loading = true;

  @override
  void initState() { super.initState(); load(); }

  static String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final result = await SupabaseService.fetchDependentes(widget.usuarioId);
      if (mounted) setState(() => items = result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
    } finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> edit([DependenteModel? old]) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: old?.nomeCompleto ?? '');
    final other = TextEditingController();
    // Sem data pré-preenchida no cadastro: o usuário precisa escolher.
    DateTime? birth = old?.dataNascimento;
    var birthMissing = false;
    const relations = ['Filho(a)', 'Pai', 'Mãe', 'Cônjuge', 'Tutelado', 'Outro'];
    // Novo cadastro começa em "Filho(a)"; na edição, um parentesco fora da
    // lista aparece em "Outro" com o texto original.
    var relation = old == null
        ? relations.first
        : (relations.contains(old.parentesco) ? old.parentesco : 'Outro');
    if (relation == 'Outro' && old != null) other.text = old.parentesco;
    var sex = old?.sexo ?? '';
    final saved = await showDialog<bool>(context: context, builder: (ctx) =>
      StatefulBuilder(builder: (ctx, refresh) => AlertDialog(
        title: Text(old == null ? 'Adicionar dependente' : 'Editar dependente'),
        content: SingleChildScrollView(child: Form(key: key, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Informe o nome' : null),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cake_outlined),
            title: const Text('Data de nascimento'),
            subtitle: Text(
              birth == null
                  ? (birthMissing ? 'Informe a data de nascimento' : 'Toque para selecionar')
                  : _formatarData(birth!),
              style: birthMissing && birth == null
                  ? TextStyle(color: Theme.of(ctx).colorScheme.error)
                  : null,
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () async {
              final hoje = DateTime.now();
              final d = await showDatePicker(
                context: ctx,
                initialDate: birth ?? DateTime(hoje.year - 10, hoje.month, hoje.day),
                firstDate: DateTime(1900),
                lastDate: hoje,
                helpText: 'Data de nascimento',
              );
              if (d != null) refresh(() { birth = d; birthMissing = false; });
            }),
          DropdownButtonFormField<String>(initialValue: relation, decoration: const InputDecoration(labelText: 'Parentesco'),
            items: relations.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => refresh(() => relation = v ?? relations.first)),
          if (relation == 'Outro') TextFormField(controller: other, decoration: const InputDecoration(labelText: 'Informe o parentesco'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Informe o parentesco' : null),
          DropdownButtonFormField<String>(initialValue: sex.isEmpty ? null : sex,
            decoration: const InputDecoration(labelText: 'Sexo (opcional)'),
            items: const [
              DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
              DropdownMenuItem(value: 'Masculino', child: Text('Masculino')),
              DropdownMenuItem(value: 'Outro', child: Text('Outro')),
              DropdownMenuItem(value: 'Não informado', child: Text('Não informar')),
            ], onChanged: (v) => refresh(() => sex = v ?? '')),
        ]))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            final formOk = key.currentState!.validate();
            if (birth == null) refresh(() => birthMissing = true);
            if (!formOk || birth == null) return;
            final item = DependenteModel(id: old?.id, nomeCompleto: name.text.trim(), dataNascimento: birth!,
              parentesco: relation == 'Outro' ? other.text.trim() : relation, sexo: sex.isEmpty ? null : sex);
            try {
              if (old == null) { await SupabaseService.criarDependente(widget.usuarioId, item); }
              else { await SupabaseService.atualizarDependente(widget.usuarioId, item); }
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Erro: $e')));
            }
          }, child: const Text('Salvar')),
        ],
      )));
    name.dispose(); other.dispose();
    if (saved == true) await load();
  }

  Future<void> remove(DependenteModel item) async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Remover dependente?'),
      content: Text('Remover ${item.nomeCompleto}? O histórico de inscrições será preservado.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remover')),
      ],
    ));
    if (yes != true || item.id == null) return;
    try { await SupabaseService.excluirDependente(widget.usuarioId, item.id!); await load(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'))); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Meus Dependentes')),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => edit(), icon: const Icon(Icons.person_add), label: const Text('Adicionar')),
    body: loading ? const Center(child: CircularProgressIndicator()) :
      items.isEmpty ? const Center(child: Text('Nenhum dependente cadastrado.')) :
      RefreshIndicator(onRefresh: load, child: ListView.separated(
        padding: const EdgeInsets.all(16), itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(item.nomeCompleto),
            subtitle: Text('${item.parentesco} • ${_formatarData(item.dataNascimento)}'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) => v == 'editar' ? edit(item) : remove(item),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'remover', child: Text('Remover')),
              ],
            ),
          ));
        },
      )),
  );
}
