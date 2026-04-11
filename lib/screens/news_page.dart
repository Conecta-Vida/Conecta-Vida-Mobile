// lib/screens/news_page.dart
import 'package:flutter/material.dart';
import '../global/appCor.dart';
import '../controllers/noticia_controller.dart';
import '../components/noticia_card.dart';
import '../components/bottom_navbar.dart';
import '../model/noticia.dart'; //

class NewsScreen extends StatefulWidget {
  final String nome;
  final String telefone;

  const NewsScreen({super.key, required this.nome, required this.telefone});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsController _newsController = NewsController(); //

  int _bottomNavIndex = 0;
  int _categoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCor.background, //
      body: _bottomNavIndex == 0
          ? _buildHomeBody(context)
          : const Center(child: Text('Outras abas em construção...')),
      bottomNavigationBar: CustomBottomNavBar( //
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    // Busca a lista de notícias do controller
    final List<NewsModel> noticias = _newsController.getNoticiasPorCategoria(_categoryIndex);
    final String tituloSessao = _newsController.getTituloSessao(_categoryIndex);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSection(context),
          const SizedBox(height: 35),
          _buildCategories(),
          const SizedBox(height: 35),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              tituloSessao,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppCor.textTitle, //
              ),
            ),
          ),
          const SizedBox(height: 15),

          // ==========================================
          // IMPLEMENTAÇÃO DO LISTVIEW.BUILDER
          // ==========================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true, // Necessário para funcionar dentro do SingleChildScrollView
              physics: const NeverScrollableScrollPhysics(), // O scroll é controlado pela tela principal
              itemCount: noticias.length,
              itemBuilder: (context, index) {
                // Renderiza cada card de notícia dinamicamente
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

  // --- Widgets de Apoio (Cabeçalho e Categorias) ---

  Widget _buildTopSection(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 24, right: 24, bottom: 60,
          ),
          decoration: const BoxDecoration(
            color: AppCor.primary, //
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Olá, ${widget.nome}', 
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Confira as novidades da saúde hoje.', 
                style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
        Positioned(
          bottom: -25,
          left: 24, right: 24,
          child: _buildSearchBar(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Pesquisar notícias...',
          prefixIcon: Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _categoryItem('Geral', AppCor.catNoticias, Icons.article, 0),
          _categoryItem('Vacina', AppCor.catVacinacao, Icons.vaccines, 1),
          _categoryItem('Sangue', AppCor.catDoacoes, Icons.bloodtype, 2),
        ],
      ),
    );
  }

  Widget _categoryItem(String label, Color color, IconData icon, int index) {
    bool isSelected = _categoryIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _categoryIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? Colors.white : color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }
}