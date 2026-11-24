"""Gera qualidade/relatorios/testes-unidade.html a partir do relatório JSON do flutter test.

Uso: python3 qualidade/relatorio_testes.py qualidade/relatorios/testes.json qualidade/relatorios/testes-unidade.html

Lista, por arquivo de teste do caso de uso "Inscrever-se em campanha", cada teste com o resultado
(PASSOU/FALHOU) e totaliza o caso de uso e a suíte completa do app.
"""
import html
import json
import sys

ARQUIVOS_DO_CASO_DE_USO = (
    "test/models/inscricao_entidades_test.dart",
    "test/usecases/inscricao_campanha_service_test.dart",
)

CSS = ("body{font-family:DejaVu Sans,Arial;font-size:12px;margin:14px}h2{font-size:16px;margin:4px 0}"
       "h3{font-size:13px;margin:12px 0 4px;color:#333}td{padding:2px 6px;border-bottom:1px solid #eee}"
       ".ok{color:#1a7f37;font-weight:bold;white-space:nowrap}.nok{color:#c0392b;font-weight:bold}")


def ler_testes(caminho_json):
    """Devolve [(arquivo, nome, passou)] na ordem de execução, sem os testes ocultos de carregamento."""
    suites, testes, resultados = {}, {}, {}
    with open(caminho_json, encoding="utf-8") as f:
        for linha in f:
            try:
                evento = json.loads(linha)
            except ValueError:
                continue
            tipo = evento.get("type")
            if tipo == "suite":
                suites[evento["suite"]["id"]] = evento["suite"]["path"]
            elif tipo == "testStart":
                t = evento["test"]
                testes[t["id"]] = (t["suiteID"], t["name"])
            elif tipo == "testDone" and not evento.get("hidden"):
                resultados[evento["testID"]] = evento["result"] == "success" and not evento.get("skipped")
    lista = []
    for id_teste, (id_suite, nome) in testes.items():
        if id_teste not in resultados:
            continue
        caminho = suites.get(id_suite, "")
        arquivo = "test/" + caminho.split("/test/", 1)[-1] if "/test/" in caminho else caminho
        lista.append((arquivo, nome, resultados[id_teste]))
    return lista


def gerar_html(lista):
    do_caso = [t for t in lista if t[0] in ARQUIVOS_DO_CASO_DE_USO]
    ok_caso = sum(1 for t in do_caso if t[2])
    ok_app = sum(1 for t in lista if t[2])
    partes = [
        f"<html><head><meta charset=utf-8><style>{CSS}</style></head><body>",
        "<h2>flutter test: testes de unidade do caso de uso \"Inscrever-se em campanha\"</h2>",
        f"<div>Execução no GitHub Actions · {ok_caso} de {len(do_caso)} testes passaram · "
        f"{len(do_caso) - ok_caso} falharam · suíte completa do app: {ok_app} de {len(lista)} passaram</div>",
    ]
    for arquivo in ARQUIVOS_DO_CASO_DE_USO:
        dele = [t for t in do_caso if t[0] == arquivo]
        partes.append(f"<h3>{html.escape(arquivo)} ({len(dele)} testes)</h3><table>")
        for _, nome, passou in dele:
            classe, rotulo = ("ok", "✔ PASSOU") if passou else ("nok", "✘ FALHOU")
            partes.append(f"<tr><td class={classe}>{rotulo}</td><td>{html.escape(nome)}</td></tr>")
        partes.append("</table>")
    partes.append("</body></html>")
    return "".join(partes)


if __name__ == "__main__":
    entrada, saida = sys.argv[1], sys.argv[2]
    with open(saida, "w", encoding="utf-8") as f:
        f.write(gerar_html(ler_testes(entrada)))
