import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 65, 89, 255)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext constext) {
  //encontrar cor de fundo correta noo futuro
  const Color primaryBlue = Color(0xFF4159FF);

  return Scaffold(
    backgroundColor: primaryBlue,
    body: Stack(
      children: [
        Image.asset('assets/images/background.png'),
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
                    )
                  ]
                ),
                child: const Center(
                  child: Icon(
                    Icons.add,
                    size: 60,
                    color:primaryBlue,
                  ),
                )
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
                      
                    )
                )
              )
            ],
          ),
        )
      ],
    )
  );
    
  }
}