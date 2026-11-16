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

  group('regra de autorização do vínculo', () {
    final hoje = DateTime(2026, 11, 15);

    test('menor de idade entra pela declaração do responsável', () {
      expect(
        DependenteModel.exigeAutorizacaoDoDependente(DateTime(2016, 5, 4), 'Filho(a)', hoje: hoje),
        isFalse,
      );
    });

    test('quem faz 18 anos amanhã ainda é menor', () {
      expect(
        DependenteModel.exigeAutorizacaoDoDependente(DateTime(2008, 11, 16), 'Filho(a)', hoje: hoje),
        isFalse,
      );
    });

    test('quem fez 18 anos hoje precisa autorizar', () {
      expect(
        DependenteModel.exigeAutorizacaoDoDependente(DateTime(2008, 11, 15), 'Filho(a)', hoje: hoje),
        isTrue,
      );
    });

    test('adulto tutelado entra pela declaração do responsável', () {
      expect(
        DependenteModel.exigeAutorizacaoDoDependente(DateTime(1990, 1, 1), ' Tutelado ', hoje: hoje),
        isFalse,
      );
    });

    test('adulto comum precisa autorizar', () {
      expect(
        DependenteModel.exigeAutorizacaoDoDependente(DateTime(1960, 1, 1), 'Pai', hoje: hoje),
        isTrue,
      );
    });
  });

  test('DependenteModel.fromMap lê a situação do vínculo', () {
    final dependente = DependenteModel.fromMap({
      'id': 1,
      'nome_completo': 'Pai',
      'data_nascimento': '1960-01-01',
      'parentesco': 'Pai',
      'status': 'pendente',
      'email_dependente': 'pai@exemplo.com',
    });
    expect(dependente.pendente, isTrue);
    expect(dependente.ativo, isFalse);
    expect(dependente.emailDependente, 'pai@exemplo.com');
  });
}
