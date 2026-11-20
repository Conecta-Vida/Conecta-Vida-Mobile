// Testes de unidade da classe de caso de uso InscricaoCampanhaService.
// Cada teste é um DRIVER: chama o serviço com uma entrada e confere a saída.
// O banco é substituído por RepositorioStub (stub + mock), e o relógio é
// fixado em 20/11/2026 para que os testes de data sejam determinísticos.
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/dependente.dart';
import 'package:mobile_app/models/inscricao.dart';
import 'package:mobile_app/models/noticia.dart';
import 'package:mobile_app/usecases/inscricao_campanha_service.dart';

import 'repositorio_stub.dart';

final hoje = DateTime(2026, 11, 20, 10);
const usuarioId = 7;
const campanhaId = 42;

NewsModel campanha({
  int? id = campanhaId,
  String tag = 'CAMPANHA',
  String status = 'ATIVA',
  String dataFim = '2026-12-31',
}) => NewsModel(
  id: id,
  tag: tag,
  data: '2026-11-01',
  dataFim: dataFim,
  titulo: 'Vacinação contra a gripe',
  subtitulo: '',
  descricao: '',
  imagem: '',
  status: status,
);

DependenteModel dependente(int id, {String status = 'ativo'}) =>
    DependenteModel(
      id: id,
      nomeCompleto: 'Dependente $id',
      dataNascimento: DateTime(2018, 1, 1),
      parentesco: 'Filho(a)',
      status: status,
    );

Participante participante(int? dependenteId, {bool vinculoAtivo = true}) =>
    dependenteId == null
    ? const Participante.titular()
    : Participante(
        dependenteId: dependenteId,
        nome: 'Dependente $dependenteId',
        parentesco: 'Filho(a)',
        vinculoAtivo: vinculoAtivo,
      );

InscricaoCampanhaService servico(RepositorioStub repo) =>
    InscricaoCampanhaService(repo, agora: () => hoje);

void main() {
  // ------------------------------------------------------------------
  group('verificarAcesso (passo 4)', () {
    final s = servico(RepositorioStub());

    test('campanha aberta e usuário identificado: libera', () {
      expect(
        () => s.verificarAcesso(
          campanha: campanha(),
          usuarioId: usuarioId,
          possuiInscricoes: false,
        ),
        returnsNormally,
      );
    });

    test('RN01: comunicação que não é campanha é recusada', () {
      expect(
        () => s.verificarAcesso(
          campanha: campanha(tag: 'NOTICIA'),
          usuarioId: usuarioId,
          possuiInscricoes: false,
        ),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoRecusa.naoECampanha,
          ),
        ),
      );
    });

    test('E1/RN02: campanha encerrada sem inscrições é recusada', () {
      expect(
        () => s.verificarAcesso(
          campanha: campanha(status: 'ENCERRADA'),
          usuarioId: usuarioId,
          possuiInscricoes: false,
        ),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'Esta campanha já foi encerrada.',
          ),
        ),
      );
    });

    test('A4: campanha encerrada com inscrições abre para cancelar', () {
      expect(
        () => s.verificarAcesso(
          campanha: campanha(status: 'ENCERRADA'),
          usuarioId: usuarioId,
          possuiInscricoes: true,
        ),
        returnsNormally,
      );
    });

    test('E2: campanha sem ID é recusada', () {
      expect(
        () => s.verificarAcesso(
          campanha: campanha(id: null),
          usuarioId: usuarioId,
          possuiInscricoes: false,
        ),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoRecusa.campanhaSemId,
          ),
        ),
      );
    });

    test('E3: usuário não identificado é recusado', () {
      expect(
        () => s.verificarAcesso(
          campanha: campanha(),
          usuarioId: null,
          possuiInscricoes: false,
        ),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoRecusa.usuarioNaoIdentificado,
          ),
        ),
      );
    });
  });

  // ------------------------------------------------------------------
  group('listarParticipantes (passo 4)', () {
    test('titular sempre primeiro, seguido dos dependentes ativos', () async {
      final repo = RepositorioStub(dependentes: [dependente(1), dependente(2)]);
      final lista = await servico(
        repo,
      ).listarParticipantes(usuarioId: usuarioId, inscricoesAtuais: []);

      expect(lista.map((p) => p.chave), [
        'titular',
        'dependente:1',
        'dependente:2',
      ]);
      expect(lista.first.ehTitular, isTrue);
    });

    test('RN03: ignora dependente pendente e dependente sem id', () async {
      final repo = RepositorioStub(
        dependentes: [
          dependente(1, status: 'pendente'),
          DependenteModel(
            nomeCompleto: 'Sem id',
            dataNascimento: DateTime(2019),
            parentesco: 'Filho(a)',
          ),
          dependente(3),
        ],
      );
      final lista = await servico(
        repo,
      ).listarParticipantes(usuarioId: usuarioId, inscricoesAtuais: []);

      expect(lista.map((p) => p.chave), ['titular', 'dependente:3']);
    });

    test(
      'inscrito que perdeu o vínculo aparece só para cancelamento',
      () async {
        final repo = RepositorioStub(dependentes: [dependente(1)]);
        final lista = await servico(repo).listarParticipantes(
          usuarioId: usuarioId,
          inscricoesAtuais: const [
            Inscricao(usuarioId: usuarioId, comunicacaoId: campanhaId),
            Inscricao(
              usuarioId: usuarioId,
              comunicacaoId: campanhaId,
              dependenteId: 1,
              participanteNome: 'Dependente 1',
            ),
            Inscricao(
              usuarioId: usuarioId,
              comunicacaoId: campanhaId,
              dependenteId: 9,
              participanteNome: 'Ex-dependente',
            ),
            Inscricao(
              usuarioId: usuarioId,
              comunicacaoId: campanhaId,
              dependenteId: 10,
            ),
          ],
        );

        expect(lista.map((p) => p.chave), [
          'titular',
          'dependente:1',
          'dependente:9',
          'dependente:10',
        ]);
        expect(lista[2].vinculoAtivo, isFalse);
        expect(lista[2].nome, 'Ex-dependente');
        expect(lista[3].nome, 'Dependente');
        expect(lista[3].parentesco, 'Cadastro indisponível');
      },
    );
  });

  // ------------------------------------------------------------------
  group('inscricoesDoUsuario', () {
    test('devolve só as inscrições da própria conta', () async {
      final repo = RepositorioStub(
        inscricoes: const [
          Inscricao(usuarioId: usuarioId, comunicacaoId: campanhaId),
          Inscricao(usuarioId: 99, comunicacaoId: campanhaId),
          Inscricao(usuarioId: usuarioId, comunicacaoId: 1),
        ],
      );
      final minhas = await servico(
        repo,
      ).inscricoesDoUsuario(comunicacaoId: campanhaId, usuarioId: usuarioId);
      expect(minhas, hasLength(1));
      expect(minhas.single.usuarioId, usuarioId);
    });
  });

  // ------------------------------------------------------------------
  group('salvarInscricoes (passos 5 a 7)', () {
    Future<ResultadoInscricao> salvar(
      RepositorioStub repo, {
      NewsModel? camp,
      int? usuario = usuarioId,
      List<Participante>? participantes,
      Set<String> atuais = const {},
      required Set<String> escolhidos,
    }) => servico(repo).salvarInscricoes(
      campanha: camp ?? campanha(),
      usuarioId: usuario,
      participantes:
          participantes ?? [participante(null), participante(1)],
      inscritosAtuais: atuais,
      escolhidos: escolhidos,
    );

    test('fluxo principal: inscreve titular e dependente', () async {
      final repo = RepositorioStub();
      final r = await salvar(repo, escolhidos: {'titular', 'dependente:1'});

      expect(repo.chamadas, [
        const Chamada('inscrever', campanhaId, usuarioId, null),
        const Chamada('inscrever', campanhaId, usuarioId, 1),
      ]);
      expect(r.alteracoes, 2);
      expect(r.sucessoTotal, isTrue);
      expect(
        r.mensagem('Gripe'),
        'Inscrições atualizadas para 2 participante(s) em: Gripe.',
      );
    });

    test('A1: desmarcar participante cancela a inscrição', () async {
      final repo = RepositorioStub();
      final r = await salvar(
        repo,
        atuais: {'titular', 'dependente:1'},
        escolhidos: {'titular'},
      );
      expect(repo.chamadas, [
        const Chamada('desinscrever', campanhaId, usuarioId, 1),
      ]);
      expect(r.alteracoes, 1);
    });

    test('A3/RN04: sem alterações não chama o banco', () async {
      final repo = RepositorioStub();
      final r = await salvar(
        repo,
        atuais: {'titular'},
        escolhidos: {'titular'},
      );
      expect(repo.chamadas, isEmpty);
      expect(r.mensagem('X'), 'Nenhuma alteração nas inscrições.');
    });

    test('RN02: campanha encerrada não aceita inscrição nova', () async {
      final repo = RepositorioStub();
      final r = await salvar(
        repo,
        camp: campanha(dataFim: '2026-11-19'),
        atuais: {'titular'},
        escolhidos: {'titular', 'dependente:1'},
      );
      expect(repo.chamadas, isEmpty);
      expect(r.falhas, ['Dependente 1: campanha encerrada']);
      expect(r.mensagem('X'), startsWith('Algumas inscrições não foram'));
    });

    test('RN02/A4: campanha encerrada permite cancelar', () async {
      final repo = RepositorioStub();
      final r = await salvar(
        repo,
        camp: campanha(status: 'ENCERRADA'),
        atuais: {'titular'},
        escolhidos: {},
      );
      expect(repo.chamadas, [
        const Chamada('desinscrever', campanhaId, usuarioId, null),
      ]);
      expect(r.sucessoTotal, isTrue);
    });

    test('RN03: dependente sem vínculo ativo não é inscrito', () async {
      final repo = RepositorioStub();
      final r = await salvar(
        repo,
        participantes: [participante(null), participante(5, vinculoAtivo: false)],
        escolhidos: {'dependente:5'},
      );
      expect(repo.chamadas, isEmpty);
      expect(r.falhas, ['Dependente 5: vínculo não está ativo']);
    });

    test('RN03: dependente sem vínculo ativo ainda pode ser cancelado', () async {
      final repo = RepositorioStub();
      await salvar(
        repo,
        participantes: [participante(null), participante(5, vinculoAtivo: false)],
        atuais: {'dependente:5'},
        escolhidos: {},
      );
      expect(repo.chamadas, [
        const Chamada('desinscrever', campanhaId, usuarioId, 5),
      ]);
    });

    test('E4: falha no banco de um participante não impede os outros', () async {
      final repo = RepositorioStub(falharPara: {1});
      final r = await salvar(repo, escolhidos: {'titular', 'dependente:1'});
      expect(repo.chamadas, hasLength(2));
      expect(r.alteracoes, 1);
      expect(r.falhas.single, contains('Dependente 1'));
    });

    test('E4: falha ao cancelar também é informada', () async {
      final repo = RepositorioStub(falharPara: {null});
      final r = await salvar(repo, atuais: {'titular'}, escolhidos: {});
      expect(r.alteracoes, 0);
      expect(r.falhas.single, startsWith('Eu (titular):'));
    });

    test('E2: campanha sem ID é recusada antes de gravar', () async {
      final repo = RepositorioStub();
      await expectLater(
        salvar(repo, camp: campanha(id: null), escolhidos: {'titular'}),
        throwsA(isA<InscricaoException>()),
      );
      expect(repo.chamadas, isEmpty);
    });

    test('RN01: notícia é recusada antes de gravar', () async {
      final repo = RepositorioStub();
      await expectLater(
        salvar(repo, camp: campanha(tag: 'ALERTA'), escolhidos: {'titular'}),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoRecusa.naoECampanha,
          ),
        ),
      );
    });

    test('E3: usuário nulo é recusado antes de gravar', () async {
      final repo = RepositorioStub();
      await expectLater(
        salvar(repo, usuario: null, escolhidos: {'titular'}),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoRecusa.usuarioNaoIdentificado,
          ),
        ),
      );
    });

    // Análise de Valor Limite: titular + até 10 dependentes = 11 participantes.
    List<Participante> participantesAte(int n) => [
      participante(null),
      for (var i = 1; i < n; i++) participante(i),
    ];

    test('RN06 limite: 11 participantes (titular + 10) são aceitos', () async {
      final repo = RepositorioStub();
      final todos = participantesAte(11);
      final r = await salvar(
        repo,
        participantes: todos,
        escolhidos: todos.map((p) => p.chave).toSet(),
      );
      expect(r.alteracoes, 11);
    });

    test('RN06 limite: 12 participantes são recusados', () async {
      final repo = RepositorioStub();
      final todos = participantesAte(12);
      await expectLater(
        salvar(
          repo,
          participantes: todos,
          escolhidos: todos.map((p) => p.chave).toSet(),
        ),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.motivo,
            'motivo',
            MotivoRecusa.limiteDeParticipantes,
          ),
        ),
      );
      expect(repo.chamadas, isEmpty);
    });
  });

  // ------------------------------------------------------------------
  group('InscricaoException.mensagem', () {
    test('todas as recusas têm mensagem para o usuário', () {
      for (final motivo in MotivoRecusa.values) {
        final e = InscricaoException(motivo);
        expect(e.mensagem, isNotEmpty);
        expect(e.toString(), e.mensagem);
      }
      expect(
        const InscricaoException(MotivoRecusa.limiteDeParticipantes).mensagem,
        contains('11'),
      );
    });
  });
}
