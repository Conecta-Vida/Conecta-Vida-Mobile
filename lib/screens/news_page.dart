import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../accessibility/accessibility_motion.dart';
import '../accessibility/accessibility_palette.dart';
import '../global/appCor.dart';
import '../global/texto.dart';
import '../controllers/noticia_controller.dart';
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../providers/usuario_provider.dart';
import '../services/push_notification_service.dart';
import '../services/supabase_service.dart';
import '../widgets/noticia_card.dart';
import '../widgets/recomendados_secao.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/noticias_header.dart';
import 'autorizacoes_screen.dart';
import 'notifications_screen.dart';
import 'unidades_screen.dart';
import 'settings_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsController _newsController = NewsController();
  int _categoryIndex = 0;
  late Future<List<NewsModel>> _noticiasFuture;
  String _searchQuery = '';
  Set<String> _cidadesFiltro = {};
  Set<String> _categoriasFiltro = {};
  List<NewsModel> _noticiasCache = [];
  bool _popupAlertaExibido = false;
  bool _usarGps = true;
  StreamSubscription<Map<String, dynamic>>? _novasComunicacoes;

  @override
  void initState() {
    super.initState();
    _carregarFiltrosSalvos();
    _refreshNoticias();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarPopupAlertaCritico();
    });
    _novasComunicacoes = SupabaseService.novasComunicacoes.listen(
      _aoPublicarComunicacao,
    );
    _avisarPedidosDeAutorizacao();
    _atualizarCidadePeloGps();
  }

  /// Com o GPS ligado nos Ajustes, mantém a cidade do perfil igual à cidade
  /// onde a pessoa está (no máximo uma vez por dia). É dela que dependem o
  /// filtro de notícias, os recomendados, os alertas da cidade, as unidades de
  /// saúde e o monitoramento automático de dengue.
  Future<void> _atualizarCidadePeloGps() async {
    if (kIsWeb) return; // no navegador o GPS pede permissão a cada visita
    try {
      final box = Hive.isBoxOpen('preferencias')
          ? Hive.box('preferencias')
          : await Hive.openBox('preferencias');
      if (box.get('usar_gps', defaultValue: true) != true) return;
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      if (box.get('cidade_gps_verificada_em') == hoje) return;

      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao != LocationPermission.whileInUse &&
          permissao != LocationPermission.always) {
        return;
      }
      final posicao = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 15),
      );
      final local = await SupabaseService.fetchLocalFromCoords(
        posicao.latitude,
        posicao.longitude,
      );
      await box.put('cidade_gps_verificada_em', hoje);
      if (local == null || !mounted) return;

      final provider = context.read<UsuarioProvider>();
      final atual = provider.usuario;
      if (atual == null ||
          Texto.normalizar(atual.localizacao) ==
              Texto.normalizar(local.cidade)) {
        return;
      }
      final atualizado = UserModel(
        id: atual.id,
        nome: atual.nome,
        email: atual.email,
        dataNascimento: atual.dataNascimento,
        sexo: atual.sexo,
        localizacao: local.cidade,
        permissao: atual.permissao,
      );
      await SupabaseService.upsertUsuario(atualizado);
      if (!mounted) return;
      provider.setUsuario(atualizado);
      await _carregarFiltrosSalvos();
      _refreshNoticias();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sua cidade foi atualizada para ${local.cidade}.'),
        ),
      );
    } catch (e) {
      debugPrint('Cidade pelo GPS indisponível: $e');
    }
  }

  /// Se alguém pediu para incluir este usuário como dependente, avisa ao
  /// abrir o app e leva direto para a tela onde ele autoriza ou recusa.
  Future<void> _avisarPedidosDeAutorizacao() async {
    try {
      final convites = await SupabaseService.fetchConvitesDeDependente();
      final pendentes = convites.where((c) => c.pendente).toList();
      if (!mounted || pendentes.isEmpty) return;

      final texto = pendentes.length == 1
          ? '${pendentes.first.titularNome} quer incluir você como dependente.'
          : '${pendentes.length} pessoas querem incluir você como dependente.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(texto),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'VER',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AutorizacoesScreen()),
              );
            },
          ),
        ),
      );
    } catch (_) {
      // Sem conexão: o pedido continua disponível em Ajustes → Autorizações.
    }
  }

  /// O painel publicou algo enquanto o app está aberto: atualiza o feed e
  /// avisa o usuário (notificação do sistema no celular, aviso na tela sempre).
  void _aoPublicarComunicacao(Map<String, dynamic> comunicacao) {
    if (!mounted) return;
    _reloadNoticias();

    final titulo = (comunicacao['titulo'] ?? '').toString();
    if (titulo.isEmpty) return;
    final tipo = (comunicacao['tipo'] ?? '').toString().toUpperCase();
    final rotulo = switch (tipo) {
      'ALERTA' => 'Novo alerta',
      'CAMPANHA' => 'Nova campanha',
      _ => 'Nova notícia',
    };

    if (!kIsWeb) {
      PushNotificationService.showNotification(
        rotulo,
        titulo,
      ).catchError((_) {});
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$rotulo: $titulo'),
        backgroundColor: tipo == 'ALERTA' ? AppCor.error : AppCor.primary,
      ),
    );
  }

  @override
  void dispose() {
    _novasComunicacoes?.cancel();
    super.dispose();
  }

  Future<void> _carregarFiltrosSalvos() async {
    try {
      final box = Hive.isBoxOpen('preferencias')
          ? Hive.box('preferencias')
          : await Hive.openBox('preferencias');

      final regioesSalvas = List<String>.from(
        // Na primeira vez, além da cidade do usuário, mostra as notícias
        // nacionais e do Estado.
        box.get(
          'regioes_interesse',
          defaultValue: <String>['Brasil', 'Estado de SP'],
        ),
      );
      // Filtros salvos antes das abrangências existirem: inclui-as uma vez.
      if (box.get('abrangencias_incluidas') != true) {
        for (final ampla in ['Brasil', 'Estado de SP']) {
          if (!regioesSalvas.contains(ampla)) regioesSalvas.add(ampla);
        }
        await box.put('regioes_interesse', regioesSalvas);
        await box.put('abrangencias_incluidas', true);
      }
      final gpsLigado = box.get('usar_gps', defaultValue: true);

      if (mounted) {
        setState(() {
          _usarGps = gpsLigado;
          _cidadesFiltro = regioesSalvas.toSet();

          // Acessa o usuário através do Provider em vez do widget.usuario
          final usuario = context.read<UsuarioProvider>().usuario!;
          final cidadeUsuario = usuario.localizacao;
          final cidadeValida =
              cidadeUsuario.isNotEmpty &&
              cidadeUsuario != 'Não informado' &&
              cidadeUsuario != 'Não disponível';

          // Se a chave GPS estiver ativa nos ajustes, injeta a cidade do usuário nos filtros
          if (_usarGps && cidadeValida) {
            _cidadesFiltro.add(cidadeUsuario);
          } else if (!_usarGps && cidadeValida) {
            _cidadesFiltro.remove(cidadeUsuario);
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar filtros do Hive: $e');
    }
  }

  Future<void> _salvarFiltros() async {
    try {
      final box = Hive.isBoxOpen('preferencias')
          ? Hive.box('preferencias')
          : await Hive.openBox('preferencias');

      // Acessa o usuário através do Provider em vez do widget.usuario
      final usuario = context.read<UsuarioProvider>().usuario!;
      final cidadeUsuario = usuario.localizacao;
      final cidadeValida =
          cidadeUsuario.isNotEmpty &&
          cidadeUsuario != 'Não informado' &&
          cidadeUsuario != 'Não disponível';

      if (cidadeValida) {
        bool isGpsAtivo = _cidadesFiltro.contains(cidadeUsuario);
        await box.put('usar_gps', isGpsAtivo);
        _usarGps = isGpsAtivo;
      }

      List<String> regioes = _cidadesFiltro.toList();
      if (cidadeValida) {
        regioes.remove(cidadeUsuario);
      }

      await box.put('regioes_interesse', regioes);
    } catch (e) {
      debugPrint('Erro ao salvar filtros no Hive: $e');
    }
  }

  /// Mostra, uma única vez, o alerta ativo mais recente que vale para a
  /// cidade do usuário (ou para todas). Alertas já vistos não reaparecem.
  Future<void> _mostrarPopupAlertaCritico() async {
    if (!mounted || _popupAlertaExibido) return;

    try {
      final box = Hive.isBoxOpen('preferencias')
          ? Hive.box('preferencias')
          : await Hive.openBox('preferencias');
      final vistos = List<String>.from(
        box.get('alertas_vistos', defaultValue: <String>[]),
      ).toSet();

      final cidade = context.read<UsuarioProvider>().usuario?.localizacao ?? '';
      final notificacoes = await SupabaseService.fetchNotificacoes();
      final alerta = notificacoes.firstWhere((item) {
        if ((item['tipo'] ?? '').toString().toUpperCase() != 'ALERTA') {
          return false;
        }
        if ((item['status'] ?? '') != 'ATIVO') return false;
        if (vistos.contains('${item['id']}')) return false;
        final local = (item['localizacao'] ?? '').toString();
        final geral =
            local.trim().isEmpty || Texto.normalizar(local) == 'geral';
        return geral || cidade.isEmpty || Texto.contem(local, cidade);
      }, orElse: () => <String, dynamic>{});

      if (alerta.isEmpty || !mounted || _popupAlertaExibido) return;
      _popupAlertaExibido = true;
      vistos.add('${alerta['id']}');
      await box.put('alertas_vistos', vistos.toList());
      if (!mounted) return;

      showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppCor.error,
              size: 36,
            ),
            title: Text((alerta['titulo'] ?? 'Alerta de saúde').toString()),
            content: Text((alerta['descricao'] ?? '').toString()),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Entendi'),
              ),
            ],
          );
        },
      );
    } catch (_) {
      // Sem conexão: o alerta continua disponível em Notificações.
    }
  }

  Future<void> _abrirInstituicoesProximas() async {
    const consulta = 'hospitais, clínicas e postos de saúde';

    Position? posicao;
    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();
      if (servicoAtivo) {
        var permissao = await Geolocator.checkPermission();
        if (permissao == LocationPermission.denied) {
          permissao = await Geolocator.requestPermission();
        }

        final permitido =
            permissao == LocationPermission.whileInUse ||
            permissao == LocationPermission.always;

        if (permitido) {
          posicao = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
        }
      }
    } catch (e) {
      debugPrint('Não foi possível obter a localização para o Maps: $e');
    }

    Uri url;
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Android Maps Intent: geo:lat,lon?q=termo pesquisa vários locais
      // nas proximidades das coordenadas fornecidas.
      final centro = posicao == null
          ? '0,0'
          : '${posicao.latitude},${posicao.longitude}';
      final query = Uri.encodeComponent(consulta);
      url = Uri.parse('geo:$centro?z=14&q=$query');
    } else if (defaultTargetPlatform == TargetPlatform.iOS && posicao != null) {
      // O esquema iOS aceita q + center para pesquisar ao redor do ponto.
      final parametros = Uri(
        queryParameters: {
          'q': consulta,
          'center': '${posicao.latitude},${posicao.longitude}',
          'zoom': '14',
        },
      ).query;
      url = Uri.parse('comgooglemaps://?$parametros');
    } else {
      // Link universal: sem coordenadas no texto para não pesquisar um pin.
      url = Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': consulta,
      });
    }

    try {
      var abriu = await launchUrl(url, mode: LaunchMode.externalApplication);

      // Se o Google Maps não tiver o esquema nativo disponível no iOS,
      // abre a pesquisa universal; o Maps usa a localização do aparelho.
      if (!abriu &&
          defaultTargetPlatform == TargetPlatform.iOS &&
          url.scheme == 'comgooglemaps') {
        final fallback = Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': consulta,
        });
        abriu = await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }

      if (!abriu && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível abrir o Google Maps.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o Google Maps: $e')),
        );
      }
    }
  }

  void _refreshNoticias() {
    _noticiasFuture = SupabaseService.fetchNoticiasPorCategoria(_categoryIndex);
  }

  List<NewsModel> _filtrarNoticias(List<NewsModel> noticias) {
    var lista = noticias;
    if (_searchQuery.isNotEmpty) {
      // Ignora acentos e maiúsculas: "vacinacao" encontra "Vacinação".
      lista = lista
          .where(
            (n) =>
                Texto.contem(n.titulo, _searchQuery) ||
                Texto.contem(n.descricao, _searchQuery),
          )
          .toList();
    }
    if (_cidadesFiltro.isNotEmpty) {
      lista = lista
          .where(
            // As cidades foram cadastradas com grafias diferentes
            // ("Braganca Paulista", " Atibaia"): a comparação ignora isso.
            // Conteúdo de abrangência geral (nacional) aparece em qualquer cidade.
            (n) =>
                n.abrangenciaGeral ||
                _cidadesFiltro.any((c) => Texto.contem(n.local, c)),
          )
          .toList();
    }
    if (_categoriasFiltro.isNotEmpty) {
      final escolhidas = _categoriasFiltro.map(Texto.normalizar).toSet();
      lista = lista
          .where((n) => escolhidas.contains(Texto.normalizar(n.categoria)))
          .toList();
    }
    return lista;
  }

  /// Categorias existentes na lista atual, uma por tema.
  List<String> _categoriasDisponiveis() {
    final porChave = <String, String>{};
    for (final noticia in _noticiasCache) {
      final categoria = noticia.categoria.trim();
      if (categoria.isEmpty) continue;
      final chave = Texto.normalizar(categoria);
      final atual = porChave[chave];
      if (atual == null || categoria.compareTo(atual) > 0) {
        porChave[chave] = categoria;
      }
    }
    return porChave.values.toList()..sort();
  }

  List<String> _cidadesDisponiveis() {
    // Uma opção por cidade, mesmo com grafias diferentes no cadastro.
    final porChave = <String, String>{};
    for (final noticia in _noticiasCache) {
      final local = noticia.local.trim();
      if (local.isEmpty || local == 'Região Geral') continue;
      final chave = Texto.normalizar(local);
      final atual = porChave[chave];
      // Prefere a grafia com acentos (ex.: "Bragança" a "Braganca").
      if (atual == null || local.compareTo(atual) > 0) porChave[chave] = local;
    }
    return porChave.values.toList()..sort();
  }

  void _abrirFiltroCidades() {
    final disponiveis = _cidadesDisponiveis();
    final categorias = _categoriasDisponiveis();
    if (disponiveis.isEmpty && categorias.isEmpty) return;

    Set<String> selecao = Set.from(_cidadesFiltro);
    Set<String> selecaoCategorias = Set.from(_categoriasFiltro);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.75,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtrar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          if (categorias.isNotEmpty) ...[
                            const Text(
                              'Categorias',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: categorias.map((categoria) {
                                final marcada = selecaoCategorias.contains(
                                  categoria,
                                );
                                return FilterChip(
                                  label: Text(categoria),
                                  selected: marcada,
                                  onSelected: (valor) {
                                    setModalState(() {
                                      valor
                                          ? selecaoCategorias.add(categoria)
                                          : selecaoCategorias.remove(categoria);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (disponiveis.isNotEmpty)
                            const Text(
                              'Cidades',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ...disponiveis.map((cidade) {
                            return CheckboxListTile(
                              title: Text(cidade),
                              value: selecao.contains(cidade),
                              activeColor: AppCor.primary,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (checked) {
                                setModalState(() {
                                  checked == true
                                      ? selecao.add(cidade)
                                      : selecao.remove(cidade);
                                });
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppCor.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _cidadesFiltro = selecao;
                            _categoriasFiltro = selecaoCategorias;
                          });
                          _salvarFiltros();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCidadeChips(BuildContext context) {
    final cidadeUsuario = context.read<UsuarioProvider>().usuario!.localizacao;
    final temFiltroAtivo = _cidadesFiltro.isNotEmpty;

    final cidadeUsuarioValida =
        cidadeUsuario.isNotEmpty &&
        cidadeUsuario != 'Não informado' &&
        cidadeUsuario != 'Não disponível';

    final cidadesExtras = _cidadesFiltro
        .where((c) => c != cidadeUsuario)
        .toList();

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildChip(
            context,
            'Todas',
            selecionado: !temFiltroAtivo,
            onTap: () {
              setState(() => _cidadesFiltro.clear());
              _salvarFiltros();
            },
          ),

          if (cidadeUsuarioValida)
            _buildChip(
              context,
              cidadeUsuario,
              selecionado: _cidadesFiltro.contains(cidadeUsuario),
              onTap: () {
                setState(() {
                  _cidadesFiltro.contains(cidadeUsuario)
                      ? _cidadesFiltro.remove(cidadeUsuario)
                      : _cidadesFiltro.add(cidadeUsuario);
                });
                _salvarFiltros();
              },
            ),

          ...cidadesExtras.map(
            (cidade) => _buildChipRemovivel(context, cidade),
          ),
          _buildChipFiltro(context),
        ],
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    String label, {
    required bool selecionado,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AccessibilityMotion.duration(
            context,
            const Duration(milliseconds: 200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selecionado
                ? AppCor.primary
                : AccessibilityPalette.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selecionado
                  ? AppCor.primary
                  : AccessibilityPalette.border(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selecionado
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipRemovivel(BuildContext context, String cidade) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AnimatedContainer(
        duration: AccessibilityMotion.duration(
          context,
          const Duration(milliseconds: 200),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppCor.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cidade,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                setState(() => _cidadesFiltro.remove(cidade));
                _salvarFiltros();
              },
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipFiltro(BuildContext context) {
    final bool temExtra =
        _cidadesFiltro.any((c) {
          final cidadeUsuario = context
              .read<UsuarioProvider>()
              .usuario!
              .localizacao;
          return c != cidadeUsuario;
        }) ||
        _categoriasFiltro.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _abrirFiltroCidades,
        child: AnimatedContainer(
          duration: AccessibilityMotion.duration(
            context,
            const Duration(milliseconds: 200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: temExtra
                ? AppCor.primary
                : AccessibilityPalette.surface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: temExtra
                  ? AppCor.primary
                  : AccessibilityPalette.border(context),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune,
                size: 14,
                color: temExtra
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Filtrar',
                style: TextStyle(
                  fontSize: 13,
                  color: temExtra ? Colors.white : AppCor.textoCinza,
                  fontWeight: temExtra ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reloadNoticias() async {
    setState(() {
      _noticiasFuture = SupabaseService.fetchNoticiasPorCategoria(
        _categoryIndex,
        forceRefresh: true,
      );
    });
    try {
      await _noticiasFuture;
    } catch (_) {
      // A própria lista mostra o aviso de falha.
    }
  }

  /// Estado vazio/erro que ainda permite "puxar para atualizar".
  Widget _avisoRolavel(String mensagem, Color cor, {IconData? icone}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icone != null) ...[
                  Icon(icone, size: 40, color: cor),
                  const SizedBox(height: 12),
                ],
                Text(
                  mensagem,
                  style: TextStyle(color: cor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Aqui pegamos o usuário atual de forma correta e síncrona
    final usuario = context.watch<UsuarioProvider>().usuario!;
    final colors = Theme.of(context).colorScheme;
    final String tituloSessao = _newsController.getTituloSessao(_categoryIndex);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            NoticiasHeader(
              nome: usuario.nome,
              onSearch: (query) => setState(() => _searchQuery = query),
              onNotifications: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Passamos 'usuario' lido do provider para as telas que ainda o pedem no construtor
                    builder: (context) => NotificationsScreen(usuario: usuario),
                  ),
                );
              },
              onCalendar: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Passamos 'usuario' lido do provider
                    builder: (context) => CalendarScreen(usuario: usuario),
                  ),
                );
              },
              onNearbyInstitutions: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnidadesScreen(
                      onBuscarNoMapa: _abrirInstituicoesProximas,
                    ),
                  ),
                );
              },
              onSettings: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    // Corrigido para const SettingsScreen() sem passar 'usuario'
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                // Quando voltar das configurações, aplica o que foi alterado lá
                _carregarFiltrosSalvos();
              },
            ),
            const SizedBox(height: 36),
            _buildCidadeChips(context),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tituloSessao,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  Text(
                    'Categoria',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RefreshIndicator(
                  onRefresh: _reloadNoticias,
                  color: AppCor.primary,
                  child: FutureBuilder<List<NewsModel>>(
                    future: _noticiasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppCor.primary,
                          ),
                        );
                      }

                      final todas = snapshot.data ?? const <NewsModel>[];
                      if (_noticiasCache != todas) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _noticiasCache = todas);
                        });
                      }
                      final noticias = _filtrarNoticias(todas);

                      if (snapshot.hasError && todas.isEmpty) {
                        return _avisoRolavel(
                          'Sem conexão com o servidor.\nPuxe para tentar de novo.',
                          colors.onSurfaceVariant,
                          icone: Icons.cloud_off_outlined,
                        );
                      }

                      // Sugestões só na aba inicial e sem pesquisa em andamento.
                      final mostrarRecomendados =
                          _categoryIndex == 0 && _searchQuery.isEmpty;

                      if (noticias.isEmpty && !mostrarRecomendados) {
                        return _avisoRolavel(
                          'Nenhuma notícia encontrada.',
                          AppCor.textoCinza,
                        );
                      }

                      final cabecalho = mostrarRecomendados ? 1 : 0;
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount:
                            noticias.length +
                            cabecalho +
                            (noticias.isEmpty ? 1 : 0),
                        itemBuilder: (context, posicao) {
                          if (mostrarRecomendados && posicao == 0) {
                            return RecomendadosSecao(usuario: usuario);
                          }
                          if (noticias.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 48),
                              child: Center(
                                child: Text(
                                  'Nenhuma notícia encontrada.',
                                  style: TextStyle(color: AppCor.textoCinza),
                                ),
                              ),
                            );
                          }
                          final index = posicao - cabecalho;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: NoticiaCard(
                              noticia: noticias[index],
                              // Pegando ID e Email diretamente do Provider
                              userEmail: usuario.email,
                              userId: usuario.id,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _categoryIndex,
        onTap: (index) {
          setState(() {
            _categoryIndex = index;
            _refreshNoticias();
          });
        },
      ),
    );
  }
}
