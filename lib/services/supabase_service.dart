import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../controllers/noticia_controller.dart';

class SupabaseService {
  // IMPORTANTE:
  // Se rodar no Emulador Android, use 'http://10.0.2.2:8080/api'
  // Se rodar no Chrome (Web), use 'http://localhost:8080/api'
  static String baseUrl = 'http://localhost:8080/api';
  static String? jwtToken;

  // Mantém a compatibilidade de inicialização de credenciais com as chamadas antigas do main
  static Future<void> initializeCredentials(String url, String anonKey) async {
    final envBaseUrl = dotenv.env['API_BASE_URL']?.trim();

    if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
      baseUrl = envBaseUrl;
      return;
    }

    // Compatibilidade: só reaproveita o parâmetro url se apontar para endpoint HTTP da API
    if (url.startsWith('http') && url.contains('/api')) {
      baseUrl = url;
    }
  }

  static Future<void> init() async {}
  static Future<void> syncDefaultNoticias() async {}

  // Registra um novo cidadão no sistema enviando os dados obrigatórios para a API
  static Future<void> signUp(UserModel usuario, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': usuario.nome.trim(),
          'email': usuario.email.trim(),
          'senha': senha.trim(),
          'data_nascimento':
              int.tryParse(usuario.dataNascimento.toString()) ?? 0,
          'sexo': usuario.sexo,
          'localizacao':
              usuario.localizacao, // As coordenadas vêm pra cá direto!
          'permissao': 'Usuário Comum',
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        developer.log('Erro do Servidor: ${response.body}', name: 'ApiService');
        throw Exception(
          'Erro REAL da API (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Falha no cadastro: $e');
    }
  }

  // Autentica o usuário na API e retorna os dados do usuário logado
  static Future<UserModel> signIn(String email, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('token')) {
          jwtToken = data['token'];
        }
        //retorna dados do usuario pro mobile
        return UserModel(
          id: data['id'],
          nome: data['nome'] ?? email.split('@').first,
          email: data['email'] ?? email,
          dataNascimento: data['data_nascimento'] is int
              ? data['data_nascimento']
              : null,
          sexo: data['sexo'] ?? 'Não informado',
          localizacao: data['localizacao'] ?? 'Não informado',
        );
      } else {
        throw Exception(
          'Erro REAL da API (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      developer.log('Erro ao fazer login: $e', name: 'ApiService');
      rethrow;
    }
  }

  // Faz o logout limpando o token da memória
  static void signOut() {
    jwtToken = null;
    developer.log('Usuário deslogado com sucesso.', name: 'ApiService');
  }

  // Deleta a conta do usuário na API
  static Future<void> deleteUsuario(String email) async {
    try {
      final userCompleto = await fetchUsuarioByEmail(email);
      if (userCompleto == null || userCompleto.id == null) {
        throw Exception("Usuário não encontrado para exclusão.");
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/usuarios/${userCompleto.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Erro ao deletar conta. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      developer.log('Erro ao deletar conta: $e', name: 'ApiService');
      rethrow;
    }
  }

  // Atualiza ou insere as informações de perfil do usuário na base de dados
  static Future<void> upsertUsuario(UserModel user, {String senha = ''}) async {
    try {
      if (user.id == null) {
        throw Exception("ID não encontrado. Faça login novamente.");
      }

      Map<String, dynamic> payload = user.toMap(senha: senha);
      payload['idade'] = int.tryParse(user.dataNascimento.toString()) ?? 0;
      payload.remove('campanhasInscritas');

      // Substituído o '0' pelo ID real do usuário:
      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/${user.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erro ao atualizar dados: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Erro ao sincronizar usuario: $e', name: 'ApiService');
      rethrow;
    }
  }

  // Busca todos os dados cadastrais de um usuário específico utilizando seu e-mail
  static Future<UserModel?> fetchUsuarioByEmail(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios/email/$email'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        data['idade'] = data['idade']?.toString() ?? '';
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      developer.log('Erro ao buscar usuario: $e', name: 'ApiService');
      return null;
    }
  }

  // Recupera as comunicações da API e as converte no formato de notícias lido pelo aplicativo
  static Future<List<NewsModel>> fetchNoticiasPorCategoria(
    int categoryIndex,
  ) async {
    try {
      developer.log(
        'A tentar buscar notícias reais da API...',
        name: 'ApiService',
      );

      final response = await http.get(
        Uri.parse('$baseUrl/comunicacoes'),
        headers: {
          'Content-Type': 'application/json',
          // Se existir um token de login, envia para o Java autorizar a busca!
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode == 200) {
        final List dynamicList = jsonDecode(response.body);

        var noticias = dynamicList.map((item) {
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
            'local': item['localizacao'] ?? 'Região Geral',
            'publicoAlvo':
                item['publico_alvo'] ?? item['publicoAlvo'] ?? 'População',
            'orgao': item['instituicao'] != null
                ? item['instituicao']['nome']
                : 'Secretaria de Saúde',
          });
        }).toList();

        if (categoryIndex == 0) {
          // Todas as notícias
          noticias = noticias
              .where((n) => n.tag.toUpperCase() == 'NOTICIA')
              .toList();
        } else if (categoryIndex == 1) {
          // Vacinações
          noticias = noticias
              .where(
                (n) =>
                    n.tag.toUpperCase() == 'CAMPANHA' &&
                    n.categoria.toLowerCase().contains('vacina'),
              )
              .toList();
        } else if (categoryIndex == 2) {
          // Doações de sangue
          noticias = noticias
              .where(
                (n) =>
                    n.tag.toUpperCase() == 'CAMPANHA' &&
                    n.categoria.toLowerCase().contains('doa'),
              )
              .toList();
        } else if (categoryIndex == 3) {
          // Alertas
          noticias = noticias
              .where((n) => n.tag.toUpperCase() == 'ALERTA')
              .toList();
        } else if (categoryIndex == 4) {
          //Todas as Campanhas
          noticias = noticias
              .where((n) => n.tag.toUpperCase() == 'CAMPANHA')
              .toList();
        }

        //ordena do mais recente pro mais antigo as noticias
        noticias.sort((a, b) => b.data.compareTo(a.data));

        developer.log(
          'Sucesso! Notícias filtradas carregadas.',
          name: 'ApiService',
        );

        return noticias;
      } else {
        // AVISO DE ERRO CRÍTICO AQUI!
        developer.log(
          '🚨 API RECUSOU DAR AS NOTÍCIAS. Status: ${response.statusCode}',
          name: 'ApiService',
        );
      }

      return NewsController().getNoticiasPorCategoria(categoryIndex);
    } catch (e) {
      developer.log(
        '🚨 ERRO FATAL DE CONEXÃO NAS NOTÍCIAS: $e',
        name: 'ApiService',
      );
      return NewsController().getNoticiasPorCategoria(categoryIndex);
    }
  }

  // Recupera notificações dinâmicas da API para alimentar a tela de notificações
  static Future<List<Map<String, dynamic>>> fetchNotificacoes() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/comunicacoes'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao carregar notificações: ${response.statusCode}',
        );
      }

      final List<dynamic> dynamicList = jsonDecode(response.body);

      final notificacoes = dynamicList.map((item) {
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

  // Alguns bancos retornam nanossegundos com mais de 6 casas; o parser do Dart
  // pode falhar. Esta normalização mantém o formato ISO parseável.
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

  // Aciona o fluxo de recuperação de senha enviando um e-mail com as instruções
  static Future<void> resetPassword(String email) async {
    final emailLimpo = email.trim();
    if (emailLimpo.isEmpty) {
      throw Exception('Informe um e-mail válido para recuperação.');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailLimpo}),
      );

      if (response.statusCode == 200) {
        return;
      }

      final body = jsonDecode(response.body);
      throw Exception(
        body['mensagem'] ?? 'Falha ao solicitar recuperação de senha.',
      );
    } catch (e) {
      developer.log('Erro no reset de senha: $e', name: 'ApiService');
      rethrow;
    }
  }

  // Salva no backend o registro de que uma notícia foi compartilhada pelo usuário
  static Future<void> trackNewsShare(
    NewsModel noticia, {
    String sharedBy = 'app_user',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comunicacoes/compartilhamentos'),
        headers: {
          'Content-Type': 'application/json',
          if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({
          'titulo': noticia.titulo,
          'categoria': noticia.categoria,
          'localizacao': noticia.local,
          'sharedBy': sharedBy,
          'data': noticia.data,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        developer.log(
          'Falha ao registrar compartilhamento. Status: ${response.statusCode}',
          name: 'ApiService',
        );
      }
    } catch (e) {
      developer.log(
        'Erro ao rastrear compartilhamento: $e',
        name: 'ApiService',
      );
    }
  }

  // Inscreve usuário em uma campanha (também usada para "adicionar ao calendário")
  static Future<void> inscreverUsuarioEmCampanha({
    required int comunicacaoId,
    required int usuarioId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/campanhas/$comunicacaoId/inscrever'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'usuario_id': usuarioId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      String detalhe = '';
      try {
        final body = jsonDecode(response.body);
        detalhe = (body is Map && body['mensagem'] != null)
            ? body['mensagem'].toString()
            : response.body;
      } catch (_) {
        detalhe = response.body;
      }
      throw Exception(
        'Falha ao inscrever em campanha (${response.statusCode}): $detalhe',
      );
    }
  }

  // Remove vínculo usuário-campanha
  static Future<void> desinscreverUsuarioDaCampanha({
    required int comunicacaoId,
    required int usuarioId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/campanhas/$comunicacaoId/desinscrever'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode({'usuario_id': usuarioId}),
    );

    if (response.statusCode != 200) {
      String detalhe = '';
      try {
        final body = jsonDecode(response.body);
        detalhe = (body is Map && body['mensagem'] != null)
            ? body['mensagem'].toString()
            : response.body;
      } catch (_) {
        detalhe = response.body;
      }
      throw Exception(
        'Falha ao desinscrever da campanha (${response.statusCode}): $detalhe',
      );
    }
  }

  // Lista inscritos de uma campanha específica
  static Future<List<Map<String, dynamic>>> fetchInscritosCampanha(
    int comunicacaoId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/campanhas/$comunicacaoId/inscritos'),
      headers: {
        'Content-Type': 'application/json',
        if (jwtToken != null) 'Authorization': 'Bearer $jwtToken',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao buscar inscritos: ${response.statusCode}');
    }

    final body = jsonDecode(response.body);

    // Compatibilidade com formatos de resposta diferentes do backend.
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (body is Map<String, dynamic>) {
      final inscritos = body['inscritos'];
      if (inscritos is List) {
        return inscritos
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      // Alguns endpoints podem devolver uma lista em outro campo.
      final candidatosLista = body.values.whereType<List>();
      if (candidatosLista.isNotEmpty) {
        final primeiraLista = candidatosLista.first;
        return primeiraLista
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return <Map<String, dynamic>>[];
  }

  static Future<bool> isUsuarioInscritoEmCampanha({
    required int comunicacaoId,
    required int usuarioId,
  }) async {
    final inscritos = await fetchInscritosCampanha(comunicacaoId);
    return inscritos.any((i) => (i['usuario_id'] ?? -1) == usuarioId);
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

  // Campanhas ativas do usuário, ordenadas por fim mais próximo primeiro
  static Future<List<NewsModel>> fetchCampanhasAtivasDoUsuario(
    int usuarioId,
  ) async {
    try {
      final campanhas = await fetchNoticiasPorCategoria(4);
      final List<NewsModel> inscritas = [];
      final hoje = DateTime.now();
      final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);

      for (final campanha in campanhas) {
        if (campanha.id == null) continue;

        bool inscrito;
        try {
          inscrito = await isUsuarioInscritoEmCampanha(
            comunicacaoId: campanha.id!,
            usuarioId: usuarioId,
          );
        } catch (e) {
          developer.log(
            'Erro ao verificar inscrição da campanha ${campanha.id}: $e',
            name: 'ApiService',
          );
          continue;
        }
        if (!inscrito) continue;

        final fim = _parseDateFlexible(campanha.dataFim);
        if (fim != null && fim.isBefore(inicioHoje)) continue;

        inscritas.add(campanha);
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

  // Gera notificações (in-app) para campanhas que acabam amanhã
  static Future<List<Map<String, dynamic>>> fetchLembretesCampanhaUmDiaAntes(
    int usuarioId,
  ) async {
    try {
      // <-- FALTAVA ESTE TRY
      final campanhas = await fetchCampanhasAtivasDoUsuario(usuarioId);
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

  // Converte coordenadas GPS em nome de cidade usando Nominatim (OpenStreetMap)
  static Future<String?> fetchCidadeFromCoords(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&accept-language=pt',
      );
      final response = await http.get(
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
}
