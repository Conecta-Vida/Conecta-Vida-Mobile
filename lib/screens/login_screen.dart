import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState;
import 'package:mobile_app/screens/news_page.dart';
import 'package:mobile_app/screens/forgot_password_screen.dart';
import 'package:mobile_app/screens/signup_screen.dart';
import 'package:provider/provider.dart';
import '../accessibility/accessibility_palette.dart';
import '../global/appCor.dart';
import '../controllers/login_controller.dart';
import '../providers/usuario_provider.dart';
import '../services/supabase_service.dart';
import 'confirmar_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = LoginController();
  bool _entrando = false;
  bool _microsoftDisponivel = false;
  StreamSubscription<AuthState>? _retornoMicrosoft;

  @override
  void initState() {
    super.initState();
    SupabaseService.microsoftDisponivel().then((ligado) {
      if (mounted) setState(() => _microsoftDisponivel = ligado);
    });
    // No celular, a Microsoft devolve o usuário ao app e a sessão chega aqui.
    _retornoMicrosoft = SupabaseService.mudancasDeLogin.listen((estado) async {
      if (estado.event != AuthChangeEvent.signedIn || _entrando || !mounted) {
        return;
      }
      final usuario = await SupabaseService.restaurarSessao();
      if (usuario == null || !mounted) return;
      context.read<UsuarioProvider>().setUsuario(usuario);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  Future<void> _entrarComMicrosoft() async {
    try {
      await SupabaseService.entrarComMicrosoft();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppCor.error,
        ),
      );
    }
  }

  bool _senhaVisivel = false;

  Future<void> _entrar() async {
    if (!_controller.tentarLogin()) return;
    final email = _controller.emailController.text.trim();

    setState(() => _entrando = true);
    try {
      final usuario = await SupabaseService.signIn(
        email,
        _controller.senhaController.text.trim(),
      );
      if (!mounted) return;
      context.read<UsuarioProvider>().setUsuario(usuario);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (error) {
      if (!mounted) return;
      // Conta criada, mas o link do e-mail ainda não foi aberto.
      if (SupabaseService.ehErroDeEmailNaoConfirmado(error)) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmarEmailScreen(email: email),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppCor.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _entrando = false);
    }
  }

  @override
  void dispose() {
    _retornoMicrosoft?.cancel();
    _controller.limparMemoria();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Conecta Vida',
                style: TextStyle(
                  color: AppCor.primary,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Acesso rápido às notícias e campanhas de saúde.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AccessibilityPalette.surface(context),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AccessibilityPalette.shadow(context),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, digite seu email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Digite um email válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _controller.senhaController,
                        obscureText: !_senhaVisivel,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _entrando ? null : _entrar(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(
                              Radius.circular(15.0),
                            ),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _senhaVisivel
                                ? 'Ocultar senha'
                                : 'Mostrar senha',
                            icon: Icon(
                              _senhaVisivel
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite sua senha';
                          }
                          if (value.length < 6) {
                            return 'A senha deve ter pelo menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppCor.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _entrando ? null : _entrar,
                        child: _entrando
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Entrar',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                      if (_microsoftDisponivel) ...[
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _entrando ? null : _entrarComMicrosoft,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const _LogoMicrosoft(),
                          label: const Text(
                            'Entrar com Microsoft',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: const Text('Cadastro'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text('Esqueci senha'),
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
      ),
    );
  }
}

/// Logotipo de quatro quadrados usado no botão "Entrar com Microsoft".
class _LogoMicrosoft extends StatelessWidget {
  const _LogoMicrosoft();

  @override
  Widget build(BuildContext context) {
    Widget quadrado(Color cor) => Container(width: 8, height: 8, color: cor);
    return SizedBox(
      width: 18,
      height: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              quadrado(const Color(0xFFF25022)),
              quadrado(const Color(0xFF7FBA00)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              quadrado(const Color(0xFF00A4EF)),
              quadrado(const Color(0xFFFFB900)),
            ],
          ),
        ],
      ),
    );
  }
}
