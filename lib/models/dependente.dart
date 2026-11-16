class DependenteModel {
  final int? id;
  final String nomeCompleto;
  final DateTime dataNascimento;
  final String parentesco;
  final String? sexo;

  /// Situação do vínculo: `pendente` (aguarda o aceite do dependente adulto),
  /// `ativo` ou `revogado`.
  final String status;

  /// E-mail do dependente adulto, que precisa autorizar o vínculo no app.
  final String? emailDependente;

  /// O titular declarou ser o responsável legal (menor de idade ou tutelado).
  final bool declarouResponsabilidade;

  const DependenteModel({
    this.id,
    required this.nomeCompleto,
    required this.dataNascimento,
    required this.parentesco,
    this.sexo,
    this.status = 'ativo',
    this.emailDependente,
    this.declarouResponsabilidade = false,
  });

  bool get pendente => status == 'pendente';
  bool get ativo => status == 'ativo';

  /// Idade completa em anos em [hoje].
  static int idadeEm(DateTime nascimento, DateTime hoje) {
    var idade = hoje.year - nascimento.year;
    final aindaNaoFezAniversario =
        hoje.month < nascimento.month ||
        (hoje.month == nascimento.month && hoje.day < nascimento.day);
    if (aindaNaoFezAniversario) idade--;
    return idade;
  }

  /// Regra do vínculo: menores de 18 anos e tutelados entram pela declaração
  /// do responsável; os demais adultos precisam autorizar pelo próprio login.
  static bool exigeAutorizacaoDoDependente(
    DateTime nascimento,
    String parentesco, {
    DateTime? hoje,
  }) {
    if (parentesco.trim().toLowerCase() == 'tutelado') return false;
    return idadeEm(nascimento, hoje ?? DateTime.now()) >= 18;
  }

  factory DependenteModel.fromMap(Map<String, dynamic> map) => DependenteModel(
    id: map['id'] is num ? (map['id'] as num).toInt() : int.tryParse('${map['id']}'),
    nomeCompleto: (map['nomeCompleto'] ?? map['nome_completo'] ?? '').toString(),
    dataNascimento: DateTime.parse((map['dataNascimento'] ?? map['data_nascimento']).toString()),
    parentesco: (map['parentesco'] ?? '').toString(),
    sexo: map['sexo']?.toString(),
    status: (map['status'] ?? 'ativo').toString(),
    emailDependente: (map['emailDependente'] ?? map['email_dependente'])?.toString(),
    declarouResponsabilidade:
        (map['declarouResponsabilidade'] ?? map['declarou_responsabilidade']) == true,
  );

  Map<String, dynamic> toRequestMap() => {
    'nomeCompleto': nomeCompleto.trim(),
    'dataNascimento': '${dataNascimento.year.toString().padLeft(4, '0')}-${dataNascimento.month.toString().padLeft(2, '0')}-${dataNascimento.day.toString().padLeft(2, '0')}',
    'parentesco': parentesco.trim(),
    'sexo': sexo,
  };
}

/// Pedido para o usuário logado ser dependente de outra conta.
class ConviteDependente {
  final int id;
  final String titularNome;
  final String parentesco;
  final String status;

  const ConviteDependente({
    required this.id,
    required this.titularNome,
    required this.parentesco,
    required this.status,
  });

  bool get pendente => status == 'pendente';

  factory ConviteDependente.fromMap(Map<String, dynamic> map) => ConviteDependente(
    id: (map['id'] as num).toInt(),
    titularNome: (map['titular_nome'] ?? '').toString(),
    parentesco: (map['parentesco'] ?? '').toString(),
    status: (map['status'] ?? 'pendente').toString(),
  );
}
