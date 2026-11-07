"""Backend del juego de cuatro llanero."""

from .combat import CombatController
from .parser import ParseResult, validar_secuencia
from .turing import MultiTapeTuringMachine

__all__ = [
    "CombatController",
    "MultiTapeTuringMachine",
    "ParseResult",
    "validar_secuencia",
]
