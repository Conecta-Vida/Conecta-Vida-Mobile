// =====================================================================
// STUB + MOCK do repositório de inscrições (Trabalho 2 de Qualidade).
//
// * STUB: substitui o Supabase devolvendo dados fixos (dependentes e
//   inscrições) configurados por cada teste.
// * MOCK (espião): registra cada chamada de inscrever/desinscrever para o
//   teste verificar QUAIS operações o caso de uso pediu ao banco.
// * Pode ser configurado para falhar em um participante, simulando um erro
//   de rede ou uma recusa da RLS.
// =====================================================================
import 'package:mobile_app/models/dependente.dart';
import 'package:mobile_app/models/inscricao.dart';
import 'package:mobile_app/usecases/inscricao_campanha_service.dart';

class Chamada {
  final String operacao; // 'inscrever' ou 'desinscrever'
  final int comunicacaoId;
  final int usuarioId;
  final int? dependenteId;

  const Chamada(
    this.operacao,
    this.comunicacaoId,
    this.usuarioId,
    this.dependenteId,
  );

  @override
  bool operator ==(Object other) =>
      other is Chamada &&
      other.operacao == operacao &&
      other.comunicacaoId == comunicacaoId &&
      other.usuarioId == usuarioId &&
      other.dependenteId == dependenteId;

  @override
  int get hashCode =>
      Object.hash(operacao, comunicacaoId, usuarioId, dependenteId);

  @override
  String toString() =>
      '$operacao(campanha: $comunicacaoId, usuario: $usuarioId, '
      'dependente: $dependenteId)';
}

class RepositorioStub implements InscricaoRepository {
  /// Dados devolvidos pelo stub.
  List<DependenteModel> dependentes;
  List<Inscricao> inscricoes;

  /// Dependente (ou `null` = titular) cuja gravação deve falhar.
  final Set<int?> falharPara;

  /// Mensagem da exceção simulada (ex.: a recusa do gatilho de vagas do banco).
  final String mensagemDeFalha;

  /// Registro das chamadas (papel de mock).
  final List<Chamada> chamadas = [];

  RepositorioStub({
    this.dependentes = const [],
    this.inscricoes = const [],
    this.falharPara = const {},
    this.mensagemDeFalha = 'falha simulada no banco',
  });

  @override
  Future<List<DependenteModel>> buscarDependentesAtivos(int usuarioId) async =>
      dependentes;

  @override
  Future<List<Inscricao>> buscarInscricoes(int comunicacaoId) async =>
      inscricoes.where((i) => i.comunicacaoId == comunicacaoId).toList();

  @override
  Future<void> inscrever({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  }) async {
    chamadas.add(
      Chamada('inscrever', comunicacaoId, usuarioId, dependenteId),
    );
    if (falharPara.contains(dependenteId)) {
      // STUB: falha simulada no banco para este participante.
      throw Exception(mensagemDeFalha);
    }
  }

  @override
  Future<void> desinscrever({
    required int comunicacaoId,
    required int usuarioId,
    int? dependenteId,
  }) async {
    chamadas.add(
      Chamada('desinscrever', comunicacaoId, usuarioId, dependenteId),
    );
    if (falharPara.contains(dependenteId)) {
      // STUB: falha simulada no banco para este participante.
      throw Exception(mensagemDeFalha);
    }
  }
}
