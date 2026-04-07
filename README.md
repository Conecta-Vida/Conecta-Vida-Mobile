# Conecta-Vida-Mobile
Versão flutter do repositorio

## Estrutura de Pastas

A pasta `lib/` do projeto foi organizada para manter o código limpo, separando bem a interface visual da lógica de negócio.

* **`components/`**: Pedaços visuais que reaproveitamos em várias partes do app, como os cards de notícia e a barra de navegação inferior. 
* **`controllers/`**: Onde fica a inteligência do app. Controla a lógica, as regras e os dados antes de mandar para a tela.
* **`global/`**: Configurações que afetam o aplicativo inteiro. O arquivo de cores padrão (`AppCor`) fica aqui. 
* **`model/`**: Onde definimos os moldes dos nossos dados. Classes como o `noticia` ficam aqui para padronizar as informações e evitar erros de digitação.
* **`screens/`**: As telas completas do aplicativo (Login, Feed, Detalhes). Elas são feitas apenas para desenhar o layout, delegando a lógica para os controllers.
* **`services/`**: A camada de comunicação com o mundo externo. É aqui que vão morar as funções que fazem as requisições HTTP para a nossa API Java. Atualmente não está em uso.
* **`main.dart`**: O arquivo que inicializa o aplicativo. Ele aplica o tema global e direciona o usuário para a tela inicial.