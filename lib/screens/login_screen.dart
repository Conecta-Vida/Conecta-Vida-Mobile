import 'package:flutter/material.dart';
import '../global/appCor.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = LoginController();

  @override
  void dispose() {
    _controller.limparMemoria();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double alturaTela = MediaQuery.of(context).size.height;
    double larguraTela = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text('LOGIN')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _controller.formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.health_and_safety, size: 80, color: Colors.blue),
              const SizedBox(height: 32),

              Text(
                "Por favor insira seu nome, telefone e senha abaixo para fazer login/cadastro:",
                style: TextStyle(color: AppCor.textoCinza),
              ),

              SizedBox(height: alturaTela * 0.05),

              // NOME
              TextFormField(
                controller: _controller.nomeController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Nome Completo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, digite o seu nome';
                  }
                  if (value.trim().split(' ').length < 2) {
                    return 'Digite pelo menos nome e apelido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // TELEFONE
              TextFormField(
                controller: _controller.telefoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '(11) 4002-8922',
                  hintStyle: TextStyle(color: AppCor.textoCinza),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15.0)),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite o seu telefone';
                  }

                  //VALIDA PRA VER SE 9 DIGITOS
                  if (value.length < 9) {
                    return 'O telefone deve ter pelo menos 9 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Botão de Envio
              ElevatedButton(
                onPressed: () {
                  bool sucesso = _controller.tentarLogin();

                  if (sucesso) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dados validados! Veja o console.'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppCor.primary,
                ),
                child: const Text(
                  'CONTINUAR',
                  style: TextStyle(fontSize: 18, color: AppCor.textoSecundario),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
