"""Analizador léxico y sintáctico del Cuatro Llanero usando ANTLR4.

Construye el lexer, parser, árbol sintáctico y ``ErrorListener`` a partir de los
archivos generados desde ``CuatroLlanero.g4``.
"""

from dataclasses import dataclass
from typing import List, Optional

from antlr4 import CommonTokenStream, InputStream, ParseTreeWalker
from antlr4.error.ErrorListener import ErrorListener

from .CuatroLlaneroLexer import CuatroLlaneroLexer
from .CuatroLlaneroListener import CuatroLlaneroListener
from .CuatroLlaneroParser import CuatroLlaneroParser


@dataclass(frozen=True)
class ParseResult:
    """Resultado de validar una secuencia musical contra la gramática."""

    valido: bool
    golpe: Optional[str]
    accion: str
    error: Optional[str]


class CuatroErrorListener(ErrorListener):
    """Captura errores léxicos y sintácticos reportados por ANTLR4."""

    def __init__(self) -> None:
        super().__init__()
        self.errors: List[str] = []

    def syntaxError(self, recognizer, offendingSymbol, line, column, msg, e) -> None:
        self.errors.append(f"columna {column}: {msg}")


class _GolpeListener(CuatroLlaneroListener):
    """Recorre el árbol de derivación para identificar el golpe ejecutado."""

    def __init__(self) -> None:
        self.golpe: Optional[str] = None
        self.accion: str = "E"

    def enterGaban(self, ctx: CuatroLlaneroParser.GabanContext) -> None:
        self.golpe, self.accion = "Golpe de Gaban", "A"

    def enterPajarillo(self, ctx: CuatroLlaneroParser.PajarilloContext) -> None:
        self.golpe, self.accion = "Golpe de Pajarillo", "A"

    def enterSeisPorDerecho(self, ctx: CuatroLlaneroParser.SeisPorDerechoContext) -> None:
        self.golpe, self.accion = "Seis por Derecho", "D"

    def enterZumbeYZumbe(self, ctx: CuatroLlaneroParser.ZumbeYZumbeContext) -> None:
        self.golpe, self.accion = "Zumbe y Zumbe", "D"

    def enterTonada(self, ctx: CuatroLlaneroParser.TonadaContext) -> None:
        self.golpe, self.accion = "Tonada de Sabana", "C"

    def enterContrapunteo(self, ctx: CuatroLlaneroParser.ContrapunteoContext) -> None:
        self.golpe, self.accion = "Contrapunteo Libre", "A"


def validar_secuencia(cadena: str) -> ParseResult:
    """Valida una secuencia completa mediante ANTLR4, incluyendo el frenao final ``F``."""
    if not isinstance(cadena, str):
        return ParseResult(False, None, "E", "ERROR_SINTACTICO: la secuencia debe ser texto")
    if not cadena.strip():
        return ParseResult(False, None, "E", "ERROR_SINTACTICO: la secuencia esta vacia")

    error_listener = CuatroErrorListener()
    lexer = CuatroLlaneroLexer(InputStream(cadena))
    lexer.removeErrorListeners()
    lexer.addErrorListener(error_listener)

    parser = CuatroLlaneroParser(CommonTokenStream(lexer))
    parser.removeErrorListeners()
    parser.addErrorListener(error_listener)

    tree = parser.ejecucion()
    if error_listener.errors:
        return ParseResult(False, None, "E", f"ERROR_SINTACTICO: {error_listener.errors[0]}")

    listener = _GolpeListener()
    ParseTreeWalker.DEFAULT.walk(listener, tree)
    if listener.golpe is None:
        return ParseResult(False, None, "E", "ERROR_SINTACTICO: la secuencia no pertenece a la gramatica")

    return ParseResult(True, listener.golpe, listener.accion, None)
