import 'package:flutter/material.dart';
import 'global/appCor.dart'; // O nosso arquivo de cores!
import 'screens/splash_screen.dart'; // Sua tela inicial

void main() {
  runApp(const ConectaVidaApp());
}

class ConectaVidaApp extends StatelessWidget {
  const ConectaVidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Conecta Vida',

      // ==================
      // THEMEDATA GLOBAL
      // ==================
      theme: ThemeData(
        // Fundo padrão
        scaffoldBackgroundColor: AppCor.background,

        // Cores Base
        colorScheme: ColorScheme.light(
          primary: AppCor.primary,
          secondary: AppCor.secondary,
          error: AppCor.error,
        ),

        // AppBar
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

        //botões elevados
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppCor.primary, // Cor de fundo
            foregroundColor: Colors.white, // Cor do texto
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        //Cor primária
        iconTheme: const IconThemeData(color: AppCor.textoCinza),
      ),

      // ==========================================
      home: const SplashScreen(),
    );
  }
}
