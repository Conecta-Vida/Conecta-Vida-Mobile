import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../accessibility/accessibility_provider.dart';
import '../accessibility/accessibility_speech_service.dart';
import '../models/noticia.dart';
import '../models/dependente.dart';
import 'package:provider/provider.dart';
import '../global/appCor.dart';
import '../services/supabase_service.dart';
import '../widgets/noticia_info_botao.dart';
import '../widgets/noticia_secao_mais.dart';

class NewsDetailsPage extends StatefulWidget {
  final NewsModel noticia;
  final String? sharedBy;
  final int? userId;

  const NewsDetailsPage({
    super.key,
    required this.noticia,
    this.sharedBy,
    this.userId,
  });

  @override
  State<NewsDetailsPage> createState() => _NewsDetailsPageState();
}

class _NewsDetailsPageState extends State<NewsDetailsPage> {
  bool _processandoCampanha = false;
  List<Map<String, dynamic>> _inscricoesUsuario = [];

  bool get _ehCampanha => widget.noticia.tag.toUpperCase() == 'CAMPANHA';

  @override
  void initState() {
    super.initState();
    _carregarStatusInscricao();
  }

  int? _idComoInt(dynamic valor) {
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }

  String _chaveParticipante(Map<String, dynamic> inscricao) {
    final dependenteId = _idComoInt(inscricao['dependente_id']);
    return dependenteId == null ? 'titular' : 'dependente:$dependenteId';
  }

  Future<void> _carregarStatusInscricao() async {
    if (!_ehCampanha || widget.userId == null || widget.noticia.id == null) {
      return;
    }

    try {
      final inscricoes =
          await SupabaseService.fetchInscritosCampanha(widget.noticia.id!);
      final minhas = inscricoes
          .where((item) => '${item['usuario_id'] ?? ''}' == '${widget.userId}')
          .toList();

      if (!mounted) return;
      setState(() => _inscricoesUsuario = minhas);
    } catch (_) {
      // Mantém a tela funcional mesmo se a API de inscrição falhar.
    }
  }

  Future<void> _alternarInscricaoCampanha() async {
    final comunicacaoId = widget.noticia.id;
    if (comunicacaoId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta campanha ainda não possui ID válido para inscrição.',
          ),
        ),
      );
      return;
    }

    int? usuarioId = widget.userId;

    // Fallback: se o id não veio da sessão, tenta resolver pelo e-mail autenticado.
    if (usuarioId == null && (widget.sharedBy ?? '').trim().isNotEmpty) {
      final user = await SupabaseService.fetchUsuarioByEmail(
        widget.sharedBy!.trim(),
      );
      usuarioId = user?.id;
    }

    if (usuarioId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar o usuário para inscrição.',
          ),
        ),
      );
      return;
    }

    setState(() => _processandoCampanha = true);

    try {
      final dependentes = await SupabaseService.fetchDependentes(usuarioId);
      await _carregarStatusInscricao();
      if (!mounted) return;

      // Mantém também participantes já inscritos cujo cadastro foi inativado,
      // para que o titular consiga cancelar essas inscrições.
      final participantes = <Map<String, dynamic>>[
        {
          'chave': 'titular',
          'nome': 'Eu (titular)',
          'parentesco': 'Titular',
          'dependente_id': null,
        },
      ];

      for (final dependente in dependentes) {
        if (dependente.id == null) continue;
        participantes.add({
          'chave': 'dependente:${dependente.id}',
          'nome': dependente.nomeCompleto,
          'parentesco': dependente.parentesco,
          'dependente_id': dependente.id,
        });
      }

      final chavesDisponiveis =
          participantes.map((item) => item['chave'] as String).toSet();
      for (final inscricao in _inscricoesUsuario) {
        final dependenteId = _idComoInt(inscricao['dependente_id']);
        if (dependenteId == null) continue;
        final chave = 'dependente:$dependenteId';
        if (chavesDisponiveis.contains(chave)) continue;

        participantes.add({
          'chave': chave,
          'nome': (inscricao['participante_nome'] ?? 'Dependente').toString(),
          'parentesco':
              (inscricao['parentesco'] ?? 'Cadastro indisponível').toString(),
          'dependente_id': dependenteId,
        });
        chavesDisponiveis.add(chave);
      }

      final selecionados = _inscricoesUsuario
          .map(_chaveParticipante)
          .toSet();

      final escolhidos = await showDialog<Set<String>>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, refresh) => AlertDialog(
            title: const Text('Quem participará desta campanha?'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Marque todas as pessoas que deseja inscrever. '
                      'Você pode selecionar você e vários dependentes.',
                    ),
                    const SizedBox(height: 12),
                    ...participantes.map((participante) {
                      final chave = participante['chave'] as String;
                      return CheckboxListTile(
                        value: selecionados.contains(chave),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(participante['nome'] as String),
                        subtitle: Text(participante['parentesco'] as String),
                        onChanged: (marcado) {
                          refresh(() {
                            if (marcado == true) {
                              selecionados.add(chave);
                            } else {
                              selecionados.remove(chave);
                            }
                          });
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx, Set<String>.from(selecionados)),
                child: const Text('Salvar inscrições'),
              ),
            ],
          ),
        ),
      );

      if (!mounted || escolhidos == null) return;

      final inscricoesAtuais = _inscricoesUsuario
          .map(_chaveParticipante)
          .toSet();
      final falhas = <String>[];
      var alteracoes = 0;

      // Cada participante é incluído/removido pela API existente.
      // Assim, uma única confirmação da tela pode atualizar várias pessoas.
      for (final participante in participantes) {
        final chave = participante['chave'] as String;
        final estavaInscrito = inscricoesAtuais.contains(chave);
        final deveEstarInscrito = escolhidos.contains(chave);
        if (estavaInscrito == deveEstarInscrito) continue;

        final dependenteId = _idComoInt(participante['dependente_id']);
        final nome = participante['nome'] as String;

        try {
          if (deveEstarInscrito) {
            await SupabaseService.inscreverUsuarioEmCampanha(
              comunicacaoId: comunicacaoId,
              usuarioId: usuarioId,
              dependenteId: dependenteId,
            );
          } else {
            await SupabaseService.desinscreverUsuarioDaCampanha(
              comunicacaoId: comunicacaoId,
              usuarioId: usuarioId,
              dependenteId: dependenteId,
            );
          }
          alteracoes++;
        } catch (e) {
          falhas.add('$nome: $e');
        }
      }

      await _carregarStatusInscricao();
      if (!mounted) return;

      if (falhas.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Algumas inscrições não foram atualizadas: ${falhas.join('; ')}',
            ),
            backgroundColor: AppCor.error,
          ),
        );
      } else if (alteracoes == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma alteração nas inscrições.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Inscrições atualizadas para ${escolhidos.length} participante(s) '
              'em: ${widget.noticia.titulo}.',
            ),
            backgroundColor: AppCor.primary,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar inscrições: $e'),
          backgroundColor: AppCor.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _processandoCampanha = false);
    }
  }

  Color _corDaCategoria(String categoria) {
    if (categoria.toLowerCase().contains('alerta')) {
      return AppCor.error;
    }
    if (categoria.toLowerCase().contains('vacina')) {
      return AppCor.catVacinacao;
    }
    if (categoria.toLowerCase().contains('sangue') ||
        categoria.toLowerCase().contains('doação')) {
      return AppCor.catNoticias;
    }
    return AppCor.primary;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String imagePath = widget.noticia.imagem.trim();
    final bool hasImage = imagePath.isNotEmpty;
    final bool isNetworkImage = hasImage && imagePath.startsWith('http');

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.92),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back,
              color: colors.onSurface,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_outlined,
                color: AppCor.primary,
                size: 20,
              ),
            ),
            onPressed: () async {
              final shareText =
                  '${widget.noticia.titulo}\n\n${widget.noticia.subtitulo}\n\n${widget.noticia.descricao}\n\nÓrgão: ${widget.noticia.orgao}\nContato: ${widget.noticia.orgaoTelefone}';
              await Share.share(shareText, subject: widget.noticia.titulo);
              await SupabaseService.trackNewsShare(
                widget.noticia,
                sharedBy: widget.sharedBy ?? 'app_user',
              );
            },
          ),
          Consumer<AccessibilityProvider>(
            builder: (context, preferences, _) {
              if (!preferences.speechEnabled) {
                return const SizedBox.shrink();
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Ouvir notícia',
                    icon: const Icon(
                      Icons.volume_up_outlined,
                      color: AppCor.primary,
                    ),
                    onPressed: () {
                      AccessibilitySpeechService.instance.speak(
                        '${widget.noticia.titulo}. '
                        '${widget.noticia.subtitulo}. '
                        '${widget.noticia.descricao}. '
                        'Local: ${widget.noticia.local}.',
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Parar leitura',
                    icon: const Icon(
                      Icons.stop_circle_outlined,
                      color: AppCor.primary,
                    ),
                    onPressed: AccessibilitySpeechService.instance.stop,
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 320,
              child: Hero(
                tag: widget.noticia.titulo + widget.noticia.data,
                child: !hasImage
                    ? Container(
                        color: const Color(0xFFEAF3FB),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF90A4AE),
                          size: 48,
                        ),
                      )
                    : isNetworkImage
                    ? Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppCor.primary,
                            ),
                          );
                        },
                      )
                    : Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _corDaCategoria(
                        widget.noticia.categoria,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.noticia.categoria.toUpperCase(),
                      style: TextStyle(
                        color: _corDaCategoria(widget.noticia.categoria),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    widget.noticia.titulo,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        NoticiasInfoBotao(
                          icone: Icons.calendar_month,
                          titulo: 'Data e Hora (Toque no ícone para gerenciar inscrições)',
                          valor: widget.noticia.data,
                          iconeAcao: _processandoCampanha
                              ? Icons.hourglass_top
                              : (_inscricoesUsuario.isNotEmpty ? Icons.alarm_on : Icons.add_alarm),
                          corAcao: _inscricoesUsuario.isNotEmpty
                              ? AppCor.catVacinacao
                              : AppCor.catDoacoes,
                          aoClicar: (_ehCampanha && !_processandoCampanha)
                              ? _alternarInscricaoCampanha
                              : null,
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.location_on,
                          titulo: 'Local (Toque para abrir)',
                          valor: widget.noticia.local,
                          iconeAcao: Icons.map_outlined,
                          corAcao: AppCor.primary,
                          aoClicar: () async {
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(widget.noticia.local)}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.business,
                          titulo: 'Órgão Publicador',
                          valor: widget.noticia.orgao,
                          iconeAcao: Icons.open_in_new,
                          corAcao: AppCor.primary,
                          aoClicar: () async {
                            final url = Uri.parse(widget.noticia.orgaoSite);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.phone,
                          titulo: 'Contato',
                          valor: widget.noticia.orgaoTelefone,
                          iconeAcao: Icons.call_outlined,
                          corAcao: AppCor.primary,
                          aoClicar: () async {
                            final url = Uri.parse(
                              'tel:${widget.noticia.orgaoTelefone}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.people,
                          titulo: 'Público-Alvo',
                          valor: widget.noticia.publicoAlvo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Detalhes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    widget.noticia.descricao,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.justify,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final shareText =
                            '${widget.noticia.titulo}\n\n${widget.noticia.subtitulo}\n\n${widget.noticia.descricao}\n\nÓrgão: ${widget.noticia.orgao}\nContato: ${widget.noticia.orgaoTelefone}';
                        await Share.share(
                          shareText,
                          subject: widget.noticia.titulo,
                        );
                        await SupabaseService.trackNewsShare(
                          widget.noticia,
                          sharedBy: widget.sharedBy ?? 'app_user',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _corDaCategoria(
                          widget.noticia.categoria,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.share, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Compartilhar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  NoticiasSecaoMais(
                    noticiaAtual: widget.noticia,
                    userId: widget.userId,
                    userEmail: widget.sharedBy,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
