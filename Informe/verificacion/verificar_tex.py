"""Comprobaciones estructurales del archivo main.tex (sin compilar).

Uso:  python Informe/verificacion/verificar_tex.py
"""
import re
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
TEX = (RAIZ / "main.tex").read_text(encoding="utf-8")
BIB = (RAIZ / "refs.bib").read_text(encoding="utf-8")

fallos = []


def comprobar(cond, mensaje):
    print(("OK   " if cond else "FALLA") + "  " + mensaje)
    if not cond:
        fallos.append(mensaje)


# 1. Entornos balanceados
pila = []
for m in re.finditer(r"\\(begin|end)\{([^}]*)\}", TEX):
    tipo, nombre = m.group(1), m.group(2)
    if tipo == "begin":
        pila.append((nombre, TEX[: m.start()].count("\n") + 1))
    else:
        if not pila or pila[-1][0] != nombre:
            print(f"FALLA  \\end{{{nombre}}} sin \\begin (linea {TEX[:m.start()].count(chr(10))+1})")
            fallos.append(nombre)
        else:
            pila.pop()
comprobar(not pila, f"entornos \\begin/\\end balanceados (pendientes: {pila})")

# 2. Llaves y corchetes
llaves = TEX.count("{") - TEX.count("\\{")
cierra = TEX.count("}") - TEX.count("\\}")
comprobar(llaves == cierra, f"llaves balanceadas ({llaves} abren, {cierra} cierran)")

# 3. Citas frente a refs.bib
claves_bib = set(re.findall(r"@\w+\{([^,]+),", BIB))
citas = set()
for m in re.finditer(r"\\cite\{([^}]*)\}", TEX):
    citas.update(k.strip() for k in m.group(1).split(","))
comprobar(not (citas - claves_bib), f"citas sin entrada en refs.bib: {sorted(citas - claves_bib)}")
print(f"     entradas sin citar: {sorted(claves_bib - citas)}")
comprobar(len(citas) == len(claves_bib), f"{len(citas)} claves citadas de {len(claves_bib)} en el .bib")

# 3b. Estilo de refs.bib: autor con nombre completo y sin direccion editorial
comprobar("address" not in BIB.lower(), "sin campos address en refs.bib")
autores = re.findall(r"author\s*=\s*\{([^}]*)\}", BIB)
con_coma = [a for a in autores if re.search(r"[A-Za-zÁÉÍÓÚáéíóúñÑü]+,\s", a)]
comprobar(not con_coma, f"autores con formato 'Apellido, Nombre': {con_coma}")
entradas_bib = [e for e in re.split(r"\n(?=@)", BIB.strip()) if e.strip()]
sin_year = [re.match(r"@\w+\{([^,]+),", e).group(1) for e in entradas_bib if not re.search(r"\byear\s*=", e)]
comprobar(not sin_year, f"entradas sin year: {sin_year}")

# 4. Referencias cruzadas
etiquetas = set(re.findall(r"\\label\{([^}]*)\}", TEX))
refs = set()
for m in re.finditer(r"\\[cC]ref\{([^}]*)\}", TEX):
    refs.update(k.strip() for k in m.group(1).split(","))
comprobar(not (refs - etiquetas), f"\\cref sin \\label: {sorted(refs - etiquetas)}")
print(f"     etiquetas nunca referenciadas: {sorted(etiquetas - refs)}")

# 5. Elementos obligatorios de la plantilla ieeeconf v1.1
obligatorios = {
    r"\documentclass[9pt]{ieeeconf}": "clase con opcion 9pt",
    r"\usepackage{bm}": "paquete bm",
    r"\usepackage{siunitx}": "paquete siunitx",
    r"\robustify\bfseries": "robustify bfseries",
    r"\usepackage{booktabs}": "paquete booktabs",
    r"\usepackage[capitalize,nameinlink]{cleveref}": "cleveref con opciones de plantilla",
    r"\crefname{equation}{}{}": "ecuaciones sin nombre",
    r"\title{": "titulo",
    r"\addauthor{": "autores con addauthor",
    r"\addaffiliation{": "afiliacion con addaffiliation",
    r"\begin{abstract}": "resumen",
    r"\begin{thebibliography}{00}": "bibliografia integrada",
}
for cmd, desc in obligatorios.items():
    comprobar(cmd in TEX, f"presente: {desc}")

# El articulo no lleva apendices; el material se conserva aparte.
comprobar(r"\appendix" not in TEX, "sin apendices en el articulo")
comprobar((RAIZ / "apendices_opcionales.tex").exists(), "material de apendice archivado aparte")

# 6. Restos que no deberian quedar
prohibidos = [r"\section*", r"\subsection*", r"Listado~", r"\vspace", r"\SI{"]
for p in prohibidos:
    comprobar(p not in TEX, f"sin restos de: {p}")

# 7. Contenido retirado por decision editorial del informe
retirados = {
    "HTTP": "solo se usa TCP como transporte",
    "latencia": "no se reportan mediciones de rendimiento",
    "benchmark": "no se reportan mediciones de rendimiento",
    "prueba unitaria": "no se reportan pruebas automatizadas",
    "unittest": "no se reportan pruebas automatizadas",
    "2\\,441\\,405": "no se reportan verificaciones exhaustivas",
}
for palabra, motivo in retirados.items():
    comprobar(palabra.lower() not in TEX.lower(), f"sin '{palabra}' ({motivo})")

# 8. Figuras externas presentes
graphicpath_groups = re.findall(r"\\graphicspath\{((?:\{[^}]*\})+)\}", TEX)
graphicpaths = [prefijo for grupo in graphicpath_groups for prefijo in re.findall(r"\{([^}]*)\}", grupo)]
for ruta in re.findall(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]*)\}", TEX):
    candidatos = [RAIZ / ruta]
    for prefijo in graphicpaths:
        candidatos.append(RAIZ / prefijo / ruta)
    comprobar(any(candidato.exists() for candidato in candidatos), f"existe la figura {ruta}")

# 9. Marcadores para completar
marcadores = re.findall(r"\[Completar[^\]]*\]", TEX)
print(f"     marcadores pendientes: {len(marcadores)} -> {sorted(set(marcadores))}")

print()
if fallos:
    print(f"RESULTADO: {len(fallos)} comprobacion(es) fallida(s)")
    sys.exit(1)
print(f"RESULTADO: todas las comprobaciones pasaron ({TEX.count(chr(10))+1} lineas)")
