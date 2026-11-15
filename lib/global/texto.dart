/// Utilitários de comparação de texto.
class Texto {
  static const Map<String, String> _acentos = {
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// Minúsculas, sem acentos e sem espaços sobrando, para comparar textos
  /// digitados de formas diferentes ("Bragança Paulista" e " braganca paulista").
  static String normalizar(String valor) {
    final minusculo = valor.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final saida = StringBuffer();
    for (final caractere in minusculo.split('')) {
      saida.write(_acentos[caractere] ?? caractere);
    }
    return saida.toString();
  }

  /// `texto` contém `trecho`, ignorando acentos, maiúsculas e espaços extras.
  static bool contem(String texto, String trecho) =>
      normalizar(texto).contains(normalizar(trecho));
}
