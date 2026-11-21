// Testes de unidade das entidades de domínio do caso de uso
// "Inscrever-se em campanha": Inscricao, Participante e a regra de
// encerramento da campanha (NewsModel.encerradaEm).
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/dependente.dart';
import 'package:mobile_app/models/inscricao.dart';
import 'package:mobile_app/models/noticia.dart';

NewsModel campanha({
  String status = 'ATIVA',
  String dataFim = '',
  int? vagas,
  int inscritos = 0,
}) =>
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
      vagas: vagas,
      inscritos: inscritos,
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

  group('NewsModel (Campanha) — conversões', () {
    test('toMap e fromMap preservam os dados da campanha', () {
      final original = NewsModel(
        id: 9,
        tag: 'CAMPANHA',
        data: '2026-11-01',
        dataInicio: '2026-11-01',
        dataFim: '2026-11-30',
        titulo: 'Novembro Azul',
        subtitulo: 'Saúde do homem',
        descricao: 'Exames',
        imagem: 'capa.png',
        categoria: 'Vacinação',
        local: 'Bragança Paulista',
        status: 'ATIVA',
        fonteUrl: 'https://www.gov.br/saude',
      );
      final copia = NewsModel.fromMap(original.toMap());
      expect(copia.toMap(), original.toMap());
      expect(copia.encerradaEm(DateTime(2026, 11, 20)), isFalse);
    });

    test('tipoLegivel traduz os tipos e mantém um tipo desconhecido', () {
      NewsModel com(String tag) => NewsModel(
        tag: tag,
        data: '',
        titulo: '',
        subtitulo: '',
        descricao: '',
        imagem: '',
      );
      expect(com('CAMPANHA').tipoLegivel, 'Campanha');
      expect(com('NOTICIA').tipoLegivel, 'Notícia');
      expect(com('ALERTA').tipoLegivel, 'Alerta');
      expect(com('EVENTO').tipoLegivel, 'EVENTO');
    });
  });

  group('NewsModel — vagas (RN07)', () {
    test('CT01 — sem vagas definidas não há limite', () {
      final c = campanha();
      expect(c.vagasRestantes, isNull);
      expect(c.lotada, isFalse);
      expect(c.comportaNovas(50), isTrue);
    });

    test('CT26 — vagas restantes = vagas − inscritos', () {
      final c = campanha(vagas: 10, inscritos: 7);
      expect(c.vagasRestantes, 3);
      expect(c.lotada, isFalse);
      expect(c.comportaNovas(3), isTrue);
      expect(c.comportaNovas(4), isFalse);
    });

    test('CT28 — última vaga ocupada: lotada', () {
      final c = campanha(vagas: 5, inscritos: 5);
      expect(c.vagasRestantes, 0);
      expect(c.lotada, isTrue);
    });

    test('CT31 — gestor reduziu abaixo dos inscritos', () {
      final c = campanha(vagas: 3, inscritos: 5);
      expect(c.vagasRestantes, 0);
      expect(c.lotada, isTrue);
    });

    test('fromMap lê vagas e inscritos do banco', () {
      final c = NewsModel.fromMap({'vagas': '4', 'inscritos': 1});
      expect(c.vagas, 4);
      expect(c.inscritos, 1);
      final sem = NewsModel.fromMap({});
      expect(sem.vagas, isNull);
      expect(sem.inscritos, 0);
    });
  });

  group('Dependente — vínculo usado na inscrição (RN03)', () {
    test('fromMap aceita id em texto e status pendente', () {
      final d = DependenteModel.fromMap({
        'id': '12',
        'nome_completo': 'Mãe',
        'data_nascimento': '1960-05-10',
        'parentesco': 'Mãe',
        'status': 'pendente',
        'email_dependente': 'mae@teste.com',
      });
      expect(d.id, 12);
      expect(d.pendente, isTrue);
      expect(d.ativo, isFalse);
    });

    test('ConviteDependente lê o pedido de autorização', () {
      final c = ConviteDependente.fromMap({
        'id': 5,
        'titular_nome': 'Titular',
        'parentesco': 'Filho(a)',
        'status': 'pendente',
      });
      expect(c.id, 5);
      expect(c.titularNome, 'Titular');
      expect(c.pendente, isTrue);
      expect(ConviteDependente.fromMap({'id': 6, 'status': 'ativo'}).pendente, isFalse);
    });
  });
}
