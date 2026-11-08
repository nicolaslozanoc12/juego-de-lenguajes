"""Backend del juego de cuatro llanero."""

from .formal.grammar.parser import ParseResult, validar_secuencia
from .formal.turing.turing import MultiTapeTuringMachine
from .game.combat import CombatController

__all__ = [
    "CombatController",
    "MultiTapeTuringMachine",
    "ParseResult",
    "validar_secuencia",
]
