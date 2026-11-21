/// Camada de aplicação do caso de uso "Inscrever-se em campanha".
///
/// Concentra as regras de negócio que antes ficavam espalhadas pela tela de
/// detalhes. O acesso a dados é feito por [InscricaoRepository], o que
/// permite testar o serviço sem o Supabase.
library;

import '../models/dependente.dart';
import '../models/inscricao.dart';
import '../models/noticia.dart';

/// Porta de acesso a dados usada pelo caso de uso.
/// Em produção: `SupabaseInscricaoRepository`.
abstract class InscricaoRepository {
  Future<List<DependenteModel>> buscarDependentesAtivos(int usuarioId);
  Future<List<Inscricao>> buscarInscricoes(int comunicacaoId);
  Future<void> inscrever({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  });
  Future<void> desinscrever({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  });
}

/// Motivos pelos quais o caso de uso não pode prosseguir. [campanhaLotada] é
/// E5 (vagas esgotadas) e [vagasInsuficientes] é E6 (novas inscrições além das
/// vagas restantes), ambos da RN07.
enum MotivoRecusa {
  campanhaSemId,
  naoECampanha,
  campanhaEncerrada,
  usuarioNaoIdentificado,
  campanhaLotada,
  vagasInsuficientes,
}

class InscricaoException implements Exception {
  final MotivoRecusa motivo;

  /// Vagas que ainda restam (usada na mensagem de E6).
  final int? vagasRestantes;
  const InscricaoException(this.motivo, {this.vagasRestantes});

  String get mensagem => switch (motivo) {
    MotivoRecusa.campanhaSemId =>
      'Esta campanha ainda não possui ID válido para inscrição.',
    MotivoRecusa.naoECampanha => 'Só é possível se inscrever em campanhas.',
    MotivoRecusa.campanhaEncerrada => 'Esta campanha já foi encerrada.',
    MotivoRecusa.usuarioNaoIdentificado =>
      'Não foi possível identificar o usuário para inscrição.',
    MotivoRecusa.campanhaLotada => 'As vagas desta campanha esgotaram.',
    MotivoRecusa.vagasInsuficientes =>
      'Restam ${vagasRestantes ?? 0} vaga(s) nesta campanha.',
  };

  @override
  String toString() => mensagem;
}

/// Resultado de "Salvar inscrições" (passos 6 e 7 do fluxo principal).
class ResultadoInscricao {
  final int alteracoes;
  final int selecionados;
  final List<String> falhas;

  const ResultadoInscricao({
    required this.alteracoes,
    required this.selecionados,
    this.falhas = const [],
  });

  bool get sucessoTotal => falhas.isEmpty;

  String mensagem(String tituloCampanha) {
    if (falhas.isNotEmpty) {
      return 'Algumas inscrições não foram atualizadas: ${falhas.join('; ')}';
    }
    if (alteracoes == 0) return 'Nenhuma alteração nas inscrições.';
    return 'Inscrições atualizadas para $selecionados participante(s) '
        'em: $tituloCampanha.';
  }
}

class InscricaoCampanhaService {
  final InscricaoRepository _repositorio;
  final DateTime Function() _agora;

  InscricaoCampanhaService(this._repositorio, {DateTime Function()? agora})
    : _agora = agora ?? DateTime.now;

  /// Passo 4: confere se o diálogo pode ser aberto (RN01, RN02, RN07, E1 a E3
  /// e E5). Campanha encerrada ou lotada só abre para quem já tem inscrição
  /// (A4: cancelar).
  void verificarAcesso({
    required NewsModel campanha,
    required int? usuarioId,
    required bool possuiInscricoes,
  }) {
    if (!campanha.ehCampanha) {
      throw const InscricaoException(MotivoRecusa.naoECampanha);
    }
    if (campanha.encerradaEm(_agora()) && !possuiInscricoes) {
      throw const InscricaoException(MotivoRecusa.campanhaEncerrada);
    }
    if (campanha.lotada && !possuiInscricoes) {
      throw const InscricaoException(MotivoRecusa.campanhaLotada);
    }
    if (campanha.id == null) {
      throw const InscricaoException(MotivoRecusa.campanhaSemId);
    }
    if (usuarioId == null) {
      throw const InscricaoException(MotivoRecusa.usuarioNaoIdentificado);
    }
  }

  /// Inscrições da conta [usuarioId] na campanha (passo 2).
  Future<List<Inscricao>> inscricoesDoUsuario({
    required int comunicacaoId,
    required int usuarioId,
  }) async {
    final todas = await _repositorio.buscarInscricoes(comunicacaoId);
    return todas.where((i) => i.usuarioId == usuarioId).toList();
  }

  /// Passo 4: titular, dependentes com vínculo ativo (RN03) e, para poder
  /// cancelar, dependentes que já estavam inscritos mas perderam o vínculo.
  Future<List<Participante>> listarParticipantes({
    required int usuarioId,
    required List<Inscricao> inscricoesAtuais,
  }) async {
    final participantes = <Participante>[const Participante.titular()];
    final chaves = <String>{participantes.first.chave};

    for (final dependente in await _repositorio.buscarDependentesAtivos(
      usuarioId,
    )) {
      if (dependente.id == null || !dependente.ativo) continue;
      final participante = Participante(
        dependenteId: dependente.id,
        nome: dependente.nomeCompleto,
        parentesco: dependente.parentesco,
      );
      if (chaves.add(participante.chave)) participantes.add(participante);
    }

    for (final inscricao in inscricoesAtuais) {
      if (inscricao.doTitular) continue;
      if (!chaves.add(inscricao.chaveParticipante)) continue;
      participantes.add(
        Participante(
          dependenteId: inscricao.dependenteId,
          nome: inscricao.participanteNome.isEmpty
              ? 'Dependente'
              : inscricao.participanteNome,
          parentesco: 'Cadastro indisponível',
          vinculoAtivo: false,
        ),
      );
    }
    return participantes;
  }

  /// Passos 5 a 7: compara quem estava inscrito com quem foi marcado e
  /// inscreve/cancela cada participante alterado, aplicando RN01 a RN04 e RN07.
  Future<ResultadoInscricao> salvarInscricoes({
    required NewsModel campanha,
    required int? usuarioId,
    required List<Participante> participantes,
    required Set<String> inscritosAtuais,
    required Set<String> escolhidos,
  }) async {
    final comunicacaoId = campanha.id;
    if (comunicacaoId == null) {
      throw const InscricaoException(MotivoRecusa.campanhaSemId);
    }
    if (!campanha.ehCampanha) {
      throw const InscricaoException(MotivoRecusa.naoECampanha);
    }
    if (usuarioId == null) {
      throw const InscricaoException(MotivoRecusa.usuarioNaoIdentificado);
    }
    if (!campanha.comportaNovas(escolhidos.difference(inscritosAtuais).length)) {
      throw InscricaoException(
        MotivoRecusa.vagasInsuficientes,
        vagasRestantes: campanha.vagasRestantes,
      );
    }

    final encerrada = campanha.encerradaEm(_agora());
    final falhas = <String>[];
    var alteracoes = 0;

    for (final participante in participantes) {
      final estavaInscrito = inscritosAtuais.contains(participante.chave);
      final deveEstarInscrito = escolhidos.contains(participante.chave);
      // RN04: sem mudança para este participante, nada a fazer.
      if (estavaInscrito == deveEstarInscrito) continue;

      if (deveEstarInscrito) {
        // RN02: campanha encerrada não aceita inscrição nova.
        if (encerrada) {
          falhas.add('${participante.nome}: campanha encerrada');
          continue;
        }
        // RN03: só titular ou dependente com vínculo ativo.
        if (!participante.vinculoAtivo) {
          falhas.add('${participante.nome}: vínculo não está ativo');
          continue;
        }
      }

      try {
        if (deveEstarInscrito) {
          await _repositorio.inscrever(
            comunicacaoId: comunicacaoId,
            usuarioId: usuarioId,
            dependenteId: participante.dependenteId,
          );
        } else {
          await _repositorio.desinscrever(
            comunicacaoId: comunicacaoId,
            usuarioId: usuarioId,
            dependenteId: participante.dependenteId,
          );
        }
        alteracoes++;
      } catch (erro) {
        falhas.add('${participante.nome}: $erro');
      }
    }

    return ResultadoInscricao(
      alteracoes: alteracoes,
      selecionados: escolhidos.length,
      falhas: falhas,
    );
  }
}
