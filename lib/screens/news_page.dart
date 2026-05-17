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

  @override
  void initState() {
    super.initState();
    _refreshNoticias();
  }

  void _refreshNoticias() {
    _noticiasFuture = SupabaseService.fetchNoticiasPorCategoria(_categoryIndex);
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
            const SizedBox(height: 20),
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

                      final noticias = snapshot.data ??
                          _newsController.getNoticiasPorCategoria(_categoryIndex);

                      if (snapshot.hasError && noticias.isEmpty) {
                        return const Center(
                          child: Text(
                            'Não foi possível carregar as notícias. Puxe para atualizar.',
                            style: TextStyle(color: AppCor.textoCinza),
                            textAlign: TextAlign.center,
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
