import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../global/appCor.dart';
import '../global/texto.dart';
import '../models/unidade_saude.dart';
import '../services/supabase_service.dart';

/// Unidades de saúde reais (CNES), das mais próximas para as mais distantes
/// quando o usuário permite a localização.
class UnidadesScreen extends StatefulWidget {
  /// Pesquisa ampla no Google Maps (hospitais, clínicas e postos por perto).
  final Future<void> Function()? onBuscarNoMapa;

  const UnidadesScreen({super.key, this.onBuscarNoMapa});

  @override
  State<UnidadesScreen> createState() => _UnidadesScreenState();
}

class _UnidadesScreenState extends State<UnidadesScreen> {
  static const _filtros = ['Todas', 'UBS', 'UPA', 'Hospital', 'CAPS', 'SAMU'];

  List<UnidadeSaude> _unidades = [];
  bool _carregando = true;
  String? _erro;
  String _filtro = 'Todas';
  String _busca = '';
  bool _somente24h = false;
  bool _semLocalizacao = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<Position?> _posicaoAtual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao != LocationPermission.whileInUse &&
          permissao != LocationPermission.always) {
        return null;
      }
      return await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resultados = await Future.wait<Object?>([
        SupabaseService.fetchUnidadesDeSaude(),
        _posicaoAtual(),
      ]);
      var unidades = resultados[0] as List<UnidadeSaude>;
      final posicao = resultados[1] as Position?;

      if (posicao != null) {
        unidades =
            unidades
                .map(
                  (u) => u.comDistancia(
                    u.temCoordenadas
                        ? Geolocator.distanceBetween(
                            posicao.latitude,
                            posicao.longitude,
                            u.latitude!,
                            u.longitude!,
                          )
                        : null,
                  ),
                )
                .toList()
              ..sort(
                (a, b) => (a.distancia ?? double.infinity).compareTo(
                  b.distancia ?? double.infinity,
                ),
              );
      }
      if (!mounted) return;
      setState(() {
        _unidades = unidades;
        _semLocalizacao = posicao == null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível carregar as unidades.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<UnidadeSaude> get _visiveis => _unidades.where((u) {
    if (_filtro != 'Todas' && u.tipo != _filtro) return false;
    if (_somente24h && !u.vinteQuatroHoras) return false;
    if (_busca.isNotEmpty && !Texto.contem('${u.nome} ${u.endereco}', _busca)) {
      return false;
    }
    return true;
  }).toList();

  Future<void> _abrir(Uri url) async {
    var abriu = false;
    try {
      abriu = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!abriu && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir.'),
          backgroundColor: AppCor.error,
        ),
      );
    }
  }

  void _ligar(UnidadeSaude u) => _abrir(
    Uri(scheme: 'tel', path: u.telefone.replaceAll(RegExp(r'[^0-9+]'), '')),
  );

  void _rota(UnidadeSaude u) {
    final destino = u.temCoordenadas
        ? '${u.latitude},${u.longitude}'
        : '${u.nome}, ${u.endereco}';
    _abrir(
      Uri.https('www.google.com', '/maps/dir/', {
        'api': '1',
        'destination': destino,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final visiveis = _visiveis;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unidades de saúde'),
        actions: [
          if (widget.onBuscarNoMapa != null)
            IconButton(
              tooltip: 'Buscar no Google Maps',
              icon: const Icon(Icons.map_outlined),
              onPressed: widget.onBuscarNoMapa,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _busca = v.trim()),
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou bairro',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final f in _filtros)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filtro == f,
                      onSelected: (_) => setState(() => _filtro = f),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: const Text('Abertas 24 h'),
                    selected: _somente24h,
                    onSelected: (v) => setState(() => _somente24h = v),
                  ),
                ),
              ],
            ),
          ),
          if (_semLocalizacao && !_carregando && _erro == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.location_off_outlined,
                    size: 16,
                    color: cores.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Permita a localização para ver as unidades mais próximas primeiro.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _carregar,
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _erro != null
                  ? _aviso(
                      Icons.cloud_off_outlined,
                      '$_erro\nPuxe para tentar de novo.',
                    )
                  : visiveis.isEmpty
                  ? _aviso(
                      Icons.search_off,
                      'Nenhuma unidade encontrada com esses filtros.',
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: visiveis.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _cartao(visiveis[i], cores),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aviso(IconData icone, String texto) {
    final cores = Theme.of(context).colorScheme;
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

  static (Color, IconData) _estiloDoTipo(String tipo) => switch (tipo) {
    'Hospital' => (const Color(0xFFD32F2F), Icons.local_hospital_outlined),
    'UPA' => (const Color(0xFFEF6C00), Icons.emergency_outlined),
    'SAMU' => (const Color(0xFFC62828), Icons.airport_shuttle_outlined),
    'CAPS' => (const Color(0xFF7B1FA2), Icons.psychology_outlined),
    _ => (const Color(0xFF00897B), Icons.health_and_safety_outlined),
  };

  Widget _cartao(UnidadeSaude u, ColorScheme cores) {
    final (cor, icone) = _estiloDoTipo(u.tipo);
    final texto = Theme.of(context).textTheme;
    final horario = u.vinteQuatroHoras
        ? 'Aberta 24 horas'
        : (u.horarioSemana.isEmpty
              ? 'Horário não informado'
              : 'Seg. a sex.: ${u.horarioSemana}');

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: cor.withValues(alpha: 0.12),
                  child: Icon(icone, color: cor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.nome,
                        style: texto.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          u.tipo,
                          if (u.distancia != null)
                            UnidadeSaude.formatarDistancia(u.distancia!),
                        ].join(' · '),
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _linha(Icons.place_outlined, u.endereco, cores),
            _linha(Icons.schedule, horario, cores),
            if (u.temTelefone) _linha(Icons.phone_outlined, u.telefone, cores),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (u.temTelefone)
                  TextButton.icon(
                    onPressed: () => _ligar(u),
                    icon: const Icon(Icons.call_outlined, size: 18),
                    label: const Text('Ligar'),
                  ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  onPressed: () => _rota(u),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Como chegar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linha(IconData icone, String texto, ColorScheme cores) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 16, color: cores.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(color: cores.onSurfaceVariant, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}
