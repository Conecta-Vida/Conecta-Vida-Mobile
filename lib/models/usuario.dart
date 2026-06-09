class UserModel {
  final String nome;
  final String email;
  final int?
  dataNascimento; // Alterado para int e opcional (null) conforme o banco
  final String sexo;
  final String localizacao;

  const UserModel({
    required this.nome,
    required this.email,
    this.dataNascimento,
    required this.sexo,
    required this.localizacao,
  });

  Map<String, dynamic> toMap({String senha = ''}) {
    return {
      'nome': nome,
      'email': email,
      'data_nascimento': dataNascimento, // Nome exato da nova coluna do banco
      'sexo': sexo,
      'localizacao': localizacao,
      'senha': senha,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      // Tenta ler como int, se vier string ou nulo, trata com segurança
      dataNascimento: map['data_nascimento'] is int
          ? map['data_nascimento']
          : int.tryParse(map['data_nascimento']?.toString() ?? ''),
      sexo: map['sexo'] ?? '',
      localizacao: map['localizacao'] ?? '',
    );
  }
}
