#!/usr/bin/env python3
"""
Engenharia reversa: lê arquivos .dart e gera um diagrama de classes em
PlantUML (padrão) ou Graphviz/DOT, com classes de produção e de teste.

Uso:
  python3 engenharia_reversa.py <arquivos ou pastas .dart> -o classes.puml
  python3 engenharia_reversa.py ... -f dot -o classes.dot

O que é extraído de cada classe/enum/classe abstrata:
  * atributos (final/var) com tipo, métodos e getters com parâmetros;
  * herança (extends) e realização (implements);
  * associação navegável quando um atributo é de outra classe do diagrama;
  * dependência quando a classe só usa a outra (parâmetro, retorno, corpo).
Arquivos de teste (_test.dart) viram uma classe <<test>> com os grupos de
teste como operações e dependência para as classes que exercitam.
"""
import argparse
import re
import sys
from pathlib import Path

CLASSE = re.compile(
    r"^(abstract\s+)?(class|enum)\s+(\w+)(?:<[^>{]*>)?"
    r"(?:\s+extends\s+([\w<>, ]+?))?(?:\s+implements\s+([\w<>, ]+?))?\s*\{",
    re.M,
)
ATRIBUTO = re.compile(r"^[ ]{2}(?:static\s+)?(?:const\s+|final\s+|late\s+final\s+)?(\w[\w<>?, ()]*?)\s+(_?\w+)\s*(?:=[^;]*)?;", re.M)
METODO = re.compile(
    r"^[ ]{2}(?:@override\s+)?(static\s+)?(\w[\w<>?, ]*?)\s+(get\s+)?(_?\w+)\s*(\([^)]*\))?\s*(?:async\s*)?(=>|\{|;)",
    re.M,
)
GRUPO = re.compile(r"group\(\s*'([^']+)'")
PALAVRAS = {"return", "if", "for", "while", "switch", "throw", "await", "new", "else"}


def corpo_da_classe(texto, inicio):
    nivel, i = 0, inicio
    while i < len(texto):
        if texto[i] == "{":
            nivel += 1
        elif texto[i] == "}":
            nivel -= 1
            if nivel == 0:
                return texto[inicio + 1:i]
        i += 1
    return texto[inicio + 1:]


def so_nivel_da_classe(corpo):
    """Remove o conteúdo dos métodos, deixando só as declarações."""
    saida, nivel, parens = [], 0, 0
    for ch in corpo:
        if ch == "(":
            parens += 1
        elif ch == ")":
            parens -= 1
        if parens > 0 and nivel == 0:
            saida.append(ch)
            continue
        if ch == "{":
            nivel += 1
            if nivel == 1:
                saida.append("{")
            continue
        if ch == "}":
            nivel -= 1
            if nivel == 0:
                saida.append("}")
            continue
        if nivel == 0:
            saida.append(ch)
    return "".join(saida)


def parametros(texto):
    texto = (texto or "").strip("(){} ")
    if not texto:
        return ""
    itens = []
    for p in re.split(r",(?![^<]*>)", texto):
        p = re.sub(r"\b(required|this\.|const)\b", "", p).split("=")[0].strip(" {}[]")
        partes = p.split()
        if len(partes) >= 2:
            itens.append(f"{partes[-1]}: {' '.join(partes[:-1])}")
        elif partes:
            itens.append(partes[0])
    return ", ".join(itens)


def ler(caminhos):
    arquivos = []
    for c in caminhos:
        p = Path(c)
        arquivos += sorted(p.rglob("*.dart")) if p.is_dir() else [p]
    return arquivos


def analisar(arquivos):
    classes = {}
    testes = []
    for arq in arquivos:
        texto = arq.read_text(encoding="utf-8")
        pacote = "teste" if "test" in arq.parts else (
            "aplicacao" if "usecases" in arq.parts else
            "infraestrutura" if "services" in arq.parts else "dominio")
        for m in CLASSE.finditer(texto):
            abstrata, tipo, nome, pai, interfaces = m.groups()
            corpo = corpo_da_classe(texto, m.end() - 1)
            declaracoes = so_nivel_da_classe(corpo)
            info = {
                "nome": nome, "tipo": "abstract class" if abstrata else tipo,
                "pacote": pacote, "pai": (pai or "").split("<")[0].strip(),
                "interfaces": [i.split("<")[0].strip() for i in (interfaces or "").split(",") if i.strip()],
                "atributos": [], "metodos": [], "corpo": corpo,
            }
            if tipo == "enum":
                valores = declaracoes.split(";")[0]
                info["atributos"] = [v.strip() for v in valores.split(",") if v.strip()]
            else:
                for t, n in ATRIBUTO.findall(declaracoes):
                    t = t.strip()
                    if t in PALAVRAS or ("(" in t and "Function" not in t) or t.endswith(" get") or t == "get":
                        continue
                    info["atributos"].append((n, "" if t in ("const", "final") else t))
                for static, ret, get, n, params, fim in METODO.findall(declaracoes):
                    ret = ret.strip()
                    if ret in PALAVRAS or n in PALAVRAS or ret in ("const", "final"):
                        continue
                    if fim == ";" and not params:
                        continue  # é atributo, não método
                    if ret.startswith("factory") or ret == nome or n == nome:
                        continue  # construtores ficam fora do diagrama
                    rotulo = (n + ("" if get else "(" + parametros(params) + ")"))
                    info["metodos"].append((rotulo, "", (ret + (" {static}" if static else "")).strip()))
            classes[nome] = info
        if arq.name.endswith("_test.dart"):
            nome = "".join(p.capitalize() for p in arq.stem.split("_"))
            testes.append({"nome": nome, "grupos": GRUPO.findall(texto), "corpo": texto})
    return classes, testes


def relacoes(classes, testes):
    nomes = set(classes)
    rels = set()
    for c in classes.values():
        if c["pai"] in nomes:
            rels.add((c["nome"], c["pai"], "heranca"))
        for i in c["interfaces"]:
            if i in nomes:
                rels.add((c["nome"], i, "realizacao"))
        tipos_atributos = {re.sub(r"[?<>]|List|Set|Map", " ", t) for _, t in c["atributos"]} if c["tipo"] != "enum" else set()
        associados = {n for n in nomes for t in tipos_atributos if re.search(rf"\b{n}\b", t)}
        for n in associados - {c["nome"]}:
            rels.add((c["nome"], n, "associacao"))
        for n in nomes - associados - {c["nome"], c["pai"], *c["interfaces"]}:
            if re.search(rf"\b{n}\b", c["corpo"]):
                rels.add((c["nome"], n, "dependencia"))
    for t in testes:
        for n in nomes:
            if re.search(rf"\b{n}\b", t["corpo"]):
                rels.add((t["nome"], n, "dependencia"))
    return sorted(rels)


def plantuml(classes, testes, rels):
    linhas = ["@startuml", "skinparam classAttributeIconSize 0", "skinparam packageStyle rectangle",
              "left to right direction", "hide empty members"]
    pacotes = {}
    for c in classes.values():
        pacotes.setdefault(c["pacote"], []).append(c)
    for pacote, itens in pacotes.items():
        linhas.append(f'package "{pacote}" {{')
        for c in itens:
            estereotipo = " <<test double>>" if pacote == "teste" else ""
            linhas.append(f"  {c['tipo']} {c['nome']}{estereotipo} {{")
            if c["tipo"] == "enum":
                linhas += [f"    {v}" for v in c["atributos"]]
            else:
                linhas += [f"    {'-' if n.startswith('_') else '+'}{n.lstrip('_')}" + (f": {t}" if t else "") for n, t in c["atributos"]]
                linhas += [f"    {'-' if n.startswith('_') else '+'}{n.lstrip('_')}" + (f": {r}" if r else "")
                           for n, p, r in c["metodos"]]
            linhas.append("  }")
        if pacote == "teste":
            for t in testes:
                linhas.append(f"  class {t['nome']} <<test>> {{")
                linhas += [f"    +{g}()" for g in t["grupos"]]
                linhas.append("  }")
        linhas.append("}")
    if testes and "teste" not in pacotes:
        linhas.append('package "teste" {')
        for t in testes:
            linhas.append(f"  class {t['nome']} <<test>> {{")
            linhas += [f"    +{g}()" for g in t["grupos"]]
            linhas.append("  }")
        linhas.append("}")
    seta = {"heranca": "--|>", "realizacao": "..|>", "associacao": "-->", "dependencia": "..>"}
    linhas += [f"{a} {seta[t]} {b}" for a, b, t in rels]
    linhas.append("@enduml")
    return "\n".join(linhas)


EMPILHAR = False


def quebrar(texto, largura=36):
    """Quebra assinaturas longas nas vírgulas, com recuo nas linhas seguintes."""
    if len(texto) <= largura:
        return [texto]
    partes, linhas, atual = re.split(r"(?<=,)\s", texto), [], ""
    for parte in partes:
        if atual and len(atual) + len(parte) + 1 > largura:
            linhas.append(atual)
            atual = "      " + parte
        else:
            atual = (atual + " " + parte) if atual else parte
    linhas.append(atual)
    # retorno longo vai para a linha seguinte
    final = []
    for linha in linhas:
        if len(linha) > largura and "): " in linha:
            a, b = linha.rsplit("): ", 1)
            final += [a + "):", "      " + b.strip()]
        else:
            final.append(linha)
    return final


def dot(classes, testes, rels):
    def esc(s):
        return s.replace("<", "&lt;").replace(">", "&gt;").replace("{", "\\{").replace("}", "\\}").replace("|", "\\|")
    linhas = ['digraph classes {', 'rankdir=BT; nodesep=0.25; ranksep=0.5; pad=0.1; concentrate=true;',
              'node [shape=record, fontname="DejaVu Sans", fontsize=12, style=filled, fillcolor="#ffffff"];',
              'edge [fontname="DejaVu Sans", fontsize=11];']
    pacotes = {}
    for c in classes.values():
        pacotes.setdefault(c["pacote"], []).append(c)
    if testes:
        pacotes.setdefault("teste", [])
    for i, (pacote, itens) in enumerate(pacotes.items()):
        cores = {"aplicacao": "#eef4fb", "dominio": "#f2f8ee", "infraestrutura": "#fff6e6", "teste": "#f5f0fb"}
        linhas.append(f'subgraph cluster_{i} {{ label="«pacote» {pacote}"; style="rounded,filled"; fillcolor="{cores.get(pacote, "#ffffff")}"; color=gray40; fontname="DejaVu Sans"; fontsize=13; labelloc=t;')
        for c in itens:
            cab = ("«enumeration»\\n" if c["tipo"] == "enum" else "«abstract»\\n" if "abstract" in c["tipo"] else
                   "«test double»\\n" if pacote == "teste" else "") + c["nome"]
            if c.get("resumida"):
                linhas.append(f'  {c["nome"]} [shape=box, label="{cab}"];')
                continue
            if c["tipo"] == "enum":
                attrs = "\\l".join(esc(v) for v in c["atributos"])
                mets = ""
            else:
                attrs = "\\l".join(esc(f"{'-' if n.startswith('_') else '+'}{n.lstrip('_')}" + (f": {t}" if t else "")) for n, t in c["atributos"])
                mets = "\\l".join(esc(linha) for n, p, r in c["metodos"]
                                  for linha in quebrar(f"{'-' if n.startswith('_') else '+'}{n.lstrip('_')}" + (f": {r}" if r else "")))
            linhas.append(f'  {c["nome"]} [label="{{{cab}|{attrs}{chr(92)+"l" if attrs else ""}|{mets}{chr(92)+"l" if mets else ""}}}"];')
        if pacote == "teste":
            for t in testes:
                mets = "\\l".join(esc(f"+{g}()") for g in t["grupos"])
                linhas.append(f'  {t["nome"]} [label="{{«test»\\n{t["nome"]}||{mets}\\l}}"];')
        linhas.append("}")
    # --empilhar: classes resumidas de um mesmo pacote ficam em coluna
    for pacote, itens in (pacotes.items() if EMPILHAR else []):
        resumidas = [c["nome"] for c in itens if c.get("resumida")]
        for a, b in zip(resumidas, resumidas[1:]):
            linhas.append(f"  {a} -> {b} [style=invis];")
    estilo = {"heranca": "arrowhead=empty", "realizacao": "arrowhead=empty, style=dashed",
              "associacao": "arrowhead=vee", "dependencia": "arrowhead=vee, style=dashed"}
    linhas += [f"  {a} -> {b} [{estilo[t]}];" for a, b, t in rels]
    linhas.append("}")
    return "\n".join(linhas)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("caminhos", nargs="+")
    ap.add_argument("-o", "--saida", required=True)
    ap.add_argument("-f", "--formato", choices=["puml", "dot"], default="puml")
    ap.add_argument("--relacoes-de", default="",
                    help="mostra só as relações que saem das classes destes pacotes")
    ap.add_argument("--empilhar", action="store_true",
                    help="empilha em coluna as classes resumidas de cada pacote")
    ap.add_argument("--resumir", default="",
                    help="pacotes (separados por vírgula) cujas classes aparecem só com o nome")
    args = ap.parse_args()
    global EMPILHAR
    EMPILHAR = args.empilhar
    classes, testes = analisar(ler(args.caminhos))
    for c in classes.values():
        if c["pacote"] in [p.strip() for p in args.resumir.split(",") if p.strip()]:
            c["atributos"], c["metodos"], c["resumida"] = [], [], True
    rels = relacoes(classes, testes)
    if args.relacoes_de:
        pacotes = {p.strip() for p in args.relacoes_de.split(",")}
        nomes_teste = {t["nome"] for t in testes}
        rels = [r for r in rels if (classes.get(r[0], {}).get("pacote") in pacotes)
                or ("teste" in pacotes and r[0] in nomes_teste)]
    texto = (plantuml if args.formato == "puml" else dot)(classes, testes, rels)
    Path(args.saida).write_text(texto, encoding="utf-8")
    print(f"{len(classes)} classes, {len(testes)} arquivos de teste, {len(rels)} relações -> {args.saida}")


if __name__ == "__main__":
    sys.exit(main())
