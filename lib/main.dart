import 'package:flutter/material.dart';

void main() {
  runApp(const ConectaVidaApp());
}

class ConectaVidaApp extends StatelessWidget {
  const ConectaVidaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Conecta Vida',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

//tela inicial base
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.health_and_safety, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Conecta Vida',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Informação e Saúde',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
