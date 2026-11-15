import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../global/appCor.dart'; // Importe o AppCor aqui
import '../models/usuario.dart';
import '../providers/usuario_provider.dart';
import '../services/supabase_service.dart';
import 'news_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  /// Mostra a abertura e, se a pessoa já entrou neste aparelho, segue direto
  /// para a tela inicial sem pedir login de novo.
  Future<void> _iniciar() async {
    final resultados = await Future.wait<Object?>([
      SupabaseService.restaurarSessao(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);
    final usuario = resultados[0] as UserModel?;
    if (!mounted) return;
    if (usuario != null) {
      context.read<UsuarioProvider>().setUsuario(usuario);
    }
    final Widget destino = usuario != null
        ? const HomeScreen()
        : const LoginScreen();

    {
      {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => destino,
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  var curva = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeIn,
                  );
                  return FadeTransition(opacity: curva, child: child);
                },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppCor.primary, Color(0xFF3C55FF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.15,
                child: Image.asset(
                  'assets/images/background.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.18),
                          blurRadius: 18,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.health_and_safety,
                        size: 60,
                        color: AppCor.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Conecta Vida',
                    style: GoogleFonts.overpass(
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Bem-vindo à rede de saúde da sua região.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
