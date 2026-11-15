import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../global/texto.dart';
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../models/dependente.dart';

/// Camada de dados do aplicativo.
///
/// O app fala direto com o Supabase (sem API Java): o login é feito pelo
/// Supabase Auth e cada consulta passa pelas regras de acesso (RLS) do
/// banco, que só liberam os dados da própria conta. As telas continuam
/// usando os mesmos métodos de antes.
class SupabaseService {
  /// Projeto Supabase. A chave é PÚBLICA (publishable): pode ir no app,
  /// pois quem protege os dados são as regras do banco.
  static String supabaseUrl = 'https://pborxjuuexiqollesfxw.supabase.co';
  static String supabaseKey = 'sb_publishable_BEMytsJ8eC0DdQt6vI7PCg_vfy7UDRd';

  /// Página (hospedada no Netlify) aberta pelo link do e-mail de recuperação.
  static String urlRedefinirSenha = '';

  static final http.Client _httpClient = http.Client();
  static SupabaseClient get _db => Supabase.instance.client;

  static const Duration _comunicacoesCacheTtl = Duration(seconds: 30);
  static const Duration _inscricaoCacheTtl = Duration(seconds: 20);
  static List<Map<String, dynamic>>? _comunicacoesCache;
  static DateTime? _comunicacoesCacheAt;
  static String? _cacheToken;
  static Future<List<Map<String, dynamic>>>? _comunicacoesRequest;
  static final Map<int, _CachedIds> _inscricoesUsuarioCache = {};

  /// Perfil (linha de `usuarios`) da conta logada.
  static UserModel? _perfil;
  static String? _tokenPush;
  static RealtimeChannel? _canalComunicacoes;

  // Notifica telas que dependem das inscrições quando uma alteração é salva.
  static final StreamController<void> _inscricoesController =
      StreamController<void>.broadcast();
  static Stream<void> get inscricoesAlteradas => _inscricoesController.stream;

  // Emite cada comunicação publicada pelo painel enquanto o app está aberto.
  static final StreamController<Map<String, dynamic>> _novasComunicacoes =
      StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get novasComunicacoes =>
      _novasComunicacoes.stream;

  static const String _colunasUsuario =
      'id, nome, email, sexo, localizacao, permissao, data_nascimento';

  /// Conecta ao Supabase. Chamar uma vez, antes do runApp.
  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
  }

  static Future<void> syncDefaultNoticias() async {}

  // ------------------------------------------------------------------
  // Conta e sessão
  // ------------------------------------------------------------------

  static String _mensagemAuth(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (m.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar (veja a caixa de entrada).';
    }
    if (m.contains('already registered') || m.contains('already been registered')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (m.contains('password should be')) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    if (m.contains('rate limit') || e.statusCode == '429') {
      return 'Muitas tentativas em pouco tempo. Aguarde alguns minutos.';
    }
    if (m.contains('administrador')) {
      return 'Este e-mail pertence a um administrador. Peça o acesso pelo painel.';
    }
    return e.message;
  }

  static UserModel _usuarioDeLinha(Map<String, dynamic> linha) => UserModel(
    id: (linha['id'] as num?)?.toInt(),
    nome: (linha['nome'] ?? '').toString(),
    email: (linha['email'] ?? '').toString(),
    dataNascimento: (linha['data_nascimento'] as num?)?.toInt(),
    sexo: (linha['sexo'] ?? 'Não informado').toString(),
    localizacao: (linha['localizacao'] ?? 'Não informado').toString(),
  );

  /// Lê o perfil da conta logada e prepara push e tempo real.
  static Future<UserModel?> _carregarPerfil() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) return null;

    final linha = await _db
        .from('usuarios')
        .select(_colunasUsuario)
        .eq('auth_id', uid)
        .maybeSingle();
    if (linha == null) return null;

    _perfil = _usuarioDeLinha(linha);
    unawaited(_sincronizarTokenPush());
    _ouvirNovasComunicacoes();
    return _perfil;
  }

  /// Se o usuário já entrou neste aparelho, devolve o perfil sem pedir login.
  static Future<UserModel?> restaurarSessao() async {
    try {
      if (_db.auth.currentSession == null) return null;
      return await _carregarPerfil();
    } catch (e) {
      developer.log('Sessão não restaurada: $e', name: 'ApiService');
      return null;
    }
  }

  static Future<void> signUp(UserModel usuario, String senha) async {
    try {
      final resposta = await _db.auth.signUp(
        email: usuario.email.trim(),
        password: senha.trim(),
        // O banco cria o perfil a partir destes dados; a permissão nunca
        // vem do aplicativo.
        data: {
          'nome': usuario.nome.trim(),
          'sexo': usuario.sexo,
          'localizacao': usuario.localizacao,
          'data_nascimento': usuario.dataNascimento?.toString() ?? '',
        },
      );

      // Com confirmação de e-mail ligada, o Supabase devolve um usuário sem
      // identidades quando o e-mail já existe.
      if (resposta.user?.identities?.isEmpty ?? false) {
        throw Exception('Este e-mail já está cadastrado.');
      }
      if (resposta.session == null) {
        throw Exception(
          'Conta criada! Confirme o e-mail enviado para '
          '${usuario.email.trim()} e depois faça login.',
        );
      }
    } on AuthException catch (e) {
      throw Exception(_mensagemAuth(e));
    }
  }

  static Future<UserModel> signIn(String email, String senha) async {
    try {
      await _db.auth.signInWithPassword(email: email.trim(), password: senha);
    } on AuthException catch (e) {
      developer.log('Erro ao fazer login: ${e.message}', name: 'ApiService');
      throw Exception(_mensagemAuth(e));
    }

    final perfil = await _carregarPerfil();
    if (perfil == null) {
      await _db.auth.signOut();
      throw Exception('Perfil não encontrado para esta conta.');
    }
    return perfil;
  }

  static void signOut() {
    final canal = _canalComunicacoes;
    _canalComunicacoes = null;
    if (canal != null) unawaited(_db.removeChannel(canal));

    _perfil = null;
    _limparCachesDeComunicacoes();
    _inscricoesUsuarioCache.clear();
    unawaited(_db.auth.signOut());

    developer.log('Usuário deslogado com sucesso.', name: 'ApiService');
  }

  /// Apaga a própria conta (perfil, dependentes, inscrições e login).
  static Future<void> deleteUsuario(String email) async {
    try {
      await _db.rpc('excluir_minha_conta');
    } catch (e) {
      developer.log('Erro ao deletar conta: $e', name: 'ApiService');
      rethrow;
    }
  }

  static Future<void> upsertUsuario(UserModel user, {String senha = ''}) async {
    try {
      if (user.id == null) {
        throw Exception("ID não encontrado. Faça login novamente.");
      }

      await _db.from('usuarios').update({
        'nome': user.nome.trim(),
        'sexo': user.sexo,
        'localizacao': user.localizacao,
        'data_nascimento': user.dataNascimento,
      }).eq('id', user.id!);

      if (senha.trim().isNotEmpty) {
        await _db.auth.updateUser(UserAttributes(password: senha.trim()));
      }
      if (_perfil?.id == user.id) _perfil = user;
    } on AuthException catch (e) {
      throw Exception(_mensagemAuth(e));
    } catch (e) {
      developer.log('Erro ao sincronizar usuario: $e', name: 'ApiService');
      rethrow;
    }
  }

  static Future<UserModel?> fetchUsuarioByEmail(String email) async {
    try {
      // As regras do banco só devolvem o perfil da própria conta.
      final linha = await _db
          .from('usuarios')
          .select(_colunasUsuario)
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      return linha == null ? null : _usuarioDeLinha(linha);
    } catch (e) {
      developer.log('Erro ao buscar usuario: $e', name: 'ApiService');
      return null;
    }
  }

  /// Envia o e-mail com o link para criar uma nova senha.
  static Future<void> resetPassword(String email) async {
    final emailLimpo = email.trim();
    if (emailLimpo.isEmpty) {
      throw Exception('Informe um e-mail válido para recuperação.');
    }

    try {
      await _db.auth.resetPasswordForEmail(
        emailLimpo,
        redirectTo: urlRedefinirSenha.isEmpty ? null : urlRedefinirSenha,
      );
    } on AuthException catch (e) {
      developer.log('Erro no reset de senha: ${e.message}', name: 'ApiService');
      throw Exception(_mensagemAuth(e));
    }
  }

  // ------------------------------------------------------------------
  // Push e tempo real
  // ------------------------------------------------------------------

  /// Guarda o token do aparelho; é gravado no banco assim que houver login.
  static Future<void> registrarTokenPush(String token) async {
    _tokenPush = token;
    await _sincronizarTokenPush();
  }

  static Future<void> _sincronizarTokenPush() async {
    final token = _tokenPush;
    final usuarioId = _perfil?.id;
    if (token == null || usuarioId == null) return;
    try {
      await _db.from('dispositivos_push').upsert({
        'usuario_id': usuarioId,
        'token': token,
        'atualizado_em': DateTime.now().toIso8601String(),
      }, onConflict: 'token');
    } catch (e) {
      developer.log('Erro ao registrar token de push: $e', name: 'ApiService');
    }
  }

  /// Recebe na hora as comunicações que o painel publica.
  static void _ouvirNovasComunicacoes() {
    if (_canalComunicacoes != null) return;
    _canalComunicacoes = _db
        .channel('comunicacoes-novas')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'comunicacoes',
          callback: (payload) {
            _limparCachesDeComunicacoes();
            _novasComunicacoes.add(Map<String, dynamic>.from(payload.newRecord));
          },
        )
        .subscribe();
  }

  // ------------------------------------------------------------------
  // Comunicações (notícias, campanhas e alertas)
  // ------------------------------------------------------------------

  static String _localLimpo(dynamic valor) {
    final local = (valor ?? '').toString().trim();
    return local.isEmpty ? 'Região Geral' : local;
  }

  static void _limparCachesDeComunicacoes() {
    _comunicacoesCache = null;
    _comunicacoesCacheAt = null;
    _cacheToken = null;
  }

  static List<Map<String, dynamic>> _copiarComunicacoes(
    List<Map<String, dynamic>> source,
  ) {
    return source.map((item) => Map<String, dynamic>.from(item)).toList();
  }


  /// Lista comum usada por notícias, notificações e filtros.
  ///
  /// Evita repetir a consulta quando várias telas abrem juntas.
  /// Cache curto (30 s) e compartilhamento da mesma Future durante a carga.
  static Future<List<Map<String, dynamic>>> _fetchComunicacoes({
    bool forceRefresh = false,
  }) async {
    final tokenAtual = _db.auth.currentUser?.id;
    final agora = DateTime.now();
    final cacheValido = _comunicacoesCache != null &&
        _comunicacoesCacheAt != null &&
        agora.difference(_comunicacoesCacheAt!) < _comunicacoesCacheTtl &&
        _cacheToken == tokenAtual;

    if (!forceRefresh && cacheValido) {
      return _copiarComunicacoes(_comunicacoesCache!);
    }

    final requisicaoEmAndamento = _comunicacoesRequest;
    if (requisicaoEmAndamento != null) {
      return _copiarComunicacoes(await requisicaoEmAndamento);
    }

    final request = () async {
      final linhas = await _db
          .from('comunicacoes')
          .select('*, instituicao:instituicoes_saude(*)')
          .order('data_postada', ascending: false);
      return linhas.map((item) => Map<String, dynamic>.from(item)).toList();
    }();

    _comunicacoesRequest = request;
    try {
      final result = await request;
      _comunicacoesCache = _copiarComunicacoes(result);
      _comunicacoesCacheAt = DateTime.now();
      _cacheToken = tokenAtual;
      return _copiarComunicacoes(result);
    } catch (e) {
      // Se a rede oscilar, a tela pode usar a última resposta conhecida.
      if (_comunicacoesCache != null && _cacheToken == tokenAtual) {
        developer.log(
          'Usando cache de comunicações após falha de rede: $e',
          name: 'ApiService',
        );
        return _copiarComunicacoes(_comunicacoesCache!);
      }
      rethrow;
    } finally {
      _comunicacoesRequest = null;
    }
  }

  static Future<Set<String>> fetchLocalizacoesComunicacoes() async {
    final comunicacoes = await _fetchComunicacoes();
    // Uma entrada por cidade, mesmo que tenha sido digitada de formas
    // diferentes; prevalece a grafia mais usada.
    final contagem = <String, Map<String, int>>{};
    for (final item in comunicacoes) {
      final local = (item['localizacao'] ?? '').toString().trim();
      if (local.isEmpty) continue;
      final grafias = contagem.putIfAbsent(Texto.normalizar(local), () => {});
      grafias[local] = (grafias[local] ?? 0) + 1;
    }
    return contagem.values.map((grafias) {
      final ordenadas = grafias.entries.toList()
        ..sort((a, b) {
          // Em empate, prefere a grafia com acentos (ex.: "Bragança").
          final porUso = b.value.compareTo(a.value);
          return porUso != 0 ? porUso : b.key.compareTo(a.key);
        });
      return ordenadas.first.key;
    }).toSet();
  }

  static Future<List<NewsModel>> fetchNoticiasPorCategoria(
    int categoryIndex, {
    bool forceRefresh = false,
  }) async {
    try {
      final dynamicList = await _fetchComunicacoes(
        forceRefresh: forceRefresh,
      );

      var noticias = dynamicList.map((item) {
        final instituicao = item['instituicao'];
        final instituicaoNome = instituicao is Map
            ? (instituicao['nome'] ?? 'Secretaria de Saúde').toString()
            : 'Secretaria de Saúde';

        return NewsModel.fromMap({
          'id': item['id'],
          'tag': item['tipo'] ?? 'Comunicação',
          'data': item['data_postada'] ?? item['dataPostada'] ?? '',
          'data_inicio': item['data_inicio'] ?? item['dataInicio'] ?? '',
          'data_fim': item['data_fim'] ?? item['dataFim'] ?? '',
          'titulo': item['titulo'] ?? '',
          'subtitulo': item['categoria'] ?? '',
          'descricao': item['descricao'] ?? '',
          'imagem': item['linkimagem'] ?? item['linkImagem'] ?? '',
          'categoria': item['categoria'] ?? 'Notícia',
          'local': _localLimpo(item['localizacao']),
          'publicoAlvo':
              item['publico_alvo'] ?? item['publicoAlvo'] ?? 'População',
          'orgao': instituicaoNome,
          'status': item['status'] ?? '',
          'fonteUrl': item['fonte_url'] ?? '',
          // Contato real da instituição; vazio quando ela não informou
          // (a tela mostra "Não informado" em vez de um número fictício).
          'orgaoTelefone': instituicao is Map
              ? (instituicao['telefone'] ?? '').toString().trim()
              : '',
          'orgaoSite': instituicao is Map
              ? (instituicao['linksite'] ?? instituicao['linkSite'] ?? '')
                    .toString()
                    .trim()
              : '',
        });
      }).toList();

      if (categoryIndex == 0) {
        noticias = noticias
            .where((n) => n.tag.toUpperCase() == 'NOTICIA')
            .toList();
      } else if (categoryIndex == 1) {
        noticias = noticias
            .where(
              (n) =>
                  n.tag.toUpperCase() == 'CAMPANHA' &&
                  n.categoria.toLowerCase().contains('vacina'),
            )
            .toList();
      } else if (categoryIndex == 2) {
        noticias = noticias
            .where(
              (n) =>
                  n.tag.toUpperCase() == 'CAMPANHA' &&
                  n.categoria.toLowerCase().contains('doa'),
            )
            .toList();
      } else if (categoryIndex == 3) {
        noticias = noticias
            .where((n) => n.tag.toUpperCase() == 'ALERTA')
            .toList();
      } else if (categoryIndex == 4) {
        noticias = noticias
            .where((n) => n.tag.toUpperCase() == 'CAMPANHA')
            .toList();
      }

      // Mais recentes primeiro; campanhas encerradas vão para o fim.
      noticias.sort((a, b) {
        if (a.encerrada != b.encerrada) return a.encerrada ? 1 : -1;
        return b.data.compareTo(a.data);
      });
      return noticias;
    } catch (e) {
      developer.log(
        'Falha ao carregar notícias da API: $e',
        name: 'ApiService',
      );
      // Sem conteúdo de exemplo: a tela mostra o aviso de falha de conexão.
      rethrow;
    }
  }

  /// Todas as comunicações publicadas (notícias, campanhas e alertas),
  /// da mais recente para a mais antiga.
  static Future<List<NewsModel>> fetchTodasAsComunicacoes({
    bool forceRefresh = false,
  }) => fetchNoticiasPorCategoria(-1, forceRefresh: forceRefresh);

  /// Sugestões para a tela inicial: campanhas em andamento e alertas que
  /// combinam com a cidade do usuário e com os temas das campanhas em que
  /// ele já se inscreveu. Nunca sugere algo em que já está inscrito.
  static Future<List<NewsModel>> fetchRecomendados(
    UserModel usuario, {
    int maximo = 6,
  }) async {
    final todas = await fetchTodasAsComunicacoes();
    final inscritas = usuario.id == null
        ? <int>{}
        : (await _fetchIdsInscricoesUsuario(usuario.id!) ?? <int>{});

    final cidade = usuario.localizacao.trim();
    final temCidade =
        cidade.isNotEmpty &&
        cidade != 'Não informado' &&
        cidade != 'Não disponível';

    // Temas (categorias) das campanhas em que o usuário já participou.
    final temasDeInteresse = todas
        .where((n) => n.id != null && inscritas.contains(n.id))
        .map((n) => Texto.normalizar(n.categoria))
        .where((c) => c.isNotEmpty)
        .toSet();

    final pontuadas = <MapEntry<NewsModel, int>>[];
    for (final item in todas) {
      final tipo = item.tag.toUpperCase();
      if (tipo != 'CAMPANHA' && tipo != 'ALERTA') continue;
      if (item.encerrada) continue;
      if (item.id != null && inscritas.contains(item.id)) continue;

      var pontos = tipo == 'CAMPANHA' ? 1 : 0;
      final naCidade = temCidade && Texto.contem(item.local, cidade);
      if (naCidade) pontos += 3;
      if (temasDeInteresse.contains(Texto.normalizar(item.categoria))) {
        pontos += 2;
      }
      // Alertas só entram quando são da cidade do usuário.
      if (tipo == 'ALERTA' && !naCidade) continue;
      pontuadas.add(MapEntry(item, pontos));
    }

    // Mais relevantes primeiro; em empate vale a ordem original (mais recentes).
    final indexadas = pontuadas.asMap().entries.toList()
      ..sort((a, b) {
        final porPontos = b.value.value.compareTo(a.value.value);
        return porPontos != 0 ? porPontos : a.key.compareTo(b.key);
      });
    return indexadas.map((e) => e.value.key).take(maximo).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchNotificacoes({
    bool forceRefresh = false,
  }) async {
    try {
      final dynamicList = await _fetchComunicacoes(
        forceRefresh: forceRefresh,
      );

      final notificacoes = dynamicList.map<Map<String, dynamic>>((item) {
        final tipo = (item['tipo'] ?? 'COMUNICACAO').toString().toUpperCase();
        final categoriaOriginal = (item['categoria'] ?? '').toString();
        final categoria = _normalizarCategoriaNotificacao(
          tipo,
          categoriaOriginal,
        );
        final dataBruta = (item['data_postada'] ?? item['dataPostada'] ?? '')
            .toString();
        final data = _normalizarDataIso(dataBruta);

        return {
          'id': (item['id'] ?? '${tipo}_${item['titulo'] ?? ''}_$data')
              .toString(),
          'titulo': (item['titulo'] ?? 'Notificação').toString(),
          'descricao': (item['descricao'] ?? 'Sem detalhes adicionais.')
              .toString(),
          'categoria': categoria,
          'data': data,
          'localizacao': (item['localizacao'] ?? '').toString(),
          'tipo': tipo,
        };
      }).toList();

      notificacoes.sort((a, b) {
        final dataA = DateTime.tryParse((a['data'] ?? '').toString());
        final dataB = DateTime.tryParse((b['data'] ?? '').toString());
        if (dataA == null && dataB == null) return 0;
        if (dataA == null) return 1;
        if (dataB == null) return -1;
        return dataB.compareTo(dataA);
      });

      return notificacoes;
    } catch (e) {
      developer.log('Erro ao buscar notificações: $e', name: 'ApiService');
      rethrow;
    }
  }

  static String _normalizarDataIso(String valor) {
    final v = valor.trim();
    if (v.isEmpty) return v;

    final normalized = v.replaceFirst(' ', 'T');
    final match = RegExp(
      r'^(.*\.)(\d+)(Z|[+-]\d{2}:?\d{2})?$',
    ).firstMatch(normalized);
    if (match == null) return normalized;

    final prefixo = match.group(1)!;
    final frac = match.group(2)!;
    final sufixo = match.group(3) ?? '';
    final frac6 = frac.length > 6 ? frac.substring(0, 6) : frac;
    return '$prefixo$frac6$sufixo';
  }

  static String _normalizarCategoriaNotificacao(
    String tipo,
    String categoriaOriginal,
  ) {
    final categoria = categoriaOriginal.toLowerCase();
    // O backend novo grava "Alerta"/"Campanha"; o antigo, "ALERTA"/"CAMPANHA"
    tipo = tipo.toUpperCase();
    if (tipo == 'ALERTA' ||
        categoria.contains('urg') ||
        categoria.contains('alert')) {
      return 'Urgentes';
    }
    if (categoria.contains('vacin')) {
      return 'Vacinação';
    }
    if (categoria.contains('doa') || categoria.contains('sangue')) {
      return 'Doações';
    }
    if (categoria.contains('evento')) {
      return 'Eventos';
    }
    if (tipo == 'CAMPANHA') {
      return 'Eventos';
    }
    return 'Todas';
  }

  /// Registra no histórico que a notícia foi compartilhada.
  static Future<void> trackNewsShare(
    NewsModel noticia, {
    String sharedBy = 'app_user',
  }) async {
    final usuarioId = _perfil?.id;
    if (usuarioId == null) return;
    try {
      final acao = 'Compartilhou "${noticia.titulo}"';
      await _db.from('logs_atividade').insert({
        'usuario_id': usuarioId,
        'acao': acao.length > 255 ? acao.substring(0, 255) : acao,
      });
    } catch (e) {
      developer.log(
        'Erro ao rastrear compartilhamento: $e',
        name: 'ApiService',
      );
    }
  }

  // ------------------------------------------------------------------
  // Dependentes
  // ------------------------------------------------------------------

  /// Mensagem do banco (regras de dependentes) sem o jargão técnico.
  static Exception _erroDoBanco(Object erro, String contexto) {
    if (erro is PostgrestException) {
      final negado =
          erro.code == '42501' ||
          erro.message.contains('row-level security');
      return Exception(
        negado ? '$contexto: operação não permitida.' : erro.message,
      );
    }
    return Exception('$contexto: $erro');
  }

  /// Dependentes da conta. Com [somenteAtivos], só os que já podem ser
  /// inscritos em campanhas (vínculo autorizado); sem ele, inclui os que
  /// aguardam a autorização do dependente adulto.
  static Future<List<DependenteModel>> fetchDependentes(
    int usuarioId, {
    bool somenteAtivos = false,
  }) async {
    var consulta = _db
        .from('dependentes')
        .select(
          'id, nome_completo, data_nascimento, parentesco, sexo, status, '
          'email_dependente, declarou_responsabilidade',
        )
        .eq('usuario_titular_id', usuarioId);
    consulta = somenteAtivos
        ? consulta.eq('status', 'ativo')
        : consulta.neq('status', 'revogado');

    final linhas = await consulta.order('nome_completo');
    return linhas
        .map((e) => DependenteModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Map<String, dynamic> _dependenteParaBanco(DependenteModel item) {
    final dados = item.toRequestMap();
    return {
      'nome_completo': dados['nomeCompleto'],
      'data_nascimento': dados['dataNascimento'],
      'parentesco': dados['parentesco'],
      'sexo': dados['sexo'],
    };
  }

  /// O banco decide a situação do vínculo: ativo (menor/tutelado, com a
  /// declaração do responsável) ou pendente (adulto, até ele autorizar).
  static Future<void> criarDependente(int usuarioId, DependenteModel item) async {
    try {
      await _db.from('dependentes').insert({
        'usuario_titular_id': usuarioId,
        ..._dependenteParaBanco(item),
        'email_dependente': item.emailDependente,
        'declarou_responsabilidade': item.declarouResponsabilidade,
      });
    } catch (e) {
      throw _erroDoBanco(e, 'Não foi possível cadastrar o dependente');
    }
  }

  static Future<void> atualizarDependente(int usuarioId, DependenteModel item) async {
    if (item.id == null) throw Exception('ID do dependente ausente.');
    try {
      await _db
          .from('dependentes')
          .update(_dependenteParaBanco(item))
          .eq('id', item.id!)
          .eq('usuario_titular_id', usuarioId);
    } catch (e) {
      throw _erroDoBanco(e, 'Não foi possível salvar o dependente');
    }
  }

  /// Pedidos para a conta logada ser dependente de alguém, e vínculos que
  /// ela já autorizou (para poder revogar).
  static Future<List<ConviteDependente>> fetchConvitesDeDependente() async {
    final linhas = await _db.rpc('meus_convites_de_dependente') as List;
    return linhas
        .map((e) => ConviteDependente.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// [acao]: `autorizar`, `recusar` (pedido pendente) ou `revogar` (vínculo ativo).
  static Future<void> responderConviteDeDependente(int id, String acao) async {
    try {
      await _db.rpc(
        'responder_convite_dependente',
        params: {'p_dependente_id': id, 'p_acao': acao},
      );
    } catch (e) {
      throw _erroDoBanco(e, 'Não foi possível registrar a resposta');
    }
  }

  /// Remoção lógica: o histórico de inscrições do dependente é preservado.
  static Future<void> excluirDependente(int usuarioId, int dependenteId) async {
    await _db
        .from('dependentes')
        .update({'ativo': false})
        .eq('id', dependenteId)
        .eq('usuario_titular_id', usuarioId);
  }

  // ------------------------------------------------------------------
  // Inscrições em campanhas
  // ------------------------------------------------------------------

  static Future<void> inscreverUsuarioEmCampanha({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  }) async {
    try {
      await _db.from('usuarios_campanhas').insert({
        'usuario_id': usuarioId,
        'comunicacao_id': comunicacaoId,
        'dependente_id': dependenteId,
        'notificacao_lida': false,
      });
    } on PostgrestException catch (e) {
      // 23505 = essa pessoa já estava inscrita: o resultado é o mesmo.
      if (e.code != '23505') {
        throw Exception('Falha ao inscrever em campanha: ${e.message}');
      }
    }

    _invalidarStatusInscricoes(usuarioId);
    _inscricoesController.add(null);
  }

  static Future<void> desinscreverUsuarioDaCampanha({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  }) async {
    try {
      final consulta = _db
          .from('usuarios_campanhas')
          .delete()
          .eq('usuario_id', usuarioId)
          .eq('comunicacao_id', comunicacaoId);
      // Sem dependente cancela só a inscrição do titular.
      await (dependenteId == null
          ? consulta.isFilter('dependente_id', null)
          : consulta.eq('dependente_id', dependenteId));
    } on PostgrestException catch (e) {
      throw Exception('Falha ao desinscrever da campanha: ${e.message}');
    }

    _invalidarStatusInscricoes(usuarioId);
    _inscricoesController.add(null);
  }

  /// Inscrições da conta logada, no formato usado pelas telas.
  /// `dependente_id` nulo significa inscrição do próprio titular.
  static Future<List<Map<String, dynamic>>> _fetchInscricoes({
    int? comunicacaoId,
  }) async {
    final usuarioId = _perfil?.id;
    if (usuarioId == null) return <Map<String, dynamic>>[];

    var consulta = _db
        .from('usuarios_campanhas')
        .select(
          'id, usuario_id, comunicacao_id, dependente_id, '
          'dependente:dependentes(nome_completo, parentesco)',
        )
        .eq('usuario_id', usuarioId);
    if (comunicacaoId != null) {
      consulta = consulta.eq('comunicacao_id', comunicacaoId);
    }

    final linhas = await consulta;
    return linhas.map<Map<String, dynamic>>((linha) {
      final dependente = linha['dependente'];
      return {
        'inscricao_id': linha['id'],
        'usuario_id': linha['usuario_id'],
        'comunicacao_id': linha['comunicacao_id'],
        'dependente_id': linha['dependente_id'],
        'participante_nome': dependente is Map
            ? dependente['nome_completo']
            : _perfil?.nome,
        'parentesco': dependente is Map ? dependente['parentesco'] : 'Titular',
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> fetchInscritosCampanha(
    int comunicacaoId,
  ) => _fetchInscricoes(comunicacaoId: comunicacaoId);

  static void _invalidarStatusInscricoes(int usuarioId) {
    _inscricoesUsuarioCache.remove(usuarioId);
  }

  /// IDs das campanhas em que a conta tem alguma inscrição (cache de 20 s).
  static Future<Set<int>?> _fetchIdsInscricoesUsuario(
    int usuarioId, {
    bool forceRefresh = false,
  }) async {
    final cached = _inscricoesUsuarioCache[usuarioId];
    if (!forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _inscricaoCacheTtl) {
      return Set<int>.from(cached.ids);
    }

    final ids = <int>{};
    for (final linha in await _fetchInscricoes()) {
      final id = linha['comunicacao_id'];
      if (id is num) ids.add(id.toInt());
    }
    _inscricoesUsuarioCache[usuarioId] = _CachedIds(
      Set<int>.from(ids),
      DateTime.now(),
    );
    return ids;
  }

  static Future<bool> isUsuarioInscritoEmCampanha({
    required int comunicacaoId,
    required int usuarioId,
    bool forceRefresh = false,
  }) async {
    final ids = await _fetchIdsInscricoesUsuario(
      usuarioId,
      forceRefresh: forceRefresh,
    );
    return ids?.contains(comunicacaoId) ?? false;
  }

  static DateTime? _parseDateFlexible(String value) {
    final texto = value.trim();
    if (texto.isEmpty) return null;
    if (texto.length >= 10) {
      final iso = texto.substring(0, 10);
      final parts = iso.split('-');
      if (parts.length == 3) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final d = int.tryParse(parts[2]);
        if (y != null && m != null && d != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return DateTime.tryParse(texto);
  }

  static Future<List<NewsModel>> fetchCampanhasAtivasDoUsuario(
    int usuarioId, {
    bool forceRefresh = false,
  }) async {
    try {
      final campanhas = await fetchNoticiasPorCategoria(
        4,
        forceRefresh: forceRefresh,
      );
      final hoje = DateTime.now();
      final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);

      final idsInscritas = await _fetchIdsInscricoesUsuario(
        usuarioId,
        forceRefresh: forceRefresh,
      );

      late final List<NewsModel> inscritas;
      if (idsInscritas != null) {
        // Caminho otimizado: a API retorna todas as inscrições em uma chamada.
        inscritas = campanhas.where((campanha) {
          if (campanha.id == null || !idsInscritas.contains(campanha.id)) {
            return false;
          }
          final fim = _parseDateFlexible(campanha.dataFim);
          return fim == null || !fim.isBefore(inicioHoje);
        }).toList();
      } else {
        // Compatibilidade com versões anteriores do backend.
        // As consultas são paralelas e compartilham cache por campanha.
        final resultados = await Future.wait(
          campanhas.map((campanha) async {
            if (campanha.id == null) return null;

            try {
              final inscrito = await isUsuarioInscritoEmCampanha(
                comunicacaoId: campanha.id!,
                usuarioId: usuarioId,
                forceRefresh: forceRefresh,
              );
              if (!inscrito) return null;

              final fim = _parseDateFlexible(campanha.dataFim);
              if (fim != null && fim.isBefore(inicioHoje)) return null;
              return campanha;
            } catch (e) {
              developer.log(
                'Erro ao verificar inscrição da campanha ${campanha.id}: $e',
                name: 'ApiService',
              );
              return null;
            }
          }),
        );

        inscritas = resultados.whereType<NewsModel>().toList();
      }

      inscritas.sort((a, b) {
        final dataA = _parseDateFlexible(a.dataFim) ?? DateTime(9999, 12, 31);
        final dataB = _parseDateFlexible(b.dataFim) ?? DateTime(9999, 12, 31);
        return dataA.compareTo(dataB);
      });

      return inscritas;
    } catch (e) {
      developer.log(
        'Falha ao carregar campanhas ativas: $e',
        name: 'ApiService',
      );
      return <NewsModel>[];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchLembretesCampanhaUmDiaAntes(
    int usuarioId, {
    bool forceRefresh = false,
  }) async {
    try {
      final campanhas = await fetchCampanhasAtivasDoUsuario(
        usuarioId,
        forceRefresh: forceRefresh,
      );
      final hoje = DateTime.now();
      final amanha = DateTime(
        hoje.year,
        hoje.month,
        hoje.day,
      ).add(const Duration(days: 1));

      final lembretes = <Map<String, dynamic>>[];

      for (final campanha in campanhas) {
        final fim = _parseDateFlexible(campanha.dataFim);
        if (fim == null) continue;

        final fimDia = DateTime(fim.year, fim.month, fim.day);
        if (fimDia.year == amanha.year &&
            fimDia.month == amanha.month &&
            fimDia.day == amanha.day) {
          lembretes.add({
            'id':
                'fim_campanha_${campanha.id ?? campanha.titulo}_${campanha.dataFim}',
            'titulo': 'Campanha termina amanhã',
            'descricao':
                'A campanha "${campanha.titulo}" encerra em breve. Confira os detalhes.',
            'categoria': 'Urgentes',
            'data': campanha.dataFim,
            'localizacao': campanha.local,
            'tipo': 'CAMPANHA',
          });
        }
      }

      return lembretes;
    } catch (e) {
      developer.log(
        'Falha ao montar lembretes de campanha: $e',
        name: 'ApiService',
      );
      return <Map<String, dynamic>>[];
    }
  }

  static Future<String?> fetchCidadeFromCoords(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=pt',
      );
      final response = await _httpClient.get(
        uri,
        headers: {'User-Agent': 'ConectaVidaApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          return address['city'] as String? ??
              address['town'] as String? ??
              address['municipality'] as String? ??
              address['county'] as String?;
        }
      }
    } catch (e) {
      developer.log('Erro no reverse geocoding: $e', name: 'ApiService');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchMinhasInscricoes() =>
      _fetchInscricoes();
}

class _CachedIds {
  const _CachedIds(this.ids, this.cachedAt);

  final Set<int> ids;
  final DateTime cachedAt;
}
