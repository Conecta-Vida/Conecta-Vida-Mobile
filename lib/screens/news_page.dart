import 'package:flutter/material.dart';
import '../global/appCor.dart';
import '../controllers/noticia_controller.dart';
import '../models/noticia.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import '../widgets/noticia_card.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/noticias_header.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserModel usuario;

  const HomeScreen({super.key, required this.usuario});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsController _newsController = NewsController();
  int _categoryIndex = 0;
  late Future<List<NewsModel>> _noticiasFuture;
  String _searchQuery = '';
  String _cidadeFiltro = '';

  @override
  void initState() {
    super.initState();
    _refreshNoticias();
  }

  void _refreshNoticias() {
    _noticiasFuture = SupabaseService.fetchNoticiasPorCategoria(_categoryIndex);
  }

  List<NewsModel> _filtrarNoticias(List<NewsModel> noticias) {
    var lista = noticias;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      lista = lista.where((n) =>
        n.titulo.toLowerCase().contains(q) ||
        n.descricao.toLowerCase().contains(q)
      ).toList();
    }
    if (_cidadeFiltro.isNotEmpty) {
      lista = lista.where((n) =>
        n.local.toLowerCase().contains(_cidadeFiltro.toLowerCase())
      ).toList();
    }
    return lista;
  }

  Widget _buildCidadeChips() {
    final cidadeUsuario = widget.usuario.localizacao;
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildChip('Todas', ''),
          if (cidadeUsuario.isNotEmpty && cidadeUsuario != 'Não informado')
            _buildChip(cidadeUsuario, cidadeUsuario),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final selecionado = _cidadeFiltro == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _cidadeFiltro = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selecionado ? AppCor.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selecionado ? AppCor.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selecionado ? Colors.white : AppCor.textoCinza,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reloadNoticias() async {
    setState(() {
      _refreshNoticias();
    });
    await _noticiasFuture;
  }

  @override
  Widget build(BuildContext context) {
    final String tituloSessao = _newsController.getTituloSessao(_categoryIndex);

    return Scaffold(
      backgroundColor: AppCor.background,
      body: SafeArea(
        child: Column(
          children: [
            NoticiasHeader(
              nome: widget.usuario.nome,
              onSearch: (query) => setState(() => _searchQuery = query),
              onNotifications: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              onCalendar: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalendarScreen(),
                  ),
                );
              },
              onSettings: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(usuario: widget.usuario),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),
            _buildCidadeChips(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tituloSessao,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppCor.textTitle,
                    ),
                  ),
                  const Text(
                    'Categoria',
                    style: TextStyle(color: AppCor.textoCinza),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RefreshIndicator(
                  onRefresh: _reloadNoticias,
                  color: AppCor.primary,
                  child: FutureBuilder<List<NewsModel>>(
                    future: _noticiasFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppCor.primary,
                          ),
                        );
                      }

                      final todas = snapshot.data ??
                          _newsController.getNoticiasPorCategoria(_categoryIndex);
                      final noticias = _filtrarNoticias(todas);

                      if (snapshot.hasError && todas.isEmpty) {
                        return const Center(
                          child: Text(
                            'Não foi possível carregar as notícias. Puxe para atualizar.',
                            style: TextStyle(color: AppCor.textoCinza),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (noticias.isEmpty) {
                        return const Center(
                          child: Text(
                            'Nenhuma notícia encontrada.',
                            style: TextStyle(color: AppCor.textoCinza),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: noticias.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: NoticiaCard(
                              noticia: noticias[index],
                              userEmail: widget.usuario.email,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _categoryIndex,
        onTap: (index) {
          setState(() {
            _categoryIndex = index;
            _refreshNoticias();
          });
        },
      ),
    );
  }
}
