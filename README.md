# Conecta Vida Mobile
Aplicativo Flutter de conteúdo e campanhas de saúde.

## O que está no app
Conecta Vida Mobile é uma versão mobile do projeto que apresenta:

- Tela de splash animada
- Login por email e senha
- Cadastro de usuário com solicitação de localização opcional
- Tela de recuperação de senha
- Feed de notícias categorizadas (Vacinação, Doações, Urgentes, Eventos)
- Detalhes da notícia com informações de órgão, contato e local
- Navegação para notificações e calendário
- Tela de configurações com perfil do usuário e equipe do projeto

## Tecnologias e pacotes usados

- Flutter
- `google_fonts`
- `url_launcher`
- `geolocator`
- `supabase_flutter`
- `share_plus`
- `flutter_lints`

## Estrutura de pastas

- `lib/screens/`: telas completas do aplicativo.
- `lib/widgets/`: componentes reutilizáveis como cards, botões e barras.
- `lib/controllers/`: lógica de negócio e dados do app.
- `lib/models/`: modelos de dados utilizados nas telas.
- `lib/global/`: estilo global e paleta de cores.

## Como executar o app Flutter

Antes de rodar, configure o arquivo `lib/services/supabase_service.dart` com seu:
- `supabaseUrl`
- `supabaseAnonKey`

Passos:

1. Abra o terminal na pasta raiz do projeto.
2. Rode `flutter pub get`.
3. Liste dispositivos com `flutter devices` (opcional).
4. Rode `flutter run` ou, para escolher um dispositivo, `flutter run -d <device_id>`.

> Se estiver usando emulador Android, inicie o emulador antes de rodar.

## Admin PC em Java

O app de administração está em `admin/` e permite gerenciar dados do Supabase via interface Swing.

Pré-requisitos:
- Java JDK 17+
- Apache Maven
- IDE com suporte a Maven/Java (opcional)

Opção 1: terminal

1. Abra o terminal em `admin/`.
2. Rode `mvn clean package`.
3. Rode `mvn exec:java -Dexec.mainClass=com.conectavida.admin.SupabaseAdminApp`.

Opção 2: IDE

1. Importe a pasta `admin/` como projeto Maven.
2. Defina `com.conectavida.admin.SupabaseAdminApp` como classe principal.
3. Execute o aplicativo a partir da IDE.

> Dica: se estiver usando VS Code, abra o workspace `admin-java.code-workspace` para que o Java reconheça `admin/src/main/java` corretamente.

Uso do admin:

1. Informe seu `Supabase URL`.
2. Informe a `Chave Anon` e a `Service Role Key`.
3. Teste a conexão.
4. Use os botões para atualizar tabelas e sincronizar dados de exemplo.

Tabelas suportadas pelo admin:
- `noticias`
- `usuarios`
- `noticias_compartilhadas`
- `compromissos`

O arquivo de exemplo está em `admin/example_data.json`.

## Backend e compartilhamento

- Integração com Supabase para sincronizar usuários, notícias e histórico de compartilhamentos.
- Login e cadastro usando autenticação Supabase.
- Recuperação de senha via Supabase na tela de recuperação.
- Notícias carregadas dinamicamente de Supabase por categoria.
- Compartilhamento de notícias via `share_plus` e registro de compartilhamento no Supabase.
- Ajuste `lib/services/supabase_service.dart` com `supabaseUrl` e `supabaseAnonKey` do seu projeto Supabase.

## Equipe

- Gustavo Tenorio
- Tsarco Gabriel Dias
- RenanVKoashi
- Luiz Henrique Gon
- Maycon Cabral

## Observações

A aplicação agora inclui suporte para sincronização com Supabase e rastreamento de notícias compartilhadas, além dos dados locais existentes como fallback.
