import 'package:flutter/material.dart';

import '../global/appCor.dart';
import '../services/supabase_service.dart';

/// Mostrada depois do cadastro (ou de um login com e-mail ainda não
/// confirmado): explica o que fazer e permite reenviar o e-mail.
class ConfirmarEmailScreen extends StatefulWidget {
  final String email;

  const ConfirmarEmailScreen({super.key, required this.email});

  @override
  State<ConfirmarEmailScreen> createState() => _ConfirmarEmailScreenState();
}

class _ConfirmarEmailScreenState extends State<ConfirmarEmailScreen> {
  bool _reenviando = false;

  Future<void> _reenviar() async {
    setState(() => _reenviando = true);
    try {
      await SupabaseService.reenviarConfirmacao(widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enviamos um novo e-mail para ${widget.email}.'),
          backgroundColor: AppCor.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppCor.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cores.surface,
      appBar: AppBar(title: const Text('Confirme seu e-mail')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppCor.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 48,
                    color: AppCor.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Falta só um passo',
                  style: texto.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Enviamos um link de confirmação para',
                  style: TextStyle(color: cores.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: texto.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Abra o e-mail, toque no link e depois volte aqui para entrar. '
                  'Se não encontrar, olhe também a caixa de spam.',
                  style: TextStyle(color: cores.onSurfaceVariant, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppCor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    // Volta para a tela de login.
                    onPressed: () =>
                        Navigator.of(context).popUntil((rota) => rota.isFirst),
                    child: const Text('Já confirmei, entrar'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _reenviando ? null : _reenviar,
                    child: Text(
                      _reenviando ? 'Reenviando...' : 'Reenviar o e-mail',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
