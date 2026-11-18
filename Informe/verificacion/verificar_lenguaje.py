"""Compara el validador con la definicion matematica del lenguaje.

Genera todas las cadenas sobre {T, S, D, M, F} de longitud 1 a 9 y comprueba
que `validar_secuencia` acepta exactamente las cadenas de L(G).

Uso, desde cualquier directorio:
    python Informe/verificacion/verificar_lenguaje.py
"""

import sys
from itertools import product
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(RAIZ))

from backend.parser import validar_secuencia  # noqa: E402

ALFABETO = "TSDMF"
FIJOS = {"TDDTF", "MSDMF", "TSDTF", "SDSDF", "TMSTF"}


def pertenece_al_lenguaje(cadena: str) -> bool:
    if cadena in FIJOS:
        return True
    if not (cadena.startswith("TD") and cadena.endswith("F")):
        return False
    cuerpo = cadena[2:-1]
    return (
        len(cuerpo) >= 3
        and len(cuerpo) % 3 == 0
        and cuerpo == "SDT" * (len(cuerpo) // 3)
    )


def main():
    aceptadas_por_longitud = {}
    discrepancias = []
    total = 0
    for longitud in range(1, 10):
        aceptadas = 0
        for simbolos in product(ALFABETO, repeat=longitud):
            cadena = "".join(simbolos)
            total += 1
            validador = validar_secuencia(cadena).valido
            formal = pertenece_al_lenguaje(cadena)
            if validador != formal:
                discrepancias.append(cadena)
            if validador:
                aceptadas += 1
        aceptadas_por_longitud[longitud] = aceptadas

    larga = "TD" + "SDT" * 100 + "F"
    print("Cadenas evaluadas:", total)
    print("Aceptadas por longitud:", aceptadas_por_longitud)
    print("Discrepancias:", len(discrepancias))
    if discrepancias:
        print("Primeras discrepancias:", discrepancias[:10])
    print("Contrapunteo de 100 ciclos aceptado:", validar_secuencia(larga).valido)
    print("Longitud del contrapunteo de 100 ciclos:", len(larga))


if __name__ == "__main__":
    main()
