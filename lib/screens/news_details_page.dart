import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/noticia.dart';
import '../global/appCor.dart';
import '../services/supabase_service.dart';
import '../widgets/noticia_info_botao.dart';
import '../widgets/noticia_secao_mais.dart';

class NewsDetailsPage extends StatelessWidget {
  final NewsModel noticia;
  final String? sharedBy;

  const NewsDetailsPage({super.key, required this.noticia, this.sharedBy});

  Color _corDaCategoria(String categoria) {
    if (categoria.toLowerCase().contains('alerta')) {
      return AppCor.error;
    }
    if (categoria.toLowerCase().contains('vacina')) {
      return AppCor.catVacinacao;
    }
    if (categoria.toLowerCase().contains('sangue') ||
        categoria.toLowerCase().contains('doação')) {
      return AppCor.catNoticias;
    }
    return AppCor.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.8),
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
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_outlined,
                color: AppCor.primary,
                size: 20,
              ),
            ),
            onPressed: () async {
              final shareText =
                  '${noticia.titulo}\n\n${noticia.subtitulo}\n\n${noticia.descricao}\n\nÓrgão: ${noticia.orgao}\nContato: ${noticia.orgaoTelefone}';
              await Share.share(shareText,
                  subject: noticia.titulo);
              await SupabaseService.trackNewsShare(
                noticia,
                sharedBy: sharedBy ?? 'app_user',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _corDaCategoria(
                        noticia.categoria,
                      ).withValues(alpha:0.1),
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

                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppCor.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppCor.textoCinza.withValues(alpha:0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        NoticiasInfoBotao(
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
                        NoticiasInfoBotao(
                          icone: Icons.location_on,
                          titulo: 'Local (Toque para abrir)',
                          valor: noticia.local,
                          iconeAcao: Icons.map_outlined,
                          corAcao: AppCor.primary,
                          aoClicar: () async {
                            final url = Uri.parse(
                              'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(noticia.local)}',
                            );
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.business,
                          titulo: 'Órgão Publicador',
                          valor: noticia.orgao,
                          iconeAcao: Icons.open_in_new,
                          corAcao: AppCor.primary,
                          aoClicar: () async {
                            final url = Uri.parse(noticia.orgaoSite);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
                          icone: Icons.phone,
                          titulo: 'Contato',
                          valor: noticia.orgaoTelefone,
                          iconeAcao: Icons.call_outlined,
                          corAcao: AppCor.primary,
                          aoClicar: () async {
                            final url = Uri.parse('tel:${noticia.orgaoTelefone}');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        NoticiasInfoBotao(
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

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final shareText =
                            '${noticia.titulo}\n\n${noticia.subtitulo}\n\n${noticia.descricao}\n\nÓrgão: ${noticia.orgao}\nContato: ${noticia.orgaoTelefone}';
                        await Share.share(shareText,
                            subject: noticia.titulo);
                        await SupabaseService.trackNewsShare(
                          noticia,
                          sharedBy: sharedBy ?? 'app_user',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _corDaCategoria(noticia.categoria),
                      ),
                      child: Text(
                        noticia.textoBotaoAcao,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  NoticiasSecaoMais(noticiaAtual: noticia),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
