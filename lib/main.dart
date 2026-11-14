import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'accessibility/accessibility_provider.dart';
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

  SupabaseService.baseUrl = ApiConfig.resolverBaseUrl();
  debugPrint('🌐 API: ${SupabaseService.baseUrl}');

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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(
          create: (_) => AccessibilityProvider(Hive.box('preferencias')),
        ),
      ],
      child: const ConectaVidaApp(),
    ),
  );
}

class ConectaVidaApp extends StatelessWidget {
  const ConectaVidaApp({super.key});

  TextTheme _withHeavierWeights(TextTheme textTheme) {
    const weights = <FontWeight>[
      FontWeight.w100,
      FontWeight.w200,
      FontWeight.w300,
      FontWeight.w400,
      FontWeight.w500,
      FontWeight.w600,
      FontWeight.w700,
      FontWeight.w800,
      FontWeight.w900,
    ];

    TextStyle? heavier(TextStyle? style) {
      if (style == null) return null;
      final current = style.fontWeight ?? FontWeight.w400;
      final index = weights.indexOf(current);
      final nextIndex = (index < 0 ? 3 : index + 1)
          .clamp(0, weights.length - 1)
          .toInt();
      return style.copyWith(fontWeight: weights[nextIndex]);
    }

    return textTheme.copyWith(
      displayLarge: heavier(textTheme.displayLarge),
      displayMedium: heavier(textTheme.displayMedium),
      displaySmall: heavier(textTheme.displaySmall),
      headlineLarge: heavier(textTheme.headlineLarge),
      headlineMedium: heavier(textTheme.headlineMedium),
      headlineSmall: heavier(textTheme.headlineSmall),
      titleLarge: heavier(textTheme.titleLarge),
      titleMedium: heavier(textTheme.titleMedium),
      titleSmall: heavier(textTheme.titleSmall),
      bodyLarge: heavier(textTheme.bodyLarge),
      bodyMedium: heavier(textTheme.bodyMedium),
      bodySmall: heavier(textTheme.bodySmall),
      labelLarge: heavier(textTheme.labelLarge),
      labelMedium: heavier(textTheme.labelMedium),
      labelSmall: heavier(textTheme.labelSmall),
    );
  }

  ThemeData _buildTheme({
    required Brightness brightness,
    required AccessibilityProvider preferences,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppCor.primary,
      brightness: brightness,
      contrastLevel: preferences.highContrast ? 1.0 : 0.0,
    ).copyWith(error: AppCor.error);

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: brightness == Brightness.dark
          ? const Color(0xFF121212)
          : AppCor.background,
      fontFamily: preferences.fontFamily == 'serif' ? 'serif' : null,
    );

    return base.copyWith(
      textTheme: preferences.boldText
          ? _withHeavierWeights(
              base.textTheme.apply(
                fontFamily:
                    preferences.fontFamily == 'serif' ? 'serif' : null,
              ),
            )
          : base.textTheme.apply(
              fontFamily:
                  preferences.fontFamily == 'serif' ? 'serif' : null,
            ),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFF1E1E1E)
            : Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: brightness == Brightness.dark
            ? Colors.white
            : AppCor.textoPrimario,
        titleTextStyle: TextStyle(
          color: brightness == Brightness.dark
              ? Colors.white
              : AppCor.textoPrimario,
          fontSize: 20,
          fontWeight: preferences.boldText
              ? FontWeight.w800
              : FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppCor.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconTheme: IconThemeData(
        color: brightness == Brightness.dark
            ? Colors.white70
            : AppCor.textoCinza,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccessibilityProvider>(
      builder: (context, preferences, _) {
        final lightTheme = _buildTheme(
          brightness: Brightness.light,
          preferences: preferences,
        );
        final darkTheme = _buildTheme(
          brightness: Brightness.dark,
          preferences: preferences,
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Conecta Vida',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: preferences.darkMode ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) {
            final media = MediaQuery.of(context);
            final systemScale = media.textScaler.scale(1.0);
            return MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  systemScale * preferences.fontScale,
                ),
                boldText: preferences.boldText || media.boldText,
                highContrast: preferences.highContrast || media.highContrast,
                // Componentes próprios podem consultar esta preferência.
                // Animações internas do framework continuam respeitando a
                // configuração de acessibilidade do sistema operacional.
                disableAnimations:
                    preferences.reduceMotion || media.disableAnimations,
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}
