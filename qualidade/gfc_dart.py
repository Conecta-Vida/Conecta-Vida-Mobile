#!/usr/bin/env python3
"""
gfc_dart.py - gera o Grafo de Fluxo de Controle (GFC) de métodos Dart e
calcula a complexidade ciclomática, no papel do ComplexGraph (que só lê Java).

Uso:
  python3 gfc_dart.py <arquivo.dart> [--metodo nome] [--dot saida.dot] [--md saida.md]

Para cada método da classe o script:
  1. extrai o corpo do método e o divide em comandos (if/else, for, while,
     try/catch, return, throw, continue, break e comandos simples);
  2. monta o GFC: um nó por comando ou decisão, arestas pelo fluxo de controle;
     dentro de um try, cada comando com `await` tem uma aresta extra para o
     catch (a chamada pode lançar exceção), então ele também é um nó predicado;
  3. calcula V(G) = E - N + 2, V(G) = P + 1 e as regiões (R = E - N + 2, pela
     fórmula de Euler para grafos planares), conferindo que as três batem;
  4. informa também os operadores lógicos (&&, ||) e ?:, que aumentam a
     complexidade por condição (McCabe estendida).
"""
import argparse
import re
import sys
from pathlib import Path


# --------------------------------------------------------------- leitura ---
def sem_comentarios(texto):
    texto = re.sub(r"/\*.*?\*/", "", texto, flags=re.S)
    return re.sub(r"//[^\n]*", "", texto)


def fecha(texto, i, abre, fecha_):
    """Índice do caractere que fecha o par aberto em texto[i]."""
    nivel, j, aspas = 0, i, None
    while j < len(texto):
        c = texto[j]
        if aspas:
            if c == "\\":
                j += 2
                continue
            if c == aspas:
                aspas = None
        elif c in "'\"":
            aspas = c
        elif c == abre:
            nivel += 1
        elif c == fecha_:
            nivel -= 1
            if nivel == 0:
                return j
        j += 1
    raise ValueError("par não fechado")


def metodos(texto):
    """[(nome, corpo, linha_inicial)] dos métodos com corpo { } na classe."""
    achados = []
    padrao = re.compile(r"^[ ]{2}(?:static\s+)?(?:Future<[^>]*(?:<[^>]*>)?[^>]*>|[\w<>?,]+)\s+(\w+)\s*\(", re.M)
    for m in padrao.finditer(texto):
        nome = m.group(1)
        if nome in ("if", "for", "while", "switch", "catch"):
            continue
        abre_par = m.end() - 1
        fecha_par = fecha(texto, abre_par, "(", ")")
        resto = texto[fecha_par + 1:]
        m2 = re.match(r"\s*(async\s*)?\{", resto)
        if not m2:
            continue
        inicio = fecha_par + 1 + m2.end() - 1
        fim = fecha(texto, inicio, "{", "}")
        achados.append((nome, texto[inicio + 1:fim], texto[:m.start()].count("\n") + 1))
    return achados


# ----------------------------------------------------------- comandos ---
def proximo_comando(s, i):
    """Lê um comando a partir de s[i]; devolve (tipo, dados, novo_i)."""
    while i < len(s) and s[i].isspace():
        i += 1
    if i >= len(s):
        return None, None, i
    resto = s[i:]
    m = re.match(r"(if|for|while)\s*\(", resto)
    if m:
        palavra = m.group(1)
        p_ini = i + m.end() - 1
        p_fim = fecha(s, p_ini, "(", ")")
        cond = s[p_ini + 1:p_fim]
        corpo, j = bloco(s, p_fim + 1)
        if palavra == "if":
            senao = None
            k = j
            while k < len(s) and s[k].isspace():
                k += 1
            if s.startswith("else", k):
                senao, j = bloco(s, k + 4)
            return "if", (cond, corpo, senao), j
        return "laco", (cond, corpo), j
    if resto.startswith("try"):
        corpo, j = bloco(s, i + 3)
        k = j
        while k < len(s) and s[k].isspace():
            k += 1
        m = re.match(r"(on\s+\w+\s*)?catch\s*\([^)]*\)", s[k:])
        if not m:
            raise ValueError("try sem catch")
        trata, j = bloco(s, k + m.end())
        return "try", (corpo, trata), j
    if resto.startswith("{"):
        corpo, j = bloco(s, i)
        return "bloco", corpo, j
    # comando simples: até o ';' fora de parênteses/chaves/colchetes
    j, nivel, aspas = i, 0, None
    while j < len(s):
        c = s[j]
        if aspas:
            if c == "\\":
                j += 2
                continue
            if c == aspas:
                aspas = None
        elif c in "'\"":
            aspas = c
        elif c in "([{":
            nivel += 1
        elif c in ")]}":
            nivel -= 1
        elif c == ";" and nivel == 0:
            break
        j += 1
    texto = " ".join(s[i:j].split())
    tipo = "simples"
    for palavra in ("return", "throw", "continue", "break"):
        if texto == palavra or texto.startswith(palavra + " ") or texto.startswith(palavra + "("):
            tipo = palavra
    return tipo, texto, j + 1


def bloco(s, i):
    """Lê `{ ... }` ou um único comando; devolve (lista de comandos, novo_i)."""
    while i < len(s) and s[i].isspace():
        i += 1
    if i < len(s) and s[i] == "{":
        fim = fecha(s, i, "{", "}")
        return comandos(s[i + 1:fim]), fim + 1
    tipo, dados, j = proximo_comando(s, i)
    return [(tipo, dados)], j


def comandos(s):
    lista, i = [], 0
    while True:
        tipo, dados, i = proximo_comando(s, i)
        if tipo is None:
            return lista
        lista.extend(dados if tipo == "bloco" else [(tipo, dados)])


# ---------------------------------------------------------------- grafo ---
class Grafo:
    def __init__(self):
        self.rotulos, self.arestas, self.predicados = [], [], set()
        self.blocos = set()   # nós de bloco básico (comandos em sequência)

    def no(self, rotulo):
        self.rotulos.append(rotulo)
        return len(self.rotulos)

    def liga(self, a, b, rotulo=""):
        if (a, b, rotulo) not in self.arestas:
            self.arestas.append((a, b, rotulo))


def construir(lista, g, entradas, ctx):
    """Liga `entradas` [(nó, rótulo)] aos comandos; devolve as saídas abertas."""
    abertas = entradas
    for tipo, dados in lista:
        if not abertas:
            break  # código inalcançável depois de return/throw/continue
        if tipo in ("simples", "return", "throw", "continue", "break"):
            texto = dados if len(dados) < 140 else dados[:137] + "..."
            pode_lancar = ctx.get("catch") is not None and "await" in dados
            # Bloco básico: comando em sequência entra no mesmo nó do anterior
            # (como no ComplexGraph), desde que não possa lançar exceção.
            if (len(abertas) == 1 and abertas[0][1] == "" and abertas[0][0] in g.blocos
                    and not pode_lancar):
                n = abertas[0][0]
                g.rotulos[n - 1] += "; " + texto
            else:
                n = g.no(texto)
                for a, r in abertas:
                    g.liga(a, n, r)
                if not pode_lancar:
                    g.blocos.add(n)
            if pode_lancar:
                g.predicados.add(n)
                ctx["catch_entradas"].append((n, "exceção"))
            if tipo == "return" or tipo == "throw":
                g.liga(n, ctx["saida"], "")
                abertas = []
            elif tipo == "continue":
                g.liga(n, ctx["laco"], "continue")
                abertas = []
            elif tipo == "break":
                ctx["quebras"].append((n, "break"))
                abertas = []
            else:
                abertas = [(n, "ok" if pode_lancar else "")]
        elif tipo == "if":
            cond, entao, senao = dados
            n = g.no(f"if ({' '.join(cond.split())})")
            g.predicados.add(n)
            for a, r in abertas:
                g.liga(a, n, r)
            saidas = construir(entao, g, [(n, "V")], ctx)
            saidas += construir(senao, g, [(n, "F")], ctx) if senao else [(n, "F")]
            abertas = saidas
        elif tipo == "laco":
            cond, corpo = dados
            n = g.no(f"laço ({' '.join(cond.split())})")
            g.predicados.add(n)
            for a, r in abertas:
                g.liga(a, n, r)
            interno = dict(ctx, laco=n, quebras=[])
            for a, r in construir(corpo, g, [(n, "V")], interno):
                g.liga(a, n, r)
            abertas = [(n, "F")] + interno["quebras"]
        elif tipo == "try":
            corpo, trata = dados
            interno = dict(ctx, catch=True, catch_entradas=[])
            saidas = construir(corpo, g, abertas, interno)
            if interno["catch_entradas"]:
                saidas += construir(trata, g, interno["catch_entradas"], ctx)
            abertas = saidas
    return abertas


def analisar(nome, corpo):
    g = Grafo()
    inicio = g.no(f"início de {nome}()")
    g.blocos.add(inicio)
    saida_idx = len(g.rotulos) + 1
    g.rotulos.append("fim")          # nó de saída reservado
    ctx = {"saida": saida_idx, "catch": None, "quebras": []}
    for a, r in construir(comandos(sem_comentarios(corpo)), g, [(inicio, "")], ctx):
        g.liga(a, saida_idx, r)
    n, e, p = len(g.rotulos), len(g.arestas), len(g.predicados)
    logicos = len(re.findall(r"&&|\|\|", corpo)) + len(re.findall(r"\?(?![?.\s]*[>,)\]]|\.)\s", corpo))
    return g, {"metodo": nome, "N": n, "E": e, "P": p, "V_EN": e - n + 2, "V_P": p + 1,
               "R": e - n + 2, "logicos": logicos}


def dot(g, m):
    linhas = [f'digraph "{m["metodo"]}" {{',
              f'  graph [fontname="DejaVu Sans", fontsize=14, labelloc=b, rankdir=TB, nodesep=0.3, ranksep=0.22, label="{m["metodo"]}() — N = {m["N"]}, '
              f'E = {m["E"]}, P = {m["P"]}  →  V(G) = E − N + 2 = {m["V_EN"]} = P + 1 = {m["V_P"]} = R = {m["R"]}"];',
              '  node [shape=circle, fontname="DejaVu Sans", fontsize=13, width=0.42, fixedsize=true, style=filled, fillcolor="#ffffff"];',
              '  edge [fontname="DejaVu Sans", fontsize=12, arrowsize=0.6];']
    for i, _ in enumerate(g.rotulos, start=1):
        cor = "#ffe3b3" if i in g.predicados else "#ffffff"
        forma = ", shape=doublecircle" if g.rotulos[i - 1] == "fim" else ""
        linhas.append(f'  {i} [fillcolor="{cor}"{forma}];')
    for a, b, r in g.arestas:
        linhas.append(f'  {a} -> {b}' + (f' [label="{r}"]' if r else "") + ";")
    def curto(t, n=50):
        t = re.sub(r"throw const InscricaoException\(MotivoRecusa\.(\w+)\)", r"throw \1", t)
        t = re.sub(r"\$\{participante\.nome\}: ", "", t)
        t = re.sub(r"\(\s*comunicacaoId: .*", "(...)", t)
        return t if len(t) <= n else t[:n - 3] + "..."
    legenda = "\\l".join(f"{i:>2}  {curto(parte.strip()).replace(chr(34), chr(39))}" if k == 0
                          else f"    {curto(parte.strip()).replace(chr(34), chr(39))}"
                          for i, t in enumerate(g.rotulos, start=1)
                          for k, parte in enumerate(t.split("; ")))
    linhas.append(f'  legenda [shape=note, fixedsize=false, fontname="DejaVu Sans Mono", fontsize=13, fillcolor="#fffef2", label="{legenda}\\l"];')
    linhas.append("}")
    return "\n".join(linhas)


def png_lado_a_lado(texto_dot, saida):
    """Desenha o grafo e a legenda separados e junta lado a lado: a legenda
    no topo do grafo aumentaria a altura de toda a figura."""
    import subprocess
    import tempfile
    from PIL import Image
    legenda = re.search(r"  legenda \[.*?\];", texto_dot, flags=re.S).group(0)
    grafo = texto_dot.replace(legenda, "")
    so_legenda = 'digraph L { graph [pad=0.1];\n' + legenda + '\n}'
    with tempfile.TemporaryDirectory() as tmp:
        imagens = []
        for nome, conteudo in (("grafo", grafo), ("legenda", so_legenda)):
            fonte, png = Path(tmp) / f"{nome}.dot", Path(tmp) / f"{nome}.png"
            fonte.write_text(conteudo, encoding="utf-8")
            subprocess.run(["dot", "-Tpng", "-Gdpi=150", str(fonte), "-o", str(png)], check=True)
            imagens.append(Image.open(png).convert("RGB"))
    a, b = imagens
    junto = Image.new("RGB", (a.width + b.width + 30, max(a.height, b.height)), "white")
    junto.paste(a, (0, 0))
    junto.paste(b, (a.width + 30, 0))
    junto.save(saida)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("arquivo")
    ap.add_argument("--metodo")
    ap.add_argument("--dot")
    ap.add_argument("--md")
    ap.add_argument("--png", help="gera PNG com o grafo e a legenda lado a lado (requer graphviz e Pillow)")
    args = ap.parse_args()
    texto = Path(args.arquivo).read_text(encoding="utf-8")
    resultados = []
    for nome, corpo, linha in metodos(texto):
        g, m = analisar(nome, corpo)
        m["linha"] = linha
        resultados.append(m)
        if args.metodo == nome and args.dot:
            Path(args.dot).write_text(dot(g, m), encoding="utf-8")
        if args.metodo == nome and args.png:
            png_lado_a_lado(dot(g, m), args.png)
    cab = "| Método | Linha | N | E | P | V(G)=E−N+2 | V(G)=P+1 | Regiões | &&, \\|\\|, ?: |"
    tab = [cab, "|" + "---|" * 9]
    for m in resultados:
        tab.append(f"| {m['metodo']}() | {m['linha']} | {m['N']} | {m['E']} | {m['P']} | {m['V_EN']} | {m['V_P']} | {m['R']} | {m['logicos']} |")
    saida = "\n".join(tab)
    print(saida)
    if args.md:
        Path(args.md).write_text(saida + "\n", encoding="utf-8")
    ok = all(m["V_EN"] == m["V_P"] for m in resultados)
    print("\nconferência V(G) = E − N + 2 = P + 1:", "OK" if ok else "DIVERGE")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
