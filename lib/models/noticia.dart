// lib/model/news_model.dart
class NewsModel {
  final String tag;
  final String data;
  final String titulo;
  final String subtitulo;
  final String descricao;
  final String imagem;
  final String categoria;
  final String local;
  final String publicoAlvo;
  final String textoBotaoAcao;
  final String orgao;
  final String orgaoTelefone;
  final String orgaoSite;

  NewsModel({
    required this.tag,
    required this.data,
    required this.titulo,
    required this.subtitulo,
    required this.descricao,
    required this.imagem,
    this.categoria = 'Geral', // Valores padrão caso não seja preenchido
    this.local = 'Bragança Paulista',
    this.publicoAlvo = 'População em Geral',
    this.textoBotaoAcao = 'Saber Mais',
    this.orgao = 'Secretaria de Saúde',
    this.orgaoTelefone = '(11) 4002-8922',
    this.orgaoSite = 'https://www.saude.gov.br',
  });

  factory NewsModel.fromMap(Map<String, dynamic> map) {
    return NewsModel(
      tag: map['tag'] ?? '',
      data: map['data'] ?? '',
      titulo: map['titulo'] ?? '',
      subtitulo: map['subtitulo'] ?? '',
      descricao: map['descricao'] ?? '',
      imagem: map['imagem'] ?? '',
      categoria: map['categoria'] ?? 'Geral',
      local: map['local'] ?? 'Bragança Paulista',
      publicoAlvo: map['publicoAlvo'] ?? 'População em Geral',
      textoBotaoAcao: map['textoBotaoAcao'] ?? 'Saber Mais',
      orgao: map['orgao'] ?? 'Secretaria de Saúde',
      orgaoTelefone: map['orgaoTelefone'] ?? '(11) 4002-8922',
      orgaoSite: map['orgaoSite'] ?? 'https://www.saude.gov.br',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tag': tag,
      'data': data,
      'titulo': titulo,
      'subtitulo': subtitulo,
      'descricao': descricao,
      'imagem': imagem,
      'categoria': categoria,
      'local': local,
      'publicoAlvo': publicoAlvo,
      'textoBotaoAcao': textoBotaoAcao,
      'orgao': orgao,
      'orgaoTelefone': orgaoTelefone,
      'orgaoSite': orgaoSite,
    };
  }
}
