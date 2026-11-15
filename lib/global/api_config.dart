import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Lê a configuração pública do aplicativo.
///
/// Prioridade de cada valor:
/// 1. --dart-define=NOME=valor (no build)
/// 2. NOME em assets/config/app.env
/// 3. padrão embutido no código
///
/// Nada aqui é segredo: a chave do Supabase é a "publishable", feita para
/// ficar no aplicativo. Os dados são protegidos pelas regras do banco.
class ApiConfig {
  static const String _urlNoBuild = String.fromEnvironment('SUPABASE_URL');
  static const String _chaveNoBuild = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const String _resetNoBuild = String.fromEnvironment(
    'PASSWORD_RESET_URL',
  );

  static String? _doEnv(String nome) {
    if (!dotenv.isInitialized) return null;
    final valor = dotenv.env[nome]?.trim();
    return (valor == null || valor.isEmpty) ? null : valor;
  }

  static String supabaseUrl(String padrao) =>
      _urlNoBuild.isNotEmpty ? _urlNoBuild : (_doEnv('SUPABASE_URL') ?? padrao);

  static String supabaseKey(String padrao) => _chaveNoBuild.isNotEmpty
      ? _chaveNoBuild
      : (_doEnv('SUPABASE_PUBLISHABLE_KEY') ?? padrao);

  /// Página que recebe o link do e-mail de recuperação de senha.
  static String urlRedefinirSenha() =>
      _resetNoBuild.isNotEmpty ? _resetNoBuild : (_doEnv('PASSWORD_RESET_URL') ?? '');
}
