import 'package:flutter/material.dart';

import '../global/appCor.dart';
import '../models/dependente.dart';
import '../services/supabase_service.dart';

/// Pedidos para a pessoa logada ser dependente de outra conta.
///
/// Um adulto só passa a ser dependente de alguém depois de autorizar aqui.
/// A autorização pode ser revogada a qualquer momento.
class AutorizacoesScreen extends StatefulWidget {
  const AutorizacoesScreen({super.key});

  @override
  State<AutorizacoesScreen> createState() => _AutorizacoesScreenState();
}

class _AutorizacoesScreenState extends State<AutorizacoesScreen> {
  List<ConviteDependente> _convites = [];
  bool _carregando = true;
  String? _erro;
  int? _respondendo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final convites = await SupabaseService.fetchConvitesDeDependente();
      if (mounted) setState(() => _convites = convites);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível carregar os pedidos.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _responder(ConviteDependente convite, String acao) async {
    if (acao != 'autorizar') {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(acao == 'recusar' ? 'Recusar pedido?' : 'Revogar autorização?'),
          content: Text(
            acao == 'recusar'
                ? '${convite.titularNome} não poderá inscrever você em campanhas.'
                : '${convite.titularNome} deixará de poder inscrever você em '
                      'campanhas, e suas inscrições em campanhas abertas feitas '
                      'por essa conta serão canceladas.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(acao == 'recusar' ? 'Recusar' : 'Revogar'),
            ),
          ],
        ),
      );
      if (confirmou != true) return;
    }

    setState(() => _respondendo = convite.id);
    try {
      await SupabaseService.responderConviteDeDependente(convite.id, acao);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (acao) {
            'autorizar' => 'Vínculo com ${convite.titularNome} autorizado.',
            'recusar' => 'Pedido recusado.',
            _ => 'Autorização revogada.',
          }),
          backgroundColor: AppCor.primary,
        ),
      );
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppCor.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _respondendo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;

    Widget corpo;
    if (_carregando) {
      corpo = const Center(child: CircularProgressIndicator());
    } else if (_erro != null) {
      corpo = _aviso(Icons.cloud_off_outlined, _erro!, cores);
    } else if (_convites.isEmpty) {
      corpo = _aviso(
        Icons.verified_user_outlined,
        'Ninguém pediu para incluir você como dependente.',
        cores,
      );
    } else {
      corpo = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _convites.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) => _cartao(_convites[i], cores),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Autorizações')),
      body: RefreshIndicator(onRefresh: _carregar, child: corpo),
    );
  }

  Widget _aviso(IconData icone, String texto, ColorScheme cores) {
    return LayoutBuilder(
      builder: (context, limites) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: limites.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icone, size: 44, color: cores.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    texto,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cores.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartao(ConviteDependente convite, ColorScheme cores) {
    final ocupado = _respondendo == convite.id;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Icon(
                    convite.pendente ? Icons.mark_email_unread_outlined : Icons.verified_user,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        convite.titularNome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        convite.pendente
                            ? 'Quer incluir você como dependente (${convite.parentesco}).'
                            : 'Você autorizou este vínculo (${convite.parentesco}).',
                        style: TextStyle(color: cores.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Com a autorização, essa pessoa pode inscrever você em campanhas '
              'de saúde e ver essas inscrições no cronograma dela.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (ocupado)
              const Center(child: CircularProgressIndicator())
            else if (convite.pendente)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _responder(convite, 'recusar'),
                    child: const Text('Recusar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _responder(convite, 'autorizar'),
                    child: const Text('Autorizar'),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _responder(convite, 'revogar'),
                  child: const Text('Revogar autorização'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
