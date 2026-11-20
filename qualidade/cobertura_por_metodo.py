#!/usr/bin/env python3
"""
cobertura_por_metodo.py - relatório de cobertura por PACOTE, CLASSE e MÉTODO
(no estilo do JaCoCo) a partir do lcov.info gerado por `flutter test --coverage`.

O lcov do Dart só informa linhas (DA:linha,execuções). O script localiza cada
método/getter/construtor nas classes do arquivo .dart, soma as linhas
instrumentadas e as executadas dentro dele e indica se o método foi testado.

Uso:
  python3 cobertura_por_metodo.py lcov.info lib/usecases lib/models/inscricao.dart ... \
      --html cobertura-metodos.html --md cobertura-metodos.md
"""
import argparse
import html
import re
from pathlib import Path

CLASSE = re.compile(r"^(?:abstract\s+)?(?:class|enum)\s+(\w+)", re.M)
MEMBRO = re.compile(
    r"^[ ]{2}(?:@override\s+)?(?:static\s+|factory\s+|const\s+)*"
    r"(?:[\w<>?,\s]+?\s+)?(get\s+)?(\w+(?:\.\w+)?)\s*(\([^;{]*?\))?\s*(?:async\s*)?(=>|\{|:)",
    re.M | re.S,
)
IGNORAR = {"if", "for", "while", "switch", "return", "catch"}


def ler_lcov(caminho):
    linhas, atual = {}, None
    for l in Path(caminho).read_text().splitlines():
        if l.startswith("SF:"):
            atual = l[3:]
            linhas.setdefault(atual, {})
        elif l.startswith("DA:") and atual:
            n, qtd = l[3:].split(",")[:2]
            linhas[atual][int(n)] = int(qtd)
    return linhas


def fim_do_membro(texto, i, tipo):
    """Posição final do corpo: chave correspondente ou ';' do =>."""
    if tipo == "=>" or tipo == ":":
        nivel = 0
        for j in range(i, len(texto)):
            c = texto[j]
            if c in "([{":
                nivel += 1
            elif c in ")]}":
                nivel -= 1
            elif c == ";" and nivel <= 0:
                return j
        return len(texto) - 1
    nivel = 0
    for j in range(i, len(texto)):
        if texto[j] == "{":
            nivel += 1
        elif texto[j] == "}":
            nivel -= 1
            if nivel == 0:
                return j
    return len(texto) - 1


def fecha_par(texto, i):
    nivel = 0
    for j in range(i, len(texto)):
        if texto[j] == "(":
            nivel += 1
        elif texto[j] == ")":
            nivel -= 1
            if nivel == 0:
                return j
    return len(texto) - 1


def membros(texto):
    """[(classe, membro, linha_ini, linha_fim)] — só declarações no nível da classe."""
    linha_de = lambda pos: texto.count("\n", 0, pos) + 1
    classes = [(m.group(1), m.start()) for m in CLASSE.finditer(texto)]
    resultado = []
    for m in re.finditer(r"^  (?=[^\s/@}])(.*)$", texto, re.M):
        linha = m.group(1)
        dono = None
        for c, pos in classes:
            if pos < m.start():
                dono = c
        if dono is None:
            continue
        g = re.match(r"(?:static\s+)?(?:[\w<>?,]+\s+)?get\s+(\w+)\s*(=>|\{)", linha)
        if g:
            corpo_ini = m.start() + 2 + g.end() - 1
            fim = fim_do_membro(texto, corpo_ini, "=>" if g.group(2) == "=>" else "{")
            resultado.append((dono, g.group(1), linha_de(m.start()), linha_de(fim)))
            continue
        f = re.match(r"((?:static|factory|const|@override|Future<.*?>+|[\w<>?,]+)\s+)*?(\w+(?:\.\w+)?)\s*\(", linha)
        if not f or f.group(2) in IGNORAR:
            continue
        abre = m.start() + 2 + f.end() - 1
        fecha_ = fecha_par(texto, abre)
        resto = texto[fecha_ + 1:]
        r = re.match(r"\s*(?:async\s*)?(=>|\{|:|;)", resto)
        if not r or r.group(1) == ";":
            continue  # abstrato, construtor sem corpo ou chamada
        tipo = r.group(1)
        corpo_ini = fecha_ + 1 + r.end() - 1
        fim = fim_do_membro(texto, corpo_ini, tipo)
        resultado.append((dono, f.group(2) + "()", linha_de(m.start()), linha_de(fim)))
    return resultado


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("lcov")
    ap.add_argument("fontes", nargs="+")
    ap.add_argument("--html")
    ap.add_argument("--md")
    a = ap.parse_args()
    cobertura = ler_lcov(a.lcov)
    arquivos = []
    for f in a.fontes:
        p = Path(f)
        arquivos += sorted(p.rglob("*.dart")) if p.is_dir() else [p]

    linhas_tab = []
    for arq in arquivos:
        chave = next((k for k in cobertura if k.endswith(str(arq))), None)
        da = cobertura.get(chave, {})
        pacote = "aplicacao" if "usecases" in arq.parts else "dominio" if "models" in arq.parts else "infraestrutura"
        for classe, membro, ini, fim in membros(arq.read_text(encoding="utf-8")):
            inst = [n for n in da if ini <= n <= fim]
            exec_ = [n for n in inst if da[n] > 0]
            if not inst:
                continue  # sem código executável (ex.: declaração abstrata)
            linhas_tab.append((pacote, arq.name, classe, membro, len(exec_), len(inst)))

    def pct(a_, b_):
        return 100.0 * a_ / b_ if b_ else 0.0

    md = ["| Pacote | Classe | Método | Linhas cobertas | % | Testado |", "|---|---|---|---|---|---|"]
    for pac, arq, cl, mb, e, t in linhas_tab:
        md.append(f"| {pac} | {cl} | {mb} | {e}/{t} | {pct(e, t):.0f}% | {'sim' if e else 'não'} |")
    total_m = len(linhas_tab)
    testados = sum(1 for x in linhas_tab if x[4])
    md.append(f"\nMétodos testados: {testados} de {total_m}.")
    texto_md = "\n".join(md)
    print(texto_md)
    if a.md:
        Path(a.md).write_text(texto_md + "\n", encoding="utf-8")

    if a.html:
        por_classe = {}
        for pac, arq, cl, mb, e, t in linhas_tab:
            por_classe.setdefault((pac, cl), []).append((mb, e, t))
        h = ["<html><head><meta charset='utf-8'><title>Cobertura por método</title><style>",
             "body{font-family:DejaVu Sans,Arial;font-size:12px;margin:16px}h1{font-size:17px}",
             "table{border-collapse:collapse;margin-bottom:10px;width:760px}th{background:#5b6fa8;color:#fff;text-align:left}",
             "td,th{border:1px solid #bbb;padding:3px 7px}.c{background:#c6efce}.p{background:#fff2cc}.n{background:#f8cbad}",
             ".cl{background:#dce6f1;font-weight:bold}.bar{display:inline-block;height:9px;background:#3c9b42}",
             ".bg{display:inline-block;width:80px;height:9px;background:#e06666;vertical-align:middle}</style></head><body>",
             "<h1>Cobertura por pacote, classe e método — caso de uso \"Inscrever-se em campanha\"</h1>",
             f"<p>Fonte: lcov.info do <code>flutter test --coverage</code>. Métodos testados: <b>{testados} de {total_m}</b>.</p>"]
        pacotes = {}
        for (pac, cl), itens in por_classe.items():
            pacotes.setdefault(pac, []).append((cl, itens))
        for pac, classes in pacotes.items():
            e_p = sum(e for _, it in classes for _, e, _ in it)
            t_p = sum(t for _, it in classes for _, _, t in it)
            h.append(f"<h2 style='font-size:14px'>Pacote {pac} — {pct(e_p, t_p):.1f}% das linhas</h2>")
            h.append("<table><tr><th>Classe / método</th><th>Linhas</th><th>Cobertura</th><th>Testado</th></tr>")
            for cl, itens in classes:
                e_c = sum(e for _, e, _ in itens)
                t_c = sum(t for _, _, t in itens)
                h.append(f"<tr class='cl'><td>{html.escape(cl)}</td><td>{e_c}/{t_c}</td><td>{pct(e_c, t_c):.0f}%</td><td></td></tr>")
                for mb, e, t in itens:
                    classe_css = "c" if e == t else ("p" if e else "n")
                    barra = f"<span class='bg'><span class='bar' style='width:{pct(e, t) * 0.8:.0f}px'></span></span>"
                    h.append(f"<tr><td>&nbsp;&nbsp;{html.escape(mb)}</td><td>{e}/{t}</td>"
                             f"<td>{barra} {pct(e, t):.0f}%</td><td class='{classe_css}'>{'sim' if e else 'não'}</td></tr>")
            h.append("</table>")
        h.append("</body></html>")
        Path(a.html).write_text("".join(h), encoding="utf-8")


if __name__ == "__main__":
    main()
