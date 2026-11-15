import 'dart:async';

import 'package:flutter/material.dart';

import '../accessibility/accessibility_palette.dart';
import '../global/appCor.dart';
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../screens/news_details_page.dart';
import '../services/supabase_service.dart';

/// Faixa "Recomendados para você" da tela inicial: campanhas em andamento e
/// alertas da cidade do usuário, e temas das campanhas em que ele já se
/// inscreveu. Some quando não há nada a sugerir.
class RecomendadosSecao extends StatefulWidget {
  final UserModel usuario;

  const RecomendadosSecao({super.key, required this.usuario});

  @override
  State<RecomendadosSecao> createState() => _RecomendadosSecaoState();
}

class _RecomendadosSecaoState extends State<RecomendadosSecao> {
  late Future<List<NewsModel>> _recomendados;
  StreamSubscription<void>? _inscricoes;
  StreamSubscription<Map<String, dynamic>>? _publicacoes;

  @override
  void initState() {
    super.initState();
    _recomendados = _carregar();
    // Refaz as sugestões quando o usuário se inscreve/cancela ou quando o
    // painel publica algo novo.
    _inscricoes = SupabaseService.inscricoesAlteradas.listen(
      (_) => _recarregar(),
    );
    _publicacoes = SupabaseService.novasComunicacoes.listen(
      (_) => _recarregar(),
    );
  }

  @override
  void didUpdateWidget(RecomendadosSecao antigo) {
    super.didUpdateWidget(antigo);
    if (antigo.usuario.localizacao != widget.usuario.localizacao) _recarregar();
  }

  @override
  void dispose() {
    _inscricoes?.cancel();
    _publicacoes?.cancel();
    super.dispose();
  }

  Future<List<NewsModel>> _carregar() async {
    try {
      return await SupabaseService.fetchRecomendados(widget.usuario);
    } catch (_) {
      return const <NewsModel>[];
    }
  }

  void _recarregar() {
    if (!mounted) return;
    setState(() => _recomendados = _carregar());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<List<NewsModel>>(
      future: _recomendados,
      builder: (context, snapshot) {
        final itens = snapshot.data ?? const <NewsModel>[];
        if (itens.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 18,
                    color: AppCor.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recomendados para você',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: itens.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) =>
                      _cartao(context, itens[index]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cartao(BuildContext context, NewsModel item) {
    final colors = Theme.of(context).colorScheme;
    final ehAlerta = item.tag.toUpperCase() == 'ALERTA';
    final cor = ehAlerta ? AppCor.error : AppCor.catVacinacao;

    return Semantics(
      button: true,
      label: '${ehAlerta ? 'Alerta' : 'Campanha'} recomendada: ${item.titulo}',
      child: Material(
        color: AccessibilityPalette.surface(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailsPage(
                  noticia: item,
                  userId: widget.usuario.id,
                  sharedBy: widget.usuario.email,
                ),
              ),
            );
          },
          child: Container(
            width: 230,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AccessibilityPalette.border(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        ehAlerta ? Icons.warning_amber_rounded : Icons.campaign,
                        size: 14,
                        color: cor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ehAlerta ? 'ALERTA' : 'CAMPANHA',
                        style: TextStyle(
                          color: cor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    item.titulo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        item.local,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
