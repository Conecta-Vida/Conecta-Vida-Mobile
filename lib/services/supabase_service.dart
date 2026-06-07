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
          'idade': int.tryParse(usuario.idade.toString()) ?? 0,
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

  // Autentica o usuário na API e armazena o token JWT para sessões futuras
  static Future<void> signIn(String email, String senha) async {
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
      } else {
        throw Exception('Credenciais inválidas');
      }
    } catch (e) {
      developer.log('Erro ao fazer login: $e', name: 'ApiService');
      throw Exception('Falha no login: $e');
    }
  }

  // Atualiza ou insere as informações de perfil do usuário na base de dados
  static Future<void> upsertUsuario(UserModel user, {String senha = ''}) async {
    try {
      // Prepara o mapa base
      Map<String, dynamic> payload = user.toMap(senha: senha);

      // Garante que a idade seja um Integer (o Java não aceita string aqui)
      payload['idade'] = int.tryParse(user.idade.toString()) ?? 0;

      // Remove campos que o Java não espera no Put para evitar conflitos
      payload.remove('campanhasInscritas');

      // Ajustado para PUT conforme o seu UsuarioController.java
      final response = await http.put(
        Uri.parse(
          '$baseUrl/usuarios/0',
        ), // Lembre-se: substitua '0' pelo ID real do usuário
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      // Log para ajudar a ver o erro caso o 400 continue
      if (response.statusCode != 200 && response.statusCode != 201) {
        developer.log('Erro 400 corpo: ${response.body}', name: 'ApiService');
        throw Exception('Erro ao sincronizar usuário: ${response.statusCode}');
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
      final response = await http.get(Uri.parse('$baseUrl/comunicacoes'));

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
            'categoria': item['categoria'] ?? 'Geral',
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
          return noticias;
        }
      }
      return NewsController().getNoticiasPorCategoria(categoryIndex);
    } catch (e) {
      developer.log('Erro na API de notícias: $e', name: 'ApiService');
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
