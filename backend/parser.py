"""Validador del lenguaje del cuatro llanero.

La gramática fuente esta en ``CuatroLlanero.g4``. Este parser recursivo mantiene
la misma estructura y permite ejecutar el servidor sin JFLAP ni una instalacion
local de ANTLR.
"""

from dataclasses import dataclass
from typing import Optional


@dataclass(frozen=True)
class ParseResult:
    valido: bool
    golpe: Optional[str]
    accion: str
    error: Optional[str]


_FIXED_GOLPES = {
    "TDDTF": ("Golpe de Gaban", "A"),
    "MSDMF": ("Golpe de Pajarillo", "A"),
    "TSDTF": ("Seis por Derecho", "D"),
    "SDSDF": ("Zumbe y Zumbe", "D"),
    "TMSTF": ("Tonada de Sabana", "C"),
}


def _es_contrapunteo(cadena: str) -> bool:
    if not cadena.startswith("TD") or not cadena.endswith("F"):
        return False
    cuerpo = cadena[2:-1]
    return len(cuerpo) >= 3 and len(cuerpo) % 3 == 0 and cuerpo == "SDT" * (len(cuerpo) // 3)


def validar_secuencia(cadena: str) -> ParseResult:
    """Valida una secuencia completa, incluyendo el frenao final ``F``."""
    if not isinstance(cadena, str):
        return ParseResult(False, None, "E", "La secuencia debe ser texto")

    normalizada = "".join(cadena.split())
    if not normalizada:
        return ParseResult(False, None, "E", "La secuencia esta vacia")
    if any(simbolo not in "TSDMF" for simbolo in normalizada):
        return ParseResult(False, None, "E", "Contiene un simbolo fuera del alfabeto")

    golpe = _FIXED_GOLPES.get(normalizada)
    if golpe is not None:
        return ParseResult(True, golpe[0], golpe[1], None)
    if _es_contrapunteo(normalizada):
        return ParseResult(True, "Contrapunteo Libre", "A", None)
    return ParseResult(False, None, "E", "La secuencia no pertenece a la gramatica")
