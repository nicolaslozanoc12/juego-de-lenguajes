"""Gramática formal y analizador sintáctico del Cuatro Llanero."""

from .parser import ParseResult, validar_secuencia

__all__ = ["ParseResult", "validar_secuencia"]
