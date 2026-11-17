import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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

  SupabaseService.supabaseUrl = ApiConfig.supabaseUrl(
    SupabaseService.supabaseUrl,
  );
  SupabaseService.supabaseKey = ApiConfig.supabaseKey(
    SupabaseService.supabaseKey,
  );
  SupabaseService.urlRedefinirSenha = ApiConfig.urlRedefinirSenha();
  SupabaseService.urlEmailConfirmado = ApiConfig.urlEmailConfirmado();
  await SupabaseService.init();
  debugPrint('🌐 Supabase: ${SupabaseService.supabaseUrl}');

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

  // Notificações locais (alertas novos chegam em tempo real pelo Supabase).
  // Não atrasam o primeiro frame do aplicativo.
  if (!kIsWeb) {
    unawaited(_inicializarNotificacoesPush());
  }
}

Future<void> _inicializarNotificacoesPush() async {
  try {
    await PushNotificationService.inicializar();
  } catch (e) {
    debugPrint('⚠️ Notificações indisponíveis: $e');
  }
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
    // "fidelity" mantém o azul da marca vivo em todas as telas (o padrão do
    // Material 3 deixava botões e cartões num roxo acinzentado).
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppCor.primary,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      contrastLevel: preferences.highContrast ? 1.0 : 0.0,
    ).copyWith(error: AppCor.error);
    final escuro = brightness == Brightness.dark;

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
                fontFamily: preferences.fontFamily == 'serif' ? 'serif' : null,
              ),
            )
          : base.textTheme.apply(
              fontFamily: preferences.fontFamily == 'serif' ? 'serif' : null,
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
          fontWeight: preferences.boldText ? FontWeight.w800 : FontWeight.bold,
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
      // Visual único para cartões, campos, chips e botões em todas as telas.
      cardTheme: CardThemeData(
        elevation: 0,
        color: escuro ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: escuro ? Colors.white12 : const Color(0xFFE6E8F0),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: escuro ? const Color(0xFF1E1E1E) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: escuro ? Colors.white24 : const Color(0xFFDDE1EC),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: escuro ? Colors.white24 : const Color(0xFFDDE1EC),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(
          color: escuro ? Colors.white24 : const Color(0xFFDDE1EC),
        ),
        showCheckmark: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          // Textos do próprio Flutter (calendário, botões de diálogo,
          // menus de seleção) em português do Brasil.
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
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
              // Android 15+ desenha o app até a borda: o rodapé de todas as
              // telas fica acima dos botões/gesto de navegação do sistema.
              child: _MolduraDesktop(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
          home: const SplashScreen(),
        );
      },
    );
  }
}

/// No computador (navegador largo), o app aparece centralizado com largura de
/// celular, sobre um fundo neutro, em vez de esticar campos e cartões pela
/// tela inteira. No celular nada muda.
class _MolduraDesktop extends StatelessWidget {
  final Widget child;
  const _MolduraDesktop({required this.child});

  static const _larguraMaxima = 480.0;

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    if (largura <= _larguraMaxima + 120) return child;

    final escuro = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: escuro ? const Color(0xFF0B0B0F) : const Color(0xFFE8EBF7),
      child: Center(
        child: Container(
          width: _larguraMaxima,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
