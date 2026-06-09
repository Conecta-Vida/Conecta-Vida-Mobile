import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../global/appCor.dart';
import '../models/usuario.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserModel usuario;

  const SettingsScreen({super.key, required this.usuario});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificacoesAtivas = true;
  bool _usarLocalizacao = false;

  List<String> _regioesDisponiveis = [];
  List<String> _regioesSelecionadas = [];

  late Box _preferenciasBox;
  bool _carregandoRegioes = true;

  @override
  void initState() {
    super.initState();
    _preferenciasBox = Hive.box('preferencias');
    _carregarConfiguracoesLocais();
    _buscarRegioesDoBanco();
  }

  // Carrega o estado dos switches e as cidades salvas do Hive
  void _carregarConfiguracoesLocais() {
    setState(() {
      _notificacoesAtivas = _preferenciasBox.get(
        'notificacoes_ligadas',
        defaultValue: true,
      );
      _usarLocalizacao = _preferenciasBox.get(
        'usar_gps',
        defaultValue: widget.usuario.localizacao != 'Não autorizado',
      );
      // Carrega a lista de cidades que o utilizador marcou anteriormente
      _regioesSelecionadas = List<String>.from(
        _preferenciasBox.get('regioes_interesse', defaultValue: <String>[]),
      );
    });
  }

  // Consome a sua API Spring Boot via HTTP para recolher as localizações existentes
  Future<void> _buscarRegioesDoBanco() async {
    final Set<String> localizacoesUnicas = {};
    // IMPORTANTE: Se usar emulador Android, coloque 10.0.2.2 em vez de http://localhost:8080/api
    const String baseUrl = SupabaseService.baseUrl;

    try {
      // Busca localizações das Comunicações/Notícias
      final resComunicacoes = await http.get(
        Uri.parse('$baseUrl/comunicacoes'),
      );
      if (resComunicacoes.statusCode == 200) {
        final List dynamicList = jsonDecode(resComunicacoes.body);
        for (var item in dynamicList) {
          if (item['localizacao'] != null &&
              item['localizacao'].toString().isNotEmpty) {
            localizacoesUnicas.add(item['localizacao'].toString().trim());
          }
        }
      }

      // Busca localizações das Instituições de Saúde
      final resInstituicoes = await http.get(
        Uri.parse('$baseUrl/instituicoes'),
      );
      if (resInstituicoes.statusCode == 200) {
        final List dynamicList = jsonDecode(resInstituicoes.body);
        for (var item in dynamicList) {
          if (item['localizacao'] != null &&
              item['localizacao'].toString().isNotEmpty) {
            localizacoesUnicas.add(item['localizacao'].toString().trim());
          }
        }
      }
    } catch (e) {
      print('🚨 Erro ao buscar regiões via HTTP: $e');
      // Fallback básico caso a API não esteja a correr no momento do teste visual
      localizacoesUnicas.addAll([
        'Joanópolis',
        'Piracaia',
        'Bragança Paulista',
      ]);
    }

    setState(() {
      _regioesDisponiveis = localizacoesUnicas.toList()..sort();
      _carregandoRegioes = false;
    });
  }

  // Salva a lista atualizada de regiões escolhidas no Hive
  Future<void> _salvarRegiao(String cidade, bool selecionado) async {
    setState(() {
      if (selecionado) {
        if (!_regioesSelecionadas.contains(cidade))
          _regioesSelecionadas.add(cidade);
      } else {
        _regioesSelecionadas.remove(cidade);
      }
    });
    await _preferenciasBox.put('regioes_interesse', _regioesSelecionadas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Fundo cinza claro
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // SECÇÃO: ALERTAS
          _buildSecaoTitulo('ALERTAS DE SAÚDE'),
          _buildContainerGrupo([
            SwitchListTile.adaptive(
              title: const Text(
                'Notificações Push',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text('Alertas críticos de epidemias e vacinas'),
              value: _notificacoesAtivas,
              activeColor: AppCor.primary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onChanged: (value) async {
                setState(() => _notificacoesAtivas = value);
                await _preferenciasBox.put('notificacoes_ligadas', value);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile.adaptive(
              title: const Text(
                'Usar Localização Atual',
                style: TextStyle(fontSize: 16),
              ),
              subtitle: const Text('Filtra dados via GPS do aparelho'),
              value: _usarLocalizacao,
              activeColor: AppCor.primary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onChanged: (value) async {
                setState(() => _usarLocalizacao = value);
                await _preferenciasBox.put('usar_gps', value);
              },
            ),
          ]),

          const SizedBox(height: 28),

          // SECÇÃO: REGIÕES DE INTERESSE
          _buildSecaoTitulo('REGIÕES DE INTERESSE'),
          _carregandoRegioes
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator.adaptive(),
                  ),
                )
              : _regioesDisponiveis.isEmpty
              ? _buildContainerGrupo([
                  const ListTile(
                    title: Text(
                      'Nenhuma região encontrada',
                      style: TextStyle(color: Colors.grey),
                    ),
                    leading: Icon(Icons.location_off, color: Colors.grey),
                  ),
                ])
              : _buildContainerGrupo(
                  _regioesDisponiveis.map((cidade) {
                    final bool isChecked = _regioesSelecionadas.contains(
                      cidade,
                    );
                    return Column(
                      children: [
                        CheckboxListTile(
                          title: Text(
                            cidade,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: isChecked,
                          activeColor: AppCor.primary,
                          controlAffinity: ListTileControlAffinity
                              .trailing, // CORRIGIDO AQUI
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          onChanged: (bool? value) {
                            if (value != null) {
                              _salvarRegiao(cidade, value);
                            }
                          },
                        ),
                        if (cidade != _regioesDisponiveis.last)
                          const Divider(height: 1, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),

          const SizedBox(height: 28),

          // SECÇÃO: CONTA
          _buildSecaoTitulo('A SUA CONTA'),
          _buildContainerGrupo([
            ListTile(
              title: const Text('Nome'),
              trailing: Text(
                widget.usuario.nome,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              title: const Text('E-mail'),
              trailing: Text(
                widget.usuario.email,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
          ]),

          const SizedBox(height: 28),

          // SECÇÃO: EQUIPA
          _buildSecaoTitulo('EQUIPA DE DESENVOLVIMENTO'),
          _buildContainerGrupo(const [
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey),
              title: Text('Gustavo Tenorio'),
              subtitle: Text('Desenvolvimento e design'),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey),
              title: Text('Tsarco Gabriel Dias'),
              subtitle: Text('Frontend / lógica'),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey),
              title: Text('RenanVKoashi'),
              subtitle: Text('Arquitetura e testes'),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey),
              title: Text('Luiz Henrique Gon'),
              subtitle: Text('Integração e conteúdo'),
            ),
            Divider(height: 1, indent: 16, endIndent: 16),
            ListTile(
              leading: Icon(Icons.person, color: Colors.grey),
              title: Text('Maycon Cabral'),
              subtitle: Text('Suporte e validação'),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Componente visual para criar os títulos das secções (CORRIGIDO)
  Widget _buildSecaoTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF8E8E93),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Componente visual que encapsula itens dentro de um card branco
  Widget _buildContainerGrupo(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
