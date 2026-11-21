| Nó | Tipo | Comandos |
|---|---|---|
| 1 | bloco | `início de salvarInscricoes()<br>final comunicacaoId = campanha.id` |
| 2 | predicado | `if (comunicacaoId == null)` |
| 3 | bloco | `throw const InscricaoException(MotivoRecusa.campanhaSemId)` |
| 4 | predicado | `if (!campanha.ehCampanha)` |
| 5 | bloco | `throw const InscricaoException(MotivoRecusa.naoECampanha)` |
| 6 | predicado | `if (usuarioId == null)` |
| 7 | bloco | `throw const InscricaoException(MotivoRecusa.usuarioNaoIdentificado)` |
| 8 | predicado | `if (escolhidos.length > limiteParticipantes)` |
| 9 | bloco | `throw const InscricaoException(MotivoRecusa.limiteDeParticipantes)` |
| 10 | bloco | `final encerrada = campanha.encerradaEm(_agora())<br>final falhas = <String>[]<br>var alteracoes = 0` |
| 11 | predicado | `laço (final participante in participantes)` |
| 12 | bloco | `final estavaInscrito = inscritosAtuais.contains(participante.chave)<br>final deveEstarInscrito = escolhidos.contains(participante.chave)` |
| 13 | predicado | `if (estavaInscrito == deveEstarInscrito)` |
| 14 | bloco | `continue` |
| 15 | predicado | `if (deveEstarInscrito)` |
| 16 | predicado | `if (encerrada)` |
| 17 | bloco | `falhas.add('${participante.nome}: campanha encerrada')<br>continue` |
| 18 | predicado | `if (!participante.vinculoAtivo)` |
| 19 | bloco | `falhas.add('${participante.nome}: vínculo não está ativo')<br>continue` |
| 20 | predicado | `if (deveEstarInscrito)` |
| 21 | predicado | `await _repositorio.inscrever( comunicacaoId: comunicacaoId, usuarioId: usuarioId, dependenteId: participante.dependenteId, )` |
| 22 | predicado | `await _repositorio.desinscrever( comunicacaoId: comunicacaoId, usuarioId: usuarioId, dependenteId: participante.dependenteId, )` |
| 23 | bloco | `alteracoes++` |
| 24 | bloco | `falhas.add('${participante.nome}: $erro')` |
| 25 | bloco | `return ResultadoInscricao( alteracoes: alteracoes, selecionados: escolhidos.length, falhas: falhas, )` |
| 26 | bloco | `fim` |
