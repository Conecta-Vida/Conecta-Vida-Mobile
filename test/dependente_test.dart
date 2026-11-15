import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/dependente.dart';

void main() {
  test('DependenteModel.fromMap aceita as colunas do banco', () {
    final dependente = DependenteModel.fromMap({
      'id': 3,
      'nome_completo': 'Pedro Teste',
      'data_nascimento': '2016-05-04',
      'parentesco': 'Filho(a)',
      'sexo': null,
    });
    expect(dependente.id, 3);
    expect(dependente.nomeCompleto, 'Pedro Teste');
    expect(dependente.dataNascimento, DateTime(2016, 5, 4));
    expect(dependente.parentesco, 'Filho(a)');
    expect(dependente.sexo, isNull);
  });

  test('toRequestMap formata a data com zeros à esquerda e limpa espaços', () {
    final dados = DependenteModel(
      nomeCompleto: '  Ana  ',
      dataNascimento: DateTime(2010, 1, 9),
      parentesco: ' Mãe ',
    ).toRequestMap();
    expect(dados['nomeCompleto'], 'Ana');
    expect(dados['dataNascimento'], '2010-01-09');
    expect(dados['parentesco'], 'Mãe');
  });
}
