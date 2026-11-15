# Conecta Vida — Aplicativo Mobile

Aplicativo cidadão do Conecta Vida, desenvolvido em Flutter para Android, iOS e execução local no navegador durante o desenvolvimento.

[![Flutter](https://img.shields.io/badge/Flutter-3.44.0-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.11.3-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-APK-3DDC84?logo=android&logoColor=white)](https://developer.android.com/)

## Autores e instituição

- Luiz Henrique Gonçalves
- Gustavo
- Gabriel
- Renan
- Maycon

**IFSP — Câmpus Bragança Paulista** · Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas.

[Assistir à demonstração do aplicativo](https://youtu.be/s7eqyfYcr3E?si=003QmXc9TUCjPm9O)

> **Branch de trabalho:** `mobile`  
> **API padrão:** `https://conecta-vida-backend-production.up.railway.app/api`  
> **Pasta Flutter:** raiz deste repositório (a pasta que contém `pubspec.yaml`).

## 1. Pré-requisitos

Instale:

- Git;
- Flutter SDK estável **3.44.0** ou compatível com o Dart exigido pelo `pubspec.yaml` (Dart `^3.11.3`);
- Android Studio com Android SDK e, para executar no Android, um emulador configurado ou um celular com depuração USB;
- Java/JDK 17 ou superior para a compilação Android;
- VS Code ou Android Studio com os plugins Flutter e Dart (opcional, mas recomendado).

Confira a instalação:

```bash
flutter doctor
flutter --version
dart --version
```

Resolva os itens necessários do `flutter doctor` antes de compilar para a plataforma desejada.

## 2. Baixar o projeto e preparar dependências

Clone o repositório:

```bash
git clone https://github.com/Conecta-Vida/Conecta-Vida-Mobile.git
cd Conecta-Vida-Mobile
git switch mobile
git pull origin mobile
flutter pub get
```

Se o repositório já estiver clonado, entre na pasta do projeto e execute:

```bash
git switch mobile
git pull origin mobile
flutter pub get
```

Confira os dispositivos disponíveis:

```bash
flutter devices
```

## 3. Configuração da API

O endereço padrão está em `assets/config/app.env`, na variável `API_BASE_URL`:

```env
API_BASE_URL=https://conecta-vida-backend-production.up.railway.app/api
```

Esse endereço é público e não é um segredo. O arquivo é incluído nos assets do aplicativo. **Não coloque senhas, tokens privados ou credenciais do banco nesse arquivo.**

Com essa configuração, o aplicativo usa a Mobile API hospedada no Railway. Portanto, para o fluxo normal de desenvolvimento e teste, não é necessário iniciar o backend Java nem o banco no computador: basta ter acesso à internet.

### Sobrescrever o endereço da API

A configuração passada por `--dart-define` tem prioridade sobre o arquivo `app.env`. Use-a somente quando precisar apontar para outra instância.

| Cenário | Valor de `API_BASE_URL` |
|---|---|
| API compartilhada no Railway | `https://conecta-vida-backend-production.up.railway.app/api` |
| API local no emulador Android | `http://10.0.2.2:8081/api` |
| API local no Chrome | `http://localhost:8081/api` |
| API local em celular físico | `http://IP_DO_COMPUTADOR:8081/api` |

Exemplo para executar com a API local no emulador Android:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8081/api
```

No celular físico, computador e telefone precisam estar na mesma rede; substitua `IP_DO_COMPUTADOR` pelo IP local do computador e libere a porta 8081 no firewall, se necessário.

Para iniciar a API local, siga as instruções do [README da Mobile API](https://github.com/Conecta-Vida/conecta-vida-backend/blob/main/mobile-api/README.md). A API usa credenciais e variáveis próprias no ambiente Java. Não copie credenciais do backend para o aplicativo Flutter.

## 4. Executar o aplicativo

### Android (emulador ou celular conectado)

Com um dispositivo aberto/conectado:

```bash
flutter run
```

Para selecionar um dispositivo específico:

```bash
flutter devices
flutter run -d ID_DO_DISPOSITIVO
```

A configuração padrão usa a API do Railway. Não use `localhost` para acessar a API online.

### Chrome (Flutter Web local)

Use uma porta fixa para que todos os desenvolvedores tenham a mesma origem local e para coincidir com a origem liberada no CORS da API:

```bash
flutter run -d chrome --web-port=5000
```

O navegador abrirá em:

```text
http://localhost:5000
```

A chamada à API vai para o domínio público do Railway definido em `app.env`. A origem `http://localhost:5000` já está prevista na configuração CORS da Mobile API. Se trocar a porta, a origem correspondente deverá ser liberada no Railway.

Para usar a API Java local no Chrome:

```bash
flutter run -d chrome --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8081/api
```

Observações:
- CORS é uma restrição do navegador; não se aplica à chamada HTTP feita pelo aplicativo Android nativo.
- Recursos de Firebase Messaging e notificações locais são inicializados apenas em plataformas nativas.
- A localização no navegador depende da permissão do usuário e de um contexto seguro; `localhost` é aceito pelos navegadores para desenvolvimento.

## 5. Gerar APK Android para testes

Com a API padrão do Railway configurada em `assets/config/app.env`, gere a APK:

```bash
flutter clean
flutter pub get
flutter build apk --release
```

O arquivo será criado em:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Copie o arquivo para o celular, abra-o e autorize a instalação quando o Android solicitar. O celular precisa de acesso à internet para falar com a API no Railway.

Para gerar APKs separados por arquitetura:

```bash
flutter build apk --release --split-per-abi
```

Os arquivos serão gerados na mesma pasta `build/app/outputs/flutter-apk/`.

> **Assinatura:** a configuração atual do Gradle usa a assinatura debug também para o build release, conforme indicado no próprio `android/app/build.gradle.kts`. Isso é suficiente para testes internos, mas **não é uma configuração de assinatura de produção nem apropriada para publicar na Play Store**. Antes de distribuir oficialmente, configure uma chave de assinatura release e proteja o keystore e suas senhas fora do Git.

### Testar as alterações desta branch

Para conferir a versão em desenvolvimento do PR de acessibilidade e desempenho:

```bash
git fetch origin
git switch feature/acessibilidade-cronograma
git pull origin feature/acessibilidade-cronograma
flutter pub get
flutter run -d chrome --web-port=5000
```

Para testar em Android, substitua a última linha por `flutter run` com um emulador ou celular conectado.

## 6. Verificações antes de enviar alterações

Execute:

```bash
dart format .
flutter analyze
```

Quando houver testes automatizados no projeto:

```bash
flutter test
```

No estado atual da branch, não há uma suíte de testes Flutter versionada em `test/`. Novas funcionalidades devem incluir testes de unidade/widget e, quando possível, testes de integração.

O workflow do GitHub Actions em `.github/workflows/flutter-web.yml` executa a compilação Web para alterações na branch `mobile`; ele não substitui a análise estática, os testes de widget ou os testes em dispositivos Android.

## 7. Estrutura principal

```text
lib/
  controllers/   # lógica de apresentação e consulta
  global/        # cores e configuração global da API
  models/        # modelos de dados
  providers/     # estado compartilhado
  screens/       # telas do aplicativo
  services/      # comunicação com API, notificações e serviços
  widgets/       # componentes reutilizáveis
assets/
  config/app.env # URL pública da Mobile API (sem segredos)
  images/        # imagens utilizadas pelo app
android/         # configuração nativa Android
ios/             # configuração nativa iOS
```

## Acessibilidade e cronograma

A tela **Acessibilidade** fica em **Ajustes → Acessibilidade**. As preferências são salvas localmente no Hive e aplicadas ao tema global do aplicativo.

Recursos incluídos nesta branch:
- Escala global de texto de 90% a 160%;
- Fonte do sistema ou fonte serifada;
- Texto em negrito;
- Tema claro/escuro e alto contraste aplicados às superfícies e textos neutros;
- As cores de marca, o azul principal e as cores de destaque das categorias de notícias permanecem preservados;
- Redução de movimento nos componentes que consultam a preferência;
- Leitura de notícias em voz alta em português, com controles para iniciar e parar;
- Rótulos semânticos e alvos de toque maiores em ações da navegação.

O leitor de voz usa `flutter_tts`. No Android, o dispositivo precisa ter uma engine e uma voz em português instaladas. TalkBack e VoiceOver continuam configurados nas opções de acessibilidade do próprio sistema operacional.

### Atualizar o cronograma

O **Meu Cronograma** escuta alterações de inscrição/cancelamento, recarrega ao retornar dos detalhes de uma campanha e ao voltar o aplicativo para primeiro plano. A atualização manual ignora o cache para consultar o servidor.

### Otimizações de carregamento

- A lista de comunicações/notícias é reutilizada por 30 segundos entre feed, notificações, alertas e filtros de regiões.
- Requisições simultâneas para a mesma lista compartilham a mesma chamada HTTP.
- Consultas de inscrição no fallback são realizadas em paralelo e usam cache curto.
- A lista de notificações e os lembretes de campanhas são carregados em paralelo.
- A inicialização do Firebase/FCM ocorre depois do primeiro frame, sem atrasar a apresentação inicial da interface.
- O serviço HTTP reutiliza uma instância de `http.Client`.

O Flutter tenta utilizar `GET /api/campanhas/minhas` para carregar todas as inscrições do usuário em uma única chamada. Esse endpoint está proposto no [PR #4 do backend](https://github.com/Conecta-Vida/conecta-vida-backend/pull/4). Até que a alteração seja integrada e implantada na Mobile API do Railway, o aplicativo detecta a ausência do endpoint e utiliza automaticamente as rotas individuais já existentes.

> A validação visual final deve incluir Android e Web, com fonte ampliada, modo escuro, alto contraste, TalkBack/VoiceOver e leitura em voz alta. A compilação Web do CI não substitui os testes nesses dispositivos.

---

## 8. Limitações conhecidas no momento

- A recuperação de senha da Mobile API ainda retorna HTTP 501; o fluxo de e-mail não está implementado.
- O registro de tokens de push no backend utiliza armazenamento em memória e não é persistido após reiniciar a API.
- A configuração de assinatura Android release ainda é de teste, conforme explicado acima.
- A branch ainda precisa ampliar sua cobertura automatizada de testes.

## 9. Serviços relacionados

- [Repositório Flutter Mobile](https://github.com/Conecta-Vida/Conecta-Vida-Mobile/tree/mobile)
- [Backend — Mobile API](https://github.com/Conecta-Vida/conecta-vida-backend/tree/main/mobile-api)
- [README para executar a Mobile API localmente](https://github.com/Conecta-Vida/conecta-vida-backend/blob/main/mobile-api/README.md)

---

IFSP — Câmpus Bragança Paulista · Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas  
© 2026 Conecta Vida


## Sistema de dependentes

Acesse **Ajustes → Meus Dependentes** para cadastrar, editar e remover dependentes. Não é solicitado CPF, e-mail ou senha. Os dados são nome completo, data de nascimento, parentesco (Filho(a), Pai, Mãe, Cônjuge, Tutelado ou Outro) e sexo opcional.

Na tela de detalhes de uma campanha, o titular escolhe se a inscrição será para si ou para um dependente ativo. O **Meu Cronograma** identifica o participante e permite cancelar a inscrição individual. A API valida titularidade pelo JWT. A remoção de um dependente é lógica para preservar o histórico.

Para testar esta funcionalidade, atualize também a branch `feature/dependentes-api` do backend e aplique a migração `V2__dependentes_and_campaign_participants.sql` conforme o [README da Mobile API](https://github.com/Conecta-Vida/conecta-vida-backend/blob/feature/dependentes-api/mobile-api/README.md).
