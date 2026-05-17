// ===== EXEMPLO DE ATUALIZAÇÃO PARA main.dart =====
// Copie e adapteo seu arquivo conforme abaixo

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'global/appCor.dart';
import 'screens/splash_screen.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Carregar variáveis de ambiente do arquivo .env
  try {
    await dotenv.load();
    print('✓ Variáveis de ambiente carregadas com sucesso');
  } catch (e) {
    print('⚠️ Aviso: Não foi possível carregar .env: $e');
    // Continuará mesmo sem o arquivo .env (útil para produção)
  }

  // 2. Obter credenciais do .env
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
        'Erro: Variáveis SUPABASE_URL e SUPABASE_ANON_KEY não configuradas no .env');
  }

  // 3. Inicializar Supabase
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    print('✓ Supabase inicializado com sucesso');
  } catch (e) {
    print('❌ Erro ao inicializar Supabase: $e');
    rethrow;
  }

  // 4. Passar credenciais para o serviço
  await SupabaseService.initializeCredentials(supabaseUrl, supabaseAnonKey);

  // 5. Sincronizar dados padrão
  try {
    await SupabaseService.syncDefaultNoticias();
    print('✓ Noticias sincronizadas');
  } catch (e) {
    print('⚠️ Erro ao sincronizar noticias: $e');
    // Continua mesmo se falhar (fallback para dados locais)
  }

  runApp(const ConectaVidaApp());
}

class ConectaVidaApp extends StatelessWidget {
  const ConectaVidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Conecta Vida',
      theme: ThemeData(
        scaffoldBackgroundColor: AppCor.background,
        colorScheme: const ColorScheme.light(
          // ... resto da sua configuração
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
