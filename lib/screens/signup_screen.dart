import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../global/appCor.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';
import 'news_page.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _idadeController = TextEditingController();
  String _sexo = 'Feminino';
  String _localizacao = 'Não autorizado';
  bool _localizacaoAtiva = false;
  bool _carregandoLocalizacao = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _idadeController.dispose();
    super.dispose();
  }

  Future<void> _solicitarLocalizacao() async {
    setState(() => _carregandoLocalizacao = true);
    bool servicoAtivo = await Geolocator.isLocationServiceEnabled();
    if (!servicoAtivo) {
      if (!mounted) return;
      setState(() => _carregandoLocalizacao = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ative o serviço de localização no dispositivo.'),
        ),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      setState(() => _carregandoLocalizacao = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permissão de localização não concedida.'),
        ),
      );
      return;
    }

    final posicao = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _localizacao =
          'Lat ${posicao.latitude.toStringAsFixed(4)}, Lon ${posicao.longitude.toStringAsFixed(4)}';
      _localizacaoAtiva = true;
      _carregandoLocalizacao = false;
    });
  }

  void _cadastro() async {
    if (_formKey.currentState!.validate()) {
      try {
        await SupabaseService.signUp(
          _emailController.text.trim(),
          _senhaController.text.trim(),
        );
        final usuario = UserModel(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          idade: _idadeController.text.trim(),
          sexo: _sexo,
          localizacao: _localizacaoAtiva ? _localizacao : 'Não autorizado',
        );
        await SupabaseService.upsertUsuario(
          usuario,
          senha: _senhaController.text.trim(),
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(usuario: usuario)),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppCor.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crie sua conta para acessar as novidades de saúde.',
                style: TextStyle(color: AppCor.textoCinza, fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite seu nome completo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite seu email';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Digite um email válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Digite sua senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter ao menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _idadeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Idade',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite sua idade';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Digite um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _sexo,
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'Feminino', child: Text('Feminino')),
                  DropdownMenuItem(
                    value: 'Masculino',
                    child: Text('Masculino'),
                  ),
                  DropdownMenuItem(
                    value: 'Prefiro não informar',
                    child: Text('Prefiro não informar'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _sexo = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregandoLocalizacao
                    ? null
                    : _solicitarLocalizacao,
                child: Text(
                  _carregandoLocalizacao
                      ? 'Solicitando localização...'
                      : (_localizacaoAtiva
                            ? 'Localização autorizada'
                            : 'Permitir localização'),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cadastro,
                child: const Text(
                  'Finalizar cadastro',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Localização: $_localizacao',
                style: const TextStyle(color: AppCor.textoCinza),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
