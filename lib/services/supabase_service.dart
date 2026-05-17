import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../controllers/noticia_controller.dart';
import 'dart:developer' as developer;

class SupabaseService {
  // Credenciais carregadas do .env (via flutter_dotenv)
  // Use: flutter_dotenv para carregar variáveis de ambiente
  static late String supabaseUrl;
  static late String supabaseAnonKey;

  // Inicializa as credenciais (chame isso antes de usar)
  static Future<void> initializeCredentials(String url, String anonKey) async {
    supabaseUrl = url;
    supabaseAnonKey = anonKey;
  }

  static Future<void> init() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  static Future<void> syncDefaultNoticias() async {
    try {
      final data = await Supabase.instance.client
          .from('noticias')
          .select('id')
          .limit(1);

      if (data.isNotEmpty) {
        developer.log('Noticias já existem no banco');
        return;
      }

      final noticias = NewsController().getAllNoticias();
      if (noticias.isEmpty) {
        developer.log('Nenhuma noticia para sincronizar');
        return;
      }

      final insertPayload = noticias.map((n) => n.toMap()).toList();

      final insertResponse = await Supabase.instance.client
          .from('noticias')
          .insert(insertPayload);

      developer.log(
        'Noticias sincronizadas com sucesso: ${insertResponse.length} registros',
      );
    } catch (e) {
      developer.log(
        'Erro ao sincronizar noticias: $e',
        name: 'SupabaseService',
      );
      rethrow;
    }
  }

  static Future<void> upsertUsuario(UserModel user, {String senha = ''}) async {
    try {
      final payload = user.toMap(senha: senha);

      await Supabase.instance.client
          .from('usuarios')
          .upsert(payload, onConflict: 'email');

      developer.log(
        'Usuario ${user.email} sincronizado com sucesso',
        name: 'SupabaseService',
      );
    } catch (e) {
      developer.log(
        'Erro ao sincronizar usuario ${user.email}: $e',
        name: 'SupabaseService',
      );
      rethrow;
    }
  }

  static Future<UserModel?> fetchUsuarioByEmail(String email) async {
    try {
      final response = await Supabase.instance.client
          .from('usuarios')
          .select()
          .eq('email', email)
          .single();

      if (response.data == null) {
        developer.log(
          'Usuario com email $email nao encontrado',
          name: 'SupabaseService',
        );
        return null;
      }

      return UserModel.fromMap(response.data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        // Sem resultados encontrados
        developer.log(
          'Usuario com email $email nao existe',
          name: 'SupabaseService',
        );
        return null;
      }
      developer.log(
        'Erro ao buscar usuario $email: $e',
        name: 'SupabaseService',
      );
      return null;
    } catch (e) {
      developer.log(
        'Erro inesperado ao buscar usuario $email: $e',
        name: 'SupabaseService',
      );
      return null;
    }
  }

  static Future<void> signUp(String email, String senha) async {
    try {
      await Supabase.instance.client.auth.signUp(email: email, password: senha);
      developer.log(
        'Usuario $email registrado com sucesso',
        name: 'SupabaseService',
      );
    } on AuthException catch (e) {
      developer.log(
        'Erro de autenticacao ao registrar: ${e.message}',
        name: 'SupabaseService',
      );
      throw Exception('Falha no cadastro: ${e.message}');
    } catch (error) {
      developer.log(
        'Erro ao registrar usuario: $error',
        name: 'SupabaseService',
      );
      throw Exception('Falha no cadastro: $error');
    }
  }

  static Future<void> signIn(String email, String senha) async {
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: senha,
      );
      developer.log(
        'Usuario $email autenticado com sucesso',
        name: 'SupabaseService',
      );
    } on AuthException catch (e) {
      developer.log(
        'Erro de autenticacao ao fazer login: ${e.message}',
        name: 'SupabaseService',
      );
      throw Exception('Falha no login: ${e.message}');
    } catch (error) {
      developer.log('Erro ao fazer login: $error', name: 'SupabaseService');
      throw Exception('Falha no login: $error');
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      developer.log(
        'Email de recuperacao enviado para $email',
        name: 'SupabaseService',
      );
    } on AuthException catch (e) {
      developer.log(
        'Erro ao enviar email de recuperacao: ${e.message}',
        name: 'SupabaseService',
      );
      throw Exception('Falha ao enviar email de recuperacao: ${e.message}');
    } catch (error) {
      developer.log(
        'Erro ao enviar email de recuperacao: $error',
        name: 'SupabaseService',
      );
      throw Exception('Falha ao enviar email de recuperacao: $error');
    }
  }

  static Future<List<NewsModel>> fetchNoticiasPorCategoria(
    int categoryIndex,
  ) async {
    final categoria = _categoriaPorIndex(categoryIndex);
    try {
      PostgrestFilterBuilder query = Supabase.instance.client
          .from('noticias')
          .select();

      if (categoria != null) {
        query = query.eq('categoria', categoria);
      }

      final response = await query.order('data', ascending: false);

      if (response.data == null ||
          (response.data is List && (response.data as List).isEmpty)) {
        developer.log(
          'Nenhuma noticia encontrada para categoria: $categoria',
          name: 'SupabaseService',
        );
        return NewsController().getNoticiasPorCategoria(categoryIndex);
      }

      return (response.data as List<dynamic>)
          .map((item) => NewsModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log(
        'Erro ao buscar noticias da categoria $categoria: $e',
        name: 'SupabaseService',
      );
      return NewsController().getNoticiasPorCategoria(categoryIndex);
    }
  }

  static Future<void> trackNewsShare(
    NewsModel noticia, {
    String sharedBy = 'app_user',
  }) async {
    try {
      await Supabase.instance.client.from('noticias_compartilhadas').insert({
        'titulo': noticia.titulo,
        'categoria': noticia.categoria,
        'orgao': noticia.orgao,
        'shared_by': sharedBy,
        'shared_at': DateTime.now().toIso8601String(),
      });
      developer.log(
        'Compartilhamento de noticia rastreado: ${noticia.titulo}',
        name: 'SupabaseService',
      );
    } on PostgrestException catch (e) {
      // Tabela pode nao existir ainda
      developer.log(
        'Erro ao rastrear compartilhamento: ${e.message}',
        name: 'SupabaseService',
      );
    } catch (e) {
      developer.log(
        'Erro ao rastrear compartilhamento: $e',
        name: 'SupabaseService',
      );
    }
  }

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
