import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/global/texto.dart';

void main() {
  group('Texto.normalizar', () {
    test('remove acentos, maiúsculas e espaços sobrando', () {
      expect(Texto.normalizar('  Bragança   Paulista '), 'braganca paulista');
      expect(Texto.normalizar('VACINAÇÃO'), 'vacinacao');
      expect(Texto.normalizar('Bom Jesus dos Perdões\r\n'), 'bom jesus dos perdoes');
    });

    test('trata como iguais as grafias diferentes da mesma cidade', () {
      expect(
        Texto.normalizar('Braganca Paulista'),
        Texto.normalizar('Bragança Paulista'),
      );
      expect(Texto.normalizar(' Atibaia'), Texto.normalizar('Atibaia'));
    });
  });

  group('Texto.contem', () {
    test('encontra o trecho ignorando acentos e maiúsculas', () {
      expect(Texto.contem('Campanha de Vacinação', 'vacinacao'), isTrue);
      expect(Texto.contem('Braganca Paulista', 'Bragança'), isTrue);
    });

    test('não encontra o que não existe', () {
      expect(Texto.contem('Atibaia', 'Itatiba'), isFalse);
    });
  });
}
