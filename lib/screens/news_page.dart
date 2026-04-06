// lib/screens/news_screen.dart
import 'package:flutter/material.dart';
import '../global/appCor.dart';
import '../controllers/noticia_controller.dart';
import '../components/noticia_card.dart';
import '../components/bottom_navbar.dart';

class NewsScreen extends StatefulWidget {
  final String nome;
  final String telefone;

  const NewsScreen({super.key, required this.nome, required this.telefone});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // Instancia o controller (O cérebro da tela)
  final NewsController _newsController = NewsController();

  int _bottomNavIndex = 0;
  int _categoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCor.background,
      body: _bottomNavIndex == 0
          ? _buildHomeBody(context)
          : Center(
              child: Text(
                'Tela em construção...',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ),
      // Usa o componente separado e passa as funções de clique
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    // Pede ao controller a lista baseada na categoria selecionada
    final noticias = _newsController.getNoticiasPorCategoria(_categoryIndex);
    final tituloSessao = _newsController.getTituloSessao(_categoryIndex);

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
                color: AppCor.textTitle,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            // Monta a lista usando o NewsCard
            child: Column(
              children: noticias.map((noticia) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: NoticiaCard(noticia: noticia),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 28),
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 10,
            left: 24,
            right: 24,
            bottom: 40,
          ),
          decoration: const BoxDecoration(
            color: AppCor.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(
                      'https://randomuser.me/api/portraits/men/32.jpg',
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Hi, ${widget.nome}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bem vindo ao Conecta Vida! O canal principal de notícias de saúde.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Telefone: ${widget.telefone}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 24,
          right: 24,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Pesquisar notícias e saúde',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Icon(Icons.search, color: Colors.grey.shade500),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
        ),
      ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
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
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
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
