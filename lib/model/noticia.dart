// lib/model/news_model.dart
class NewsModel {
  final String tag;
  final String data;
  final String titulo;
  final String subtitulo;
  final String descricao;
  final String imagem;

  NewsModel({
    required this.tag,
    required this.data,
    required this.titulo,
    required this.subtitulo,
    required this.descricao,
    required this.imagem,
  });
}
