class DependenteModel {
  final int? id;
  final String nomeCompleto;
  final DateTime dataNascimento;
  final String parentesco;
  final String? sexo;

  const DependenteModel({this.id, required this.nomeCompleto, required this.dataNascimento, required this.parentesco, this.sexo});

  factory DependenteModel.fromMap(Map<String, dynamic> map) => DependenteModel(
    id: map['id'] is num ? (map['id'] as num).toInt() : int.tryParse('${map['id']}'),
    nomeCompleto: (map['nomeCompleto'] ?? map['nome_completo'] ?? '').toString(),
    dataNascimento: DateTime.parse((map['dataNascimento'] ?? map['data_nascimento']).toString()),
    parentesco: (map['parentesco'] ?? '').toString(),
    sexo: map['sexo']?.toString(),
  );

  Map<String, dynamic> toRequestMap() => {
    'nomeCompleto': nomeCompleto.trim(),
    'dataNascimento': '${dataNascimento.year.toString().padLeft(4, '0')}-${dataNascimento.month.toString().padLeft(2, '0')}-${dataNascimento.day.toString().padLeft(2, '0')}',
    'parentesco': parentesco.trim(),
    'sexo': sexo,
  };
}
