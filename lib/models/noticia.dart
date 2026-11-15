// lib/model/news_model.dart
class NewsModel {
  final int? id;
  final String tag;
  final String data;
  final String dataInicio;
  final String dataFim;
  final String titulo;
  final String subtitulo;
  final String descricao;
  final String imagem;
  final String categoria;
  final String local;
  final String publicoAlvo;
  final String textoBotaoAcao;
  final String orgao;
  final String orgaoTelefone;
  final String orgaoSite;
  final String status;

  /// Endereço da matéria original, quando veio de uma fonte oficial.
  final String fonteUrl;

  /// Vale para todas as cidades (ex.: notícias nacionais do Ministério da Saúde).
  bool get abrangenciaGeral {
    final onde = local.trim().toLowerCase();
    return onde.isEmpty ||
        onde == 'geral' ||
        onde == 'região geral' ||
        onde == 'nacional';
  }

  bool get ehCampanha => tag.toUpperCase() == 'CAMPANHA';

  /// Nome do tipo para mostrar ao usuário ("Notícia", "Campanha", "Alerta").
  String get tipoLegivel => switch (tag.toUpperCase()) {
    'NOTICIA' => 'Notícia',
    'CAMPANHA' => 'Campanha',
    'ALERTA' => 'Alerta',
    _ => tag,
  };

  /// Data de publicação no formato brasileiro (dd/mm/aaaa).
  String get dataLegivel {
    final partes = data.trim().split('-');
    if (partes.length != 3 || partes[0].length != 4) return data;
    return '${partes[2]}/${partes[1]}/${partes[0]}';
  }

  /// Campanha encerrada pelo painel ou com a data de término já passada.
  bool get encerrada {
    if (!ehCampanha) return false;
    final situacao = status.toUpperCase();
    if (situacao.startsWith('ENCERR') || situacao.startsWith('CONCLU')) {
      return true;
    }
    if (dataFim.trim().length < 10) return false;
    final fim = DateTime.tryParse(dataFim.trim().substring(0, 10));
    if (fim == null) return false;
    final hoje = DateTime.now();
    return fim.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  NewsModel({
    this.id,
    required this.tag,
    required this.data,
    this.dataInicio = '',
    this.dataFim = '',
    required this.titulo,
    required this.subtitulo,
    required this.descricao,
    required this.imagem,
    this.categoria = 'Geral', // Valores padrão caso não seja preenchido
    this.local = 'Bragança Paulista',
    this.publicoAlvo = 'População em Geral',
    this.textoBotaoAcao = 'Saber Mais',
    this.orgao = 'Secretaria de Saúde',
    this.orgaoTelefone = '(11) 4002-8922',
    this.orgaoSite = 'https://www.saude.gov.br',
    this.status = '',
    this.fonteUrl = '',
  });

  factory NewsModel.fromMap(Map<String, dynamic> map) {
    // Pegamos a data bruta que vem do banco
    String dataBruta = map['data'] ?? '';
    String dataFormatada = dataBruta;

    // Se a data for maior que 10 caracteres (ex: 2026-06-02 14:18:46...)
    if (dataBruta.length >= 10) {
      // Corta a string para pegar apenas o "Ano-Mês-Dia" (os 10 primeiros caracteres)
      dataFormatada = dataBruta.substring(0, 10);
    }

    return NewsModel(
      id: map['id'] is int ? map['id'] : int.tryParse('${map['id'] ?? ''}'),
      tag: map['tag'] ?? '',
      data: dataFormatada,
      dataInicio: (map['dataInicio'] ?? map['data_inicio'] ?? '').toString(),
      dataFim: (map['dataFim'] ?? map['data_fim'] ?? '').toString(),
      titulo: map['titulo'] ?? '',
      subtitulo: map['subtitulo'] ?? '',
      descricao: map['descricao'] ?? '',
      imagem: map['imagem'] ?? '',
      categoria: map['categoria'] ?? 'Geral',
      local: map['local'] ?? 'Bragança Paulista',
      publicoAlvo: map['publicoAlvo'] ?? 'População em Geral',
      textoBotaoAcao: map['textoBotaoAcao'] ?? 'Saber Mais',
      orgao: map['orgao'] ?? 'Secretaria de Saúde',
      orgaoTelefone: map['orgaoTelefone'] ?? '(11) 4002-8922',
      orgaoSite: map['orgaoSite'] ?? 'https://www.saude.gov.br',
      status: (map['status'] ?? '').toString(),
      fonteUrl: (map['fonteUrl'] ?? map['fonte_url'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tag': tag,
      'data': data,
      'dataInicio': dataInicio,
      'dataFim': dataFim,
      'titulo': titulo,
      'subtitulo': subtitulo,
      'descricao': descricao,
      'imagem': imagem,
      'categoria': categoria,
      'local': local,
      'publicoAlvo': publicoAlvo,
      'textoBotaoAcao': textoBotaoAcao,
      'orgao': orgao,
      'orgaoTelefone': orgaoTelefone,
      'orgaoSite': orgaoSite,
      'status': status,
      'fonteUrl': fonteUrl,
    };
  }
}
