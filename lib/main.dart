import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const ConectaVidaApp());
}

class ConectaVidaApp extends StatelessWidget {
  const ConectaVidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conecta Vida App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 65, 89, 255),
        ),
        useMaterial3: true,
      ),
      home: LoginScreen(), //const no começo
      debugShowCheckedModeBanner: false,
    );
  }
}
