import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'global/api_config.dart';
import 'global/appCor.dart';
import 'providers/usuario_provider.dart';
import 'screens/splash_screen.dart';
import 'services/push_notification_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Hive.initFlutter();
    await Hive.openBox('preferencias');
    await dotenv.load(fileName: "assets/config/app.env", isOptional: true);
  } catch (e) {
    debugPrint('⚠️ Configurações locais não carregadas: $e');
  }

  // No navegador, /api usa a mesma origem e pode ser encaminhado pelo Nginx.
  // Durante o desenvolvimento local, informe a URL da API com --dart-define.
  SupabaseService.baseUrl = ApiConfig.resolverBaseUrl();
  debugPrint('🌐 API: ${SupabaseService.baseUrl}');

  // Firebase Messaging e flutter_local_notifications ficam restritos às
  // plataformas nativas. O app Web continua utilizável sem push.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      await PushNotificationService.inicializar(
        apiBaseUrl: SupabaseService.baseUrl,
      );
    } catch (e) {
      debugPrint('⚠️ Push notifications indisponíveis: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => UsuarioProvider(),
      child: const ConectaVidaApp(),
    ),
  );
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
          primary: AppCor.primary,
          secondary: AppCor.secondary,
          error: AppCor.error,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppCor.textoPrimario),
          titleTextStyle: TextStyle(
            color: AppCor.textoPrimario,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppCor.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: AppCor.textoCinza),
      ),
      home: const SplashScreen(),
    );
  }
}
