/// Entidades de domínio do caso de uso "Inscrever-se em campanha".
library;

/// Inscrição de um participante (titular ou dependente) numa campanha.
/// `dependenteId` nulo significa que o próprio titular participará.
class Inscricao {
  final int? id;
  final int usuarioId;
  final int comunicacaoId;
  final int? dependenteId;
  final String participanteNome;
  final String parentesco;

  const Inscricao({
    this.id,
    required this.usuarioId,
    required this.comunicacaoId,
    this.dependenteId,
    this.participanteNome = '',
    this.parentesco = 'Titular',
  });

  bool get doTitular => dependenteId == null;

  /// Identifica o participante dentro da conta: `titular` ou `dependente:<id>`.
  String get chaveParticipante =>
      Participante.chaveDe(dependenteId: dependenteId);

  static int? _inteiro(Object? valor) {
    if (valor is num) return valor.toInt();
    return int.tryParse(valor?.toString() ?? '');
  }

  factory Inscricao.fromMap(Map<String, dynamic> map) => Inscricao(
    id: _inteiro(map['inscricao_id'] ?? map['id']),
    usuarioId: _inteiro(map['usuario_id']) ?? 0,
    comunicacaoId: _inteiro(map['comunicacao_id']) ?? 0,
    dependenteId: _inteiro(map['dependente_id']),
    participanteNome: (map['participante_nome'] ?? '').toString(),
    parentesco: (map['parentesco'] ?? 'Titular').toString(),
  );
}

/// Pessoa que pode ser marcada no diálogo de inscrição.
class Participante {
  final int? dependenteId;
  final String nome;
  final String parentesco;

  /// Falso para dependente cujo vínculo deixou de estar ativo, mas que ainda
  /// tem inscrição (o titular só pode cancelá-la, nunca criar uma nova).
  final bool vinculoAtivo;

  const Participante({
    this.dependenteId,
    required this.nome,
    required this.parentesco,
    this.vinculoAtivo = true,
  });

  const Participante.titular()
    : dependenteId = null,
      nome = 'Eu (titular)',
      parentesco = 'Titular',
      vinculoAtivo = true;

  bool get ehTitular => dependenteId == null;

  String get chave => chaveDe(dependenteId: dependenteId);

  static String chaveDe({int? dependenteId}) =>
      dependenteId == null ? 'titular' : 'dependente:$dependenteId';
}
