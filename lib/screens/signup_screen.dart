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
  final _cidadeController = TextEditingController();
  String _sexo = 'Feminino';
  bool _localizacaoAtiva = false;
  bool _carregandoLocalizacao = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _idadeController.dispose();
    _cidadeController.dispose();
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
    final cidade = await SupabaseService.fetchCidadeFromCoords(
      posicao.latitude,
      posicao.longitude,
    );
    if (!mounted) return;
    setState(() {
      _cidadeController.text = cidade ?? '';
      _localizacaoAtiva = true;
      _carregandoLocalizacao = false;
    });
  }

  void _cadastro() async {
    if (_formKey.currentState!.validate()) {
      try {
        int? anoNascimento = int.tryParse(_idadeController.text.trim());
        String localizacaoLimpa =
            _localizacaoAtiva || _cidadeController.text.isNotEmpty
            ? _cidadeController.text.trim()
            : 'Não informado';

        // Monta o usuário temporário (sem ID)
        final usuarioLocal = UserModel(
          nome: _nomeController.text.trim(),
          email: _emailController.text.trim(),
          dataNascimento: anoNascimento,
          sexo: _sexo,
          localizacao: localizacaoLimpa,
        );

        String senhaDigitada = _senhaController.text.trim();

        // 2. Manda o Java salvar no banco (O Java vai gerar o ID 32, por exemplo)
        await SupabaseService.signUp(usuarioLocal, senhaDigitada);

        // 3. Faz login automático por baixo dos panos para ganhar o Token JWT
        await SupabaseService.signIn(usuarioLocal.email, senhaDigitada);

        // 4. AGORA SIM! Busca o perfil oficial do banco, que vem com o ID preenchido
        final usuarioOficialComId = await SupabaseService.fetchUsuarioByEmail(
          usuarioLocal.email,
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Passa o usuário oficial para a Home. Se der erro, usa o local como fallback.
            builder: (context) =>
                HomeScreen(usuario: usuarioOficialComId ?? usuarioLocal),
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll('Exception: ', '')),
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
                  labelText: 'Data de Nascimento',
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Digite sua data de nascimento';
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
                      ? 'Detectando cidade...'
                      : (_localizacaoAtiva
                            ? 'Localização detectada ✓'
                            : 'Detectar minha cidade'),
                ),
              ),
              if (_localizacaoAtiva || _cidadeController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cidadeController,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    helperText: 'Detectada pelo GPS — edite se necessário',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15.0)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _cadastro,
                child: const Text(
                  'Finalizar cadastro',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
