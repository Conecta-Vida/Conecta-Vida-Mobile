import 'package:flutter/material.dart';
import '../accessibility/accessibility_palette.dart';
import '../global/appCor.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    {
      'active': Icons.article,
      'inactive': Icons.article_outlined,
      'label': 'Notícias',
    },
    {
      'active': Icons.vaccines,
      'inactive': Icons.vaccines_outlined,
      'label': 'Vacinas',
    },
    {
      'active': Icons.water_drop,
      'inactive': Icons.water_drop_outlined,
      'label': 'Doações',
    },
    {
      'active': Icons.warning_rounded,
      'inactive': Icons.warning_amber_outlined,
      'label': 'Alertas',
    },
    {
      'active': Icons.campaign,
      'inactive': Icons.campaign_outlined,
      'label': 'Campanhas',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Normalmente zero: o app já reserva o espaço dos botões do sistema
    // (main.dart). Fica aqui caso a barra seja usada fora desse cuidado.
    final espacoDoSistema = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.only(bottom: espacoDoSistema),
      decoration: BoxDecoration(
        color: AccessibilityPalette.surface(context),
        boxShadow: [
          BoxShadow(
            color: AccessibilityPalette.shadow(context),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SizedBox(
        height: 66,
        child: Row(
          children: List.generate(
            _items.length,
            (index) => Expanded(
              child: _buildNavItem(
                context,
                _items[index]['active'] as IconData,
                _items[index]['inactive'] as IconData,
                index,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
  ) {
    final isSelected = currentIndex == index;
    final cor = isSelected
        ? AppCor.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final rotulo = _items[index]['label'] as String;
    return Semantics(
      label: rotulo,
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppCor.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: cor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rotulo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: cor,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
