// lib/components/news_card.dart
import 'package:flutter/material.dart';
import '../global/appCor.dart';
import '../accessibility/accessibility_palette.dart';
import '../models/noticia.dart';
import '../screens/news_details_page.dart';

class NoticiaCard extends StatelessWidget {
  final NewsModel noticia;
  final String? userEmail;
  final int? userId;

  const NoticiaCard({
    super.key,
    required this.noticia,
    this.userEmail,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final String imagePath = noticia.imagem.trim();
    final bool hasImage = imagePath.isNotEmpty;
    final bool isNetworkImage = hasImage && imagePath.startsWith('http');

    // Cada tipo tem cor e ícone próprios, para ser reconhecido de relance
    // (e sem depender só da cor).
    final (Color corDoTipo, IconData iconeDoTipo) = switch (noticia.tag
        .toUpperCase()) {
      'ALERTA' => (AppCor.error, Icons.warning_amber_rounded),
      'CAMPANHA' => (const Color(0xFF00897B), Icons.campaign_outlined),
      _ => (const Color(0xFF1E88E5), Icons.article_outlined),
    };

    return GestureDetector(
      onTap: () {
        // Passa dados para os Detalhes
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailsPage(
              noticia: noticia,
              sharedBy: userEmail,
              userId: userId,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AccessibilityPalette.surface(context),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withValues(alpha: 0.08),
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
                tag: noticia.titulo + noticia.data,
                child: !hasImage
                    ? Container(
                        height: 140,
                        width: double.infinity,
                        color: const Color(0xFFEAF3FB),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0xFF90A4AE),
                          size: 34,
                        ),
                      )
                    : isNetworkImage
                    ? Image.network(
                        imagePath,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        // Link de imagem quebrado não deve derrubar o card.
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 140,
                          width: double.infinity,
                          color: const Color(0xFFEAF3FB),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF90A4AE),
                            size: 34,
                          ),
                        ),
                      )
                    : Image.asset(
                        imagePath,
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
                          color: corDoTipo.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconeDoTipo, size: 14, color: corDoTipo),
                            const SizedBox(width: 4),
                            Text(
                              noticia.tipoLegivel,
                              style: TextStyle(
                                color: corDoTipo,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (noticia.encerrada)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'ENCERRADA',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        noticia.dataLegivel,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    noticia.titulo,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    noticia.descricao,
                    maxLines: 2,
                    overflow: TextOverflow
                        .ellipsis, // Adiciona "..." se o texto for maior que as 2 linhas
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
