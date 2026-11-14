import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../accessibility/accessibility_provider.dart';
import '../accessibility/accessibility_speech_service.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acessibilidade'),
      ),
      body: Consumer<AccessibilityProvider>(
        builder: (context, preferences, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Adapte o aplicativo às suas necessidades.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'LEITURA'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Tamanho do texto',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('${(preferences.fontScale * 100).round()}%'),
                        ],
                      ),
                      Slider(
                        min: 0.9,
                        max: 1.6,
                        divisions: 7,
                        value: preferences.fontScale,
                        label: '${(preferences.fontScale * 100).round()}%',
                        onChanged: preferences.atualizarEscala,
                      ),
                      Text(
                        'Exemplo de texto para leitura.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: preferences.fontFamily,
                        decoration: const InputDecoration(
                          labelText: 'Tipo de fonte',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text('Fonte do sistema'),
                          ),
                          DropdownMenuItem(
                            value: 'serif',
                            child: Text('Fonte serifada'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            preferences.setFontFamily(value);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Card(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.format_bold),
                      title: const Text('Texto em negrito'),
                      subtitle: const Text('Reforça o peso dos textos do tema'),
                      value: preferences.boldText,
                      onChanged: preferences.setBoldText,
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.record_voice_over),
                      title: const Text('Leitura em voz alta'),
                      subtitle: const Text(
                        'Habilita o botão para ouvir notícias e conteúdos',
                      ),
                      value: preferences.speechEnabled,
                      onChanged: (enabled) async {
                        if (!enabled) {
                          await AccessibilitySpeechService.instance.stop();
                        }
                        await preferences.setSpeechEnabled(enabled);
                      },
                    ),
                    if (preferences.speechEnabled) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.volume_up),
                        title: const Text('Testar leitura em voz alta'),
                        subtitle: const Text(
                          'O aparelho precisa ter uma voz em português instalada.',
                        ),
                        onTap: () => AccessibilitySpeechService.instance.speak(
                          'Olá! Esta é uma demonstração da leitura em voz alta do Conecta Vida.',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.stop_circle_outlined),
                        title: const Text('Parar leitura'),
                        onTap: AccessibilitySpeechService.instance.stop,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionTitle(context, 'VISUAL'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.contrast),
                      title: const Text('Alto contraste'),
                      subtitle: const Text(
                        'Aumenta o contraste das cores do tema',
                      ),
                      value: preferences.highContrast,
                      onChanged: preferences.setHighContrast,
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Modo escuro'),
                      value: preferences.darkMode,
                      onChanged: preferences.setDarkMode,
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.motion_photos_off_outlined),
                      title: const Text('Reduzir animações'),
                      subtitle: const Text(
                        'Reduz movimentos em componentes que respeitam esta preferência',
                      ),
                      value: preferences.reduceMotion,
                      onChanged: preferences.setReduceMotion,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: preferences.reset,
                icon: const Icon(Icons.restore),
                label: const Text('Restaurar configurações padrão'),
              ),
              const SizedBox(height: 12),
              Text(
                'As preferências são salvas neste dispositivo. O TalkBack (Android) e o VoiceOver (iOS) continuam sendo controlados nas configurações de acessibilidade do próprio sistema.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}
