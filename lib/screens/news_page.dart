import 'package:flutter/material.dart';
import '../global/appCor.dart';
import '../controllers/noticia_controller.dart';
import '../models/noticia.dart';
import '../widgets/noticia_card.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/noticias_header.dart';
import '../widgets/noticias_categorias.dart';

class NewsScreen extends StatefulWidget {
  final String nome;
  final String telefone;

  const NewsScreen({super.key, required this.nome, required this.telefone});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsController _newsController = NewsController();

  int _bottomNavIndex = 0;
  int _categoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCor.background,
      body: _bottomNavIndex == 0
          ? _buildHomeBody(context)
          : const Center(child: Text('Outras abas em construção...')),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    final List<NewsModel> noticias = _newsController.getNoticiasPorCategoria(
      _categoryIndex,
    );
    final String tituloSessao = _newsController.getTituloSessao(_categoryIndex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // WIDGET DE CABEÇALHO
          NoticiasHeader(nome: widget.nome),

          const SizedBox(height: 35),

          // WIDGET DE CATEGORIAS
          Categorias(
            categoryIndex: _categoryIndex,
            onTap: (index) => setState(() => _categoryIndex = index),
          ),

          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              tituloSessao,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppCor.textTitle,
              ),
            ),
          ),
          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: noticias.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: NoticiaCard(noticia: noticias[index]),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
