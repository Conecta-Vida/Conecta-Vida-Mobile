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
  int? vagas,
  int inscritos = 0,
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
  vagas: vagas,
  inscritos: inscritos,
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

    test('CT01 · C5 — campanha aberta e usuário identificado: libera', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
        () => s.verificarAcesso(
          campanha: campanha(),
          usuarioId: usuarioId,
          possuiInscricoes: false,
        ),
        returnsNormally,
      );
    });

    test('CT17 · C2 — RN01: comunicação que não é campanha é recusada', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
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

    test('CT04 · C1 — E1/RN02: campanha encerrada sem inscrições é recusada', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
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

    test('CT10 · C7 — A4: campanha encerrada com inscrições abre para cancelar', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
        () => s.verificarAcesso(
          campanha: campanha(status: 'ENCERRADA'),
          usuarioId: usuarioId,
          possuiInscricoes: true,
        ),
        returnsNormally,
      );
    });

    test('CT20 · C2 — E2: campanha sem ID é recusada', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
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

    test('CT20 · C2 — E3: usuário não identificado é recusado', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
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

    test('CT28 · C1 — E5/RN07: campanha lotada sem inscrições é recusada', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
        () => s.verificarAcesso(
          campanha: campanha(vagas: 3, inscritos: 3),
          usuarioId: usuarioId,
          possuiInscricoes: false,
        ),
        throwsA(
          isA<InscricaoException>().having(
            (e) => e.mensagem,
            'mensagem',
            'As vagas desta campanha esgotaram.',
          ),
        ),
      );
    });

    test('CT29 · C7 — A4/RN07: campanha lotada com inscrições abre para cancelar', () {
      expect(
        // DRIVER: chama o serviço com a entrada do caso de teste.
        () => s.verificarAcesso(
          campanha: campanha(vagas: 3, inscritos: 3),
          usuarioId: usuarioId,
          possuiInscricoes: true,
        ),
        returnsNormally,
      );
    });
  });

  // ------------------------------------------------------------------
  group('listarParticipantes (passo 4)', () {
    test('CT02 · C5 — titular sempre primeiro, seguido dos dependentes ativos', () async {
      // STUB: dados fixos no lugar do banco.
      final repo = RepositorioStub(dependentes: [dependente(1), dependente(2)]);
      // DRIVER: chama o serviço com a entrada do caso de teste.
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

    test('CT12 · C5 — RN03: ignora dependente pendente e dependente sem id', () async {
      // STUB: dados fixos no lugar do banco.
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
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final lista = await servico(
        repo,
      ).listarParticipantes(usuarioId: usuarioId, inscricoesAtuais: []);

      expect(lista.map((p) => p.chave), ['titular', 'dependente:3']);
    });

    test(
      'CT14 · C7 — inscrito que perdeu o vínculo aparece só para cancelamento',
      () async {
        // STUB: dados fixos no lugar do banco.
        final repo = RepositorioStub(dependentes: [dependente(1)]);
        // DRIVER: chama o serviço com a entrada do caso de teste.
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
    test('CT01 · C5 — devolve só as inscrições da própria conta', () async {
      // STUB: dados fixos no lugar do banco.
      final repo = RepositorioStub(
        inscricoes: const [
          Inscricao(usuarioId: usuarioId, comunicacaoId: campanhaId),
          Inscricao(usuarioId: 99, comunicacaoId: campanhaId),
          Inscricao(usuarioId: usuarioId, comunicacaoId: 1),
        ],
      );
      // DRIVER: chama o serviço com a entrada do caso de teste.
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

    test('CT02 · C5 · P9 — fluxo principal: inscreve titular e dependente', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(repo, escolhidos: {'titular', 'dependente:1'});

      // MOCK: confere quais operações o serviço pediu ao banco.
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

    test('CT06 · C7 · P11 — A1: desmarcar participante cancela a inscrição', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        atuais: {'titular', 'dependente:1'},
        escolhidos: {'titular'},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, [
        const Chamada('desinscrever', campanhaId, usuarioId, 1),
      ]);
      expect(r.alteracoes, 1);
    });

    test('CT09 · C4 · P6 — A3/RN04: sem alterações não chama o banco', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        atuais: {'titular'},
        escolhidos: {'titular'},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, isEmpty);
      expect(r.mensagem('X'), 'Nenhuma alteração nas inscrições.');
    });

    test('CT11 · C6 · P7 — RN02: campanha encerrada não aceita inscrição nova', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        camp: campanha(dataFim: '2026-11-19'),
        atuais: {'titular'},
        escolhidos: {'titular', 'dependente:1'},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, isEmpty);
      expect(r.falhas, ['Dependente 1: campanha encerrada']);
      expect(r.mensagem('X'), startsWith('Algumas inscrições não foram'));
    });

    test('CT10 · C7 · P11 — RN02/A4: campanha encerrada permite cancelar', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        camp: campanha(status: 'ENCERRADA'),
        atuais: {'titular'},
        escolhidos: {},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, [
        const Chamada('desinscrever', campanhaId, usuarioId, null),
      ]);
      expect(r.sucessoTotal, isTrue);
    });

    test('CT21 · C10 · P8 — RN03: dependente sem vínculo ativo não é inscrito', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        participantes: [participante(null), participante(5, vinculoAtivo: false)],
        escolhidos: {'dependente:5'},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, isEmpty);
      expect(r.falhas, ['Dependente 5: vínculo não está ativo']);
    });

    test('CT14 · C7 · P11 — RN03: dependente sem vínculo ativo ainda pode ser cancelado', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      await salvar(
        repo,
        participantes: [participante(null), participante(5, vinculoAtivo: false)],
        atuais: {'dependente:5'},
        escolhidos: {},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, [
        const Chamada('desinscrever', campanhaId, usuarioId, 5),
      ]);
    });

    test('CT18 · C8 · P10 — E4: falha no banco de um participante não impede os outros', () async {
      // STUB: dados fixos no lugar do banco.
      final repo = RepositorioStub(falharPara: {1});
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(repo, escolhidos: {'titular', 'dependente:1'});
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, hasLength(2));
      expect(r.alteracoes, 1);
      expect(r.falhas.single, contains('Dependente 1'));
    });

    test('CT19 · C9 · P12 — E4: falha ao cancelar também é informada', () async {
      // STUB: dados fixos no lugar do banco.
      final repo = RepositorioStub(falharPara: {null});
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(repo, atuais: {'titular'}, escolhidos: {});
      expect(r.alteracoes, 0);
      expect(r.falhas.single, startsWith('Eu (titular):'));
    });

    test('CT20 · C2 · P1 — E2: campanha sem ID é recusada antes de gravar', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      await expectLater(
        // DRIVER: chama o serviço com a entrada do caso de teste.
        salvar(repo, camp: campanha(id: null), escolhidos: {'titular'}),
        throwsA(isA<InscricaoException>()),
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, isEmpty);
    });

    test('CT17 · C2 · P2 — RN01: notícia é recusada antes de gravar', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      await expectLater(
        // DRIVER: chama o serviço com a entrada do caso de teste.
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

    test('CT20 · C2 · P3 — E3: usuário nulo é recusado antes de gravar', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      await expectLater(
        // DRIVER: chama o serviço com a entrada do caso de teste.
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

    // Análise de Valor Limite da RN07: vagas restantes x novas inscrições.
    List<Participante> participantesAte(int n) => [
      participante(null),
      for (var i = 1; i < n; i++) participante(i),
    ];

    test('CT26 · C5 · P9 — RN07 limite: novas inscrições iguais às vagas restantes são aceitas', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        camp: campanha(vagas: 3, inscritos: 1),
        escolhidos: {'titular', 'dependente:1'},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, [
        const Chamada('inscrever', campanhaId, usuarioId, null),
        const Chamada('inscrever', campanhaId, usuarioId, 1),
      ]);
      expect(r.alteracoes, 2);
    });

    test('CT27 · C11 · P4 — RN07 limite: uma inscrição além das vagas restantes é recusada (E6)', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      await expectLater(
        // DRIVER: chama o serviço com a entrada do caso de teste.
        salvar(
          repo,
          camp: campanha(vagas: 2, inscritos: 1),
          escolhidos: {'titular', 'dependente:1'},
        ),
        throwsA(
          isA<InscricaoException>()
              .having((e) => e.motivo, 'motivo', MotivoRecusa.vagasInsuficientes)
              .having(
                (e) => e.mensagem,
                'mensagem',
                'Restam 1 vaga(s) nesta campanha.',
              ),
        ),
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, isEmpty);
    });

    test('CT29 · C7 · P11 — RN07: campanha lotada ainda permite cancelar', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        camp: campanha(vagas: 2, inscritos: 2),
        atuais: {'titular'},
        escolhidos: {},
      );
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, [
        const Chamada('desinscrever', campanhaId, usuarioId, null),
      ]);
      expect(r.sucessoTotal, isTrue);
    });

    test('P5 — laço sem participantes: nada é gravado', () async {
      final repo = RepositorioStub();
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(repo, participantes: [], escolhidos: {});
      // MOCK: confere quais operações o serviço pediu ao banco.
      expect(repo.chamadas, isEmpty);
      expect(r.alteracoes, 0);
    });

    test('CT32 · C8 · P10 — E4/RN07: banco recusa a vaga disputada', () async {
      // STUB: dados fixos no lugar do banco.
      final repo = RepositorioStub(
        falharPara: {null},
        mensagemDeFalha: 'Vagas esgotadas para esta campanha.',
      );
      // DRIVER: chama o serviço com a entrada do caso de teste.
      final r = await salvar(
        repo,
        camp: campanha(vagas: 5, inscritos: 1),
        participantes: participantesAte(1),
        escolhidos: {'titular'},
      );
      expect(r.alteracoes, 0);
      expect(r.falhas.single, contains('Vagas esgotadas para esta campanha.'));
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
        const InscricaoException(
          MotivoRecusa.vagasInsuficientes,
          vagasRestantes: 1,
        ).mensagem,
        'Restam 1 vaga(s) nesta campanha.',
      );
    });
  });
}
