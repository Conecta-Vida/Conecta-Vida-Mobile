// lib/screens/news_details_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/noticia.dart';
import '../global/appCor.dart';
import '../controllers/noticia_controller.dart';

class NewsDetailsPage extends StatelessWidget {
  final NewsModel noticia;

  const NewsDetailsPage({super.key, required this.noticia});

  Color _corDaCategoria(String categoria) {
    if (categoria.toLowerCase().contains('alerta')) return AppCor.error;
    if (categoria.toLowerCase().contains('vacina')) return AppCor.catVacinacao;
    if (categoria.toLowerCase().contains('sangue') ||
        categoria.toLowerCase().contains('doaç'))
      return AppCor.catNoticias;
    return AppCor.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ==========================================
      // CABEÇALHO COM BOTÕES DE VOLTAR E COMPARTILHAR
      // ==========================================
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // O famoso BOTÃO DE VOLTAR
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppCor.textoPrimario,
              size: 20,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        // O novo BOTÃO DE COMPARTILHAR
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_outlined,
                color: AppCor.primary,
                size: 20,
              ),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preparando para compartilhar...'),
                ),
              );
              // Dica: No futuro, use o pacote "share_plus" aqui para abrir o WhatsApp!
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true, // Faz a imagem subir por trás da barra

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEM NO TOPO
            SizedBox(
              width: double.infinity,
              height: 320,
              child: Hero(
                tag: noticia.titulo + noticia.data,
                child: noticia.imagem.startsWith('http')
                    ? Image.network(
                        noticia.imagem,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppCor.primary,
                            ),
                          );
                        },
                      )
                    : Image.asset(noticia.imagem, fit: BoxFit.cover),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TAG DA CATEGORIA
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _corDaCategoria(
                        noticia.categoria,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      noticia.categoria.toUpperCase(),
                      style: TextStyle(
                        color: _corDaCategoria(noticia.categoria),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // TÍTULO DA NOTÍCIA
                  Text(
                    noticia.titulo,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppCor.textoPrimario,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // CAIXA DE INFORMAÇÕES (Data, Local, etc)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppCor.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppCor.textoCinza.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        _infoInterativa(
                          context,
                          icone: Icons.calendar_month,
                          titulo: 'Data e Hora',
                          valor: noticia.data,
                          iconeAcao: Icons.add_alarm,
                          corAcao: AppCor.catDoacoes,
                          aoClicar: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '🔔 Lembrete salvo no calendário!',
                                  ),
                                  backgroundColor: AppCor.catVacinacao,
                                ),
                              ),
                        ),
                        const Divider(height: 1),
                        _infoInterativa(
                          context,
                          icone: Icons.location_on,
                          titulo: 'Local (Toque para abrir)',
                          valor: noticia.local,
                          iconeAcao: Icons.map_outlined,
                          corAcao: AppCor.primary,
                          aoClicar: () async {
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(noticia.local)}',
                            );
                            if (await canLaunchUrl(url)) await launchUrl(url);
                          },
                        ),
                        const Divider(height: 1),
                        _infoInterativa(
                          context,
                          icone: Icons.people,
                          titulo: 'Público-Alvo',
                          valor: noticia.publicoAlvo,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Detalhes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppCor.textoPrimario,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    noticia.descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 24),

                  // BOTÃO DE AÇÃO PRINCIPAL
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _corDaCategoria(noticia.categoria),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        noticia.textoBotaoAcao,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ==========================================
                  // SEÇÃO DE NOTÍCIAS RELACIONADAS (DE VOLTA!)
                  // ==========================================
                  _construirSecaoMaisNoticias(context),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET AUXILIAR INTERATIVO
  Widget _infoInterativa(
    BuildContext context, {
    required IconData icone,
    required String titulo,
    required String valor,
    IconData? iconeAcao,
    Color? corAcao,
    VoidCallback? aoClicar,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icone, color: AppCor.textoCinza, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppCor.textoPrimario,
                      ),
                    ),
                  ],
                ),
              ),
              if (iconeAcao != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: corAcao!.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconeAcao, color: corAcao, size: 20),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FUNÇÕES DA SEÇÃO DE NOTÍCIAS RELACIONADAS
  // ==========================================
  Widget _construirSecaoMaisNoticias(BuildContext context) {
    // Chama o cérebro das notícias
    final controller = NewsController();

    // Pega todas as notícias (aqui estamos a pegar as da Home, mas pode ser qualquer categoria)
    List<NewsModel> todasAsNoticias = controller.getNoticiasPorCategoria(0);

    // Remove a notícia que o utilizador já está a ler (para não repetir)
    List<NewsModel> recomendadas = todasAsNoticias
        .where((n) => n.titulo != noticia.titulo)
        .toList();

    // Se não houver mais notícias, esconde a seção
    if (recomendadas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outras Campanhas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppCor.textoPrimario,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65,
          ),
          // Mostra as recomendadas (limitado a 4 no máximo para não ficar gigante)
          itemCount: recomendadas.length > 4 ? 4 : recomendadas.length,
          itemBuilder: (context, index) {
            return _construirCardDinamico(context, recomendadas[index]);
          },
        ),
      ],
    );
  }

  // Novo Card que lê qualquer notícia que vier do Controller
  Widget _construirCardDinamico(
    BuildContext context,
    NewsModel noticiaRelacionada,
  ) {
    bool ehUrgente =
        noticiaRelacionada.categoria.toLowerCase().contains('sangue') ||
        noticiaRelacionada.categoria.toLowerCase().contains('alerta');

    return GestureDetector(
      onTap: () {
        // Navega para abrir a notícia clicada
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailsPage(noticia: noticiaRelacionada),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppCor.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  // Ícone dinâmico baseado na urgência
                  child: Icon(
                    ehUrgente ? Icons.warning_rounded : Icons.article,
                    size: 50,
                    color: ehUrgente ? AppCor.error : AppCor.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      noticiaRelacionada.titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      noticiaRelacionada.categoria,
                      style: const TextStyle(
                        color: AppCor.textoCinza,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          noticiaRelacionada.tag,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: ehUrgente
                                ? AppCor.error
                                : AppCor.textoPrimario,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
