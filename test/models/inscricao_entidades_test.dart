// Testes de unidade das entidades de domínio do caso de uso
// "Inscrever-se em campanha": Inscricao, Participante e a regra de
// encerramento da campanha (NewsModel.encerradaEm).
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/inscricao.dart';
import 'package:mobile_app/models/noticia.dart';

NewsModel campanha({String status = 'ATIVA', String dataFim = ''}) =>
    NewsModel(
      id: 1,
      tag: 'CAMPANHA',
      data: '2026-11-01',
      dataFim: dataFim,
      titulo: 'Campanha',
      subtitulo: '',
      descricao: '',
      imagem: '',
      status: status,
    );

void main() {
  group('Inscricao', () {
    test('fromMap lê números e textos vindos do banco', () {
      final i = Inscricao.fromMap({
        'inscricao_id': '15',
        'usuario_id': 7,
        'comunicacao_id': 42.0,
        'dependente_id': '3',
        'participante_nome': 'Ana',
        'parentesco': 'Filha',
      });
      expect(i.id, 15);
      expect(i.usuarioId, 7);
      expect(i.comunicacaoId, 42);
      expect(i.dependenteId, 3);
      expect(i.doTitular, isFalse);
      expect(i.chaveParticipante, 'dependente:3');
      expect(i.participanteNome, 'Ana');
    });

    test('dependente_id nulo é a inscrição do titular', () {
      final i = Inscricao.fromMap({
        'id': 1,
        'usuario_id': 7,
        'comunicacao_id': 42,
        'dependente_id': null,
      });
      expect(i.doTitular, isTrue);
      expect(i.chaveParticipante, 'titular');
      expect(i.parentesco, 'Titular');
    });

    test('valores ausentes ou inválidos viram padrão', () {
      final i = Inscricao.fromMap({'usuario_id': 'abc'});
      expect(i.id, isNull);
      expect(i.usuarioId, 0);
      expect(i.comunicacaoId, 0);
      expect(i.participanteNome, '');
    });
  });

  group('Participante', () {
    test('titular tem chave "titular" e vínculo ativo', () {
      const p = Participante.titular();
      expect(p.ehTitular, isTrue);
      expect(p.chave, 'titular');
      expect(p.vinculoAtivo, isTrue);
    });

    test('dependente tem chave com o id', () {
      const p = Participante(dependenteId: 4, nome: 'Léo', parentesco: 'Filho');
      expect(p.ehTitular, isFalse);
      expect(p.chave, 'dependente:4');
    });
  });

  // Análise de Valor Limite sobre a data de término (RN02),
  // com "hoje" = 20/11/2026.
  group('NewsModel.encerradaEm (RN02)', () {
    final hoje = DateTime(2026, 11, 20, 15, 30);

    test('término ontem (limite inferior): encerrada', () {
      expect(campanha(dataFim: '2026-11-19').encerradaEm(hoje), isTrue);
    });

    test('término hoje (no limite): ainda aberta', () {
      expect(campanha(dataFim: '2026-11-20T08:00:00').encerradaEm(hoje), isFalse);
    });

    test('término amanhã (acima do limite): aberta', () {
      expect(campanha(dataFim: '2026-11-21').encerradaEm(hoje), isFalse);
    });

    test('status ENCERRADA ou CONCLUÍDA encerra mesmo no prazo', () {
      expect(campanha(status: 'ENCERRADA', dataFim: '2026-12-31').encerradaEm(hoje), isTrue);
      expect(campanha(status: 'Concluída', dataFim: '2026-12-31').encerradaEm(hoje), isTrue);
    });

    test('sem data de término ou data inválida: aberta', () {
      expect(campanha().encerradaEm(hoje), isFalse);
      expect(campanha(dataFim: 'xx/yy/zzzz').encerradaEm(hoje), isFalse);
    });

    test('notícia nunca é "encerrada"', () {
      final noticia = NewsModel(
        tag: 'NOTICIA',
        data: '2026-11-01',
        dataFim: '2020-01-01',
        titulo: 'N',
        subtitulo: '',
        descricao: '',
        imagem: '',
      );
      expect(noticia.encerradaEm(hoje), isFalse);
    });
  });
}
