# Qualidade de Software: caso de uso "Inscrever-se em campanha"

Material do Trabalho 2 de Qualidade de Software (IFSP Bragança Paulista, ADS).

| Pasta / arquivo | Conteúdo |
| :--- | :--- |
| `lib/usecases/inscricao_campanha_service.dart` | Camada de aplicação (use case/service) com as regras RN01 a RN06. |
| `lib/models/inscricao.dart` | Entidades de domínio `Inscricao` e `Participante`. |
| `test/usecases/` | Testes de unidade do serviço; `repositorio_stub.dart` é o **stub/mock** do banco. |
| `test/models/inscricao_entidades_test.dart` | Testes das entidades e da regra de encerramento (valor limite). |
| `qualidade/diagramas/` | Fontes Graphviz (.dot) e imagens dos diagramas dos exercícios 2, 3, 4, 5 e 8. |
| `qualidade/engenharia_reversa.py` | Gera o diagrama de classes (produção + teste) a partir do código Dart. |
| `qualidade/relatorios/` | Gerado pelo GitHub Actions: resultado dos testes, cobertura (lcov/genhtml) e diagrama. |

Rodar localmente:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Os testes das regras no banco (pytest + PostgreSQL) ficam no repositório
`Conecta-Vida-Admin`, pasta `qualidade/`.
