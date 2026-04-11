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
  });
}
