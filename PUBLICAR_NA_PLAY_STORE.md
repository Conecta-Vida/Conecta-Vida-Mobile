# Publicar o Conecta Vida na Play Store

O que já está pronto no código:

| Requisito da Play Store | Situação |
|---|---|
| Identificador próprio do app (não pode ser `com.example`) | `br.edu.ifsp.conectavida` |
| Versão | `1.0.0` (código 1), em `pubspec.yaml` (`version: 1.0.0+1`). Suba o número depois do `+` a cada envio. |
| SDK alvo recente | `targetSdk` do Flutter 3.44 (API 36) |
| Ícone próprio (adaptativo) e nome "Conecta Vida" | `android/app/src/main/res/mipmap-*` |
| Ícone 512×512 e imagem de destaque 1024×500 | pasta `loja/` |
| Política de privacidade (URL pública) | https://conecta-vida-admin.netlify.app/privacidade (também em Ajustes → Política de privacidade) |
| Exclusão de conta pelo app | Ajustes → Deletar |
| Exclusão de conta pela web (exigida desde 2024) | https://conecta-vida-admin.netlify.app/excluir-conta |
| Sem Firebase (não há `google-services.json`) | removido; alertas chegam pelo Supabase |
| Assinatura de release | lida de `android/key.properties` (não vai para o GitHub) |

## 1. Criar a chave de upload (uma vez só)

No computador de quem vai publicar (precisa do Java/Android Studio):

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Guarde o arquivo `.jks` e as senhas em lugar seguro (gerenciador de senhas). **Não** coloque no GitHub nem no grupo.
Com o "Play App Signing" (padrão), se a chave de upload for perdida dá para pedir uma nova ao Google.

Copie `android/key.properties.exemplo` para `android/key.properties` e preencha com as senhas e o caminho do `.jks`.

## 2. Gerar o pacote para a loja

```bash
flutter build appbundle --release
```

O arquivo sai em `build/app/outputs/bundle/release/app-release.aab`.

## 3. Play Console

1. Conta de desenvolvedor: https://play.google.com/console (taxa única de US$ 25).
   Contas **pessoais** criadas depois de nov/2023 precisam de um **teste fechado com pelo menos 12 testadores por 14 dias** antes de liberar em produção. Os colegas e o professor podem ser os testadores.
2. Criar app → nome "Conecta Vida", idioma português (Brasil), App, Gratuito.
3. Enviar o `.aab` em Testes → Teste fechado (ou Produção, se a conta permitir).
4. Preencher "Conteúdo do app":
   - **Política de privacidade:** `https://conecta-vida-admin.netlify.app/privacidade`
   - **Acesso ao app:** o app exige login → informe uma conta de teste para a revisão do Google (crie uma conta comum pelo painel, em Usuários → Novo Registro).
   - **Anúncios:** não contém anúncios.
   - **Classificação de conteúdo:** questionário → categoria "Referência, notícias ou educacional"; sem violência, sem conteúdo adulto → Livre.
   - **Público-alvo:** 18 anos ou mais.
   - **App de saúde:** marcar "informações de saúde/campanhas públicas"; o app não é dispositivo médico.
   - **Segurança dos dados** (respostas abaixo).
   - **Exclusão de conta:** `https://conecta-vida-admin.netlify.app/excluir-conta`
5. "Página da loja principal": textos abaixo, ícone `loja/icone-512.png`, imagem de destaque `loja/imagem-destaque-1024x500.png` e pelo menos 2 capturas de tela do celular.

### Segurança dos dados (Data safety)

- Coleta dados? **Sim**. Compartilha com terceiros? **Não** (Supabase e Netlify são provedores de serviço, não contam como compartilhamento).
- Dados criptografados em trânsito? **Sim**. O usuário pode pedir exclusão? **Sim**.
- Tipos coletados:
  - Informações pessoais → Nome, E-mail (funcionalidade do app, gerenciamento de conta; obrigatório)
  - Informações pessoais → Outras (ano de nascimento, sexo; opcional; personalização)
  - Localização → Aproximada e precisa (funcionalidade do app: cidade e unidades próximas; opcional; não armazenada como histórico)
  - Atividade no app → Outras ações (inscrições em campanhas; funcionalidade do app)

### Textos da loja

**Descrição curta (até 80 caracteres):**
Notícias, campanhas e alertas de saúde de fontes oficiais, perto de você.

**Descrição completa:**
O Conecta Vida reúne em um só lugar as informações de saúde pública que importam para você e sua família, sempre de fontes oficiais.

• Notícias do Ministério da Saúde e do Governo do Estado, com imagens e link para a matéria original
• Campanhas de vacinação e saúde da sua cidade, com inscrição pelo app (para você e seus dependentes)
• Alertas de saúde em tempo real
• Unidades de saúde do SUS da sua cidade (dados oficiais do CNES), das mais próximas para as mais distantes, com telefone e rota
• Cronograma das campanhas em que você se inscreveu
• Recursos de acessibilidade: tamanho de texto, alto contraste, modo escuro e leitura em voz alta

Projeto acadêmico do curso de Análise e Desenvolvimento de Sistemas do IFSP – Câmpus Bragança Paulista.

**Categoria:** Medicina (ou Saúde e fitness). **E-mail de contato:** obrigatório na ficha da loja — use um e-mail do grupo.

## APK para instalar direto (sem a loja)

```bash
flutter build apk --release
```

Gera `build/app/outputs/flutter-apk/app-release.apk`. Sem `key.properties` ele é assinado com a chave de teste: serve para instalar no celular, não para a loja.
