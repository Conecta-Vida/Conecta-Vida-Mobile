class UserModel {
  final String nome;
  final String email;
  final String idade;
  final String sexo;
  final String localizacao;

  const UserModel({
    required this.nome,
    required this.email,
    required this.idade,
    required this.sexo,
    required this.localizacao,
  });

  Map<String, dynamic> toMap({String senha = ''}) {
    return {
      'nome': nome,
      'email': email,
      'idade': idade,
      'sexo': sexo,
      'localizacao': localizacao,
      'senha': senha,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      nome: map['nome'] ?? '',
      email: map['email'] ?? '',
      idade: map['idade'] ?? '',
      sexo: map['sexo'] ?? '',
      localizacao: map['localizacao'] ?? '',
    );
  }
}

