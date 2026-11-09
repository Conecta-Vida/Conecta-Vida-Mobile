# 📱 Conecta Vida - Aplicativo Móvel Cidadão

<p align="center">
<strong>A interface reativa, portátil e o ponto de contato direto do cidadão com o ecossistema de saúde pública regional. Responsável pela captação de geolocalização ativa, consumo assíncrono de informativos regionalizados, inscrição em mutirões comunitários e interceptação impositiva de alertas epidemiológicos críticos.</strong>
</p>

<p align="center">
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart">
<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android">
<img src="https://img.shields.io/badge/iOS-000000?style=for-the-badge&logo=ios&logoColor=white" alt="iOS">
<img src="https://img.shields.io/badge/Java-17-ED8B00?style=for-the-badge&logo=openjdk&logoColor=white" alt="Java 17">
<img src="https://img.shields.io/badge/Spring%20Boot-4.0.5-6DB33F?style=for-the-badge&logo=springboot&logoColor=white" alt="Spring Boot 4.0.5">
<img src="https://img.shields.io/badge/PostgreSQL-17-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" alt="PostgreSQL 17">
<img src="https://img.shields.io/badge/Supabase-Pooler-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white" alt="Supabase">
<img src="https://img.shields.io/badge/Gradle-8.x-02303A?style=for-the-badge&logo=gradle&logoColor=white" alt="Gradle">
</p>

<p align="center">
  <a href="https://youtu.be/s7eqyfYcr3E?si=003QmXc9TUCjPm9O" title="Clique para assistir à demonstração">
    <img src="https://img.shields.io/badge/Assista%20à%20Demonstração-FF0000?style=for-the-badge&logo=youtube&logoColor=white" alt="Assista à Demonstração">
  </a>
</p>

---

## 👥 Autores e Instituição
* **Luiz Henrique Gonçalves**
* **Gustavo**
* **Gabriel**
* **Renan**
* **Maycon**

**IFSP - Câmpus Bragança Paulista** *Curso Superior de Tecnologia em Análise e Desenvolvimento de Sistemas*

---

## 📊 Composição do Código (Languages)

A distribuição das linguagens no repositório reflete a estrutura de uma aplicação Flutter multiplataforma nativa, contendo a lógica em Dart e os runners de compilação específicos:

```text
Dart ───────────────────────────────────────────── 76.9% ███████████████████████████████████░░░░░░░░░░
C++ ────────────────────────────────────────────── 11.4% █████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
CMake ────────────────────────────────────────────  8.8% ████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Swift ────────────────────────────────────────────  1.4% █░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
HTML ─────────────────────────────────────────────  0.7% ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
C ────────────────────────────────────────────────  0.7% ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
Outros ───────────────────────────────────────────  0.1% ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

```

* **Dart (76.9%):** Core design do ecossistema móvel, contemplando todas as views, controllers, gerência de estados e consumo assíncrono.
* **C++ / CMake (20.2%):** Vinculados às engines de compilação nativa de baixo nível e renderização do Flutter Desktop/Android Shell.
* **Swift (1.4%):** Arquivos de manifesto e delegates nativos do ecossistema iOS.

---

## 📖 Sobre o Módulo Mobile (Aplicativo)

O aplicativo móvel do **Conecta Vida** foi desenvolvido em **Flutter** para entregar uma experiência fluida, reativa e descentralizada de utilidade pública. Ele adota uma arquitetura modularizada dividida em telas (`Screens`), componentes reaproveitáveis (`Widgets`), controladores de estado e lógica (`Controllers`) e modelos de dados estruturados (`Models`).

A aplicação interage de forma assíncrona com os microsserviços da nossa infraestrutura, consumindo dados geográficos locais para reconstruir dinamicamente o feed de notícias do usuário, além de garantir barreira de segurança local contra crises biológicas na comunidade.

---

## Pré-requisitos

Antes de compilar e executar o aplicativo móvel, certifique-se de que o seu ambiente de desenvolvimento possui os seguintes componentes configurados:

* **Flutter SDK (Versão estável mais recente)**: Engine para renderização nativa multiplataforma.
* **Dart SDK**: Linguagem base do projeto.
* **Java JDK 17**: Obrigatório para o funcionamento do pipeline de compilação do Gradle do Android.
* **Android Studio / VS Code**: Ambientes recomendados com as extensões do Flutter instaladas.
* **Emulador Ativo ou Smartphone Físico**: Com a depuração USB ativa para execução dos testes.

---

## Passo 1: Configurar a API local

O aplicativo Flutter usa a **Mobile API** Java/Spring Boot, que acessa o PostgreSQL do Supabase. A senha do banco fica somente no ambiente da API; não coloque credenciais do Supabase no Flutter.

Para executar a demonstração no próprio computador, a API deve estar disponível em:

```text
http://localhost:8081/api
```

O CORS da Mobile API já permite, por padrão, `http://localhost:5000` e `http://127.0.0.1:5000`. As instruções para iniciar a API e configurar as variáveis do Supabase estão em [mobile-api/README.md](https://github.com/Conecta-Vida/conecta-vida-backend/blob/mobile/mobile-api/README.md).

## Passo 2: Executar no celular ou emulador

Na raiz do projeto:

```bash
flutter pub get
flutter run
```

O endereço padrão da API é `http://10.0.2.2:8081/api` no emulador Android e `http://localhost:8081/api` no desktop/iOS Simulator. Em um celular físico, informe o IP local do computador via `--dart-define=API_BASE_URL=http://IP_DO_PC:8081/api`.

## Passo 3: Executar no navegador (demonstração local)

1. Inicie a Mobile API na porta `8081`, conectada ao Supabase.
2. Em outro terminal, na pasta do projeto Flutter, execute:

```bash
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8081/api
```

O Chrome abrirá o aplicativo em `http://localhost:5000`. O hot reload permite alterar os arquivos Dart e visualizar as mudanças no navegador.

Não é necessário Docker, Nginx, Render ou publicar o aplicativo na internet para esse fluxo. O servidor Web do Flutter e a API Java ficam rodando localmente.

### Observações sobre a Web

- O Firebase Messaging e as notificações locais são recursos nativos e não são inicializados no navegador.
- A localização funciona em `localhost`, desde que o usuário permita o acesso no navegador.
- Caso altere a porta do Flutter, atualize a origem permitida no CORS da Mobile API.
- A recuperação de senha ainda não está implementada na Mobile API.

## Passo 4: Testar as funcionalidades principais

Com o aplicativo em execução, valide o cadastro/login, a navegação pelo feed, os filtros de vacinação/doações/alertas/eventos e as inscrições em campanhas.

## Passo 5: Compilar o aplicativo Android

Para gerar o APK de distribuição nativa:

```bash
flutter build apk --release
```

O arquivo será gerado em `build/app/outputs/flutter-apk/app-release.apk`.

---

© 2026 Conecta à Vida. Sistema homologado para fins acadêmicos. IFSP Bragança Paulista.
