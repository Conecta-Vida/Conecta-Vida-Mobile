import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // 1. O initState deve ficar FORA do build
  @override
  void initState() {
    super.initState();

    // Timer de 3 segundos para ir pra proxima tela
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),

            // duracao da transicao
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
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF4159FF);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: Stack(
        children: [
          Image.asset(
            'assets/images/background.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.add, size: 60, color: primaryBlue),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Conecta Vida',
                  style: GoogleFonts.overpass(
                    textStyle: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w100,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
