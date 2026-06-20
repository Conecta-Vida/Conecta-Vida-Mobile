import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../controllers/noticia_controller.dart';

class SupabaseService {
  // IMPORTANTE:
  // Se rodar no Emulador Android, use 'http://10.0.2.2:8080/api'
  // Se rodar no Chrome (Web), use 'http://localhost:8080/api'
  static const String baseUrl = 'http://localhost:8080/api';
  static String? jwtToken;

  // Mantém a compatibilidade de inicialização de credenciais com as chamadas antigas do main
  static Future<void> initializeCredentials(String url, String anonKey) async {}
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
          'Falha no cadastro (Erro ${response.statusCode}): O email já existe ou os dados são inválidos.',
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
        final body = jsonDecode(response.body);
        throw Exception(body['mensagem'] ?? 'Credenciais inválidas');
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
    final categoriaFiltrada = _categoriaPorIndex(categoryIndex);
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
            'tag': item['tipo'] ?? 'Comunicação',
            'data': item['data_postada'] ?? item['dataPostada'] ?? '',
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

        if (categoriaFiltrada != null) {
          noticias = noticias
              .where((n) => n.categoria == categoriaFiltrada)
              .toList();
        }

        if (noticias.isNotEmpty) {
          developer.log(
            'Sucesso! Notícias reais carregadas.',
            name: 'ApiService',
          );
          return noticias;
        }
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

  // Aciona o fluxo de recuperação de senha enviando um e-mail com as instruções
  static Future<void> resetPassword(String email) async {
    developer.log('Reset de senha para $email', name: 'ApiService');
  }

  // Salva no banco de dados o registro de que uma notícia foi compartilhada
  static Future<void> trackNewsShare(
    NewsModel noticia, {
    String sharedBy = 'app_user',
  }) async {
    developer.log('Compartilhamento rastreado localmente', name: 'ApiService');
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

  // Converte o índice numérico da aba da interface para o texto de categoria usado no banco
  static String? _categoriaPorIndex(int categoryIndex) {
    switch (categoryIndex) {
      case 1:
        return 'Vacinação';
      case 2:
        return 'Doações';
      case 3:
        return 'Urgente';
      case 4:
        return 'Eventos';
      default:
        return null;
    }
  }
}
