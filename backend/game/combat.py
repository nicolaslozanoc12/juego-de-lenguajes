"""Resolución de turnos entre el llanero y el enemigo."""

from dataclasses import dataclass
from typing import Any, Dict

from backend.formal.grammar.parser import ParseResult, validar_secuencia
from backend.formal.turing.turing import MultiTapeTuringMachine, TuringStep


@dataclass
class CombatState:
    vida_jugador: int = 100
    vida_enemigo: int = 100


class CombatController:
    def __init__(self) -> None:
        self.state = CombatState()
        self.turing = MultiTapeTuringMachine()

    def reset(self) -> None:
        self.state = CombatState()
        self.turing = MultiTapeTuringMachine()

    def process(self, secuencia: str) -> Dict[str, Any]:
        parsed = validar_secuencia(secuencia)
        turing_step = self.turing.step(parsed.accion)
        dano_enemigo = self._dano_del_jugador(parsed)
        dano_jugador = self._dano_del_enemigo(turing_step, parsed.accion)
        self.state.vida_enemigo = max(0, self.state.vida_enemigo - dano_enemigo)
        if self.state.vida_enemigo == 0:
            dano_jugador = 0
        self.state.vida_jugador = max(0, self.state.vida_jugador - dano_jugador)

        response: Dict[str, Any] = {
            "valido": parsed.valido,
            "golpe": parsed.golpe,
            "accion": parsed.accion,
            "error": parsed.error,
            "dano_enemigo": dano_enemigo,
            "dano_jugador": dano_jugador,
            "enemigo_accion": turing_step.decision,
            "vida_jugador": self.state.vida_jugador,
            "vida_enemigo": self.state.vida_enemigo,
            "estado": "VICTORIA" if self.state.vida_enemigo == 0 else (
                "DERROTA" if self.state.vida_jugador == 0 else "JUGANDO"
            ),
            "cintas": turing_step.cintas,
            "cabezales": turing_step.cabezales,
        }
        return response

    @staticmethod
    def _dano_del_jugador(parsed: ParseResult) -> int:
        if not parsed.valido:
            return 0
        if parsed.golpe == "Golpe de Pajarillo":
            return 30
        if parsed.golpe == "Contrapunteo Libre":
            return 25
        if parsed.golpe == "Golpe de Gaban":
            return 15
        return 0

    @staticmethod
    def _dano_del_enemigo(step: TuringStep, accion: str) -> int:
        if accion == "E":
            return 35
        if accion == "D":
            return 0
        return {"ATAQUE_RAPIDO": 10, "ATAQUE_PESADO": 20, "CASTIGO": 35}.get(step.decision, 0)
