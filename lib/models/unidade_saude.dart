/// Unidade de saúde (UBS, hospital, UPA, CAPS, SAMU) vinda do CNES.
class UnidadeSaude {
  final int id;
  final String tipo;
  final String nome;
  final String telefone;
  final String endereco;
  final String horarioSemana;
  final String horarioSabado;
  final String horarioDomingo;
  final double? latitude;
  final double? longitude;

  /// Distância até o usuário, em metros (quando a localização é conhecida).
  final double? distancia;

  const UnidadeSaude({
    required this.id,
    required this.tipo,
    required this.nome,
    required this.telefone,
    required this.endereco,
    this.horarioSemana = '',
    this.horarioSabado = '',
    this.horarioDomingo = '',
    this.latitude,
    this.longitude,
    this.distancia,
  });

  bool get temCoordenadas => latitude != null && longitude != null;

  bool get temTelefone {
    final digitos = telefone.replaceAll(RegExp(r'\D'), '');
    return digitos.length >= 8;
  }

  /// Atende 24 horas todos os dias.
  bool get vinteQuatroHoras =>
      horarioSemana.toLowerCase().contains('24 horas') &&
      horarioDomingo.toLowerCase().contains('24 horas');

  UnidadeSaude comDistancia(double? metros) => UnidadeSaude(
    id: id,
    tipo: tipo,
    nome: nome,
    telefone: telefone,
    endereco: endereco,
    horarioSemana: horarioSemana,
    horarioSabado: horarioSabado,
    horarioDomingo: horarioDomingo,
    latitude: latitude,
    longitude: longitude,
    distancia: metros,
  );

  /// "350 m" ou "2,4 km".
  static String formatarDistancia(double metros) {
    if (metros < 1000) return '${(metros / 10).round() * 10} m';
    final km = metros / 1000;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0).replaceAll('.', ',')} km';
  }

  factory UnidadeSaude.fromMap(Map<String, dynamic> map) {
    double? numero(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
    String texto(dynamic v) => (v ?? '').toString().trim();
    return UnidadeSaude(
      id: (map['id'] as num).toInt(),
      tipo: texto(map['tipo_instituicao']),
      nome: texto(map['nome']),
      telefone: texto(map['telefone']),
      endereco: texto(map['endereco']),
      horarioSemana: texto(map['horario_seg_sex']),
      horarioSabado: texto(map['horario_sabado']),
      horarioDomingo: texto(map['horario_domingo']),
      latitude: numero(map['latitude']),
      longitude: numero(map['longitude']),
    );
  }
}
