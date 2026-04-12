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
      bottomNavigationBar: CustomBottomNavBar(
        //
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    // Busca a lista de notícias do controller
    final List<NewsModel> noticias = _newsController.getNoticiasPorCategoria(
      _categoryIndex,
    );
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
              shrinkWrap:
                  true, // Necessário para funcionar dentro do SingleChildScrollView
              physics:
                  const NeverScrollableScrollPhysics(), // O scroll é controlado pela tela principal
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
            left: 24,
            right: 24,
            bottom: 60,
          ),
          decoration: const BoxDecoration(
            color: AppCor.primary, //
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, ${widget.nome}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Confira as novidades da saúde hoje.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        Positioned(bottom: -25, left: 24, right: 24, child: _buildSearchBar()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Categorias',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppCor.textTitle,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _categoryItem('Notícias', AppCor.catNoticias, Icons.article, 0),
              _categoryItem(
                'Vacinação',
                AppCor.catVacinacao,
                Icons.vaccines,
                1,
              ),
              _categoryItem('Doações', AppCor.catDoacoes, Icons.water_drop, 2),
              _categoryItem(
                'Urgentes',
                AppCor.catUrgentes,
                Icons.warning_rounded,
                3,
              ),
              _categoryItem('Eventos', AppCor.catEventos, Icons.event, 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryItem(String label, Color color, IconData icon, int index) {
    bool isSelected = _categoryIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _categoryIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white, // Fundo da pílula
          borderRadius: BorderRadius.circular(
            40,
          ), // Curvatura acentuada (formato pílula)
          border: Border.all(
            color: isSelected
                ? color
                : Colors.transparent, // Borda colorida apenas se selecionado
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Garante que a coluna ocupe apenas o espaço necessário
          children: [
            // Círculo colorido com o ícone no meio
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            // Texto da categoria
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppCor.textSubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
