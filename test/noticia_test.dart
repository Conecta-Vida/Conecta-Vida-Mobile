import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/noticia.dart';

NewsModel _campanha({String status = 'ATIVA', String dataFim = ''}) => NewsModel(
  id: 1,
  tag: 'CAMPANHA',
  data: '2026-01-01',
  dataFim: dataFim,
  titulo: 'Campanha',
  subtitulo: '',
  descricao: '',
  imagem: '',
  status: status,
);

String _dia(int deslocamento) => DateTime.now()
    .add(Duration(days: deslocamento))
    .toIso8601String();

void main() {
  group('NewsModel.encerrada', () {
    test('campanha ativa e dentro do prazo não está encerrada', () {
      expect(_campanha(dataFim: _dia(5)).encerrada, isFalse);
    });

    test('campanha que termina hoje ainda vale', () {
      expect(_campanha(dataFim: _dia(0)).encerrada, isFalse);
    });

    test('campanha com data de término passada está encerrada', () {
      expect(_campanha(dataFim: _dia(-1)).encerrada, isTrue);
    });

    test('campanha encerrada pelo painel está encerrada mesmo no prazo', () {
      expect(_campanha(status: 'ENCERRADA', dataFim: _dia(5)).encerrada, isTrue);
      expect(_campanha(status: 'Concluída', dataFim: _dia(5)).encerrada, isTrue);
    });

    test('campanha sem data de término fica aberta', () {
      expect(_campanha().encerrada, isFalse);
    });

    test('notícias e alertas nunca são "encerrados"', () {
      final noticia = NewsModel(
        tag: 'NOTICIA',
        data: '2026-01-01',
        dataFim: _dia(-30),
        titulo: 'Notícia',
        subtitulo: '',
        descricao: '',
        imagem: '',
        status: 'ENCERRADA',
      );
      expect(noticia.encerrada, isFalse);
    });
  });

  test('conteúdo de abrangência geral vale para qualquer cidade', () {
    NewsModel em(String local) => NewsModel(
      tag: 'NOTICIA',
      data: '2026-01-01',
      titulo: 't',
      subtitulo: '',
      descricao: '',
      imagem: '',
      local: local,
    );
    expect(em('Geral').abrangenciaGeral, isTrue);
    expect(em('Região Geral').abrangenciaGeral, isTrue);
    expect(em('').abrangenciaGeral, isTrue);
    expect(em('Atibaia').abrangenciaGeral, isFalse);
  });

  test('NewsModel.fromMap lê o link da fonte oficial', () {
    final noticia = NewsModel.fromMap({
      'tag': 'NOTICIA',
      'titulo': 't',
      'fonte_url': 'https://www.gov.br/saude/materia',
    });
    expect(noticia.fonteUrl, 'https://www.gov.br/saude/materia');
  });

  test('NewsModel.fromMap lê o status e corta a data de publicação', () {
    final noticia = NewsModel.fromMap({
      'id': '7',
      'tag': 'CAMPANHA',
      'data': '2026-06-02T14:18:46.123',
      'titulo': 'Título',
      'status': 'ATIVA',
    });
    expect(noticia.id, 7);
    expect(noticia.data, '2026-06-02');
    expect(noticia.status, 'ATIVA');
    expect(noticia.ehCampanha, isTrue);
  });
}
