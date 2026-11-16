import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/models/unidade_saude.dart';

void main() {
  test('distância formatada em metros ou quilômetros', () {
    expect(UnidadeSaude.formatarDistancia(347), '350 m');
    expect(UnidadeSaude.formatarDistancia(2440), '2,4 km');
    expect(UnidadeSaude.formatarDistancia(15300), '15 km');
  });

  test('lê a unidade do banco e reconhece atendimento 24 horas', () {
    final unidade = UnidadeSaude.fromMap({
      'id': 61,
      'tipo_instituicao': 'Hospital',
      'nome': 'Complexo Hospitalar Santa Casa',
      'telefone': '(11) 4481-8016',
      'endereco': 'Rua Cel Assis Goncalves, 700',
      'horario_seg_sex': '24 horas',
      'horario_domingo': '24 horas',
      'latitude': -22.95,
      'longitude': '-46.54',
    });
    expect(unidade.vinteQuatroHoras, isTrue);
    expect(unidade.temTelefone, isTrue);
    expect(unidade.temCoordenadas, isTrue);
    expect(unidade.longitude, -46.54);
  });

  test('telefone "Não informado" não vira botão de ligar', () {
    final unidade = UnidadeSaude.fromMap({
      'id': 1,
      'tipo_instituicao': 'UBS',
      'nome': 'ESF Penha',
      'telefone': 'Não informado',
      'endereco': '',
    });
    expect(unidade.temTelefone, isFalse);
    expect(unidade.temCoordenadas, isFalse);
  });
}
