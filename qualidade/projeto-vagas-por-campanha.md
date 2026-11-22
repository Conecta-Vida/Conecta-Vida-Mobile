# Projeto: vagas por campanha (RN07)

## Intenção

Antes desta mudança, o app recusava inscrições com mais de 11 participantes por meio de uma constante fixa
(`limiteParticipantes = 11` em `InscricaoCampanhaService`), que não existia no app original.
O limite real do sistema é outro: o banco recusa o 11º dependente por conta (RN06). O grupo
quer trocar a constante fixa por um número que o gestor define no painel para cada campanha:
o **total de vagas**, porque campanhas de saúde têm capacidade limitada (doses, horários) e
esse número varia de campanha para campanha.

## Objetivos

- O gestor define, ao cadastrar ou editar uma campanha, quantas vagas ela tem (vazio = sem limite).
- Cada pessoa inscrita (titular ou dependente) ocupa uma vaga; cancelar libera a vaga.
- Campanha lotada recusa inscrições novas, mas continua aceitando cancelamentos.
- O banco garante o limite mesmo com dois cidadãos disputando a última vaga ao mesmo tempo.
- O app mostra as vagas restantes e avisa antes de tentar gravar.
- O Trabalho 2 passa a descrever, modelar e testar a nova regra (RN07) em todos os exercícios.

## Não objetivos

- Fila de espera, reserva de horário ou vagas por posto de vacinação.
- Mudar a RN06 (máximo de 10 dependentes por conta), que continua só no banco.
- Publicar em produção: a mudança fica no branch `qualidade/trabalho2` até o grupo decidir.

## Anti-objetivos

- O app aceitar mais inscrições que vagas (o limite nunca pode depender só do app).
- Campanhas já existentes ou criadas pelo calendário automático ficarem bloqueadas.
- Remover inscrições de quem já estava inscrito quando o gestor reduz as vagas.

## Restrições

- RLS: o cidadão só lê as próprias inscrições (`cv_inscricoes_leitura`), então o app não
  consegue contar as inscrições dos outros.
- As regras de inscrição já ficam na política `cv_inscricoes_insert` e em gatilhos; os testes
  do banco (pytest) rodam as migrations reais.
- O GFC de `salvarInscricoes()` (exercício 8) já foi gerado no ComplexGraph; o print precisa
  mostrar o código novo.
- Prazo de entrega: 29/11/2026.

## Abordagens consideradas

1. **Banco decide e app avisa antes (escolhida pelo grupo).** Coluna de vagas na campanha,
   gatilho que trava a campanha e confere a lotação antes de gravar, e o app confere antes de
   tentar. Segura contra concorrência e dá aviso claro ao cidadão.
2. Só o banco decide: app mais simples, mas o cidadão só descobre que lotou depois de salvar
   (aparece como falha E4).
3. Só o app confere: descartada, porque duas pessoas ao mesmo tempo passariam do limite.

## Decisões

### Banco (Conecta-Vida-Admin, nova migration)

- `comunicacoes.vagas integer null` com `check (vagas is null or vagas > 0)`; nulo = sem limite.
- `comunicacoes.inscritos integer not null default 0`: contador mantido por gatilhos, porque o
  cidadão não enxerga as inscrições dos outros. A migration preenche o contador com as
  inscrições existentes.
- Gatilho `before insert` em `usuarios_campanhas` (SECURITY DEFINER, `search_path` fixo): lê a
  campanha com `for update` e, se `vagas` não for nulo e `inscritos >= vagas`, recusa com a
  mensagem `Vagas esgotadas para esta campanha.` Gatilhos `after insert`/`after delete`
  incrementam e decrementam `inscritos`, o que cobre também os cancelamentos automáticos da RN05.
- O gestor pode reduzir as vagas abaixo do número de inscritos: ninguém é removido, a campanha
  só fica lotada (minha proposta).

### Painel administrativo

- Campo "Vagas (vazio = sem limite)" no cadastro e na edição da campanha (`campanhaParaBanco`,
  `paraCampanha`, tipo `Campanha`).
- Detalhes e lista de campanhas mostram "X de Y vagas" (ou "X inscritos" sem limite).

### App (Conecta-Vida-Mobile)

- `NewsModel` ganha `vagas` (int?) e `inscritos` (int), com `vagasRestantes` (nulo = sem limite)
  e `lotada`.
- `InscricaoCampanhaService`: saem `limiteDependentes` e `limiteParticipantes`;
  `MotivoRecusa.limiteDeParticipantes` vira `vagasInsuficientes`.
  - `verificarAcesso` (passo 4): campanha lotada e titular sem inscrições → recusa com
    "As vagas desta campanha esgotaram." (E5). Lotada com inscrições → abre só para cancelar
    (A4 passa a valer para "encerrada ou lotada").
  - `salvarInscricoes` (passo 6): troca o `if` do limite fixo por "novas marcações >
    vagas restantes" → recusa antes de gravar com "Restam N vaga(s) nesta campanha." (E6).
    Cancelamentos da mesma confirmação não contam como vaga liberada para ela (minha
    proposta: mantém o método com um só laço e o GFC com V(G) = 13).
- Tela de detalhes: selo "Vagas: N restantes" ou "Vagas esgotadas"; o diálogo não deixa marcar
  participante novo em campanha lotada.

### Trabalho 2 (documento, planilha, diagramas, testes)

- Quadro 1a: RN07, E5, E6 e A4 ampliado; RN06 volta a ser só "10 dependentes por conta".
- Ex. 2 e 11: diagramas de classes regenerados (sem as constantes; `NewsModel` com vagas).
- Ex. 4: diagrama de atividades com a decisão de vagas; GFC, V(G) e Quadro 2a recalculados.
- Ex. 5: estado "Lotada" no diagrama de estados; GE, V(G) e Quadro 2b recalculados.
- Ex. 6 e 7: casos de teste de vagas com valor limite (última vaga, uma além, lotada com e sem
  inscrição, gestor aumenta vagas); massa de dados com campanha de vagas.
- Ex. 8: GFC de `salvarInscricoes()` regerado pela ferramenta e novo print do ComplexGraph.
- Ex. 9 e 10: testes de unidade (vagas) e de banco (lotação, concorrência, contador, RN05
  liberando vaga); relatórios e cobertura atualizados.
- Ex. 12: Quadro 4a com os números novos.

## Deixado para quem implementar

- Nomes exatos da migration, das funções e dos componentes de tela.
- Numeração final de nós, caminhos, transições e casos de teste, desde que consistente entre
  diagramas, quadros, planilha e testes.
- Textos dos selos e mensagens, mantendo os sentidos acima.
