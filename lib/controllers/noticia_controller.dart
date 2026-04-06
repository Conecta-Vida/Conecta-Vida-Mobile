// lib/controllers/news_controller.dart
import '../model/noticia.dart';

class NewsController {
  // Função que a tela vai chamar para pegar a lista certa
  List<NewsModel> getNoticiasPorCategoria(int categoryIndex) {
    switch (categoryIndex) {
      case 0:
        return _noticiasHome;
      case 1:
        return _noticiasVacinacao;
      case 2:
        return _noticiasSangue;
      case 3:
        return _noticiasUrgentes;
      case 4:
        return _noticiasEventos;
      default:
        return _noticiasHome;
    }
  }

  // Função para pegar o título da seção
  String getTituloSessao(int categoryIndex) {
    switch (categoryIndex) {
      case 0:
        return 'Últimas Notícias';
      case 1:
        return 'Vacinações';
      case 2:
        return 'Doações de Sangue';
      case 3:
        return 'Casos Urgentes';
      case 4:
        return 'Próximos Eventos';
      default:
        return 'Últimas Notícias';
    }
  }

  // --- AS LISTAS DE DADOS ---
  final List<NewsModel> _noticiasHome = [
    NewsModel(
      tag: 'SUS - Região Bragantina',
      data: '03/04/2025',
      titulo: 'Vacinação contra Influenza aberta para todas as idades',
      subtitulo: 'Válido até Junho de 2025. Vacina Sempre Brasil!',
      descricao:
          'A campanha de vacinação está disponível para toda a população...',
      imagem: 'assets/images/vacina_banner.png',
    ),
    NewsModel(
      tag: 'Informativo',
      data: '21/03/2025',
      titulo: 'Ouvidoria aberta à população reforça transparência',
      subtitulo: 'A escuta ativa da população é fundamental.',
      descricao: 'A Ouvidoria do SUS reforça seus canais de atendimento...',
      imagem:
          'https://images.unsplash.com/photo-1551076805-e1869033e561?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  final List<NewsModel> _noticiasVacinacao = [
    NewsModel(
      tag: 'Campanha',
      data: '03/04/2025',
      titulo: 'Vacinação contra Influenza',
      subtitulo: 'Válido até Junho de 2025.',
      descricao: 'A vacina da Influenza já está liberada nos postos.',
      imagem:
          'assets/images/vacina_banner.png', // Lembre-se de ter essa imagem ou trocar por uma URL
    ),
  ];

  final List<NewsModel> _noticiasSangue = [
    NewsModel(
      tag: 'Ato de Amor',
      data: '19/03/2025',
      titulo: 'Doe sangue, salve vidas!',
      subtitulo: 'Um simples gesto.',
      descricao: 'Participe da nossa campanha de doação no hemocentro central.',
      imagem:
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  final List<NewsModel> _noticiasUrgentes = [
    NewsModel(
      tag: 'ALERTA',
      data: '19/03/2025',
      titulo: 'URGENTE! Ana Clara precisa de doações',
      subtitulo: 'Ajude a salvar uma vida.',
      descricao: 'Precisamos de sangue O- com urgência.',
      imagem:
          'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  final List<NewsModel> _noticiasEventos = [
    NewsModel(
      tag: 'Solidariedade',
      data: '19/03/2025',
      titulo: 'Evento de doação no domingo',
      subtitulo: 'Compareça e ajude!',
      descricao: 'Participe do nosso evento solidário na praça principal.',
      imagem:
          'https://images.unsplash.com/photo-1615461066841-6116e61058f4?q=80&w=800&auto=format&fit=crop',
    ),
  ];
}
