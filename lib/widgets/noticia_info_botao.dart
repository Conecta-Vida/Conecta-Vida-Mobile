import 'package:flutter/material.dart';

class NoticiasInfoBotao extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String valor;
  final IconData? iconeAcao;
  final Color? corAcao;
  final VoidCallback? aoClicar;

  const NoticiasInfoBotao({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
    this.iconeAcao,
    this.corAcao,
    this.aoClicar,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: aoClicar,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icone, color: colors.onSurfaceVariant, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      valor,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (iconeAcao != null && aoClicar != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: corAcao!.withValues(alpha: 0.1),
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
}
