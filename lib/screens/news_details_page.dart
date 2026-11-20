import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../accessibility/accessibility_provider.dart';
import '../accessibility/accessibility_speech_service.dart';
import '../models/inscricao.dart';
import '../models/noticia.dart';
import 'package:provider/provider.dart';
import '../global/appCor.dart';
import '../services/supabase_inscricao_repository.dart';
import '../services/supabase_service.dart';
import '../usecases/inscricao_campanha_service.dart';
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
  List<Inscricao> _inscricoesUsuario = [];

  bool get _ehCampanha => widget.noticia.tag.toUpperCase() == 'CAMPANHA';

  bool get _temTelefone =>
      widget.noticia.orgaoTelefone.replaceAll(RegExp(r'\D'), '').length >= 3;

  /// Link da matéria original, quando a notícia veio de uma fonte oficial.
  Uri? get _fonte {
    final endereco = widget.noticia.fonteUrl.trim();
    if (!endereco.startsWith('https://')) return null;
    final uri = Uri.tryParse(endereco);
    return (uri != null && uri.host.isNotEmpty) ? uri : null;
  }

  /// Site da instituição, quando informado. Aceita endereços sem "https://".
  Uri? get _siteDoOrgao {
    final site = widget.noticia.orgaoSite.trim();
    if (site.isEmpty) return null;
    final comEsquema = site.contains('://') ? site : 'https://$site';
    final uri = Uri.tryParse(comEsquema);
    return (uri != null && uri.host.isNotEmpty) ? uri : null;
  }

  /// Período da campanha (dd/mm/aaaa), ou a data de publicação nos demais casos.
  String get _dataExibida {
    String formatar(String iso) {
      final d = DateTime.tryParse(iso.trim().replaceFirst(' ', 'T'));
      if (d == null) return '';
      return '${d.day.toString().padLeft(2, '0')}/'
          '${d.month.toString().padLeft(2, '0')}/${d.year}';
    }

    final publicada = formatar(widget.noticia.data);
    final publicacao = publicada.isEmpty ? widget.noticia.data : publicada;
    if (!_ehCampanha) return publicacao;

    final inicio = formatar(widget.noticia.dataInicio);
    final fim = formatar(widget.noticia.dataFim);
    if (inicio.isNotEmpty && fim.isNotEmpty) return 'De $inicio até $fim';
    if (fim.isNotEmpty) return 'Até $fim';
    if (inicio.isNotEmpty) return 'A partir de $inicio';
    return publicacao;
  }

  Future<void> _abrirLink(Uri url) async {
    var aberto = false;
    try {
      aberto = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      aberto = false;
    }
    if (!aberto && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir este link.'),
          backgroundColor: AppCor.error,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _carregarStatusInscricao();
  }

  /// Caso de uso "Inscrever-se em campanha" (camada de aplicação).
  final InscricaoCampanhaService _inscricoes = InscricaoCampanhaService(
    const SupabaseInscricaoRepository(),
  );

  Future<void> _carregarStatusInscricao() async {
    if (!_ehCampanha || widget.userId == null || widget.noticia.id == null) {
      return;
    }

    try {
      final minhas = await _inscricoes.inscricoesDoUsuario(
        comunicacaoId: widget.noticia.id!,
        usuarioId: widget.userId!,
      );
      if (!mounted) return;
      setState(() => _inscricoesUsuario = minhas);
    } catch (_) {
      // Mantém a tela funcional mesmo se a API de inscrição falhar.
    }
  }

  void _avisar(String mensagem, {Color? cor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: cor),
    );
  }

  Future<void> _alternarInscricaoCampanha() async {
    int? usuarioId = widget.userId;

    // Fallback: se o id não veio da sessão, tenta resolver pelo e-mail autenticado.
    if (usuarioId == null && (widget.sharedBy ?? '').trim().isNotEmpty) {
      final user = await SupabaseService.fetchUsuarioByEmail(
        widget.sharedBy!.trim(),
      );
      usuarioId = user?.id;
    }

    // Passo 4: campanha encerrada só abre para cancelar inscrições existentes.
    try {
      _inscricoes.verificarAcesso(
        campanha: widget.noticia,
        usuarioId: usuarioId,
        possuiInscricoes: _inscricoesUsuario.isNotEmpty,
      );
    } on InscricaoException catch (e) {
      _avisar(e.mensagem);
      return;
    }

    setState(() => _processandoCampanha = true);

    try {
      await _carregarStatusInscricao();
      final participantes = await _inscricoes.listarParticipantes(
        usuarioId: usuarioId!,
        inscricoesAtuais: _inscricoesUsuario,
      );
      if (!mounted) return;

      final encerrada = widget.noticia.encerrada;
      final inscritosAtuais = _inscricoesUsuario
          .map((i) => i.chaveParticipante)
          .toSet();
      final selecionados = Set<String>.from(inscritosAtuais);

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
                    Text(
                      encerrada
                          ? 'Esta campanha foi encerrada: você só pode '
                                'cancelar as inscrições existentes.'
                          : 'Marque todas as pessoas que deseja inscrever. '
                                'Você pode selecionar você e vários dependentes.',
                    ),
                    const SizedBox(height: 12),
                    ...participantes.map((participante) {
                      final chave = participante.chave;
                      final jaInscrito = inscritosAtuais.contains(chave);
                      // RN02 e RN03: só desmarca quem não pode ser inscrito.
                      final podeMarcar =
                          jaInscrito || (!encerrada && participante.vinculoAtivo);
                      return CheckboxListTile(
                        value: selecionados.contains(chave),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(participante.nome),
                        subtitle: Text(participante.parentesco),
                        onChanged: podeMarcar
                            ? (marcado) {
                                refresh(() {
                                  if (marcado == true) {
                                    selecionados.add(chave);
                                  } else {
                                    selecionados.remove(chave);
                                  }
                                });
                              }
                            : null,
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

      // Passos 6 e 7: o serviço aplica as regras e grava cada alteração.
      final resultado = await _inscricoes.salvarInscricoes(
        campanha: widget.noticia,
        usuarioId: usuarioId,
        participantes: participantes,
        inscritosAtuais: inscritosAtuais,
        escolhidos: escolhidos,
      );

      await _carregarStatusInscricao();
      _avisar(
        resultado.mensagem(widget.noticia.titulo),
        cor: !resultado.sucessoTotal
            ? AppCor.error
            : (resultado.alteracoes == 0 ? null : AppCor.primary),
      );
    } on InscricaoException catch (e) {
      _avisar(e.mensagem, cor: AppCor.error);
    } catch (e) {
      _avisar('Erro ao processar inscrições: $e', cor: AppCor.error);
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
            child: Icon(Icons.arrow_back, color: colors.onSurface, size: 20),
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
                  '${widget.noticia.titulo}\n\n${widget.noticia.subtitulo}\n\n${widget.noticia.descricao}\n\nÓrgão: ${widget.noticia.orgao}${_temTelefone ? '\nContato: ${widget.noticia.orgaoTelefone}' : ''}';
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFEAF3FB),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF90A4AE),
                            size: 48,
                          ),
                        ),
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
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        NoticiasInfoBotao(
                          icone: Icons.calendar_month,
                          titulo: !_ehCampanha
                              ? 'Data de publicação'
                              : widget.noticia.encerrada
                              ? 'Período (campanha encerrada)'
                              : 'Período (toque no ícone para gerenciar inscrições)',
                          valor: _dataExibida,
                          iconeAcao: !_ehCampanha
                              ? null
                              : _processandoCampanha
                              ? Icons.hourglass_top
                              : (_inscricoesUsuario.isNotEmpty
                                    ? Icons.alarm_on
                                    : Icons.add_alarm),
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
                          titulo: widget.noticia.localEhCidade
                              ? 'Local (Toque para abrir)'
                              : 'Abrangência',
                          valor: widget.noticia.abrangenciaGeral
                              ? 'Todas as cidades'
                              : widget.noticia.local,
                          iconeAcao: Icons.map_outlined,
                          corAcao: AppCor.primary,
                          // "Brasil" ou "Estado de SP" não são um ponto no mapa.
                          aoClicar: widget.noticia.localEhCidade
                              ? () => _abrirLink(
                                  Uri.https('www.google.com', '/maps/search/', {
                                    'api': '1',
                                    'query':
                                        '${widget.noticia.local.trim()}, SP',
                                  }),
                                )
                              : null,
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.business,
                          titulo: 'Órgão Publicador',
                          valor: widget.noticia.orgao,
                          iconeAcao: _siteDoOrgao == null
                              ? null
                              : Icons.open_in_new,
                          corAcao: AppCor.primary,
                          aoClicar: _siteDoOrgao == null
                              ? null
                              : () => _abrirLink(_siteDoOrgao!),
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.phone,
                          titulo: 'Contato',
                          valor: _temTelefone
                              ? widget.noticia.orgaoTelefone
                              : 'Não informado',
                          iconeAcao: _temTelefone ? Icons.call_outlined : null,
                          corAcao: AppCor.primary,
                          aoClicar: _temTelefone
                              ? () => _abrirLink(
                                  Uri(
                                    scheme: 'tel',
                                    path: widget.noticia.orgaoTelefone
                                        .replaceAll(RegExp(r'[^0-9+]'), ''),
                                  ),
                                )
                              : null,
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

                  // Matéria importada de fonte oficial: leva ao texto completo.
                  if (_fonte != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _abrirLink(_fonte!),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: Text(
                          'Ler a notícia completa em ${_fonte!.host}',
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final shareText =
                            '${widget.noticia.titulo}\n\n${widget.noticia.subtitulo}\n\n${widget.noticia.descricao}\n\nÓrgão: ${widget.noticia.orgao}${_temTelefone ? '\nContato: ${widget.noticia.orgaoTelefone}' : ''}';
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
