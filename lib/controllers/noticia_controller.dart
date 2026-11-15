/// Títulos das seções da tela inicial.
///
/// As notícias vêm sempre do Supabase; não há mais conteúdo de exemplo no
/// código (num aplicativo de saúde, é melhor avisar que não há conexão do
/// que mostrar informação fictícia).
class NewsController {
  String getTituloSessao(int categoryIndex) {
    switch (categoryIndex) {
      case 0:
        return 'Todas as Notícias';
      case 1:
        return 'Campanhas de Vacinação';
      case 2:
        return 'Doações de Sangue';
      case 3:
        return 'Alertas Urgentes';
      case 4:
        return 'Todas as Campanhas';
      default:
        return 'Últimas Notícias';
    }
  }
}
