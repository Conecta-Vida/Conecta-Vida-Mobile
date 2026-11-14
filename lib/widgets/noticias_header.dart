import 'package:flutter/material.dart';
import '../accessibility/accessibility_palette.dart';
import '../global/appCor.dart';

class NoticiasHeader extends StatelessWidget {
  final String nome;
  final VoidCallback? onNotifications;
  final VoidCallback? onCalendar;
  final VoidCallback? onSettings;
  final ValueChanged<String>? onSearch;

  const NoticiasHeader({
    super.key,
    required this.nome,
    this.onNotifications,
    this.onCalendar,
    this.onSettings,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
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
            bottom: 70,
          ),
          decoration: const BoxDecoration(
            color: AppCor.primary,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildIconButton(Icons.notifications_outlined, 'Notificações', onNotifications),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.calendar_month, 'Meu cronograma', onCalendar),
                  const SizedBox(width: 4),
                  _buildIconButton(Icons.settings, 'Ajustes', onSettings),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Olá, $nome',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
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

  Widget _buildIconButton(
    IconData icon,
    String label,
    VoidCallback? action,
  ) {
    return IconButton(
      tooltip: label,
      onPressed: action,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon, color: Colors.white, size: 22),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AccessibilityPalette.surface(context),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: AccessibilityPalette.shadow(context), blurRadius: 10),
        ],
      ),
      child: TextField(
        onChanged: onSearch,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Pesquisar notícias...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
