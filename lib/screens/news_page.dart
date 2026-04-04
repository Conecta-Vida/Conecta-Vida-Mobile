import 'package:flutter/material.dart';
import 'news_details_page.dart';

class NewsScreen extends StatefulWidget {
  final String nome;
  final String telefone;

  const NewsScreen({super.key, required this.nome, required this.telefone});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  // Controle da barra de navegação inferior (0 = Home, 1 = Notificações, etc.)
  int _bottomNavIndex = 0;

  // Controle das categorias de notícias (0 = Notícias, 1 = Vacinação, etc.)
  int _categoryIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),

      // O corpo da tela muda dependendo do botão clicado na barra inferior
      body: _bottomNavIndex == 0
          ? _buildHomeBody(context) // Se estiver na Home, mostra as notícias
          : Center(
              child: Text(
                'Tela em construção...',
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ),

      // A NOVA BARRA DE NAVEGAÇÃO INFERIOR CUSTOMIZADA
      bottomNavigationBar: _buildCustomBottomBar(),
    );
  }

  // ==========================================================================
  // CORPO PRINCIPAL DA HOME (Onde ficam as notícias e categorias)
  // ==========================================================================
  Widget _buildHomeBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopSection(context),
          const SizedBox(height: 35),

          _buildCategories(), // Pílulas (Notícias, Vacinação, Doações...)
          const SizedBox(height: 35),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionTitle(_getSectionTitle()),
          ),
          const SizedBox(height: 15),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildNewsFeed(context, _getCurrentNewsList()),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // A NOVA BARRA DE NAVEGAÇÃO INFERIOR (Idêntica à Imagem)
  // ==========================================================================
  Widget _buildCustomBottomBar() {
    return Container(
      height: 70, // Altura da barra
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, -5), // Sombra leve para cima
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 0. Home
          _buildNavItem(Icons.home, Icons.home_outlined, 0),
          // 1. Notificações (com bolinha vermelha)
          _buildNotificationItem(1),
          // 2. Botão Central de Adicionar (+)
          _buildCenterAddItem(2),
          // 3. Sacola
          _buildNavItem(Icons.shopping_bag, Icons.shopping_bag_outlined, 3),
          // 4. Perfil
          _buildNavItem(Icons.person, Icons.person_outline, 4),
        ],
      ),
    );
  }

  // Ícone normal da barra
  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, int index) {
    bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _bottomNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? const Color(0xFF3C64F4) : Colors.grey.shade400,
          size: 28,
        ),
      ),
    );
  }

  // Ícone de Notificação com a bolinha vermelha
  Widget _buildNotificationItem(int index) {
    bool isSelected = _bottomNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _bottomNavIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Stack(
          children: [
            Icon(
              isSelected
                  ? Icons.notifications
                  : Icons.notifications_none_outlined,
              color: isSelected
                  ? const Color(0xFF3C64F4)
                  : Colors.grey.shade400,
              size: 28,
            ),
            // A bolinha vermelha
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ), // Bordinha branca para destacar
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Botão quadrado azul central
  Widget _buildCenterAddItem(int index) {
    return GestureDetector(
      onTap: () => setState(() => _bottomNavIndex = index),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFF3C64F4), // Azul vibrante
          borderRadius: BorderRadius.circular(
            12,
          ), // Quadrado com cantos arredondados
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }

  // ==========================================================================
  // CABEÇALHO AZUL E BARRA DE PESQUISA
  // ==========================================================================
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
            color: Color(0xFF3C64F4),
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
                      Stack(
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 28,
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF3C64F4),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Bem vindo ao Conecta Vida! O canal principal de notícias de saúde da sua região.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Telefone: ${widget.telefone}',
                style: TextStyle(
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
                hintText: 'Search Medicine & Healthcare products',
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

  // ==========================================================================
  // CATEGORIAS (Pílulas)
  // ==========================================================================
  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Top Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _categoryItem('Notícias', const Color(0xFFFF6B8B), 0),
              _categoryItem('Vacinação', const Color(0xFF00C996), 1),
              _categoryItem('Doações', const Color(0xFFFF9548), 2),
              _categoryItem('Urgentes', const Color(0xFF3B82F6), 3),
              _categoryItem('Eventos', const Color(0xFF8B5CF6), 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryItem(String label, Color color, int index) {
    bool isSelected = _categoryIndex == index;

    return GestureDetector(
      onTap: () => setState(
        () => _categoryIndex = index,
      ), // Altera qual lista de notícia mostrar
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
              child: Icon(
                _getIconForCategory(index),
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF546E7A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(int index) {
    switch (index) {
      case 0:
        return Icons.article;
      case 1:
        return Icons.vaccines;
      case 2:
        return Icons.water_drop;
      case 3:
        return Icons.warning_rounded;
      case 4:
        return Icons.event;
      default:
        return Icons.category;
    }
  }

  // ==========================================================================
  // FUNÇÕES AUXILIARES DE NOTÍCIA
  // ==========================================================================
  String _getSectionTitle() {
    switch (_categoryIndex) {
      case 0:
        return 'Últimas Notícias';
      case 1:
        return 'Vacinações';
      case 2:
        return 'Doações de Sangue';
      case 3:
        return 'Casos Urgentes';
      case 4:
        return 'Próximos Eventos';
      default:
        return 'Últimas Notícias';
    }
  }

  List<Map<String, String>> _getCurrentNewsList() {
    switch (_categoryIndex) {
      case 0:
        return _noticiasHome;
      case 1:
        return _noticiasVacinacao;
      case 2:
        return _noticiasSangue;
      case 3:
        return _noticiasUrgentes;
      case 4:
        return _noticiasEventos;
      default:
        return _noticiasHome;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildNewsFeed(
    BuildContext context,
    List<Map<String, String>> noticias,
  ) {
    return Column(
      children: noticias.map((noticia) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: _buildNewsCard(
            context: context,
            tag: noticia['tag']!,
            data: noticia['data']!,
            titulo: noticia['titulo']!,
            subtitulo: noticia['subtitulo']!,
            descricao: noticia['descricao']!,
            imageUrl: noticia['imagem']!,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNewsCard({
    required BuildContext context,
    required String tag,
    required String data,
    required String titulo,
    required String subtitulo,
    required String descricao,
    required String imageUrl,
  }) {
    final bool isNetworkImage = imageUrl.startsWith('http');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailsPage(
              title: titulo,
              description: descricao,
              imageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Hero(
                tag: titulo + data,
                child: isNetworkImage
                    ? Image.network(
                        imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        data,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E50),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitulo,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // DADOS DAS NOTÍCIAS (MANTIDOS)
  // ==========================================================================

  List<Map<String, String>> get _noticiasHome => [
    {
      'tag': 'SUS - Região Bragantina',
      'data': '03/04/2025',
      'titulo': 'Vacinação contra Influenza aberta para todas as idades',
      'subtitulo': 'Válido até Junho de 2025. Vacina Sempre Brasil!',
      'descricao': 'A campanha de vacinação está disponível.',
      'imagem': 'assets/images/vacina_banner.png',
    },
    {
      'tag': 'Informativo',
      'data': '21/03/2025',
      'titulo':
          'Ouvidoria aberta a população reforça o compromisso com a transparência',
      'subtitulo': 'A escuta ativa da população é fundamental.',
      'descricao': 'A Ouvidoria do SUS reforça seus canais.',
      'imagem':
          'https://images.unsplash.com/photo-1551076805-e1869033e561?q=80&w=800&auto=format&fit=crop',
    },
  ];

  List<Map<String, String>> get _noticiasVacinacao => [
    {
      'tag': 'Campanha',
      'data': '03/04/2025',
      'titulo': 'Vacinação contra Influenza',
      'subtitulo': 'Válido até Junho de 2025.',
      'descricao': 'A vacina da Influenza já está liberada.',
      'imagem': 'assets/images/vacina_banner.png',
    },
  ];

  List<Map<String, String>> get _noticiasSangue => [
    {
      'tag': 'Ato de Amor',
      'data': '19/03/2025',
      'titulo': 'Doe sangue, salve vidas!',
      'subtitulo': 'Um simples gesto.',
      'descricao': 'Participe da nossa campanha de doação.',
      'imagem':
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?q=80&w=800&auto=format&fit=crop',
    },
  ];

  List<Map<String, String>> get _noticiasUrgentes => [
    {
      'tag': 'ALERTA',
      'data': '19/03/2025',
      'titulo': 'URGENTE! Ana Clara precisa de doações',
      'subtitulo': 'Ajude a salvar uma vida.',
      'descricao': 'Doe no dia 10 de junho.',
      'imagem':
          'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?q=80&w=800&auto=format&fit=crop',
    },
  ];

  List<Map<String, String>> get _noticiasEventos => [
    {
      'tag': 'Solidariedade',
      'data': '19/03/2025',
      'titulo': 'Evento de doação no domingo',
      'subtitulo': 'Compareça e ajude!',
      'descricao': 'Participe do nosso evento.',
      'imagem':
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?q=80&w=800&auto=format&fit=crop',
    },
  ];
}
