import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../accessibility/accessibility_provider.dart';
import '../accessibility/accessibility_speech_service.dart';
import '../models/noticia.dart';
import '../models/dependente.dart';
import 'package:provider/provider.dart';
import '../global/appCor.dart';
import '../services/maps_launcher.dart';
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

  /// Inscrições da conta nesta campanha: o titular (`dependenteId` nulo)
  /// e/ou dependentes. A API permite vários participantes por campanha.
  List<_Participante> _inscritos = [];

  bool get _inscrito => _inscritos.isNotEmpty;

  bool get _ehCampanha => widget.noticia.tag.toUpperCase() == 'CAMPANHA';

  bool get _temTelefone => widget.noticia.orgaoTelefone.trim().isNotEmpty;

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
    if (!aberto) _avisar('Não foi possível abrir este link.', erro: true);
  }

  String get _nomesInscritos =>
      _inscrito ? _inscritos.map((p) => p.nome).join(', ') : 'Ninguém inscrito';

  @override
  void initState() {
    super.initState();
    _carregarStatusInscricao();
  }

  static int? _lerId(dynamic valor) {
    if (valor is num) return valor.toInt();
    if (valor == null) return null;
    return int.tryParse('$valor');
  }

  Future<List<_Participante>> _buscarInscritos(int usuarioId) async {
    final inscricoes = await SupabaseService.fetchInscritosCampanha(
      widget.noticia.id!,
    );
    final participantes = <_Participante>[];
    for (final item in inscricoes) {
      if ('${item['usuario_id'] ?? ''}' != '$usuarioId') continue;
      final dependenteId = _lerId(item['dependente_id']);
      participantes.add(
        _Participante(
          dependenteId: dependenteId,
          nome: dependenteId == null
              ? 'Você'
              : (item['participante_nome'] ?? 'Dependente').toString(),
        ),
      );
    }
    // Titular primeiro, depois dependentes em ordem alfabética.
    participantes.sort((a, b) {
      if (a.dependenteId == null) return -1;
      if (b.dependenteId == null) return 1;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });
    return participantes;
  }

  Future<void> _carregarStatusInscricao() async {
    if (!_ehCampanha || widget.userId == null || widget.noticia.id == null) {
      return;
    }

    try {
      final participantes = await _buscarInscritos(widget.userId!);
      if (!mounted) return;
      setState(() => _inscritos = participantes);
    } catch (_) {
      // Mantém a tela funcional mesmo se a API de inscrição falhar.
    }
  }

  void _avisar(String mensagem, {bool erro = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? AppCor.error : AppCor.primary,
      ),
    );
  }

  Future<void> _alternarInscricaoCampanha() async {
    if (widget.noticia.id == null) {
      _avisar('Esta campanha ainda não possui ID válido para inscrição.');
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
      _avisar('Não foi possível identificar o usuário para inscrição.');
      return;
    }

    setState(() => _processandoCampanha = true);

    try {
      // Sem dependentes a inscrição continua sendo um toque só. Se a lista
      // não puder ser carregada, o titular ainda consegue se inscrever.
      List<DependenteModel> dependentes;
      try {
        dependentes = await SupabaseService.fetchDependentes(usuarioId);
      } catch (_) {
        dependentes = const [];
      }
      if (!mounted) return;

      // Opções: titular, dependentes ativos e inscritos que já não estão
      // na lista de dependentes (para ainda permitir o cancelamento).
      final opcoes = <_Participante>[
        const _Participante(dependenteId: null, nome: 'Você'),
        ...dependentes
            .where((d) => d.id != null)
            .map(
              (d) => _Participante(
                dependenteId: d.id,
                nome: d.nomeCompleto,
                detalhe: d.parentesco,
              ),
            ),
      ];
      for (final inscrito in _inscritos) {
        if (!opcoes.any((o) => o.dependenteId == inscrito.dependenteId)) {
          opcoes.add(inscrito);
        }
      }

      final _Participante? escolhido = opcoes.length == 1
          ? opcoes.first
          : await _escolherParticipante(opcoes);
      if (!mounted || escolhido == null) return;

      final jaInscrito = _inscritos.any(
        (p) => p.dependenteId == escolhido.dependenteId,
      );
      final quem = escolhido.dependenteId == null ? 'você' : escolhido.nome;

      if (jaInscrito) {
        await SupabaseService.desinscreverUsuarioDaCampanha(
          comunicacaoId: widget.noticia.id!,
          usuarioId: usuarioId,
          dependenteId: escolhido.dependenteId,
        );
      } else {
        await SupabaseService.inscreverUsuarioEmCampanha(
          comunicacaoId: widget.noticia.id!,
          usuarioId: usuarioId,
          dependenteId: escolhido.dependenteId,
        );
      }

      // Relê da API para refletir exatamente o que ficou gravado.
      List<_Participante> atualizados;
      try {
        atualizados = await _buscarInscritos(usuarioId);
      } catch (_) {
        atualizados = jaInscrito
            ? _inscritos
                  .where((p) => p.dependenteId != escolhido.dependenteId)
                  .toList()
            : [..._inscritos, escolhido];
      }
      if (!mounted) return;
      setState(() => _inscritos = atualizados);

      _avisar(
        jaInscrito
            ? 'Inscrição de $quem cancelada em: "${widget.noticia.titulo}".'
            : 'Inscrição realizada para $quem em: "${widget.noticia.titulo}".',
      );
    } catch (e) {
      _avisar('Erro ao processar a inscrição: $e', erro: true);
    } finally {
      if (mounted) setState(() => _processandoCampanha = false);
    }
  }

  Future<_Participante?> _escolherParticipante(List<_Participante> opcoes) {
    return showDialog<_Participante>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Quem participará desta campanha?'),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Toque em um participante para inscrever ou cancelar a inscrição.',
            ),
          ),
          ...opcoes.map((opcao) {
            final inscrito = _inscritos.any(
              (p) => p.dependenteId == opcao.dependenteId,
            );
            final ehTitular = opcao.dependenteId == null;
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, opcao),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  ehTitular ? Icons.person : Icons.family_restroom,
                ),
                title: Text(ehTitular ? 'Eu (titular)' : opcao.nome),
                subtitle: Text(
                  inscrito
                      ? 'Inscrito · toque para cancelar'
                      : (opcao.detalhe ?? 'Toque para inscrever'),
                ),
                trailing: Icon(
                  inscrito ? Icons.check_circle : Icons.add_circle_outline,
                  color: inscrito ? AppCor.catVacinacao : null,
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar'),
              ),
            ),
          ),
        ],
      ),
    );
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
                      border: Border.all(
                        color: colors.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        NoticiasInfoBotao(
                          icone: Icons.calendar_month,
                          titulo: _ehCampanha
                              ? 'Período (toque no ícone para inscrever)'
                              : 'Data de publicação',
                          valor: _dataExibida,
                          iconeAcao: !_ehCampanha
                              ? null
                              : _processandoCampanha
                              ? Icons.hourglass_top
                              : (_inscrito ? Icons.alarm_on : Icons.add_alarm),
                          corAcao: _inscrito
                              ? AppCor.catVacinacao
                              : AppCor.catDoacoes,
                          aoClicar: (_ehCampanha && !_processandoCampanha)
                              ? _alternarInscricaoCampanha
                              : null,
                        ),
                        if (_ehCampanha) ...[
                          const Divider(height: 1),
                          NoticiasInfoBotao(
                            icone: Icons.how_to_reg,
                            titulo: 'Participantes inscritos',
                            valor: _nomesInscritos,
                          ),
                        ],
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.location_on,
                          titulo: 'Local (Toque para abrir)',
                          valor: widget.noticia.local,
                          iconeAcao: Icons.map_outlined,
                          corAcao: AppCor.primary,
                          aoClicar: () => MapsLauncher.abrirPesquisa(
                            context,
                            widget.noticia.local,
                          ),
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

/// Quem participa de uma campanha: o titular da conta (`dependenteId` nulo)
/// ou um dos seus dependentes.
class _Participante {
  const _Participante({
    required this.dependenteId,
    required this.nome,
    this.detalhe,
  });

  final int? dependenteId;
  final String nome;
  final String? detalhe;
}
