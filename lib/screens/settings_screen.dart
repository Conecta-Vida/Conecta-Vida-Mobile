import 'package:flutter/material.dart';
import '../global/appCor.dart';
import '../models/usuario.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel usuario;

  const SettingsScreen({super.key, required this.usuario});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificacoesAtivas = true;
  bool _usarLocalizacao = false;

  @override
  void initState() {
    super.initState();
    _usarLocalizacao = widget.usuario.localizacao != 'Não autorizado';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Perfil',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Nome'),
            subtitle: Text(widget.usuario.nome),
          ),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(widget.usuario.email),
          ),
          ListTile(
            title: const Text('Idade'),
            subtitle: Text(widget.usuario.idade),
          ),
          ListTile(
            title: const Text('Sexo'),
            subtitle: Text(widget.usuario.sexo),
          ),
          ListTile(
            title: const Text('Localização'),
            subtitle: Text(widget.usuario.localizacao),
          ),
          const SizedBox(height: 24),
          const Text(
            'Preferências',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Receber notificações'),
            value: _notificacoesAtivas,
            activeThumbColor: AppCor.primary,
            onChanged: (value) => setState(() => _notificacoesAtivas = value),
          ),
          SwitchListTile(
            title: const Text('Usar localização'),
            value: _usarLocalizacao,
            activeThumbColor: AppCor.primary,
            onChanged: (value) => setState(() => _usarLocalizacao = value),
          ),
          const SizedBox(height: 24),
          const Text(
            'Equipe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Gustavo Tenorio'),
            subtitle: Text('Desenvolvimento e design'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Tsarco Gabriel Dias'),
            subtitle: Text('Frontend / lógica'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('RenanVKoashi'),
            subtitle: Text('Arquitetura e testes'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Luiz Henrique Gon'),
            subtitle: Text('Integração e conteúdo'),
          ),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Maycon Cabral'),
            subtitle: Text('Suporte e validação'),
          ),
        ],
      ),
    );
  }
}
